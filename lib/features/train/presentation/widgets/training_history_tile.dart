import 'package:flutter/material.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/formatters/formatters.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/features/home/domain/entities/training_plan.dart';
import 'package:paceup/features/train/domain/entities/training_run.dart';
import 'package:paceup/l10n/l10n_labels.dart';
import 'package:paceup/shared/widgets/organisms/route_map_view.dart';

IconData iconForSessionType(SessionType type) => switch (type) {
  SessionType.easy || SessionType.recovery => Icons.self_improvement_rounded,
  SessionType.tempo => Icons.speed_rounded,
  SessionType.intervals => Icons.timer_outlined,
  SessionType.long => Icons.landscape_outlined,
  SessionType.rest => Icons.bedtime_outlined,
  SessionType.race => Icons.emoji_events_outlined,
};

class TrainingHistoryTile extends StatelessWidget {
  const TrainingHistoryTile({
    required this.run,
    required this.onTap,
    super.key,
  });

  final TrainingRun run;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: c.border),
              boxShadow: c.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.primaryContainer,
                  ),
                  child: Icon(
                    iconForSessionType(run.type),
                    size: 19,
                    color: c.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        run.localizedTitle(context.l10n),
                        style: context.text.titleMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${Fmt.weekdayDayMonth(run.startedAt)} · '
                        '${Fmt.timeOfDay(run.startedAt)}',
                        style: context.text.bodySm.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.md,
                        children: [
                          _Metric(
                            icon: Icons.straighten_rounded,
                            value: Fmt.distance(run.distanceKm),
                          ),
                          _Metric(
                            icon: Icons.speed_rounded,
                            value: Fmt.paceWithUnit(run.avgPacePerKm),
                          ),
                          _Metric(
                            icon: Icons.schedule_rounded,
                            value: Fmt.durationShort(run.elapsed),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                RouteThumbnail(route: run.route),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c.textSecondary),
        const SizedBox(width: AppSpacing.xxs + 2),
        Text(
          value,
          style: context.text.bodySm.copyWith(color: c.textSecondary),
        ),
      ],
    );
  }
}
