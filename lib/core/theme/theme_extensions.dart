import 'package:flutter/material.dart';
import 'package:paceup/core/theme/app_colors.dart';
import 'package:paceup/core/theme/app_shadows.dart';

/// Every semantic colour role the app uses, including the ones Material 3 does
/// not model (success/warning pairs, ring track, map overlay, brand gradients).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.isDark,
    required this.primary,
    required this.primaryLight,
    required this.primaryContainer,
    required this.onPrimary,
    required this.accentBlue,
    required this.error,
    required this.errorBg,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.surface,
    required this.surfaceElevated,
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.inkPill,
    required this.onInkPill,
    required this.ringTrack,
    required this.mapOverlay,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  factory AppPalette.light() => const AppPalette(
    isDark: false,
    primary: LightTokens.primary,
    primaryLight: LightTokens.primaryLight,
    primaryContainer: LightTokens.primaryContainer,
    onPrimary: LightTokens.onPrimary,
    accentBlue: LightTokens.accentBlue,
    error: LightTokens.error,
    errorBg: LightTokens.errorBg,
    success: LightTokens.success,
    successBg: LightTokens.successBg,
    warning: LightTokens.warning,
    warningBg: LightTokens.warningBg,
    surface: LightTokens.surface,
    surfaceElevated: LightTokens.surfaceElevated,
    background: LightTokens.background,
    textPrimary: LightTokens.textPrimary,
    textSecondary: LightTokens.textSecondary,
    border: LightTokens.border,
    inkPill: LightTokens.inkPill,
    onInkPill: LightTokens.onInkPill,
    ringTrack: LightTokens.ringTrack,
    mapOverlay: LightTokens.mapOverlay,
    shimmerBase: LightTokens.shimmerBase,
    shimmerHighlight: LightTokens.shimmerHighlight,
  );

  factory AppPalette.dark() => const AppPalette(
    isDark: true,
    primary: DarkTokens.primary,
    primaryLight: DarkTokens.primaryLight,
    primaryContainer: DarkTokens.primaryContainer,
    onPrimary: DarkTokens.onPrimary,
    accentBlue: DarkTokens.accentBlue,
    error: DarkTokens.error,
    errorBg: DarkTokens.errorBg,
    success: DarkTokens.success,
    successBg: DarkTokens.successBg,
    warning: DarkTokens.warning,
    warningBg: DarkTokens.warningBg,
    surface: DarkTokens.surface,
    surfaceElevated: DarkTokens.surfaceElevated,
    background: DarkTokens.background,
    textPrimary: DarkTokens.textPrimary,
    textSecondary: DarkTokens.textSecondary,
    border: DarkTokens.border,
    inkPill: DarkTokens.inkPill,
    onInkPill: DarkTokens.onInkPill,
    ringTrack: DarkTokens.ringTrack,
    mapOverlay: DarkTokens.mapOverlay,
    shimmerBase: DarkTokens.shimmerBase,
    shimmerHighlight: DarkTokens.shimmerHighlight,
  );

  final bool isDark;

  final Color primary;
  final Color primaryLight;
  final Color primaryContainer;
  final Color onPrimary;
  final Color accentBlue;

  final Color error;
  final Color errorBg;
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;

  final Color surface;
  final Color surfaceElevated;
  final Color background;

  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  final Color inkPill;
  final Color onInkPill;

  final Color ringTrack;
  final Color mapOverlay;
  final Color shimmerBase;
  final Color shimmerHighlight;

  /// 135° brand gradient — countdown pill, progress rings, highlighted CTAs.
  LinearGradient get brandGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  /// Route polyline: purple to blue.
  LinearGradient get routeGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accentBlue],
  );

  /// Scrim laid over hero imagery so overlaid text keeps AA contrast.
  LinearGradient get heroOverlay => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x59000000)],
  );

  List<BoxShadow> get cardShadow =>
      AppShadows.card(tint: primary, isDark: isDark);

  List<BoxShadow> get floatingShadow =>
      AppShadows.floating(tint: primary, isDark: isDark);

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      isDark: t < 0.5 ? isDark : other.isDark,
      primary: c(primary, other.primary),
      primaryLight: c(primaryLight, other.primaryLight),
      primaryContainer: c(primaryContainer, other.primaryContainer),
      onPrimary: c(onPrimary, other.onPrimary),
      accentBlue: c(accentBlue, other.accentBlue),
      error: c(error, other.error),
      errorBg: c(errorBg, other.errorBg),
      success: c(success, other.success),
      successBg: c(successBg, other.successBg),
      warning: c(warning, other.warning),
      warningBg: c(warningBg, other.warningBg),
      surface: c(surface, other.surface),
      surfaceElevated: c(surfaceElevated, other.surfaceElevated),
      background: c(background, other.background),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      border: c(border, other.border),
      inkPill: c(inkPill, other.inkPill),
      onInkPill: c(onInkPill, other.onInkPill),
      ringTrack: c(ringTrack, other.ringTrack),
      mapOverlay: c(mapOverlay, other.mapOverlay),
      shimmerBase: c(shimmerBase, other.shimmerBase),
      shimmerHighlight: c(shimmerHighlight, other.shimmerHighlight),
    );
  }
}
