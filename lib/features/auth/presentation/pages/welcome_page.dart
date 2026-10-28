import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/features/auth/presentation/widgets/cam_story.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// La puerta de la app: la historia del CAM y, debajo, crear cuenta o entrar.
///
/// Con [firstRun] es la primera arrancada (`/onboarding`): al elegir se marca
/// como vista y se sale con `go`, porque hasta entonces el guard no deja pasar
/// a ninguna pantalla de acceso.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({this.firstRun = false, super.key});

  final bool firstRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open(String route) {
      if (!firstRun) {
        context.push(route);
        return;
      }
      ref.read(settingsProvider.notifier).markOnboardingSeen();
      context.go(route);
    }

    return Scaffold(
      body: CamStory(
        onCreateAccount: () => open(Routes.signUp),
        onSignIn: () => open(Routes.signIn),
      ),
    );
  }
}
