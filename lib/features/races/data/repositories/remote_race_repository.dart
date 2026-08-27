import 'package:paceup/core/utils/result.dart';
import 'package:paceup/features/races/data/datasources/races_api.dart';
import 'package:paceup/features/races/data/race_mappers.dart';
import 'package:paceup/features/races/domain/entities/race_entry.dart';
import 'package:paceup/features/races/domain/entities/registration.dart';
import 'package:paceup/features/races/domain/repositories/race_repository.dart';

/// Mis carreras y la inscripcion, contra la API.
///
/// Sin cache local a proposito, al reves que el catalogo: una carrera propia
/// lleva dorsal, estado de pago y puesto, y todo eso cambia del lado del
/// servidor sin que la app se entere. Enseñar un dorsal cacheado que ya no es
/// el tuyo el dia de la carrera es peor que enseñar un spinner.
class RemoteRaceRepository implements RaceRepository {
  const RemoteRaceRepository(this._api);

  final RacesApi _api;

  @override
  Future<Result<List<RaceEntry>>> fetchEntries() =>
      guard(() async => [for (final j in await _api.myRaces()) raceEntryFrom(j)]);

  @override
  Future<Result<RaceTotals>> fetchTotals() =>
      guard(() async => raceTotalsFrom(await _api.summary()));

  /// El detalle **si** trae los pagos: es donde se pinta cuanto se pago y con
  /// que. Van en paralelo porque no dependen entre si y la pantalla necesita
  /// los dos para su primer frame.
  @override
  Future<Result<RaceEntry>> fetchById(String registrationId) => guard(() async {
    final (carrera, pagos) = await (
      _api.race(registrationId),
      _api.paymentsOf(registrationId),
    ).wait;

    return raceEntryFrom(carrera, payments: pagos);
  });

  @override
  Future<Result<Registration>> startRegistration({
    required String marathonId,
    required RegistrationPersonalData data,
  }) => guard(
    () async => registrationFrom(
      await _api.createDraft(
        marathonId: marathonId,
        personalData: data.toApi(),
      ),
    ),
  );

  @override
  Future<Result<Registration>> setCategoryAndExtras({
    required String registrationId,
    String? categoryId,
    required List<ExtraSelection> extras,
  }) => guard(
    () async => registrationFrom(
      await _api.setCategoryAndExtras(
        registrationId: registrationId,
        categoryId: categoryId,
        extras: [for (final e in extras) e.toApi()],
      ),
    ),
  );

  @override
  Future<Result<RegistrationQuote>> quote(String registrationId) =>
      guard(() async => quoteFrom(await _api.quote(registrationId)));

  @override
  Future<Result<CheckoutOutcome>> checkout({
    required String registrationId,
    required RacePaymentMethod method,
    required String idempotencyKey,
    CardDetails? card,
  }) => guard(
    () async => checkoutFrom(
      await _api.checkout(
        registrationId: registrationId,
        method: method.api,
        idempotencyKey: idempotencyKey,
        card: card?.toApi(),
      ),
    ),
  );

  @override
  Future<Result<PaymentInfo>> pollPayment(String paymentId) =>
      guard(() async => paymentFrom(await _api.payment(paymentId)));

  @override
  Future<Result<PaymentInfo>> uploadProof({
    required String paymentId,
    required String filePath,
    String? reference,
  }) => guard(() async {
    await _api.uploadProof(
      paymentId: paymentId,
      filePath: filePath,
      reference: reference,
    );
    // Se relee el cobro en vez de coser el comprobante sobre el que habia: el
    // servidor es quien decide si con esto el cobro cambio de estado.
    return paymentFrom(await _api.payment(paymentId));
  });

  @override
  Future<Result<void>> cancel(String registrationId) =>
      guard(() => _api.cancel(registrationId));
}
