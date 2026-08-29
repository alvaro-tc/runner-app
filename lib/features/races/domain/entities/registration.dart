import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:meta/meta.dart';

/// El borrador de inscripcion y lo que cuesta, tal como lo lleva el servidor.
///
/// Nada de esto se calcula en el movil. El total que se ve en la pantalla de
/// pago es el que devolvio la API, porque es el que la API va a cobrar: un
/// subtotal sumado aqui se desvia en cuanto cambia un precio o un cargo, y el
/// usuario ve un numero y paga otro.

/// En que paso quedo la inscripcion, para poder retomarla donde se dejo.
enum RegistrationStep {
  personalData(1),
  categoryAndExtras(2),
  payment(3);

  const RegistrationStep(this.number);
  final int number;

  static RegistrationStep fromNumber(int n) =>
      values.firstWhere((s) => s.number == n, orElse: () => personalData);
}

enum RegistrationState {
  draft,
  pendingPayment,
  confirmed,
  cancelled,
  expired;

  static RegistrationState fromApi(String? value) => switch (value) {
    'pending_payment' => pendingPayment,
    'confirmed' => confirmed,
    'cancelled' => cancelled,
    'expired' => expired,
    _ => draft,
  };

  bool get isConfirmed => this == confirmed;
}

/// Metodos de cobro.
///
/// [qrManual] es **temporal** y no lo atiende ningun proveedor: se muestra el QR
/// bancario del organizador, el corredor sube una captura del pago y una
/// persona lo verifica. Ver `docs/pago-qr-manual.md` en la API.
///
/// Solo el codigo de la API: el nombre visible sale del ARB, via
/// `RacePaymentMethodL10n`.
enum RacePaymentMethod {
  card('card'),
  qr('qr'),
  bankTransfer('bank_transfer'),
  qrManual('qr_manual');

  const RacePaymentMethod(this.api);
  final String api;

  /// Los metodos que hoy se pueden ofrecer al usuario.
  ///
  /// Tarjeta, QR de pasarela y transferencia siguen implementados de punta a
  /// punta —el proveedor simulado responde a los tres— pero **no hay pasarela
  /// contratada**, asi que ofrecerlos seria prometer un cobro que nadie va a
  /// atender. Se apagan aqui, en un solo sitio: el dia que entre el PSP se
  /// vuelven a listar y no hay que tocar ninguna pantalla.
  static const List<RacePaymentMethod> offered = [qrManual];

  /// Solo la tarjeta resuelve en el acto; el resto queda pendiente y hay que
  /// sondear el cobro.
  bool get settlesImmediately => this == card;

  /// Espera a que una persona mire un comprobante, no a un banco. Sondear no
  /// sirve de nada aqui: nadie lo va a resolver en los proximos segundos.
  bool get needsProof => this == qrManual;
}

/// Estado del comprobante que subio el corredor. **Temporal.**
enum ProofState {
  /// Subido y esperando al organizador. El cobro sigue pendiente: haber
  /// mandado la captura no es haber pagado.
  inReview,
  approved,
  rejected;

  static ProofState fromApi(String? value) => switch (value) {
    'approved' => approved,
    'rejected' => rejected,
    _ => inReview,
  };
}

/// El comprobante subido para un cobro por QR. **Temporal.**
@immutable
class PaymentProof {
  const PaymentProof({
    required this.id,
    required this.state,
    required this.imageUrl,
    this.reference,
    this.note,
  });

  final String id;
  final ProofState state;
  final String imageUrl;
  final String? reference;

  /// Motivo del rechazo, escrito por el organizador. Es lo que le dice al
  /// corredor que corregir, asi que se pinta tal cual.
  final String? note;
}

enum RacePaymentState {
  pending,
  paid,
  failed,
  refunded;

  static RacePaymentState fromApi(String? value) => switch (value) {
    'paid' => paid,
    'failed' => failed,
    'refunded' => refunded,
    _ => pending,
  };
}

/// Datos personales del paso 1.
@immutable
class RegistrationPersonalData {
  const RegistrationPersonalData({
    required this.fullName,
    required this.docId,
    required this.phone,
    required this.knowsCam,
    required this.acceptsDonorCall,
    this.email,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.bloodType,
    this.shirtSize,
  });

  final String fullName;

  /// Cedula de identidad. Es lo que cruza esta inscripcion con un pago hecho
  /// desde la web, asi que no es un dato de relleno.
  final String docId;

  /// Celular. Obligatorio: es por donde avisan un cambio de ultima hora.
  final String phone;

  /// ¿Conoce el trabajo del CAM?
  final bool knowsCam;

  /// ¿Acepta que le llamen para ser donante del CAM? Es un consentimiento: se
  /// manda tal cual lo respondio, y `false` significa que dijo que no — no que
  /// no contesto.
  final bool acceptsDonorCall;

  final String? email;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? bloodType;
  final String? shirtSize;

  Map<String, Object?> toApi() => {
    'fullName': fullName,
    'docId': docId,
    'phone': phone,
    'knowsCam': knowsCam,
    'acceptsDonorCall': acceptsDonorCall,
    if (email != null && email!.isNotEmpty) 'email': email,
    if (emergencyContactName != null && emergencyContactName!.isNotEmpty)
      'emergencyContactName': emergencyContactName,
    if (emergencyContactPhone != null && emergencyContactPhone!.isNotEmpty)
      'emergencyContactPhone': emergencyContactPhone,
    if (bloodType != null && bloodType!.isNotEmpty) 'bloodType': bloodType,
    if (shirtSize != null && shirtSize!.isNotEmpty) 'shirtSize': shirtSize,
  };
}

/// Una linea del desglose que devuelve el servidor.
@immutable
class QuoteLine {
  const QuoteLine({
    required this.label,
    required this.quantity,
    required this.amount,
  });

  final String label;
  final int quantity;
  final Money amount;
}

/// Lo que cuesta la inscripcion ahora mismo, con su desglose.
@immutable
class RegistrationQuote {
  const RegistrationQuote({
    required this.lines,
    required this.subtotal,
    required this.total,
    this.serviceFee,
    this.serviceFeeLabel,
  });

  final List<QuoteLine> lines;
  final Money subtotal;
  final Money total;

  /// `null` significa que hoy **no se cobra** cargo por servicio, que no es lo
  /// mismo que cobrar cero: la linea no se pinta.
  final Money? serviceFee;
  final String? serviceFeeLabel;
}

/// Un extra elegido, con su cantidad.
@immutable
class ExtraSelection {
  const ExtraSelection({required this.extraId, this.quantity = 1});

  final String extraId;
  final int quantity;

  Map<String, Object?> toApi() => {'extraId': extraId, 'quantity': quantity};
}

/// El borrador vivo, con lo que lleva elegido y lo que cuesta.
@immutable
class Registration {
  const Registration({
    required this.id,
    required this.marathonId,
    required this.marathonName,
    required this.state,
    required this.step,
    required this.quote,
    this.marathonDate,
    this.marathonCity,
    this.categoryId,
    this.bibNumber,
  });

  final String id;
  final String marathonId;
  final String marathonName;

  /// Fecha y ciudad de la maraton. Solo para pintar una inscripcion que
  /// todavia no es carrera —no sale en `/races/me`— sin ir a buscar el
  /// catalogo entero por dos lineas de texto.
  final DateTime? marathonDate;
  final String? marathonCity;
  final RegistrationState state;
  final RegistrationStep step;
  final RegistrationQuote quote;
  final String? categoryId;
  final String? bibNumber;
}

/// Datos de tarjeta. Viajan una sola vez y no se guardan en ningun sitio.
///
/// El proveedor es simulado y responde por numero: 4242…4242 aprueba,
/// 4000…0002 rechaza y 4000…0069 responde tarjeta vencida. Sirve para probar
/// los tres caminos sin montar un banco.
@immutable
class CardDetails {
  const CardDetails({
    required this.number,
    required this.holder,
    required this.expMonth,
    required this.expYear,
    required this.cvv,
  });

  final String number;
  final String holder;
  final int expMonth;
  final int expYear;
  final String cvv;

  Map<String, Object?> toApi() => {
    'number': number.replaceAll(RegExp(r'\s'), ''),
    'holder': holder,
    'expMonth': expMonth,
    'expYear': expYear,
    'cvv': cvv,
  };
}

/// Estado de un cobro. Lo que se sondea mientras el QR sigue abierto.
@immutable
class PaymentInfo {
  const PaymentInfo({
    required this.id,
    required this.method,
    required this.state,
    required this.amount,
    this.failureReason,
    this.qrPayload,
    this.qrInstructions,
    this.qrReference,
    this.bankReference,
    this.last4,
    this.proof,
  });

  final String id;
  final RacePaymentMethod method;
  final RacePaymentState state;
  final Money amount;

  /// Motivo estable del rechazo (`card_declined`, `expired_card`…). Se ramifica
  /// por esto y nunca por el texto del mensaje.
  final String? failureReason;

  /// El contenido del QR **como texto**. La app dibuja el codigo con esto en
  /// vez de descargar una imagen: pesa bytes en lugar de cientos de KB, sale
  /// nitido a cualquier tamano y no depende de la red para pintarse.
  final String? qrPayload;

  /// Instrucciones del organizador junto al QR, y la glosa que hay que poner en
  /// la transferencia. **Temporal**, solo en `qr_manual`.
  final String? qrInstructions;
  final String? qrReference;

  final String? bankReference;
  final String? last4;

  /// El ultimo comprobante subido, si el metodo lo lleva. **Temporal.**
  final PaymentProof? proof;

  bool get isSettled => state != RacePaymentState.pending;

  /// Esta esperando a que un organizador mire el comprobante. Es distinto de
  /// "no ha subido nada": en ese caso lo que toca es pedirselo, no esperar.
  bool get isAwaitingReview =>
      !isSettled && proof?.state == ProofState.inReview;

  /// Le rechazaron la captura y el cobro sigue abierto: puede subir otra.
  bool get needsAnotherProof =>
      !isSettled &&
      method.needsProof &&
      (proof == null || proof!.state == ProofState.rejected);
}

/// Lo que devuelve el checkout: el cobro y como quedo la inscripcion.
///
/// Van juntos porque la pantalla tiene que pintar el dorsal y el estado nuevo a
/// la vez; con dos llamadas hay un instante en que se ve "pagado" y "sin
/// dorsal".
@immutable
class CheckoutOutcome {
  const CheckoutOutcome({required this.payment, required this.registration});

  final PaymentInfo payment;
  final Registration registration;

  bool get isConfirmed => registration.state.isConfirmed;
}
