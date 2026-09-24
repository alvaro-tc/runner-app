import 'package:camrun/features/notifications/domain/notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the inbox row and exposes navigation data', () {
    final n = AppNotification.fromJson({
      'id': 'n1',
      'type': NotificationTypes.proofSubmitted,
      'title': 'Nuevo pago por validar',
      'body': '...',
      'data': {
        'paymentId': 'p1',
        'registrationId': 'r1',
        'amountCents': '15000',
        'currency': 'BOB',
        'runnerName': 'Ana',
      },
      'readAt': null,
      'createdAt': '2026-09-24T12:00:00.000Z',
    });

    expect(n.unread, isTrue);
    expect(n.paymentId, 'p1');
    expect(n.registrationId, 'r1');
    expect(n.amountCents, 15000);
    expect(n.bibNumber, isNull);
    expect(n.markedRead().unread, isFalse);
  });
}
