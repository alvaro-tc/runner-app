import 'package:flutter/material.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/formatters/formatters.dart';
import 'package:paceup/core/theme/app_spacing.dart';

/// `34d : 10h : 24m` on a dark pill. Digits stay bright, unit letters recede.
class CountdownPill extends StatelessWidget {
  const CountdownPill({
    required this.remaining,
    this.showSeconds = false,
    super.key,
  });

  final Duration remaining;
  final bool showSeconds;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final parts = Fmt.countdown(remaining);
    final segments = <(String, String)>[
      (parts.days, 'd'),
      (parts.hours, 'h'),
      (parts.minutes, 'm'),
      if (showSeconds) (parts.seconds, 's'),
    ];

    return Semantics(
      label:
          'Starts in ${parts.days} days ${parts.hours} hours '
          '${parts.minutes} minutes',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: c.inkPill,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            for (var i = 0; i < segments.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Text(
                    ':',
                    style: context.text.bodySm.copyWith(
                      color: c.onInkPill.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              Text(
                segments[i].$1,
                style: context.text.titleMd.copyWith(color: c.onInkPill),
              ),
              Text(
                segments[i].$2,
                style: context.text.labelSm.copyWith(
                  color: c.onInkPill.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
