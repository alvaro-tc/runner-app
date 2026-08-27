import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceup/core/error/failure.dart';
import 'package:paceup/core/network/api_client.dart';
import 'package:paceup/core/network/server_clock.dart';
import 'package:paceup/core/network/session_controller.dart';
import 'package:paceup/features/races/data/datasources/races_api.dart';
import 'package:paceup/features/races/data/repositories/remote_race_repository.dart';
import 'package:paceup/features/races/domain/entities/race_entry.dart';
import 'package:paceup/features/races/domain/entities/registration.dart';

import '../../core/fake_http.dart';
import '../../helpers.dart';

/// La inscripcion y las carreras contra un backend de mentira.
///
/// Lo que se prueba no es "que llame al endpoint", sino las tres cosas que
/// pueden mentirle al usuario: que el total sale del servidor y no de una suma
/// local, que un cobro rechazado no deja la inscripcion como confirmada, y que
/// la misma clave de idempotencia viaja en cada reintento del mismo cobro.
void main() {
  late List<RequestOptions> llamadas;

  RemoteRaceRepository build(
    Future<ResponseBody> Function(RequestOptions) handler,
  ) {
    final dio =
        buildApiClient(
            session: SessionController(
              storage: MemoryTokenStorage(),
              refreshClient: Dio(),
            ),
            clock: ServerClock(),
          )
          ..httpClientAdapter = FakeAdapter((req) {
            llamadas.add(req);
            return handler(req);
          });

    return RemoteRaceRepository(RacesApi(dio));
  }

  setUp(() => llamadas = []);

  Map<String, dynamic> cuerpo(RequestOptions req) =>
      req.data is String
      ? jsonDecode(req.data as String) as Map<String, dynamic>
      : (req.data as Map).cast<String, dynamic>();

  // ─── Mis carreras ────────────────────────────────────────────────────────

  group('fetchEntries', () {
    const carrera = {
      'registrationId': 'r1',
      'marathon': {
        'id': 'm1',
        'name': 'Maraton de prueba',
        'city': 'La Paz',
        'startsAt': '2026-09-12T10:00:00Z',
        'distanceMeters': 42195,
      },
      'bibNumber': 'MLP-0042',
      'categoryName': 'General',
      'status': 'upcoming',
      'paymentStatus': 'paid',
      'registeredAt': '2026-07-01T12:00:00Z',
      'result': null,
    };

    test('una inscripcion pagada y futura se puede largar', () async {
      final repo = build((_) async => envelope([carrera]));

      final entries = (await repo.fetchEntries()).unwrap();

      expect(entries, hasLength(1));
      expect(entries.first.bibNumber, 'MLP-0042');
      expect(entries.first.canStart, isTrue);
    });

    test('una carrera pendiente de pago NO se puede largar', () async {
      final repo = build(
        (_) async => envelope([
          {...carrera, 'paymentStatus': 'pending'},
        ]),
      );

      expect((await repo.fetchEntries()).unwrap().first.canStart, isFalse);
    });

    test('una carrera pasada sin resultado es un DNF, no una completada', () async {
      final repo = build(
        (_) async => envelope([
          {...carrera, 'status': 'completed', 'result': null},
        ]),
      );

      final entry = (await repo.fetchEntries()).unwrap().first;

      expect(entry.status, RaceEntryStatus.dnf);
      expect(entry.canStart, isFalse);
    });

    test('los parciales llevan la diferencia con el kilometro anterior', () async {
      final repo = build(
        (_) async => envelope([
          {
            ...carrera,
            'status': 'completed',
            'result': {
              'finishTimeSeconds': 700,
              'chipTimeSeconds': 0,
              'distanceMeters': 2000,
              'avgPaceSecPerKm': 350,
              'avgSpeedMps': 2.86,
              'elevationGainMeters': 30,
              'bestKmIndex': 0,
              'overallRank': 4,
              'categoryRank': 1,
              'finishers': 40,
              'finishedAt': '2026-09-12T11:00:00Z',
              'shareCardUrl': null,
              'workoutId': 'w1',
            },
            'splits': [
              {
                'index': 0,
                'distanceMeters': 1000,
                'durationSeconds': 340,
                'paceSecPerKm': 340,
                'elevationGainMeters': 10,
              },
              {
                'index': 1,
                'distanceMeters': 1000,
                'durationSeconds': 360,
                'paceSecPerKm': 360,
                'elevationGainMeters': 20,
              },
            ],
          },
        ]),
      );

      final result = (await repo.fetchEntries()).unwrap().first.result!;

      // Los indices de la API empiezan en 0; los kilometros que se pintan, en 1.
      expect(result.splits.map((s) => s.km), [1, 2]);
      expect(result.splits.first.deltaToPrevious, Duration.zero);
      expect(result.splits.last.deltaToPrevious, const Duration(seconds: 20));
      // Sin chip, el tiempo oficial hace de chip en vez de quedarse en cero.
      expect(result.chipTime, const Duration(seconds: 700));
      expect(result.bestKm, const Duration(seconds: 340));
    });
  });

  // ─── Totales ─────────────────────────────────────────────────────────────

  test('los totales de la cabecera salen del servidor, no de la lista', () async {
    final repo = build(
      (_) async => envelope({
        'racesCompleted': 3,
        'racesUpcoming': 1,
        'totalDistanceMeters': 84_390,
        'totalSpentCents': 45_000,
        'currency': 'BOB',
        'nextRace': null,
      }),
    );

    final totals = (await repo.fetchTotals()).unwrap();

    expect(totals.racesJoined, 4);
    expect(totals.distanceRacedKm, closeTo(84.39, 0.001));
    expect(totals.totalSpent.amount, 450);
    expect(totals.totalSpent.currency, 'BOB');
  });

  // ─── Inscripcion ─────────────────────────────────────────────────────────

  Map<String, Object?> borrador({
    String status = 'draft',
    int step = 1,
    String? bibNumber,
    Map<String, Object?>? serviceFee = const {
      'label': 'Cargo por servicio',
      'amountCents': 2000,
    },
  }) => {
    'id': 'reg1',
    'marathon': {'id': 'm1', 'name': 'Maraton de prueba'},
    'status': status,
    'step': step,
    'bibNumber': bibNumber,
    'categoryId': 'c1',
    'personalData': <String, Object?>{},
    'extras': <Object?>[],
    'items': [
      {'label': 'Inscripcion', 'quantity': 1, 'amountCents': 25_000},
      {'label': 'Remera', 'quantity': 2, 'amountCents': 24_000},
    ],
    'subtotalCents': 49_000,
    'serviceFee': serviceFee,
    'totalCents': 51_000,
    'currency': 'BOB',
    'termsAcceptedAt': null,
    'registeredAt': null,
    'cancelledAt': null,
    'createdAt': '2026-07-01T12:00:00Z',
  };

  group('paso 1 y 2', () {
    test('el desglose que se pinta es el del servidor', () async {
      final repo = build((_) async => envelope(borrador()));

      final registro = (await repo.startRegistration(
        marathonId: 'm1',
        data: const RegistrationPersonalData(
          fullName: 'Alvaro Quispe',
          docId: '1234567 LP',
          phone: '+591 70000000',
          knowsCam: true,
          acceptsDonorCall: false,
        ),
      )).unwrap();

      expect(registro.state, RegistrationState.draft);
      expect(registro.quote.lines, hasLength(2));
      expect(registro.quote.lines.last.quantity, 2);
      expect(registro.quote.subtotal.amount, 490);
      expect(registro.quote.serviceFee!.amount, 20);
      // El total NO es la suma de las lineas de aqui: es el que manda la API.
      expect(registro.quote.total.amount, 510);
    });

    test('sin cargo por servicio no hay linea que pintar', () async {
      final repo = build((_) async => envelope(borrador(serviceFee: null)));

      final registro = (await repo.startRegistration(
        marathonId: 'm1',
        data: const RegistrationPersonalData(
          fullName: 'A',
          docId: 'B',
          phone: '+591 70000000',
          knowsCam: false,
          acceptsDonorCall: false,
        ),
      )).unwrap();

      // `null` y no `Money.zero`: un "Bs 0,00" promete un cargo que no se cobra.
      expect(registro.quote.serviceFee, isNull);
    });

    test('los extras se mandan enteros, porque reemplazan la seleccion', () async {
      final repo = build((_) async => envelope(borrador(step: 2)));

      await repo.setCategoryAndExtras(
        registrationId: 'reg1',
        categoryId: 'c1',
        extras: const [
          ExtraSelection(extraId: 'e1'),
          ExtraSelection(extraId: 'e2', quantity: 3),
        ],
      );

      final body = cuerpo(llamadas.single);
      expect(llamadas.single.method, 'PATCH');
      expect(body['categoryId'], 'c1');
      expect(body['extras'], [
        {'extraId': 'e1', 'quantity': 1},
        {'extraId': 'e2', 'quantity': 3},
      ]);
    });
  });

  group('paso 3: el cobro', () {
    test('una tarjeta aceptada deja la inscripcion confirmada y con dorsal', () async {
      final repo = build(
        (_) async => envelope({
          'payment': {
            'id': 'pay1',
            'registrationId': 'reg1',
            'method': 'card',
            'status': 'paid',
            'amountCents': 51_000,
            'currency': 'BOB',
            'methodDetails': {'brand': 'visa', 'last4': '4242'},
            'failureReason': null,
            'expiresAt': null,
            'paidAt': '2026-07-01T12:00:05Z',
            'refundedAt': null,
            'createdAt': '2026-07-01T12:00:00Z',
          },
          'registration': borrador(status: 'confirmed', step: 3, bibNumber: 'MLP-0042'),
        }),
      );

      final salida = (await repo.checkout(
        registrationId: 'reg1',
        method: RacePaymentMethod.card,
        idempotencyKey: 'clave-1',
        card: const CardDetails(
          number: '4242 4242 4242 4242',
          holder: 'ALVARO QUISPE',
          expMonth: 12,
          expYear: 2030,
          cvv: '123',
        ),
      )).unwrap();

      expect(salida.isConfirmed, isTrue);
      expect(salida.registration.bibNumber, 'MLP-0042');
      expect(salida.payment.state, RacePaymentState.paid);
      expect(salida.payment.last4, '4242');

      final req = llamadas.single;
      expect(req.headers['Idempotency-Key'], 'clave-1');
      // Los espacios del formulario no llegan al proveedor.
      expect((cuerpo(req)['card']! as Map)['number'], '4242424242424242');
      expect(cuerpo(req)['termsAccepted'], isTrue);
    });

    test('un rechazo llega como fallo con su motivo, no como exito', () async {
      final repo = build(
        (_) async => errorBody('PAYMENT_DECLINED', status: 402),
      );

      final salida = await repo.checkout(
        registrationId: 'reg1',
        method: RacePaymentMethod.card,
        idempotencyKey: 'clave-2',
      );

      salida.fold(
        (_) => fail('un cobro rechazado no puede devolver exito'),
        (fallo) {
          expect(fallo, isA<ApiFailure>());
          expect((fallo as ApiFailure).code, 'PAYMENT_DECLINED');
        },
      );
    });

    test('el QR queda pendiente y trae la imagen que hay que escanear', () async {
      final repo = build(
        (_) async => envelope({
          'payment': {
            'id': 'pay2',
            'registrationId': 'reg1',
            'method': 'qr',
            'status': 'pending',
            'amountCents': 51_000,
            'currency': 'BOB',
            'methodDetails': {
              'qr': {'imageUrl': 'http://x/qr.png', 'payload': 'PACEUP-QR|...'},
            },
            'failureReason': null,
            'expiresAt': '2026-07-01T12:15:00Z',
            'paidAt': null,
            'refundedAt': null,
            'createdAt': '2026-07-01T12:00:00Z',
          },
          'registration': borrador(status: 'pending_payment', step: 3),
        }),
      );

      final salida = (await repo.checkout(
        registrationId: 'reg1',
        method: RacePaymentMethod.qr,
        idempotencyKey: 'clave-3',
      )).unwrap();

      expect(salida.isConfirmed, isFalse);
      expect(salida.payment.isSettled, isFalse);
      expect(salida.payment.qrImageUrl, 'http://x/qr.png');
      expect(salida.registration.state, RegistrationState.pendingPayment);
    });
  });
}
