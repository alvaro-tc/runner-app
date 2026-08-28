import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/core/theme/app_typography.dart';
import 'package:camrun/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(AppPalette.light(), Brightness.light);
  static ThemeData get dark => _build(AppPalette.dark(), Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final text = AppTextStyles.resolve(p.textPrimary);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.primary,
          brightness: brightness,
        ).copyWith(
          primary: p.primary,
          onPrimary: p.onPrimary,
          primaryContainer: p.primaryContainer,
          onPrimaryContainer: p.primary,
          secondary: p.accentBlue,
          surface: p.surface,
          onSurface: p.textPrimary,
          surfaceContainerHighest: p.surfaceElevated,
          error: p.error,
          onError: p.onPrimary,
          errorContainer: p.errorBg,
          onErrorContainer: p.error,
          outline: p.border,
          outlineVariant: p.border,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.surface,
      dividerColor: p.border,
      fontFamily: AppTypography.family,
      textTheme: AppTypography.textTheme(text, p.textSecondary),
      extensions: [p, text],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleMd,
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size.fromHeight(AppSizes.controlHeight),
          textStyle: text.button,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          minimumSize: const Size.fromHeight(AppSizes.controlHeight),
          textStyle: text.button,
          side: BorderSide(color: p.primary, width: 1.5),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: text.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: text.bodyMd.copyWith(color: p.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.base,
        ),
        border: _inputBorder(p.border),
        enabledBorder: _inputBorder(p.border),
        focusedBorder: _inputBorder(p.primary),
        errorBorder: _inputBorder(p.error),
        focusedErrorBorder: _inputBorder(p.error),
        errorStyle: text.bodySm.copyWith(color: p.error),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.primary,
        unselectedItemColor: p.textSecondary,
        selectedLabelStyle: text.labelSm,
        unselectedLabelStyle: text.labelSm,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        titleTextStyle: text.headingMd,
        contentTextStyle: text.bodyMd.copyWith(color: p.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.inkPill,
        contentTextStyle: text.bodyMd.copyWith(color: p.onInkPill),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.ringTrack,
        circularTrackColor: p.ringTrack,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.primaryContainer,
        labelStyle: text.labelSm.copyWith(color: p.primary),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.lg),
    borderSide: BorderSide(color: color, width: 1.5),
  );
}
