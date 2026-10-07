import 'package:camrun/app/dependencies.dart';
import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/services/apple_sign_in_service.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Continuar con Apple", con el boton **del sistema**.
///
/// La guia de Apple prefiere el `ASAuthorizationAppleIDButton` a uno dibujado:
/// trae la apariencia aprobada, el titulo traducido al idioma del dispositivo y
/// la etiqueta de VoiceOver. Aqui se monta tal cual con una vista nativa y solo
/// se decide lo que la guia deja decidir:
///
/// - **Titulo** "Continuar con Apple": entrar y darse de alta son la misma
///   llamada, igual que con Google, y se usa el mismo en las dos pantallas.
/// - **Estilo** negro sobre fondo claro y blanco sobre oscuro.
/// - **Tamano y esquinas** iguales a los del boton de Google: la guia pide que
///   no sea mas pequeno que ningun otro boton de acceso.
///
/// Solo existe en iOS (iPhone y iPad). En el resto no ocupa sitio, y por eso
/// el hueco que lo separa del boton de abajo lo trae el mismo.
class AppleAuthButton extends ConsumerStatefulWidget {
  const AppleAuthButton({super.key});

  @override
  ConsumerState<AppleAuthButton> createState() => _AppleAuthButtonState();
}

class _AppleAuthButtonState extends ConsumerState<AppleAuthButton> {
  bool _loading = false;
  MethodChannel? _canal;

  @override
  void dispose() {
    _canal?.setMethodCallHandler(null);
    super.dispose();
  }

  void _alCrear(int id) {
    _canal = MethodChannel('${AppleSignInService.buttonViewType}/$id')
      ..setMethodCallHandler((llamada) async {
        if (llamada.method == 'pressed') await _signIn();
      });
  }

  /// La hoja de Apple, el servidor y, si todo va bien, la bienvenida por el
  /// nombre que compartio: la guia pide recibir al usuario en su cuenta en
  /// cuanto termina, y usar lo que compartio para que vea en que se usa. De
  /// entrar a Home se encarga el guard del router.
  Future<void> _signIn() async {
    if (_loading) return;
    setState(() => _loading = true);
    final (:user, :failure) = await ref
        .read(authProvider.notifier)
        .signInWithApple();
    if (!mounted) return;
    setState(() => _loading = false);

    final t = context.l10n;
    if (failure != null) {
      // Solo el backend manda mensajes que se le puedan ensenar a alguien; lo
      // que venga del sistema es texto para un log.
      context.showSnack(
        failure is ApiFailure ? failure.message : t.authAppleError,
      );
    } else if (user != null) {
      context.showSnack(t.authAppleWelcome(user.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(appleSignInServiceProvider).isSupported) {
      return const SizedBox.shrink();
    }

    final c = context.colors;
    // Negro sobre fondo claro, blanco sobre oscuro: los dos que la guia
    // permite segun el fondo. El contorno es solo para fondos blancos puros.
    final estilo = c.isDark ? 'white' : 'black';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SizedBox(
        height: AppSizes.controlHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            UiKitView(
              // Cambiar de tema cambia de estilo, y el boton nativo no lo admite
              // en caliente: se crea otro.
              key: ValueKey(estilo),
              viewType: AppleSignInService.buttonViewType,
              creationParams: {
                'type': 'continue',
                'style': estilo,
                'cornerRadius': AppRadius.lg,
              },
              creationParamsCodec: const StandardMessageCodec(),
              onPlatformViewCreated: _alCrear,
            ),
            // Mientras el servidor responde, el mismo boton pasa a indicador,
            // como el de Google: evita una segunda pulsacion y dice que se esta
            // en ello. Negro y blanco puros a proposito: son los colores del
            // boton de Apple, no los de la paleta de la app.
            if (_loading)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: c.isDark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Center(
                  child: SizedBox.square(
                    dimension: AppSpacing.lg,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
