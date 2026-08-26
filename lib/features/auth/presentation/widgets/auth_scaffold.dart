import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paceup/app/router/app_routes.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/shared/widgets/atoms/app_icon_button.dart';

/// Shared chrome for sign-in, sign-up and password recovery: back arrow,
/// screen gutter, and a scroll view so the keyboard never causes an overflow.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.contentMaxWidth,
            ),
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
