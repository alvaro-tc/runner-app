import 'package:camrun/core/utils/result.dart';

/// Los tipos que la app sabe abrir. El resto se pinta con el texto del
/// servidor y no navega.
abstract final class NotificationTypes {
  /// Al organizador: un corredor subio un comprobante.
  static const proofSubmitted = 'payment.proof_submitted';

  /// Al corredor: su pago fue validado.
  static const paymentApproved = 'payment.approved';

  /// Al corredor: rechazaron su comprobante. El cobro sigue abierto.
  static const paymentRejected = 'payment.rejected';

  /// Los que abren una ventana sola al llegar: el corredor esta esperando.
  static const announced = {paymentApproved, paymentRejected};
}

/// Un aviso de la bandeja de la campana.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        data: {
          for (final e in ((json['data'] as Map?) ?? const {}).entries)
            '${e.key}': '${e.value}',
        },
        readAt: DateTime.tryParse(json['readAt'] as String? ?? ''),
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  final String id;
  final String type;

  /// Texto del servidor, en espanol. La app redacta el suyo para los tipos que
  /// conoce; este queda para los que no.
  final String title;
  final String body;

  /// Ids para navegar y datos para redactar. Todo string, como llega de FCM.
  final Map<String, String> data;

  final DateTime? readAt;
  final DateTime createdAt;

  bool get unread => readAt == null;

  String? get paymentId => data['paymentId'];
  String? get registrationId => data['registrationId'];
  String? get marathonId => data['marathonId'];

  /// Motivo del rechazo, escrito por el organizador.
  String get reason => data['reason'] ?? '';
  String get marathonName => data['marathonName'] ?? '';
  String get runnerName => data['runnerName'] ?? '';
  int? get amountCents => int.tryParse(data['amountCents'] ?? '');
  String get currency => data['currency'] ?? 'BOB';
  String? get bibNumber => data['bibNumber'];

  AppNotification markedRead() => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    data: data,
    createdAt: createdAt,
    readAt: readAt ?? DateTime.now(),
  );
}

typedef NotificationInbox = ({List<AppNotification> items, int unreadCount});

abstract interface class NotificationRepository {
  Future<Result<NotificationInbox>> fetchInbox();

  Future<Result<void>> markRead(String id);

  Future<Result<void>> markAllRead();

  /// Cuelga el token de FCM de este telefono en la cuenta con sesion.
  Future<Result<void>> registerPushToken(String token);
}
