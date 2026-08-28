import 'dart:async';

import 'package:camrun/app/dependencies.dart';
import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/network/network_providers.dart';
import 'package:camrun/core/sync/sync_providers.dart';
import 'package:camrun/features/auth/data/models/auth_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Habia sesion al arrancar. Se resuelve en `bootstrap()` leyendo el refresh
/// token del almacen seguro —una lectura asincrona que no puede hacerse dentro
/// del `build` de un `Notifier` sincrono—; sin ese dato, quien ya estaba dentro
/// veria Welcome un instante antes del primer frame de Home.
final initialSessionProvider = Provider<bool>((ref) => false);

/// Lo que el router necesita saber de la sesion.
///
/// Son **dos** cosas y no una: hay sesion, y esa sesion todavia arrastra una
/// contrasena que el usuario no eligio (alta desde la web: usuario CI,
/// contrasena CI). La segunda es una puerta, no un aviso — con ella abierta lo
/// unico que se puede hacer en la app es cerrarla.
@immutable
class AuthState {
  const AuthState({
    this.signedIn = false,
    this.mustChangePassword = false,
    this.role = '',
  });

  final bool signedIn;
  final bool mustChangePassword;

  /// `admin`, `organizer` o `runner`. Vacio mientras no se sepa: con sesion
  /// recuperada del arranque el rol tarda una peticion en llegar, y asumir
  /// `admin` un instante abriria el panel a cualquiera que reinstale.
  final String role;

  /// Puede moverse por la app con normalidad.
  bool get ready => signedIn && !mustChangePassword;

  /// Le toca el panel y no la app de corredor.
  bool get isAdmin => role == 'admin';
}

/// Whether a session exists. The router redirect watches this.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // El refresh puede morir en cualquier peticion, no solo al pulsar salir.
    final caducada = ref.watch(sessionControllerProvider).expired;
    void alCaducar() {
      if (caducada.value) unawaited(_cerrarLocal());
    }

    caducada.addListener(alCaducar);
    ref.onDispose(() => caducada.removeListener(alCaducar));

    final habiaSesion = ref.watch(initialSessionProvider);

    // `mustChangePassword` no vive en el dispositivo: pudo cambiar desde el
    // ultimo login —un admin reseteando la clave, un alta hecha en la web
    // despues— asi que se relee. Hasta que responda se asume que no bloquea:
    // arrancar bloqueado y desbloquear despues haria parpadear la pantalla de
    // cambio a todo el mundo en cada arranque.
    if (habiaSesion) unawaited(_refrescarUsuario());

    return AuthState(signedIn: habiaSesion);
  }

  Future<Failure?> signIn(String identifier, String password) async {
    final result = await ref
        .read(authRepositoryProvider)
        .signIn(identifier: identifier, password: password);
    return _aplicar(result.fold((user) => user, (f) => f));
  }

  Future<Failure?> signUp({
    required String name,
    required String password,
    String? email,
    String? ci,
  }) async {
    final result = await ref
        .read(authRepositoryProvider)
        .signUp(fullName: name, password: password, email: email, ci: ci);
    return _aplicar(result.fold((user) => user, (f) => f));
  }

  /// Cambia la contrasena y, si sale bien, levanta la puerta.
  Future<Failure?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await ref
        .read(authRepositoryProvider)
        .changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
    return _aplicar(result.fold((user) => user, (f) => f));
  }

  Failure? _aplicar(Object resultado) {
    if (resultado is Failure) return resultado;

    final user = resultado as AuthUser;
    state = AuthState(
      signedIn: true,
      mustChangePassword: user.mustChangePassword,
      role: user.role,
    );
    return null;
  }

  Future<void> _refrescarUsuario() async {
    final result = await ref.read(authRepositoryProvider).currentUser();
    // Un fallo de red al arrancar no puede echar a nadie ni encerrarlo en la
    // pantalla de cambio: se deja el estado como estaba y se reintentara en el
    // siguiente login.
    result.fold(
      (AuthUser user) => state = AuthState(
        signedIn: true,
        mustChangePassword: user.mustChangePassword,
        role: user.role,
      ),
      (Failure _) {},
    );
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AuthState();
  }

  /// Borrado de cuenta. Si el servidor lo confirma el repositorio ya dejo el
  /// dispositivo limpio, asi que aqui solo queda caer la sesion y dejar que el
  /// guard mande a Welcome.
  Future<Failure?> deleteAccount(String password) async {
    final result = await ref
        .read(authRepositoryProvider)
        .deleteAccount(password);
    return result.fold((_) {
      state = const AuthState();
      return null;
    }, (Failure f) => f);
  }

  /// La sesion murio sola (refresh rechazado). Los tokens ya los borro
  /// [SessionController]; falta la cache, que es de ese usuario y de nadie mas.
  Future<void> _cerrarLocal() async {
    state = const AuthState();
    await ref.read(appDatabaseProvider).wipe();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
