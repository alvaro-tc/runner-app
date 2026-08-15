import 'package:flutter/material.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/theme/app_spacing.dart';

/// Icon bubble + big value + caption. The unit of every metric grid.
class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    this.tone,
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = tone ?? c.primary;
    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.base),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: compact ? context.text.headingMd : context.text.headingLg,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: context.text.labelSm.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Icon + title on the left, value (and optional chevron) on the right.
class StatRow extends StatelessWidget {
  const StatRow({
    required this.icon,
    required this.title,
    this.value,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.tone,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? value;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = tone ?? c.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 19, color: accent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleMd),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: context.text.bodySm.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (value != null)
              Flexible(
                child: Text(
                  value!,
                  textAlign: TextAlign.right,
                  style: context.text.bodyMd.copyWith(color: c.textSecondary),
                ),
              ),
            ?trailing,
            if (onTap != null && trailing == null) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: c.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Section title with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: context.text.headingMd,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (action != null) ...[const SizedBox(width: AppSpacing.sm), action!],
      ],
    );
  }
}

/// Label/value pair used in payment breakdowns and race registration details.
class SessionSummaryRow extends StatelessWidget {
  const SessionSummaryRow({
    required this.label,
    required this.value,
    this.emphasise = false,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasise;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasise
                  ? context.text.titleMd
                  : context.text.bodyMd.copyWith(color: c.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          Text(
            value,
            textAlign: TextAlign.right,
            style: (emphasise ? context.text.titleMd : context.text.bodyMd)
                .copyWith(color: valueColor ?? c.textPrimary),
          ),
        ],
      ),
    );
  }
}
