import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/features/auth/presentation/providers/auth_provider.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Boton unico de "Continuar con Google" para login y registro: el alta y el
/// acceso son la misma llamada, asi que las dos pantallas comparten widget.
class GoogleAuthButton extends ConsumerStatefulWidget {
  const GoogleAuthButton({super.key});

  @override
  ConsumerState<GoogleAuthButton> createState() => _GoogleAuthButtonState();
}

class _GoogleAuthButtonState extends ConsumerState<GoogleAuthButton> {
  bool _loading = false;

  /// El error de Google va en un snack y no en un campo: el boton no tiene
  /// donde pintarlo. Cancelar el dialogo no devuelve fallo, y de entrar a Home
  /// se encarga el guard del router en cuanto la sesion existe.
  Future<void> _signIn() async {
    if (_loading) return;
    setState(() => _loading = true);
    final failure = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);

    // Solo el backend manda mensajes que se le puedan ensenar a alguien; lo que
    // venga del SDK de Google es texto para un log.
    if (failure != null) {
      context.showSnack(
        failure is ApiFailure ? failure.message : context.l10n.authGoogleError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SocialAuthButton(
      provider: 'Google',
      isLoading: _loading,
      onPressed: _signIn,
      icon: SvgPicture.asset('assets/icons/google.svg'),
    );
  }
}
