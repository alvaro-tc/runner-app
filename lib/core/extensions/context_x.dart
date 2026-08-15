import 'package:flutter/material.dart';
import 'package:paceup/core/theme/app_typography.dart';
import 'package:paceup/core/theme/theme_extensions.dart';

extension ContextX on BuildContext {
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
