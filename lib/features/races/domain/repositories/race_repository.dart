import 'package:camrun/core/utils/result.dart';
import 'package:camrun/features/races/domain/entities/race_entry.dart';
import 'package:camrun/features/races/domain/entities/registration.dart';

/// Mis carreras y el camino para llegar a tener una.
///
/// La inscripcion son **tres pasos con estado en el servidor**, no una llamada:
/// el borrador se puede retomar donde se dejo, el precio lo recalcula la API en
/// cada cambio y el cobro lleva su clave de idempotencia. Por eso son cinco
/// metodos y no un `register(...)` — meterlos en uno obligaria al movil a
/// guardarse el paso intermedio, que es justo lo que se pierde al cerrar la app.
abstract interface class RaceRepository {
  Future<Result<List<RaceEntry>>> fetchEntries();

  Future<Result<RaceEntry>> fetchById(String registrationId);

  /// Los totales de la cabecera. Vienen del servidor y **no** se derivan de la
  /// lista: el gasto sale de los cobros, que la lista no trae.
  Future<Result<RaceTotals>> fetchTotals();

  /// Las inscripciones que ya mandaron el comprobante y esperan a que un
  /// administrador lo mire.
  ///
  /// Van aparte de [fetchEntries] porque **no son carreras todavia**: el
  /// servidor no las devuelve en "mis carreras" hasta que el pago se valida, y
  /// sin esto el usuario que sube su captura no vuelve a ver su inscripcion en
  /// ningun sitio.
  Future<Result<List<Registration>>> awaitingValidation();

  // ─── Inscripcion ─────────────────────────────────────────────────────────

  /// Paso 1. Devuelve el borrador que ya hubiera para esa maraton en vez de
  /// abrir un segundo.
  Future<Result<Registration>> startRegistration({
    required String marathonId,
    required RegistrationPersonalData data,
  });

  /// Paso 2. [extras] es la seleccion **completa**: reemplaza a la anterior.
  Future<Result<Registration>> setCategoryAndExtras({
    required String registrationId,
    String? categoryId,
    required List<ExtraSelection> extras,
  });

  /// El total vigente. Se pide en cada cambio del paso 2.
  Future<Result<RegistrationQuote>> quote(String registrationId);

  /// Paso 3. [idempotencyKey] tiene que ser la misma en cada reintento del
  /// mismo cobro, o se cobra dos veces.
  Future<Result<CheckoutOutcome>> checkout({
    required String registrationId,
    required RacePaymentMethod method,
    required String idempotencyKey,
    CardDetails? card,
  });

  /// Sondeo del cobro pendiente (QR y transferencia).
  Future<Result<PaymentInfo>> pollPayment(String paymentId);

  /// Sube el comprobante de un cobro por QR. **Temporal.**
  ///
  /// Devuelve el cobro releido, no solo el comprobante: la pantalla tiene que
  /// pintar el estado nuevo entero, y con dos llamadas hay un instante en que
  /// se ve el comprobante subido y el cobro como si no lo estuviera.
  Future<Result<PaymentInfo>> uploadProof({
    required String paymentId,
    required String filePath,
    String? reference,
  });

  Future<Result<void>> cancel(String registrationId);
}
