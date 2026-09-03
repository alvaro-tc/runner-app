import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  final settings = ref.read(settingsProvider);

  // Primera arrancada: nadie ha elegido tema todavia. Se pregunta antes que
  // nada para que los slides ya se pinten con el tema que el usuario quiere.
  if (!settings.themeChosen) {
    return location == Routes.themeSetup ? null : Routes.themeSetup;
  }

  final onboardingSeen = settings.onboardingSeen;
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

  // El panel y la app de corredor son dos aplicaciones que comparten binario.
  // La separacion se hace aqui y no escondiendo botones: un admin que escriba
  // /train no tiene por que ver un plan de entrenamiento que no existe, y un
  // corredor que llegue a /admin por un enlace no puede quedarse ahi.
  // Las subpantallas de perfil —ajustes, idioma, apariencia— son de los dos:
  // viven fuera de los shells y no pertenecen a ninguno de los dos lados.
  if (location.startsWith('${Routes.profile}/')) return null;

  // Tres destinos y no dos: el organizador tiene su propio arbol, con el mapa
  // sin los botones de largada y con la cola de cobros. Cada rol se queda en
  // el suyo — un organizador que escriba /admin no puede cortar una carrera.
  final enAdmin = location.startsWith(Routes.admin);
  final enOrganizador = location.startsWith(Routes.organizer);
  if (auth.isAdmin) return enAdmin ? null : Routes.admin;
  if (auth.isOrganizer) return enOrganizador ? null : Routes.organizer;
  return enAdmin || enOrganizador ? Routes.home : null;
}
