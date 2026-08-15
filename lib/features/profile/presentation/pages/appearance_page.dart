import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/services/settings_provider.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/core/theme/app_theme.dart';
import 'package:paceup/shared/widgets/atoms/app_icon_button.dart';

class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  static const _options = <({ThemeMode mode, String label, String detail})>[
    (
      mode: ThemeMode.light,
      label: 'Light',
      detail: 'Bright surfaces, best in daylight.',
    ),
    (
      mode: ThemeMode.dark,
      label: 'Dark',
      detail: 'Easier on the eyes for evening runs.',
    ),
    (
      mode: ThemeMode.system,
      label: 'System',
      detail: 'Follows whatever your phone is set to.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: AppIconButton(
            icon: Icons.arrow_back_rounded,
            semanticsLabel: 'Go back',
            onPressed: () => context.pop(),
          ),
        ),
        title: const Text('Appearance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        children: [
          for (final option in _options)
            _ThemeOption(
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

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.detail,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String detail;
  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: selected ? c.primaryContainer : c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: selected ? c.primary : c.border),
            ),
            child: Row(
              children: [
                _Preview(mode: mode),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: context.text.titleMd),
                      Text(
                        detail,
                        style: context.text.bodySm.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: selected ? c.primary : c.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Miniature of the theme it selects, rendered with the real palette.
class _Preview extends StatelessWidget {
  const _Preview({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final isDark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    final theme = isDark ? AppTheme.dark : AppTheme.light;

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final c = context.colors;
          return Container(
            width: 52,
            height: 62,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: c.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 6, width: 26, color: c.primary),
                const SizedBox(height: AppSpacing.xs),
                Container(height: 4, width: 34, color: c.border),
                const SizedBox(height: AppSpacing.xxs),
                Container(height: 4, width: 30, color: c.border),
                const Spacer(),
                Container(height: 12, width: double.infinity, color: c.surface),
              ],
            ),
          );
        },
      ),
    );
  }
}
