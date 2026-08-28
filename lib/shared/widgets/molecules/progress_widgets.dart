import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/shared/widgets/atoms/app_progress_ring.dart';
import 'package:flutter/material.dart';

/// One column of the weekly plan strip: weekday label above a ring (or a rest
/// dot), with today rendered heavier.
class DayProgressItem extends StatelessWidget {
  const DayProgressItem({
    required this.weekday,
    required this.progress,
    required this.isRest,
    required this.isToday,
    this.label,
    this.onTap,
    this.selected = false,
    this.ringSize = AppSizes.dayRing,
    super.key,
  });

  final String weekday;
  final double progress;
  final bool isRest;
  final bool isToday;
  final String? label;
  final VoidCallback? onTap;

  /// El dia que se esta mirando en la tarjeta de abajo.
  final bool selected;

  /// Shrunk by the parent when seven columns will not fit at full size.
  final double ringSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: onTap != null,
      label: isRest
          ? context.l10n.daySemanticsRest(weekday)
          : context.l10n.daySemanticsProgress(
              weekday,
              label ?? '',
              (progress * 100).round(),
            ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: selected
              ? BoxDecoration(
                  color: c.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                )
              : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                weekday,
                style: context.text.labelSm.copyWith(
                  color: isToday ? c.primary : c.textSecondary,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (isRest)
                RestDayDot(size: ringSize)
              else
                AppProgressRing(
                  progress: progress,
                  size: ringSize,
                  label: label,
                  emphasised: isToday,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lap tracker for the live session: completed segments carry the brand
/// gradient, the active lap is marked by a raised dot.
class SegmentedProgressBar extends StatelessWidget {
  const SegmentedProgressBar({
    required this.total,
    required this.completed,
    this.currentProgress = 0,
    this.height = 6,
    super.key,
  });

  final int total;
  final int completed;

  /// 0..1 within the active segment.
  final double currentProgress;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: context.l10n.runLapSemantics(completed + 1, total),
      child: SizedBox(
        height: height + AppSpacing.sm,
        child: Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: c.ringTrack,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: i < completed
                          ? 1.0
                          : i == completed
                          ? currentProgress.clamp(0.0, 1.0)
                          : 0.0,
                      child: Container(
                        height: height,
                        decoration: BoxDecoration(
                          gradient: c.brandGradient,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                    if (i == completed)
                      Positioned(
                        left: 0,
                        child: FractionallySizedBox(
                          widthFactor: currentProgress.clamp(0.0, 1.0),
                          child: const Align(
                            alignment: Alignment.centerRight,
                            child: _LapDot(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LapDot extends StatelessWidget {
  const _LapDot();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.surface,
        border: Border.all(color: c.primary, width: 3),
        boxShadow: c.floatingShadow,
      ),
    );
  }
}
