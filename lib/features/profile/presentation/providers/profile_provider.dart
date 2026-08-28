import 'dart:async';

import 'package:camrun/app/dependencies.dart';
import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/core/utils/result.dart';
import 'package:camrun/features/auth/presentation/providers/auth_provider.dart';
import 'package:camrun/features/profile/domain/entities/user_profile.dart';
import 'package:camrun/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async =>
      (await ref.watch(profileRepositoryProvider).fetch()).unwrap();

  /// Optimistic save: the UI shows the new values immediately and rolls back
  /// if the repository rejects them.
  Future<Failure?> save(UserProfile updated) async {
    final previous = state;
    state = AsyncData(updated);
    final result = await ref.read(profileRepositoryProvider).save(updated);
    return result.fold((_) => null, (failure) {
      state = previous;
      return failure;
    });
  }

  /// Zapatillas y salud no son optimistas: los dos llegan con la lista o el
  /// bloque que devuelve el servidor, y ese es el que se pinta.
  Future<Failure?> addShoe({
    required String brand,
    required String model,
    required double retireAtKm,
  }) => _apply(
    (repo) =>
        repo.addShoe(brand: brand, model: model, retireAtKm: retireAtKm),
  );

  Future<Failure?> removeShoe(String id) => _apply((repo) => repo.removeShoe(id));

  Future<Failure?> saveHealth({
    required List<Injury> injuries,
    required Duration sleep,
    required HydrationHabit hydration,
  }) => _apply(
    (repo) => repo.saveHealth(
      injuries: injuries,
      sleep: sleep,
      hydration: hydration,
    ),
  );

  Future<Failure?> _apply(
    Future<Result<UserProfile>> Function(ProfileRepository) call,
  ) async {
    final result = await call(ref.read(profileRepositoryProvider));
    return result.fold((profile) {
      state = AsyncData(profile);
      return null;
    }, (failure) => failure);
  }

  /// La foto se sube primero y el estado se actualiza con lo que responde el
  /// servidor: aqui no hay nada optimista que enseñar, la URL la pone el.
  Future<Failure?> uploadAvatar(String filePath) async {
    final result = await ref
        .read(profileRepositoryProvider)
        .uploadAvatar(filePath);
    return result.fold((profile) {
      state = AsyncData(profile);
      return null;
    }, (failure) => failure);
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile>(
  ProfileNotifier.new,
);

class ProfilePreferencesNotifier extends AsyncNotifier<ProfilePreferences> {
  @override
  Future<ProfilePreferences> build() async =>
      (await ref.watch(profileRepositoryProvider).fetchPreferences()).unwrap();

  /// Igual que el perfil: el interruptor se mueve ya y vuelve a su sitio si el
  /// servidor lo rechaza.
  Future<Failure?> save(ProfilePreferences next) async {
    final previous = state;
    state = AsyncData(next);
    final result = await ref
        .read(profileRepositoryProvider)
        .savePreferences(next);
    return result.fold((_) => null, (failure) {
      state = previous;
      return failure;
    });
  }
}

final profilePreferencesProvider =
    AsyncNotifierProvider<ProfilePreferencesNotifier, ProfilePreferences>(
      ProfilePreferencesNotifier.new,
    );

/// Tema, unidades e idioma se guardan en el servidor, pero la copia local es
/// la que pinta el primer frame: leerla es sincrona y la del servidor tarda una
/// peticion, asi que el tema no parpadea. Cuando la respuesta llega, manda ella
/// —es la que sobrevive a un reinstall— y se reescribe la copia local.
///
/// Los dos `listen` se cruzan a proposito y `remoto` es lo que corta el bucle:
/// lo que acaba de llegar del servidor no se le devuelve.
final appearanceSyncProvider = Provider<void>((ref) {
  // Sin sesion no hay preferencias que pedir: pedirlas seria un 401 seguro.
  if (!ref.watch(authProvider).signedIn) return;

  Appearance? remoto;

  void delServidor(ProfilePreferences? prefs) {
    if (prefs == null || prefs.appearance == remoto) return;
    remoto = prefs.appearance;
    unawaited(ref.read(settingsProvider.notifier).applyAppearance(remoto!));
  }

  ref
    ..listen(profilePreferencesProvider, (_, next) => delServidor(next.value))
    ..listen(settingsProvider, (_, next) {
      if (next.appearance == remoto) return;
      remoto = next.appearance;
      final prefs = ref.read(profilePreferencesProvider).value;
      // Sin las preferencias cargadas no hay sobre el que aplicar el cambio;
      // la eleccion queda en disco y la de arriba manda cuando llegue.
      if (prefs == null) return;
      unawaited(
        ref
            .read(profilePreferencesProvider.notifier)
            .save(prefs.withAppearance(next.appearance)),
      );
    });

  // Riverpod prohibe tocar otro provider mientras se construye este, asi que
  // el valor que ya estuviera cargado se aplica en el siguiente turno.
  Future.microtask(
    () => delServidor(ref.read(profilePreferencesProvider).value),
  );
});

/// Traduce entre los strings del servidor y los enums de la app.
extension AppearancePrefs on ProfilePreferences {
  Appearance get appearance => (
    themeMode: ThemeMode.values.asNameMap()[theme] ?? ThemeMode.system,
    unit: units == 'imperial' ? DistanceUnit.mi : DistanceUnit.km,
    language: switch (locale) {
      'system' => AppLanguage.system,
      // El publico objetivo es hispanohablante: cualquier cosa que no sea
      // ingles cae al espanol, igual que el arranque sin nada guardado.
      final l when l.startsWith('en') => AppLanguage.english,
      _ => AppLanguage.spanish,
    },
  );

  ProfilePreferences withAppearance(Appearance a) => copyWith(
    theme: a.themeMode.name,
    units: a.unit.isMiles ? 'imperial' : 'metric',
    locale: switch (a.language) {
      AppLanguage.system => 'system',
      AppLanguage.spanish => 'es',
      AppLanguage.english => 'en',
    },
  );
}
