import 'package:flutter/material.dart';

/// Text style set exposed through the theme so screens never build a
/// [TextStyle] by hand.
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({
    required this.displayLg,
    required this.displayMd,
    required this.headingLg,
    required this.headingMd,
    required this.titleMd,
    required this.bodyMd,
    required this.bodySm,
    required this.labelSm,
    required this.button,
  });

  /// Builds the scale on top of a single colour so light/dark only differ in
  /// the resolved [color].
  factory AppTextStyles.resolve(Color color) {
    TextStyle base(double size, FontWeight weight, double height) => TextStyle(
      fontFamily: AppTypography.family,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
    );

    return AppTextStyles(
      displayLg: base(
        40,
        FontWeight.w700,
        1.1,
      ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      displayMd: base(32, FontWeight.w700, 1.15),
      headingLg: base(24, FontWeight.w700, 1.25),
      headingMd: base(20, FontWeight.w600, 1.3),
      titleMd: base(17, FontWeight.w600, 1.3),
      bodyMd: base(15, FontWeight.w400, 1.5),
      bodySm: base(13, FontWeight.w400, 1.4),
      labelSm: base(12, FontWeight.w500, 1.3).copyWith(letterSpacing: 0.2),
      button: base(16, FontWeight.w600, 1.2),
    );
  }

  final TextStyle displayLg;
  final TextStyle displayMd;
  final TextStyle headingLg;
  final TextStyle headingMd;
  final TextStyle titleMd;
  final TextStyle bodyMd;
  final TextStyle bodySm;
  final TextStyle labelSm;
  final TextStyle button;

  @override
  AppTextStyles copyWith({
    TextStyle? displayLg,
    TextStyle? displayMd,
    TextStyle? headingLg,
    TextStyle? headingMd,
    TextStyle? titleMd,
    TextStyle? bodyMd,
    TextStyle? bodySm,
    TextStyle? labelSm,
    TextStyle? button,
  }) {
    return AppTextStyles(
      displayLg: displayLg ?? this.displayLg,
      displayMd: displayMd ?? this.displayMd,
      headingLg: headingLg ?? this.headingLg,
      headingMd: headingMd ?? this.headingMd,
      titleMd: titleMd ?? this.titleMd,
      bodyMd: bodyMd ?? this.bodyMd,
      bodySm: bodySm ?? this.bodySm,
      labelSm: labelSm ?? this.labelSm,
      button: button ?? this.button,
    );
  }

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) {
    if (other is! AppTextStyles) return this;
    return AppTextStyles(
      displayLg: TextStyle.lerp(displayLg, other.displayLg, t)!,
      displayMd: TextStyle.lerp(displayMd, other.displayMd, t)!,
      headingLg: TextStyle.lerp(headingLg, other.headingLg, t)!,
      headingMd: TextStyle.lerp(headingMd, other.headingMd, t)!,
      titleMd: TextStyle.lerp(titleMd, other.titleMd, t)!,
      bodyMd: TextStyle.lerp(bodyMd, other.bodyMd, t)!,
      bodySm: TextStyle.lerp(bodySm, other.bodySm, t)!,
      labelSm: TextStyle.lerp(labelSm, other.labelSm, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
    );
  }
}

abstract final class AppTypography {
  static const family = 'Poppins';

  /// Maps the CamRun scale onto Material 3 slots so stock widgets inherit it.
  static TextTheme textTheme(AppTextStyles s, Color secondary) => TextTheme(
    displayLarge: s.displayLg,
    displayMedium: s.displayMd,
    displaySmall: s.headingLg,
    headlineLarge: s.headingLg,
    headlineMedium: s.headingMd,
    headlineSmall: s.titleMd,
    titleLarge: s.headingMd,
    titleMedium: s.titleMd,
    titleSmall: s.bodyMd,
    bodyLarge: s.bodyMd,
    bodyMedium: s.bodyMd,
    bodySmall: s.bodySm.copyWith(color: secondary),
    labelLarge: s.button,
    labelMedium: s.labelSm,
    labelSmall: s.labelSm.copyWith(color: secondary),
  );
}
