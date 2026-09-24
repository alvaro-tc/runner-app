import 'dart:async';

import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/features/auth/presentation/providers/auth_provider.dart';
import 'package:camrun/features/notifications/domain/notifications.dart';
import 'package:camrun/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:camrun/features/notifications/presentation/widgets/payment_result_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Titulo y cuerpo en el idioma del usuario. El servidor manda su texto en
/// espanol; para los tipos conocidos se redacta aqui con los datos que trae.
({String title, String body}) notificationText(
  BuildContext context,
  AppNotification n,
) {
  final t = context.l10n;
  switch (n.type) {
    case NotificationTypes.proofSubmitted:
      final cents = n.amountCents;
      if (cents == null) break;
      return (
        title: t.notificationProofSubmittedTitle,
        body: t.notificationProofSubmittedBody(
          n.runnerName,
          Fmt.money(cents / 100, n.currency),
          n.marathonName,
        ),
      );
    case NotificationTypes.paymentApproved:
      return (
        title: t.notificationPaymentApprovedTitle,
        body: t.notificationPaymentApprovedBody(n.marathonName),
      );
    case NotificationTypes.paymentRejected:
      return (
        title: t.notificationPaymentRejectedTitle,
        body: t.notificationPaymentRejectedBody(n.marathonName, n.reason),
      );
  }
  return (title: n.title, body: n.body);
}

IconData notificationIcon(AppNotification n) => switch (n.type) {
  NotificationTypes.proofSubmitted => Icons.receipt_long_rounded,
  NotificationTypes.paymentApproved => Icons.verified_rounded,
  NotificationTypes.paymentRejected => Icons.error_outline_rounded,
  _ => Icons.notifications_rounded,
};

/// Marca la notificacion como leida y lleva a donde se atiende: la ficha del
/// cobro para el organizador; para el corredor, la ventana del resultado y
/// despues su inscripcion o el paso de pago para subir otro comprobante.
Future<void> openNotification(
  BuildContext context,
  WidgetRef ref,
  AppNotification n,
) async {
  unawaited(ref.read(notificationsProvider.notifier).markRead(n.id));

  switch (n.type) {
    case NotificationTypes.proofSubmitted:
      final esAdmin = ref.read(authProvider).isAdmin;
      final destino = Routes.ticketsFocused(
        esAdmin ? Routes.adminTickets : Routes.organizerTickets,
        n.paymentId,
      );
      // El admin no tiene pestana de cobros: se apila, con su flecha de volver.
      if (esAdmin) {
        unawaited(context.push(destino));
      } else {
        context.go(destino);
      }
    case NotificationTypes.paymentApproved:
      final inscripcion = n.registrationId;
      final ver = await showPaymentApprovedDialog(context, n);
      if (ver && inscripcion != null && context.mounted) {
        context.go(Routes.raceDetailOf(inscripcion));
      }
    case NotificationTypes.paymentRejected:
      final (maraton, inscripcion) = (n.marathonId, n.registrationId);
      final reintentar = await showPaymentRejectedDialog(context, n);
      if (reintentar &&
          maraton != null &&
          inscripcion != null &&
          context.mounted) {
        context.go(Routes.marathonResumePaymentOf(maraton, inscripcion));
      }
  }
}
