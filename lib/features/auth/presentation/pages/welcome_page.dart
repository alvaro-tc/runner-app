import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/blob_illustration.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              // Fills tall screens, scrolls on short ones — never overflows.
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.contentMaxWidth,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenH,
                        vertical: AppSpacing.xl,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BlobIllustration(
                            icon: Icons.directions_run_rounded,
                            seed: 5,
                            size: constraints.maxHeight * 0.34,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          Text(
                            context.l10n.authWelcomeTitle,
                            textAlign: TextAlign.center,
                            style: context.text.displayMd.copyWith(
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.base),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Text(
                              context.l10n.authWelcomeBody,
                              textAlign: TextAlign.center,
                              style: context.text.bodyMd.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxxl),
                          AppButton(
                            label: context.l10n.authLogin,
                            onPressed: () => context.push(Routes.signIn),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            label: context.l10n.authRegister,
                            variant: AppButtonVariant.secondary,
                            onPressed: () => context.push(Routes.signUp),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
