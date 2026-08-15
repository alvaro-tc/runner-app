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

/// Onboarding first, then a session, then the app. Debug-only routes are let
/// through untouched so the component showcase stays reachable.
String? appGuard(Ref ref, GoRouterState state) {
  final location = state.matchedLocation;
  if (location.startsWith('/dev')) return null;

  final onboardingSeen = ref.read(settingsProvider).onboardingSeen;
  final signedIn = ref.read(authProvider);

  if (!onboardingSeen) {
    return location == Routes.onboarding ? null : Routes.onboarding;
  }
  if (location == Routes.onboarding) {
    return signedIn ? Routes.home : Routes.welcome;
  }

  final isAuthRoute = _authRoutes.contains(location);
  if (!signedIn) return isAuthRoute ? null : Routes.welcome;
  if (isAuthRoute) return Routes.home;
  return null;
}
