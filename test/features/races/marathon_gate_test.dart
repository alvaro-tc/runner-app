import 'package:camrun/core/network/live_socket.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/races/domain/entities/race_entry.dart';
import 'package:camrun/features/races/presentation/providers/live_marathon_provider.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:flutter_test/flutter_test.dart';

/// La regla del bloqueo el dia de la carrera.
///
/// Es la parte del cambio que no puede fallar en produccion: dejar la app viva
/// en preparacion arruina la largada, y bloquearsela a quien no corre esa
/// maraton lo deja sin app sin haber hecho nada.
void main() {
  final hoy = DateTime(2026, 9, 2, 7);

  Marathon maraton({
    DateTime? preparingAt,
    String? preparingMessage,
    DateTime? liveStartedAt,
    DateTime? liveFinishedAt,
  }) => Marathon(
    id: 'm1',
    name: 'Maraton de La Paz',
    date: hoy,
    city: 'La Paz',
    country: 'BO',
    heroImageUrl: '',
    distanceKm: 42.2,
    entryFee: const Money(350, 'BOB'),
    slotsTotal: 500,
    slotsTaken: 100,
    status: RegistrationStatus.closed,
    about: '',
    schedule: const [],
    included: const [],
    routePreview: const [],
    preparingAt: preparingAt,
    preparingMessage: preparingMessage,
    liveStartedAt: liveStartedAt,
    liveFinishedAt: liveFinishedAt,
  );

  RaceEntry inscripcion({
    required Marathon en,
    PaymentStatus paymentStatus = PaymentStatus.paid,
    RaceEntryStatus status = RaceEntryStatus.completed,
    RaceResult? result,
    String bib = 'MLP-0042',
  }) => RaceEntry(
    id: 'reg1',
    marathon: en,
    registeredAt: hoy.subtract(const Duration(days: 30)),
    amountPaid: const Money(350, 'BOB'),
    paymentStatus: paymentStatus,
    bibNumber: bib,
    status: status,
    result: result,
  );

  const resultado = RaceResult(
    finishTime: Duration(hours: 4),
    chipTime: Duration(hours: 4),
    avgPacePerKm: Duration(minutes: 5, seconds: 41),
    avgSpeedKmh: 10.5,
    distanceKm: 42.2,
    route: <GeoPoint>[],
    splits: <KmSplit>[],
    elevationGainM: 300,
  );

  test('sin inscripciones la app no se bloquea', () {
    expect(resolverPuerta(const []), isA<GateOpen>());
  });

  test('una maraton sin empezar no bloquea nada', () {
    final puerta = resolverPuerta([inscripcion(en: maraton())]);
    expect(puerta, isA<GateOpen>());
  });

  test('en preparacion bloquea al inscrito, con el aviso del organizador', () {
    final puerta = resolverPuerta([
      inscripcion(
        en: maraton(preparingAt: hoy, preparingMessage: 'Salimos 06:45'),
      ),
    ]);

    expect(puerta, isA<GatePreparing>());
    expect((puerta as GatePreparing).message, 'Salimos 06:45');
  });

  test('sin aviso propio el mensaje queda en null: lo pone la app', () {
    final puerta = resolverPuerta([inscripcion(en: maraton(preparingAt: hoy))]);
    expect((puerta as GatePreparing).message, isNull);
  });

  test('a quien no pago no se le bloquea nada', () {
    final puerta = resolverPuerta([
      inscripcion(
        en: maraton(preparingAt: hoy),
        paymentStatus: PaymentStatus.pending,
      ),
    ]);
    expect(puerta, isA<GateOpen>());
  });

  test('a quien cancelo su inscripcion tampoco', () {
    final puerta = resolverPuerta([
      inscripcion(
        en: maraton(preparingAt: hoy),
        status: RaceEntryStatus.cancelled,
      ),
    ]);
    expect(puerta, isA<GateOpen>());
  });

  test('en marcha, el inscrito que no llego va a la pantalla de carrera', () {
    final puerta = resolverPuerta([
      inscripcion(
        en: maraton(preparingAt: hoy, liveStartedAt: hoy),
      ),
    ]);

    expect(puerta, isA<GateRunning>());
    expect((puerta as GateRunning).startedAt, hoy);
  });

  test('con la maraton en marcha, quien ya tiene resultado ve sus datos', () {
    final puerta = resolverPuerta([
      inscripcion(
        en: maraton(liveStartedAt: hoy),
        result: resultado,
      ),
    ]);
    expect(puerta, isA<GateFinished>());
  });

  test('el dorsal recien llegado cuenta antes de que exista el resultado', () {
    // El servidor anuncia la llegada y consolida el resultado despues: sin
    // esto el corredor volveria un instante a la pantalla de carrera.
    final puerta = resolverPuerta(
      [inscripcion(en: maraton(liveStartedAt: hoy))],
      llegados: {'MLP-0042'},
    );
    expect(puerta, isA<GateFinished>());
  });

  test('la llegada de otro dorsal no mueve nada', () {
    final puerta = resolverPuerta(
      [inscripcion(en: maraton(liveStartedAt: hoy))],
      llegados: {'MLP-0099'},
    );
    expect(puerta, isA<GateRunning>());
  });

  test('cortada la carrera, todo el mundo recupera la app', () {
    final puerta = resolverPuerta([
      inscripcion(
        en: maraton(preparingAt: hoy, liveStartedAt: hoy, liveFinishedAt: hoy),
        result: resultado,
      ),
    ]);
    expect(puerta, isA<GateOpen>());
  });

  test('lo que dice el socket manda sobre lo que trajo la lista', () {
    // La lista se cargo antes de que el organizador tocara el boton.
    final puerta = resolverPuerta(
      [inscripcion(en: maraton())],
      avisos: {
        'm1': MarathonLiveState(
          marathonId: 'm1',
          preparingAt: hoy,
          preparingMessage: 'Ya casi',
        ),
      },
    );

    expect((puerta as GatePreparing).message, 'Ya casi');
  });

  test('y el corte por socket suelta al corredor aunque la lista diga otra '
      'cosa', () {
    final puerta = resolverPuerta(
      [inscripcion(en: maraton(liveStartedAt: hoy))],
      avisos: {
        'm1': MarathonLiveState(
          marathonId: 'm1',
          startedAt: hoy,
          finishedAt: hoy.add(const Duration(hours: 6)),
        ),
      },
    );

    expect(puerta, isA<GateOpen>());
  });
}
