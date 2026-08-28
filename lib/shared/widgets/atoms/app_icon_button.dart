import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum AppIconButtonStyle {
  /// Bare glyph — the back arrow on the auth screens.
  plain,

  /// Circular surface + 1px border — app bars over content.
  bordered,

  /// Filled dark circle — the map re-centre control.
  ink,

  /// Filled brand circle — the music control in a live session.
  brand,
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    required this.semanticsLabel,
    this.style = AppIconButtonStyle.bordered,
    this.size = AppSizes.minTapTarget,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticsLabel;
  final AppIconButtonStyle style;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg, border) = switch (style) {
      AppIconButtonStyle.plain => (Colors.transparent, c.textPrimary, null),
      AppIconButtonStyle.bordered => (
        c.surface,
        c.textPrimary,
        BorderSide(color: c.border),
      ),
      AppIconButtonStyle.ink => (c.inkPill, c.onInkPill, null),
      AppIconButtonStyle.brand => (c.primary, c.onPrimary, null),
    };

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: SizedBox.square(
        dimension: size < AppSizes.minTapTarget ? AppSizes.minTapTarget : size,
        child: Center(
          child: Material(
            color: bg,
            shape: CircleBorder(side: border ?? BorderSide.none),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: SizedBox.square(
                dimension: size,
                child: Icon(icon, size: size * 0.45, color: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
