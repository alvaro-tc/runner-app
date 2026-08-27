import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/home/domain/entities/training_plan.dart';
import 'package:camrun/shared/widgets/molecules/progress_widgets.dart';
import 'package:flutter/material.dart';

/// Seven day columns. Falls back to a horizontal scroll on narrow screens or
/// at large text scales rather than squeezing the rings.
class WeeklyPlanStrip extends StatelessWidget {
  const WeeklyPlanStrip({required this.week, this.onSessionTap, super.key});

  final TrainingWeek week;
  final void Function(PlannedSession session)? onSessionTap;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    List<Widget> buildItems(double ringSize) => [
      for (final session in week.sessions)
        DayProgressItem(
          ringSize: ringSize,
          weekday: Fmt.weekdayShort(session.date),
          progress: session.completionRatio,
          isRest: session.type.isRest,
          isToday:
              session.date.year == today.year &&
              session.date.month == today.month &&
              session.date.day == today.day,
          label: session.type.isRest
              ? null
              : Fmt.distanceShort(session.targetDistanceKm),
          onTap: onSessionTap == null ? null : () => onSessionTap!(session),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Each column carries 8pt of internal padding. Shrink the rings to fit
        // seven of them; below 40pt the labels stop being readable, so the
        // strip scrolls instead.
        final available = constraints.maxWidth / 7 - AppSpacing.sm;
        if (available >= 40) {
          final ringSize = available.clamp(40.0, AppSizes.dayRing);
          return Row(
            children: [
              for (final item in buildItems(ringSize)) Expanded(child: item),
            ],
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final item in buildItems(AppSizes.dayRing))
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: SizedBox(width: 64, child: item),
                ),
            ],
          ),
        );
      },
    );
  }
}
