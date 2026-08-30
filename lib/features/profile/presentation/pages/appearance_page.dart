import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/profile/presentation/widgets/theme_option_tile.dart';
import 'package:camrun/shared/widgets/atoms/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final current = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: AppIconButton(
            icon: Icons.arrow_back_rounded,
            semanticsLabel: t.commonBack,
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(t.profileAppearance),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        children: [
          for (final option in themeOptions(t))
            ThemeOptionTile(
              label: option.label,
              detail: option.detail,
              mode: option.mode,
              selected: current == option.mode,
              onTap: () =>
                  ref.read(settingsProvider.notifier).setThemeMode(option.mode),
            ),
        ],
      ),
    );
  }
}
