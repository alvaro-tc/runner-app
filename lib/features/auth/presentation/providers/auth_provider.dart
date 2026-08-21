import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paceup/app/dependencies.dart';
import 'package:paceup/core/error/failure.dart';
import 'package:paceup/core/network/network_providers.dart';
import 'package:paceup/core/sync/sync_providers.dart';

/// Habia sesion al arrancar. Se resuelve en `bootstrap()` leyendo el refresh
/// token del almacen seguro —una lectura asincrona que no puede hacerse dentro
/// del `build` de un `Notifier` sincrono—; sin ese dato, quien ya estaba dentro
/// veria Welcome un instante antes del primer frame de Home.
final initialSessionProvider = Provider<bool>((ref) => false);

/// Whether a session exists. The router redirect watches this.
class AuthNotifier extends Notifier<bool> {
  @override
  bool build() {
    // El refresh puede morir en cualquier peticion, no solo al pulsar salir.
    final caducada = ref.watch(sessionControllerProvider).expired;
    void alCaducar() {
      if (caducada.value) unawaited(_cerrarLocal());
    }

    caducada.addListener(alCaducar);
    ref.onDispose(() => caducada.removeListener(alCaducar));
    return ref.watch(initialSessionProvider);
  }

  Future<Failure?> signIn(String email, String password) async {
    final result = await ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password);
    return _aplicar(result.fold((user) => user, (f) => f));
  }

  Future<Failure?> signUp(String name, String email, String password) async {
    final result = await ref
        .read(authRepositoryProvider)
        .signUp(fullName: name, email: email, password: password);
    return _aplicar(result.fold((user) => user, (f) => f));
  }

  Failure? _aplicar(Object resultado) {
    if (resultado is Failure) return resultado;
    state = true;
    return null;
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = false;
  }

  /// La sesion murio sola (refresh rechazado). Los tokens ya los borro
  /// [SessionController]; falta la cache, que es de ese usuario y de nadie mas.
  Future<void> _cerrarLocal() async {
    state = false;
    await ref.read(appDatabaseProvider).wipe();
  }
}

final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);
