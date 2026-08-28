import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/home/domain/entities/training_plan.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:flutter/material.dart';

class TodaySessionCard extends StatelessWidget {
  const TodaySessionCard({
    required this.session,
    required this.onToggleCompleted,
    required this.onReschedule,
    required this.onStart,
    super.key,
  });

  final PlannedSession session;
  final ValueChanged<bool> onToggleCompleted;
  final VoidCallback onReschedule;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    Fmt.weekdayDayMonth(session.date),
                    style: context.text.bodySm.copyWith(color: c.textSecondary),
                  ),
                ),
              ),
              AppCheckbox(
                value: session.isCompleted,
                semanticsLabel: t.homeMarkSessionDone(session.title(t)),
                onChanged: onToggleCompleted,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: session.title(t), style: context.text.headingMd),
                if (!session.type.isRest)
                  TextSpan(
                    text:
                        ' • ${Fmt.durationShort(session.targetDuration)} @ '
                        '${Fmt.paceRange(session.targetPace.min, session.targetPace.max)}',
                    style: context.text.bodyMd.copyWith(color: c.textSecondary),
                  ),
              ],
            ),
          ),
          if (session.routeName != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.route_rounded, size: 15, color: c.textSecondary),
                const SizedBox(width: AppSpacing.xs + 2),
                Flexible(
                  child: Text(
                    session.routeName!,
                    style: context.text.bodySm.copyWith(color: c.textSecondary),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                flex: 10,
                child: AppButton(
                  label: t.homeReschedule,
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.md,
                  onPressed: onReschedule,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 13,
                child: AppButton(
                  label: t.homeStartRun,
                  size: AppButtonSize.md,
                  onPressed: session.type.isRest ? null : onStart,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
