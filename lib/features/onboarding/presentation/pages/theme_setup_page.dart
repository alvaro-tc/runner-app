import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/profile/presentation/widgets/theme_option_tile.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Primera pantalla de la primera arrancada: elegir tema antes de ver nada mas.
/// Solo aparece mientras `themeChosen` sea `false`; tocar una opcion ya lo
/// guarda, y el boton confirma la que este marcada por si nadie toco ninguna.
class ThemeSetupPage extends ConsumerWidget {
  const ThemeSetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final c = context.colors;
    final current = ref.watch(themeModeProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenH),
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Text(t.themeSetupTitle, style: context.text.headingMd),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    t.themeSetupSubtitle,
                    style: context.text.bodyMd.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  for (final option in themeOptions(t))
                    ThemeOptionTile(
                      label: option.label,
                      detail: option.detail,
                      mode: option.mode,
                      selected: current == option.mode,
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(option.mode),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.md,
                AppSpacing.screenH,
                AppSpacing.xxl,
              ),
              child: AppButton(
                label: t.commonContinue,
                onPressed: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(current);
                  if (context.mounted) context.go(Routes.onboarding);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
