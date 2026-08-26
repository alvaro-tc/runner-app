import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paceup/app/router/app_routes.dart';
import 'package:paceup/core/services/settings_provider.dart';
import 'package:paceup/features/auth/presentation/providers/auth_provider.dart';

const _authRoutes = {
  Routes.welcome,
  Routes.signIn,
  Routes.signUp,
  Routes.forgotPassword,
};

/// Onboarding first, then a session, then the app. Los slides preceden a cada
/// login: quien ya tiene sesion viva entra directo. Debug-only routes are let
/// through untouched so the component showcase stays reachable.
String? appGuard(Ref ref, GoRouterState state) {
  final location = state.matchedLocation;
  if (location.startsWith('/dev')) return null;

  final onboardingSeen = ref.read(settingsProvider).onboardingSeen;
  final auth = ref.read(authProvider);
  final signedIn = auth.signedIn;

  if (!signedIn && !onboardingSeen) {
    return location == Routes.onboarding ? null : Routes.onboarding;
  }
  if (location == Routes.onboarding) {
    return signedIn ? Routes.home : Routes.welcome;
  }

  final isAuthRoute = _authRoutes.contains(location);
  if (!signedIn) return isAuthRoute ? null : Routes.welcome;

  // Entro con una contrasena que no eligio el —usuario CI, contrasena CI, alta
  // desde la web— y esa clave la sabe cualquiera que le haya visto el carnet.
  // Es una puerta y no un aviso: hasta que la cambie, la unica pantalla que
  // existe es esta.
  if (auth.mustChangePassword) {
    return location == Routes.changePassword ? null : Routes.changePassword;
  }
  if (location == Routes.changePassword) return Routes.home;

  if (isAuthRoute) return Routes.home;
  return null;
}
