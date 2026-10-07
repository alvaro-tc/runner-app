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

  /// The same gutter once the window is tablet-wide (see `AppLayout.gutter`).
  static const screenHWide = 32.0;
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

  /// Forms and auth: one column you read top to bottom.
  static const contentMaxWidth = 560.0;

  /// Settings lists and single-column detail screens.
  static const readableMaxWidth = 760.0;

  /// Dashboards and two-column details on tablets.
  static const wideMaxWidth = 1200.0;

  /// Fixed column beside a map: live session stats, race controls.
  static const sidePanelWidth = 380.0;

  /// Sheets that become centred dialogs on wide windows.
  static const dialogMaxWidth = 560.0;

  /// Navigation rail widths, collapsed (icon + label) and extended.
  static const navRail = 88.0;
  static const navRailExtended = 232.0;
}
