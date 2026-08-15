import 'package:flutter/animation.dart';

/// 4pt spacing scale.
abstract final class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const base = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;

  /// Horizontal gutter used by every full-screen page.
  static const screenH = 20.0;
}

abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const sheet = 32.0;
  static const pill = 999.0;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
  static const curve = Curves.easeOutCubic;
}

abstract final class AppSizes {
  static const controlHeight = 56.0;
  static const minTapTarget = 48.0;
  static const dayRing = 56.0;
  static const avatarProfile = 110.0;
  static const contentMaxWidth = 560.0;
}
