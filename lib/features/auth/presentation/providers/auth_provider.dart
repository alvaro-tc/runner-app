import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paceup/app/dependencies.dart';
import 'package:paceup/core/error/failure.dart';

/// Whether a session exists. The router redirect watches this.
class AuthNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(authRepositoryProvider).isAuthenticated;

  Future<Failure?> signIn(String email, String password) async {
    final result = await ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password);
    return result.fold((_) {
      state = true;
      return null;
    }, (f) => f);
  }

  Future<Failure?> signUp(String name, String email, String password) async {
    final result = await ref
        .read(authRepositoryProvider)
        .signUp(fullName: name, email: email, password: password);
    return result.fold((_) {
      state = true;
      return null;
    }, (f) => f);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = false;
  }
}

final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);
