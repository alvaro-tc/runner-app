import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

enum AppButtonSize {
  sm(40, AppSpacing.base, 14),
  md(48, AppSpacing.md, 15),
  lg(AppSizes.controlHeight, AppSpacing.xl, 16);

  const AppButtonSize(this.height, this.padH, this.fontSize);

  final double height;
  final double padH;
  final double fontSize;
}

/// The single button in the app. Screens pick a variant and a size; nothing
/// else about it is configurable, which is what keeps the CTAs consistent.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.lg,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.semanticsLabel,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final String? semanticsLabel;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg, border) = switch (variant) {
      AppButtonVariant.primary => (c.primary, c.onPrimary, null),
      AppButtonVariant.secondary => (c.primaryContainer, c.primary, null),
      AppButtonVariant.outline => (
        Colors.transparent,
        c.primary,
        BorderSide(color: c.primary, width: 1.5),
      ),
      AppButtonVariant.ghost => (Colors.transparent, c.textSecondary, null),
      AppButtonVariant.danger => (c.error, c.onPrimary, null),
    };

    final radius = BorderRadius.circular(AppRadius.pill);

    final button = Semantics(
      button: true,
      enabled: _enabled,
      label: semanticsLabel ?? label,
      child: Opacity(
        opacity: _enabled ? 1 : 0.45,
        child: Material(
          color: bg,
          borderRadius: radius,
          child: InkWell(
            onTap: _enabled ? onPressed : null,
            borderRadius: radius,
            splashColor: fg.withValues(alpha: 0.12),
            highlightColor: fg.withValues(alpha: 0.06),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: border == null ? null : Border.fromBorderSide(border),
              ),
              child: Container(
                height: size.height,
                width: isFullWidth ? double.infinity : null,
                padding: EdgeInsets.symmetric(horizontal: size.padH),
                alignment: Alignment.center,
                child: isLoading
                    ? SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: fg,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: size.fontSize + 4, color: fg),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.button.copyWith(
                                color: fg,
                                fontSize: size.fontSize,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );

    // Material fills whatever constraints it is given, so shrink-wrapping has
    // to be forced from the outside.
    return isFullWidth ? button : IntrinsicWidth(child: button);
  }
}
