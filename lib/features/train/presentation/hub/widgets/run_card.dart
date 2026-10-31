import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/train/domain/entities/workout_log.dart';
import 'package:camrun/features/train/presentation/hub/train_labels.dart';
import 'package:camrun/features/train/presentation/hub/widgets/hub_motion.dart';
import 'package:flutter/material.dart';

/// La distancia, en un disco con el degradado de la marca.
///
/// Es la pieza que vuela de la tarjeta a la cabecera del detalle, de ahi el
/// [Hero] y de ahi el [FittedBox]: el texto se escala con el disco durante el
/// vuelo en vez de dar un salto de tamano al aterrizar.
class DistanceBadge extends StatelessWidget {
  const DistanceBadge({
    required this.runId,
    required this.distanceKm,
    required this.miles,
    this.size = 64,
    super.key,
  });

  final String runId;
  final double distanceKm;
  final bool miles;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Hero(
      tag: 'run-badge-$runId',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: c.brandGradient,
          shape: BoxShape.circle,
          boxShadow: c.cardShadow,
        ),
        padding: EdgeInsets.all(size * 0.14),
        child: FittedBox(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Fmt.distanceValue(distanceKm, miles: miles, decimals: 1),
                style: context.text.titleMd.copyWith(color: c.onPrimary),
              ),
              Text(
                miles ? 'mi' : 'km',
                style: context.text.labelSm.copyWith(
                  color: c.onPrimary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una salida del historial.
class RunCard extends StatelessWidget {
  const RunCard({
    required this.run,
    required this.miles,
    required this.onTap,
    super.key,
  });

  final WorkoutLog run;
  final bool miles;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            DistanceBadge(
              runId: run.id,
              distanceKm: run.distanceKm,
              miles: miles,
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(run.kind.icon, size: 16, color: c.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          runTitle(run, t),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleMd,
                        ),
                      ),
                      if (run.mood != null)
                        Text(run.mood!.emoji, style: context.text.bodyMd),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${Fmt.weekdayDayMonth(run.startedAt)} · '
                    '${Fmt.timeOfDay(run.startedAt)}',
                    style: context.text.labelSm.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Tiempo y ritmo, nada mas: el desnivel y las calorias de
                  // cada salida estan a un toque, en el detalle.
                  Row(
                    children: [
                      _Chip(
                        icon: Icons.schedule_rounded,
                        text: Fmt.clock(run.duration),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _Chip(
                        icon: Icons.speed_rounded,
                        text: run.avgPace == null
                            ? '--'
                            : Fmt.pace(run.avgPace!, miles: miles),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 14, color: c.textSecondary),
        const SizedBox(width: AppSpacing.xxs),
        Text(text, style: context.text.labelSm.copyWith(color: c.textPrimary)),
      ],
    );
  }
}
