import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Chooses system indicator colors from the opaque backgrounds behind them.
SystemUiOverlayStyle systemUiStyleFor(
  Color statusBackground, {
  Color? navigationBackground,
}) {
  final statusBrightness = ThemeData.estimateBrightnessForColor(
    statusBackground,
  );
  final navigationBrightness = ThemeData.estimateBrightnessForColor(
    navigationBackground ?? statusBackground,
  );
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    // iOS expects the background brightness; Android expects icon brightness.
    statusBarBrightness: statusBrightness,
    statusBarIconBrightness: statusBrightness == Brightness.light
        ? Brightness.dark
        : Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: navigationBrightness == Brightness.light
        ? Brightness.dark
        : Brightness.light,
  );
}
