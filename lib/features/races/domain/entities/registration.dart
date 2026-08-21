import 'package:meta/meta.dart';
import 'package:paceup/features/home/domain/entities/marathon.dart';

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

/// Metodos de cobro que atiende el proveedor simulado.
enum RacePaymentMethod {
  card('card', 'Card'),
  qr('qr', 'QR'),
  bankTransfer('bank_transfer', 'Bank transfer');

  const RacePaymentMethod(this.api, this.label);
  final String api;
  final String label;

  /// Solo la tarjeta resuelve en el acto; el resto queda pendiente y hay que
  /// sondear el cobro.
  bool get settlesImmediately => this == card;
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
    this.phone,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.bloodType,
    this.shirtSize,
  });

  final String fullName;
  final String docId;
  final String? phone;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? bloodType;
  final String? shirtSize;

  Map<String, Object?> toApi() => {
    'fullName': fullName,
    'docId': docId,
    if (phone != null && phone!.isNotEmpty) 'phone': phone,
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
    this.categoryId,
    this.bibNumber,
  });

  final String id;
  final String marathonId;
  final String marathonName;
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
    this.qrImageUrl,
    this.bankReference,
    this.last4,
  });

  final String id;
  final RacePaymentMethod method;
  final RacePaymentState state;
  final Money amount;

  /// Motivo estable del rechazo (`card_declined`, `expired_card`…). Se ramifica
  /// por esto y nunca por el texto del mensaje.
  final String? failureReason;

  final String? qrImageUrl;
  final String? bankReference;
  final String? last4;

  bool get isSettled => state != RacePaymentState.pending;
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
