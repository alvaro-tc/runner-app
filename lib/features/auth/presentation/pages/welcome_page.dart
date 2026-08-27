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
                            // Cede altura a la ficha del CAM en pantallas
                            // bajas, sin desaparecer en las altas.
                            size: (constraints.maxHeight * 0.24).clamp(
                              96.0,
                              200.0,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            context.l10n.authWelcomeTitle,
                            textAlign: TextAlign.center,
                            style: context.text.displayMd.copyWith(
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Quien abre la app por primera vez no sabe que hay
                          // detras: el CAM se presenta antes de pedir cuenta.
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.base),
                            decoration: BoxDecoration(
                              color: c.primaryContainer,
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.favorite_rounded,
                                      size: 16,
                                      color: c.primary,
                                    ),
                                    const SizedBox(width: AppSpacing.xs + 2),
                                    Flexible(
                                      child: Text(
                                        context.l10n.authWelcomeCamTitle,
                                        textAlign: TextAlign.center,
                                        style: context.text.labelSm.copyWith(
                                          color: c.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  context.l10n.authWelcomeCamBody,
                                  textAlign: TextAlign.center,
                                  style: context.text.bodySm.copyWith(
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
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
