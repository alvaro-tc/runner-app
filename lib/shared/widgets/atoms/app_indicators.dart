import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Semantic tone shared by badges, pills and chips.
enum AppTone { neutral, brand, success, warning, error, info }

extension AppToneColors on AppTone {
  ({Color fg, Color bg}) resolve(BuildContext context) {
    final c = context.colors;
    return switch (this) {
      AppTone.neutral => (
        fg: c.textSecondary,
        bg: c.border.withValues(alpha: 0.4),
      ),
      AppTone.brand => (fg: c.primary, bg: c.primaryContainer),
      AppTone.success => (fg: c.success, bg: c.successBg),
      AppTone.warning => (fg: c.warning, bg: c.warningBg),
      AppTone.error => (fg: c.error, bg: c.errorBg),
      AppTone.info => (
        fg: c.accentBlue,
        bg: c.accentBlue.withValues(alpha: 0.12),
      ),
    };
  }
}

/// Small status label: `Registration open`, `Paid $85.00`, `BIB 0666`.
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    this.tone = AppTone.brand,
    this.icon,
    super.key,
  });

  final String label;
  final AppTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = tone.resolve(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: t.fg),
            const SizedBox(width: AppSpacing.xs + 2),
          ],
          Text(label, style: context.text.labelSm.copyWith(color: t.fg)),
        ],
      ),
    );
  }
}

/// Larger, tappable sibling of [AppBadge] — used as a filter chip.
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.primary : c.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: selected ? c.primary : c.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 15,
                    color: selected ? c.onPrimary : c.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                ],
                Text(
                  label,
                  style: context.text.labelSm.copyWith(
                    color: selected ? c.onPrimary : c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded-square checkbox from the Home "today session" card.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    required this.value,
    required this.onChanged,
    this.semanticsLabel,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      checked: value,
      label: semanticsLabel,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: AppDurations.curve,
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value ? c.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: value ? c.primary : c.border,
                width: 1.5,
              ),
            ),
            child: value
                ? Icon(Icons.check_rounded, size: 16, color: c.onPrimary)
                : null,
          ),
        ),
      ),
    );
  }
}

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.initials,
    this.imageUrl,
    this.size = 44,
    this.ringWidth = 0,
    this.ringColor,
    super.key,
  });

  final String initials;
  final String? imageUrl;
  final double size;
  final double ringWidth;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringWidth > 0 ? (ringColor ?? c.surface) : Colors.transparent,
      ),
      child: ClipOval(
        child: ColoredBox(
          color: c.primaryContainer,
          child: Center(
            child: Text(
              initials,
              style: context.text.titleMd.copyWith(
                color: c.primary,
                fontSize: size * 0.34,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppDivider extends StatelessWidget {
  const AppDivider({this.indent = 0, super.key});

  final double indent;

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    indent: indent,
    color: context.colors.border,
  );
}
