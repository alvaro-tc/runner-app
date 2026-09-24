import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/notifications/domain/notifications.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:flutter/material.dart';

/// La ventana que ve el corredor cuando un organizador valida su pago.
///
/// Devuelve `true` si quiere ir a ver su inscripcion.
Future<bool> showPaymentApprovedDialog(
  BuildContext context,
  AppNotification n,
) {
  final t = context.l10n;
  final dorsal = n.bibNumber;
  return _mostrar(
    context,
    _PaymentResultDialog(
      tone: AppTone.success,
      icon: Icons.check_circle_rounded,
      title: t.paymentApprovedDialogTitle,
      body: t.paymentApprovedDialogBody(n.marathonName),
      detail: dorsal == null
          ? null
          : AppBadge(
              label: t.paymentApprovedBib(dorsal),
              tone: AppTone.success,
              icon: Icons.confirmation_number_rounded,
            ),
      actionLabel: t.paymentApprovedViewRegistration,
    ),
  );
}

/// La ventana del comprobante rechazado, con el motivo del organizador.
///
/// Devuelve `true` si quiere subir otro comprobante ahora.
Future<bool> showPaymentRejectedDialog(
  BuildContext context,
  AppNotification n,
) {
  final t = context.l10n;
  return _mostrar(
    context,
    _PaymentResultDialog(
      tone: AppTone.error,
      icon: Icons.error_rounded,
      title: t.paymentRejectedDialogTitle,
      body: t.paymentRejectedDialogBody(n.marathonName),
      detail: n.reason.isEmpty ? null : _Motivo(reason: n.reason),
      actionLabel: t.paymentRejectedUploadAgain,
    ),
  );
}

Future<bool> _mostrar(BuildContext context, Widget dialogo) async =>
    await showDialog<bool>(context: context, builder: (_) => dialogo) ?? false;

/// El motivo tal cual lo escribio el organizador: es lo unico que le dice al
/// corredor que corregir.
class _Motivo extends StatelessWidget {
  const _Motivo({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.errorBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.paymentRejectedReason,
            style: context.text.labelSm.copyWith(color: c.error),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(reason, style: context.text.bodyMd),
        ],
      ),
    );
  }
}

class _PaymentResultDialog extends StatelessWidget {
  const _PaymentResultDialog({
    required this.tone,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    this.detail,
  });

  final AppTone tone;
  final IconData icon;
  final String title;
  final String body;
  final Widget? detail;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final colores = tone.resolve(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // El icono entra con un rebote: es el momento que el corredor
            // estaba esperando. Sin animacion si el sistema pide menos
            // movimiento.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: context.reduceMotion ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colores.bg,
                ),
                child: Icon(icon, size: 64, color: colores.fg),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.headingLg,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: context.text.bodyMd.copyWith(color: c.textSecondary),
            ),
            if (detail != null) ...[
              const SizedBox(height: AppSpacing.base),
              detail!,
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: actionLabel,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: context.l10n.commonClose,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
