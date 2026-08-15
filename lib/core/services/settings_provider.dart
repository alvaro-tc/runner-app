import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paceup/core/services/preferences_provider.dart';

enum DistanceUnit {
  km('km'),
  mi('mi');

  const DistanceUnit(this.label);
  final String label;

  bool get isMiles => this == DistanceUnit.mi;
}

@immutable
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.unit,
    required this.onboardingSeen,
  });

  final ThemeMode themeMode;
  final DistanceUnit unit;
  final bool onboardingSeen;

  AppSettings copyWith({
    ThemeMode? themeMode,
    DistanceUnit? unit,
    bool? onboardingSeen,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    unit: unit ?? this.unit,
    onboardingSeen: onboardingSeen ?? this.onboardingSeen,
  );
}

/// Device-level preferences, read synchronously at startup and written back on
/// every change so a restart restores exactly what the user picked.
class SettingsNotifier extends Notifier<AppSettings> {
  static const _kTheme = 'settings.themeMode';
  static const _kUnit = 'settings.distanceUnit';
  static const _kOnboarding = 'settings.onboardingSeen';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == prefs.getString(_kTheme),
        orElse: () => ThemeMode.system,
      ),
      unit: DistanceUnit.values.firstWhere(
        (u) => u.name == prefs.getString(_kUnit),
        orElse: () => DistanceUnit.km,
      ),
      onboardingSeen: prefs.getBool(_kOnboarding) ?? false,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref.read(sharedPreferencesProvider).setString(_kTheme, mode.name);
  }

  Future<void> setUnit(DistanceUnit unit) async {
    state = state.copyWith(unit: unit);
    await ref.read(sharedPreferencesProvider).setString(_kUnit, unit.name);
  }

  Future<void> markOnboardingSeen() async {
    state = state.copyWith(onboardingSeen: true);
    await ref.read(sharedPreferencesProvider).setBool(_kOnboarding, true);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(settingsProvider.select((s) => s.themeMode)),
);

final distanceUnitProvider = Provider<DistanceUnit>(
  (ref) => ref.watch(settingsProvider.select((s) => s.unit)),
);

/// Convenience flag for formatters, which take `miles: bool`.
final useMilesProvider = Provider<bool>(
  (ref) => ref.watch(distanceUnitProvider).isMiles,
);
