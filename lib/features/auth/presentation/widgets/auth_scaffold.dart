import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/layout/breakpoints.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/shared/widgets/atoms/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared chrome for sign-in, sign-up and password recovery: back arrow,
/// screen gutter, and a scroll view so the keyboard never causes an overflow.
///
/// En una tablet apaisada el formulario solo seria una columna perdida en el
/// medio: se parte en dos, con la marca a la izquierda y el formulario a la
/// derecha, cada uno en su mitad.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final form = SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.sm,
              AppSpacing.screenH,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppIconButton(
                    icon: Icons.arrow_back_rounded,
                    style: AppIconButtonStyle.plain,
                    semanticsLabel: context.l10n.commonBack,
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(Routes.welcome),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: context.windowClass.isAtLeast(WindowClass.expanded)
          ? Row(
              children: [
                const Expanded(child: AuthBrandPanel()),
                Expanded(child: form),
              ],
            )
          : form,
    );
  }
}

/// La mitad de marca de las pantallas de acceso en tablet: el icono, el
/// nombre y en que consiste la app, sobre el degradado de la marca.
class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key});

  static const _logoSize = 96.0;

  /// Una linea de texto comoda de leer, aunque la mitad de la tablet sea mas
  /// ancha.
  static const _textMaxWidth = 420.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: c.brandGradient),
      child: SafeArea(
        right: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _textMaxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    child: Image.asset(
                      'assets/icons/icono-tienda-1024.png',
                      width: _logoSize,
                      height: _logoSize,
                      cacheWidth:
                          (_logoSize * MediaQuery.devicePixelRatioOf(context))
                              .ceil(),
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    context.l10n.appTitle,
                    style: context.text.displayMd.copyWith(color: c.onPrimary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.l10n.authWelcomeBody,
                    style: context.text.bodyMd.copyWith(
                      color: c.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two hairlines with the word `or` between them.
class AuthDivider extends StatelessWidget {
  const AuthDivider({this.label, super.key});

  /// Por defecto, el `o` traducido del idioma activo.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: c.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Text(
            label ?? context.l10n.commonOr,
            style: context.text.bodyMd.copyWith(color: c.textSecondary),
          ),
        ),
        Expanded(child: Container(height: 1, color: c.border)),
      ],
    );
  }
}
