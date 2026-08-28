import 'package:camrun/core/theme/app_typography.dart';
import 'package:camrun/core/theme/theme_extensions.dart';
import 'package:camrun/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

extension ContextX on BuildContext {
  /// Textos traducidos. `AppLocalizations.of` no devuelve null porque el
  /// delegate esta siempre montado desde `CamRunApp`.
  AppLocalizations get l10n => AppLocalizations.of(this);

  AppPalette get colors => Theme.of(this).extension<AppPalette>()!;
  AppTextStyles get text => Theme.of(this).extension<AppTextStyles>()!;

  MediaQueryData get mq => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Honours the OS "reduce motion" switch — every animated widget checks this
  /// before running a tween.
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;

  void showSnack(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
