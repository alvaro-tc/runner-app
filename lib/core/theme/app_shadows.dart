import 'package:flutter/material.dart';

/// Elevation is expressed with brand-tinted shadows in light mode. Dark
/// surfaces swallow shadows, so there they collapse to nothing and elevation is
/// communicated with `surfaceElevated` + a 1px border instead.
abstract final class AppShadows {
  static List<BoxShadow> card({required Color tint, required bool isDark}) {
    if (isDark) return const [];
    return [
      BoxShadow(
        color: tint.withValues(alpha: 0.06),
        offset: const Offset(0, 8),
        blurRadius: 24,
      ),
    ];
  }

  static List<BoxShadow> floating({required Color tint, required bool isDark}) {
    if (isDark) return const [];
    return [
      BoxShadow(
        color: tint.withValues(alpha: 0.12),
        offset: const Offset(0, 12),
        blurRadius: 32,
      ),
    ];
  }
}
