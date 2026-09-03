import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Que boton ofrece un ticket, y con quien queda firmado.
///
/// Es lo unico de esta pantalla que mueve dinero: la ficha elige entre aprobar
/// el comprobante y confirmar la transferencia leyendo estas dos propiedades, y
/// equivocarse manda un POST al endpoint que no era —o, peor, ofrece acreditar
/// un cobro que ya estaba pagado—.
Map<String, dynamic> _json({
  String status = 'pending',
  String method = 'qr_manual',
  String? proofId,
  String? validatedBy,
  String? refundedBy,
}) => {
  'id': 'pay_1',
  'method': method,
  'status': status,
  'amountCents': 20000,
  'currency': 'BOB',
  'marathon': 'Maraton de La Paz',
  'runner': 'Ana Quispe',
  'proofId': proofId,
  'validatedBy': validatedBy,
  'refundedBy': refundedBy,
};

void main() {
  group('acciones de un ticket', () {
    test('QR con comprobante esperando: se revisa la imagen', () {
      final ticket = AdminTicket.fromJson(_json(proofId: 'proof_1'));

      expect(ticket.canReviewProof, isTrue);
      expect(ticket.canConfirmTransfer, isFalse);
    });

    test('transferencia sin comprobante: se confirma contra el extracto', () {
      final ticket = AdminTicket.fromJson(_json(method: 'bank_transfer'));

      expect(ticket.canReviewProof, isFalse);
      expect(ticket.canConfirmTransfer, isTrue);
    });

    test('una tarjeta no se acredita a mano', () {
      final ticket = AdminTicket.fromJson(_json(method: 'card'));

      expect(ticket.canReviewProof, isFalse);
      expect(ticket.canConfirmTransfer, isFalse);
    });

    test('lo ya cobrado no se aprueba otra vez: se devuelve', () {
      final ticket = AdminTicket.fromJson(
        _json(status: 'paid', proofId: 'proof_1'),
      );

      expect(ticket.pending, isFalse);
      expect(ticket.canReviewProof, isFalse);
      expect(ticket.canConfirmTransfer, isFalse);
      expect(ticket.canRefund, isTrue);
    });

    test('un cobro pendiente no se devuelve, se rechaza', () {
      expect(AdminTicket.fromJson(_json()).canRefund, isFalse);
    });

    test('lo ya devuelto no se devuelve dos veces', () {
      final ticket = AdminTicket.fromJson(_json(status: 'refunded'));

      expect(ticket.refunded, isTrue);
      expect(ticket.canRefund, isFalse);
    });
  });

  group('auditoria', () {
    test('sin validar mientras nadie le puso el nombre', () {
      expect(AdminTicket.fromJson(_json()).validatedBy, isNull);
    });

    test('quien devolvio y quien aprobo son dos asientos, no uno', () {
      final ticket = AdminTicket.fromJson(
        _json(
          status: 'refunded',
          validatedBy: 'Marcela Ruiz',
          refundedBy: 'Diego Soto',
        ),
      );

      // Devolver no borra a quien habia aprobado: los dos nombres se
      // conservan, que es lo unico que le pide una auditoria.
      expect(ticket.validatedBy, 'Marcela Ruiz');
      expect(ticket.refundedBy, 'Diego Soto');
    });

    test('el nombre de quien aprobo llega tal cual', () {
      final ticket = AdminTicket.fromJson(
        _json(status: 'paid', validatedBy: 'Marcela Ruiz'),
      );

      expect(ticket.validatedBy, 'Marcela Ruiz');
    });
  });
}
