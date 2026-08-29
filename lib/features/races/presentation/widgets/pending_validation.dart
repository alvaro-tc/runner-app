import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/races/domain/entities/registration.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:flutter/material.dart';

/// Lo unico que hay que decirle a quien ya subio su comprobante: que espere.
///
/// Es el mismo mensaje en "Mis carreras" y en la ficha de la maraton, y por eso
/// vive en un solo sitio: son la misma respuesta a la misma pregunta —"¿y ahora
/// que?"— y contarla distinto en cada pantalla es lo que hace que el usuario
/// crea que son dos cosas.
Future<void> showPendingValidationDialog(BuildContext context) {
  final t = context.l10n;

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.racesPendingValidation),
      content: Text(t.racesPendingValidationBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.commonClose),
        ),
      ],
    ),
  );
}

/// Una inscripcion pagada por QR que espera a que un administrador mire la
/// captura.
///
/// No es una [RaceCard]: no hay dorsal, ni cuenta atras, ni carrera que largar
/// —el servidor todavia no la da por inscrita—. Pintarla como una carrera mas
/// prometeria una plaza que aun no esta reservada.
class PendingValidationCard extends StatelessWidget {
  const PendingValidationCard({required this.registration, super.key});

  final Registration registration;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final fecha = registration.marathonDate;
    final ciudad = registration.marathonCity;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              registration.marathonName,
              style: context.text.titleMd,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (fecha != null || ciudad != null)
              Text(
                [if (fecha != null) Fmt.dayMonth(fecha), ?ciudad].join(' · '),
                style: context.text.bodySm.copyWith(color: c.textSecondary),
              ),
            const SizedBox(height: AppSpacing.md),
            AppBadge(
              label: t.racesPendingValidation,
              tone: AppTone.warning,
              icon: Icons.hourglass_top_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: t.racesViewDetails,
              variant: AppButtonVariant.outline,
              size: AppButtonSize.sm,
              onPressed: () => showPendingValidationDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}
