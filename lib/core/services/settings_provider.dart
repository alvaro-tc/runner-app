import 'package:camrun/core/services/preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DistanceUnit {
  km('km'),
  mi('mi');

  const DistanceUnit(this.label);
  final String label;

  bool get isMiles => this == DistanceUnit.mi;
}

/// Idiomas que la app ofrece en Ajustes.
///
/// `system` no fija locale: deja que Flutter resuelva el del dispositivo contra
/// `supportedLocales`, y cae al espanol si el idioma del telefono no esta.
enum AppLanguage {
  system(null),
  spanish(Locale('es')),
  english(Locale('en'));

  const AppLanguage(this.locale);

  /// `null` cuando se sigue al sistema — es justo lo que espera `MaterialApp`.
  final Locale? locale;
}

/// Los tres ajustes que el servidor guarda en `/users/me/preferences`. Como
/// record tiene igualdad por valor, que es lo que usa la sincronizacion para
/// no devolver al servidor lo que acaba de llegar de el.
typedef Appearance = ({
  ThemeMode themeMode,
  AppLanguage language,
  DistanceUnit unit,
});

@immutable
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.language,
    required this.unit,
    required this.onboardingSeen,
  });

  final ThemeMode themeMode;
  final AppLanguage language;
  final DistanceUnit unit;
  final bool onboardingSeen;

  Appearance get appearance =>
      (themeMode: themeMode, language: language, unit: unit);

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
    DistanceUnit? unit,
    bool? onboardingSeen,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    language: language ?? this.language,
    unit: unit ?? this.unit,
    onboardingSeen: onboardingSeen ?? this.onboardingSeen,
  );
}

/// Device-level preferences, read synchronously at startup and written back on
/// every change so a restart restores exactly what the user picked.
class SettingsNotifier extends Notifier<AppSettings> {
  static const _kTheme = 'settings.themeMode';
  static const _kLanguage = 'settings.language';
  static const _kUnit = 'settings.distanceUnit';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == prefs.getString(_kTheme),
        orElse: () => ThemeMode.system,
      ),
      // El publico objetivo es hispanohablante: sin eleccion guardada la app
      // arranca en espanol, no en el idioma del telefono.
      language: AppLanguage.values.firstWhere(
        (l) => l.name == prefs.getString(_kLanguage),
        orElse: () => AppLanguage.spanish,
      ),
      unit: DistanceUnit.values.firstWhere(
        (u) => u.name == prefs.getString(_kUnit),
        orElse: () => DistanceUnit.km,
      ),
      // Los slides son parte del arranque, no un tramite que se firma una vez:
      // se ven en cada sesion nueva. Por eso el flag vive solo en memoria.
      onboardingSeen: false,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref.read(sharedPreferencesProvider).setString(_kTheme, mode.name);
  }

  /// El cambio es en caliente: `state` se actualiza antes del `await`, asi que
  /// `MaterialApp` se reconstruye con el locale nuevo sin esperar al disco.
  Future<void> setLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    await ref
        .read(sharedPreferencesProvider)
        .setString(_kLanguage, language.name);
  }

  Future<void> setUnit(DistanceUnit unit) async {
    state = state.copyWith(unit: unit);
    await ref.read(sharedPreferencesProvider).setString(_kUnit, unit.name);
  }

  /// Lo que llega del servidor. Se guarda tambien en disco: asi la proxima
  /// arrancada pinta el tema correcto antes de que haya red.
  Future<void> applyAppearance(Appearance next) async {
    state = state.copyWith(
      themeMode: next.themeMode,
      language: next.language,
      unit: next.unit,
    );
    final prefs = ref.read(sharedPreferencesProvider);
    await Future.wait([
      prefs.setString(_kTheme, next.themeMode.name),
      prefs.setString(_kLanguage, next.language.name),
      prefs.setString(_kUnit, next.unit.name),
    ]);
  }

  void markOnboardingSeen() => state = state.copyWith(onboardingSeen: true);
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(settingsProvider.select((s) => s.themeMode)),
);

final languageProvider = Provider<AppLanguage>(
  (ref) => ref.watch(settingsProvider.select((s) => s.language)),
);

/// `null` = seguir al sistema.
final localeProvider = Provider<Locale?>(
  (ref) => ref.watch(languageProvider).locale,
);

final distanceUnitProvider = Provider<DistanceUnit>(
  (ref) => ref.watch(settingsProvider.select((s) => s.unit)),
);

/// Convenience flag for formatters, which take `miles: bool`.
final useMilesProvider = Provider<bool>(
  (ref) => ref.watch(distanceUnitProvider).isMiles,
);
