import 'package:flutter/painting.dart';

/// Raw colour tokens. Never referenced from the UI directly — they are only
/// consumed by [AppPalette] and [AppTheme], which expose semantic roles.
abstract final class LightTokens {
  static const primary = Color(0xFF8B5CF6);
  static const primaryLight = Color(0xFFC4B5FD);
  static const primaryContainer = Color(0xFFEDE9FE);
  static const onPrimary = Color(0xFFFFFFFF);

  static const accentBlue = Color(0xFF3B82F6);

  static const error = Color(0xFFF43F5E);
  static const errorBg = Color(0xFFFFE4E6);
  static const success = Color(0xFF22C55E);
  static const successBg = Color(0xFFDCFCE7);
  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFEF3C7);

  static const surface = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const background = Color(0xFFF4F2FF);

  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);

  /// Dark chip used by the countdown pill and the map re-centre button.
  static const inkPill = Color(0xFF2A2140);
  static const onInkPill = Color(0xFFFFFFFF);

  static const ringTrack = Color(0xFFEDE9FE);
  static const mapOverlay = Color(0x1A2A2140);
  static const shimmerBase = Color(0xFFEDEAF6);
  static const shimmerHighlight = Color(0xFFF8F6FF);
}

abstract final class DarkTokens {
  static const primary = Color(0xFFA78BFA);
  static const primaryLight = Color(0xFFC4B5FD);
  static const primaryContainer = Color(0xFF2E2545);
  static const onPrimary = Color(0xFF1B1725);

  static const accentBlue = Color(0xFF60A5FA);

  static const error = Color(0xFFFB7185);
  static const errorBg = Color(0xFF3B1E28);
  static const success = Color(0xFF4ADE80);
  static const successBg = Color(0xFF14301F);
  static const warning = Color(0xFFFBBF24);
  static const warningBg = Color(0xFF3A2A0B);

  static const surface = Color(0xFF1B1725);
  static const surfaceElevated = Color(0xFF241E33);
  static const background = Color(0xFF12101A);

  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const border = Color(0xFF2E2A3B);

  static const inkPill = Color(0xFF241E33);
  static const onInkPill = Color(0xFFF1F5F9);

  static const ringTrack = Color(0xFF2E2545);
  static const mapOverlay = Color(0x33000000);
  static const shimmerBase = Color(0xFF241E33);
  static const shimmerHighlight = Color(0xFF2E2745);
}
