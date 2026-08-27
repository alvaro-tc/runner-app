import 'package:flutter/material.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/formatters/formatters.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/features/home/domain/entities/marathon.dart';
import 'package:paceup/shared/widgets/atoms/app_indicators.dart';
import 'package:paceup/shared/widgets/atoms/event_image.dart';

/// Event artwork with a white card overhanging its bottom edge — the hero
/// block at the top of Home.
class MarathonHeroCard extends StatelessWidget {
  const MarathonHeroCard({required this.marathon, this.onTap, super.key});

  final Marathon marathon;
  final VoidCallback? onTap;

  static const _overhang = 44.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: onTap != null,
      label: '${marathon.name}, ${Fmt.dayMonth(marathon.date)}',
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: _overhang),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AspectRatio(
                aspectRatio: 16 / 11,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    border: Border.all(color: c.inkPill, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Hero(
                    tag: 'marathon-${marathon.id}',
                    child: EventImage(
                      imageUrl: marathon.heroImageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.base,
                right: AppSpacing.base,
                bottom: -_overhang,
                child: _InfoCard(marathon: marathon),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.marathon});

  final Marathon marathon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: c.isDark ? Border.all(color: c.border) : null,
        boxShadow: c.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // One text run so a long event name wraps instead of eating the
          // date, which is the more useful half.
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: marathon.name),
                TextSpan(
                  text: '  •  ${Fmt.dayMonth(marathon.date)}',
                  style: TextStyle(color: c.textSecondary),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleMd,
          ),
          const SizedBox(height: AppSpacing.sm),
          // El afiche solo dice el nombre: donde es, cuanto se corre y cuanto
          // cuesta son las tres preguntas que decide mirar la tarjeta.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppBadge(
                // La ciudad sola: el pais alarga la pastilla hasta partir la
                // fila y la ficha ya tapa bastante afiche.
                label: marathon.city,
                icon: Icons.place_outlined,
                tone: AppTone.neutral,
              ),
              AppBadge(
                label: Fmt.distanceShort(marathon.distanceKm),
                icon: Icons.straighten_rounded,
                tone: AppTone.neutral,
              ),
              if (marathon.entryFee.amount > 0)
                AppBadge(
                  label: Fmt.money(
                    marathon.entryFee.amount,
                    marathon.entryFee.currency,
                  ),
                  icon: Icons.sell_outlined,
                  tone: AppTone.neutral,
                ),
              AppBadge(
                label: marathon.slotsTotal > 0 && marathon.status.acceptsEntries
                    ? '${marathon.slotsLeft} slots left'
                    : marathon.status.label,
                icon: Icons.confirmation_number_outlined,
                tone: switch (marathon.status) {
                  RegistrationStatus.open => AppTone.success,
                  RegistrationStatus.closingSoon => AppTone.warning,
                  RegistrationStatus.full ||
                  RegistrationStatus.closed => AppTone.neutral,
                },
              ),
            ],
          ),
          if (marathon.predictedFinishMin != null &&
              marathon.predictedFinishMax != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: c.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                context.l10n.marathonPredictedFinish(
                  Fmt.durationRange(
                    marathon.predictedFinishMin!,
                    marathon.predictedFinishMax!,
                  ),
                ),
                style: context.text.bodySm.copyWith(color: c.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
