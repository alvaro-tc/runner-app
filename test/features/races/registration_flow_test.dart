import 'package:camrun/app/dependencies.dart';
import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/utils/result.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/races/domain/entities/race_entry.dart';
import 'package:camrun/features/races/domain/entities/registration.dart';
import 'package:camrun/features/races/domain/repositories/race_repository.dart';
import 'package:camrun/features/races/presentation/providers/registration_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repositorio de mentira que anota las claves de idempotencia con las que se
/// le pidio cobrar. Es lo unico que hace falta espiar: el resto del flujo ya se
/// prueba contra HTTP en `race_repository_test.dart`.
class _FakeRaceRepository implements RaceRepository {
  _FakeRaceRepository();

  final List<String> claves = [];
  int cobros = 0;
  int sondeos = 0;

  /// Que devuelve el cobro. `null` = confirmado a la primera.
  CheckoutOutcome? checkoutResult;

  /// Lo que devuelve el siguiente sondeo del cobro pendiente.
  PaymentInfo? siguientePago;

  static const _quote = RegistrationQuote(
    lines: [],
    subtotal: Money(490, 'BOB'),
    total: Money(510, 'BOB'),
  );

  static Registration _registro(RegistrationState state) => Registration(
    id: 'reg1',
    marathonId: 'm1',
    marathonName: 'Maraton de prueba',
    state: state,
    step: RegistrationStep.payment,
    quote: _quote,
    bibNumber: state.isConfirmed ? 'MLP-0042' : null,
  );

  static PaymentInfo _pago(
    RacePaymentState state, {
    RacePaymentMethod method = RacePaymentMethod.qr,
    PaymentProof? proof,
  }) => PaymentInfo(
    id: 'pay1',
    method: method,
    state: state,
    amount: const Money(510, 'BOB'),
    proof: proof,
  );

  @override
  Future<Result<Registration>> startRegistration({
    required String marathonId,
    required RegistrationPersonalData data,
  }) async => Result.success(_registro(RegistrationState.draft));

  @override
  Future<Result<Registration>> setCategoryAndExtras({
    required String registrationId,
    String? categoryId,
    required List<ExtraSelection> extras,
  }) async => Result.success(_registro(RegistrationState.draft));

  @override
  Future<Result<CheckoutOutcome>> checkout({
    required String registrationId,
    required RacePaymentMethod method,
    required String idempotencyKey,
    CardDetails? card,
  }) async {
    claves.add(idempotencyKey);
    cobros++;

    return Result.success(
      checkoutResult ??
          CheckoutOutcome(
            payment: _pago(RacePaymentState.paid),
            registration: _registro(RegistrationState.confirmed),
          ),
    );
  }

  @override
  Future<Result<PaymentInfo>> pollPayment(String paymentId) async {
    sondeos++;
    return Result.success(siguientePago ?? _pago(RacePaymentState.pending));
  }

  /// Comprobantes subidos, para comprobar que subir uno NO confirma nada.
  final List<String> comprobantes = [];

  @override
  Future<Result<PaymentInfo>> uploadProof({
    required String paymentId,
    required String filePath,
    String? reference,
  }) async {
    comprobantes.add(filePath);
    return Result.success(siguientePago ?? _pago(RacePaymentState.pending));
  }

  @override
  Future<Result<RegistrationQuote>> quote(String registrationId) async =>
      const Result.success(_quote);

  @override
  Future<Result<List<RaceEntry>>> fetchEntries() async =>
      const Result.success([]);

  @override
  Future<Result<RaceEntry>> fetchById(String registrationId) async =>
      const Result.failure(NotFoundFailure());

  @override
  Future<Result<RaceTotals>> fetchTotals() async => const Result.success(
    RaceTotals(racesJoined: 0, distanceRacedKm: 0, totalSpent: Money.zero),
  );

  /// Inscripciones canceladas, para comprobar que el flujo llama al servidor y
  /// no se limita a limpiar la pantalla.
  final List<String> canceladas = [];

  @override
  Future<Result<List<Registration>>> awaitingValidation() async =>
      const Result.success([]);

  @override
  Future<Result<void>> cancel(String registrationId) async {
    canceladas.add(registrationId);
    return const Result.success(null);
  }
}

void main() {
  late _FakeRaceRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeRaceRepository();
    container = ProviderContainer(
      overrides: [raceRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  RegistrationFlowNotifier flow() =>
      container.read(registrationFlowProvider.notifier);

  RegistrationFlowState estado() => container.read(registrationFlowProvider);

  const datos = RegistrationPersonalData(
    fullName: 'Alvaro Quispe',
    docId: '1234567 LP',
    phone: '+591 70000000',
    knowsCam: true,
    acceptsDonorCall: false,
  );

  test('sin abrir una maraton, el paso 1 no hace nada', () async {
    expect(await flow().submitPersonalData(datos), isFalse);
    expect(estado().registration, isNull);
  });

  test('el paso 1 deja el borrador y su total en el estado', () async {
    flow().openFor('m1');

    expect(await flow().submitPersonalData(datos), isTrue);
    expect(estado().registration?.id, 'reg1');
    expect(estado().quote?.total.amount, 510);
    expect(estado().busy, isFalse);
  });

  test('abrir otra maraton descarta el borrador a medias', () async {
    flow().openFor('m1');
    await flow().submitPersonalData(datos);

    flow().openFor('m2');

    // Seguir con el borrador de la maraton anterior acabaria pagando la que no
    // era: por eso se tira en vez de conservarse.
    expect(estado().registration, isNull);
    expect(estado().marathonId, 'm2');
  });

  test('reabrir la MISMA maraton conserva el borrador', () async {
    flow().openFor('m1');
    await flow().submitPersonalData(datos);

    flow().openFor('m1');

    expect(estado().registration?.id, 'reg1');
  });

  test('un cobro aceptado confirma la inscripcion y trae el dorsal', () async {
    flow().openFor('m1');
    await flow().submitPersonalData(datos);

    expect(await flow().pay(method: RacePaymentMethod.card), isTrue);
    expect(estado().isConfirmed, isTrue);
    expect(estado().registration?.bibNumber, 'MLP-0042');
  });

  test('reintentar el mismo cobro reusa la clave de idempotencia', () async {
    flow().openFor('m1');
    await flow().submitPersonalData(datos);

    await flow().pay(method: RacePaymentMethod.card);
    await flow().pay(method: RacePaymentMethod.card);

    expect(repo.cobros, 2);
    // La misma clave las dos veces: es lo que impide que el servidor cobre dos
    // veces por tocar "pagar" dos veces.
    expect(repo.claves.toSet(), hasLength(1));
  });

  test('tras un rechazo, el reintento va con una clave nueva', () async {
    flow().openFor('m1');
    await flow().submitPersonalData(datos);
    await flow().pay(method: RacePaymentMethod.card);

    flow().retryPayment();
    await flow().pay(method: RacePaymentMethod.card);

    // La clave vieja identifica el intento ya resuelto; reusarla devolveria
    // aquel resultado para siempre.
    expect(repo.claves.toSet(), hasLength(2));
  });

  test('el QR manual NO se sondea: al otro lado hay una persona', () async {
    repo.checkoutResult = CheckoutOutcome(
      payment: _FakeRaceRepository._pago(
        RacePaymentState.pending,
        method: RacePaymentMethod.qrManual,
      ),
      registration: _FakeRaceRepository._registro(
        RegistrationState.pendingPayment,
      ),
    );

    flow().openFor('m1');
    await flow().submitPersonalData(datos);

    expect(await flow().pay(method: RacePaymentMethod.qrManual), isFalse);
    expect(estado().isAwaitingPayment, isTrue);

    // Sondear cada dos segundos a un organizador que va a mirar la imagen
    // cuando pueda solo gasta bateria.
    await Future<void>.delayed(const Duration(seconds: 3));
    expect(repo.sondeos, 0);
  });

  test('subir el comprobante NO confirma la inscripcion', () async {
    repo.checkoutResult = CheckoutOutcome(
      payment: _FakeRaceRepository._pago(
        RacePaymentState.pending,
        method: RacePaymentMethod.qrManual,
      ),
      registration: _FakeRaceRepository._registro(
        RegistrationState.pendingPayment,
      ),
    );

    flow().openFor('m1');
    await flow().submitPersonalData(datos);
    await flow().pay(method: RacePaymentMethod.qrManual);

    repo.siguientePago = _FakeRaceRepository._pago(
      RacePaymentState.pending,
      method: RacePaymentMethod.qrManual,
      proof: const PaymentProof(
        id: 'proof1',
        state: ProofState.inReview,
        imageUrl: 'https://api.test/uploads/p.webp',
      ),
    );

    expect(
      await flow().uploadProof(filePath: '/tmp/captura.jpg', reference: '123'),
      isTrue,
    );

    expect(repo.comprobantes, ['/tmp/captura.jpg']);
    // Mandar la captura no es haber pagado: el cobro sigue abierto y la
    // inscripcion sin confirmar hasta que un organizador lo mire.
    expect(estado().isConfirmed, isFalse);
    expect(estado().payment!.isAwaitingReview, isTrue);
    expect(estado().payment!.needsAnotherProof, isFalse);
  });

  test('un comprobante rechazado deja subir otro', () {
    const pago = PaymentInfo(
      id: 'pay1',
      method: RacePaymentMethod.qrManual,
      state: RacePaymentState.pending,
      amount: Money(510, 'BOB'),
      proof: PaymentProof(
        id: 'proof1',
        state: ProofState.rejected,
        imageUrl: 'https://api.test/uploads/p.webp',
        note: 'La captura es de otra transferencia',
      ),
    );

    // Rechazar no cierra el cobro: obligar a rehacer la inscripcion entera por
    // una foto equivocada seria soltarle el cupo al corredor.
    expect(pago.needsAnotherProof, isTrue);
    expect(pago.isAwaitingReview, isFalse);
  });

  test('con QR la inscripcion queda esperando y se sondea el cobro', () async {
    repo.checkoutResult = CheckoutOutcome(
      payment: _FakeRaceRepository._pago(RacePaymentState.pending),
      registration: _FakeRaceRepository._registro(
        RegistrationState.pendingPayment,
      ),
    );

    flow().openFor('m1');
    await flow().submitPersonalData(datos);

    expect(await flow().pay(method: RacePaymentMethod.qr), isFalse);
    expect(estado().isAwaitingPayment, isTrue);

    // El sondeo corre solo; aqui basta con comprobar que arranco.
    await Future<void>.delayed(const Duration(seconds: 3));
    expect(repo.sondeos, greaterThan(0));
  });

  test('cancelar cierra el cobro en el servidor y tira el borrador', () async {
    repo.checkoutResult = CheckoutOutcome(
      payment: _FakeRaceRepository._pago(
        RacePaymentState.pending,
        method: RacePaymentMethod.qrManual,
      ),
      registration: _FakeRaceRepository._registro(
        RegistrationState.pendingPayment,
      ),
    );

    flow().openFor('m1');
    await flow().submitPersonalData(datos);
    await flow().pay(method: RacePaymentMethod.qrManual);

    expect(await flow().cancelRegistration(), isTrue);

    // Lo importante es que se cancelo **contra el servidor**: limpiar solo la
    // pantalla dejaria el cobro abierto, y un organizador podria aprobar su
    // comprobante y confirmar sola una inscripcion que el usuario anulo.
    expect(repo.canceladas, ['reg1']);
    expect(estado().payment, isNull);
    expect(estado().registration, isNull);
    // La maraton se conserva: se cancelo el pago, no se salio de la carrera.
    expect(estado().marathonId, 'm1');
  });

  test('hoy solo se ofrece el QR: no hay pasarela detras de los demas', () {
    expect(RacePaymentMethod.offered, [RacePaymentMethod.qrManual]);
  });
}
