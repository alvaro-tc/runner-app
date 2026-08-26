import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/services/settings_provider.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/l10n/l10n_labels.dart';
import 'package:paceup/shared/widgets/atoms/app_icon_button.dart';

/// Selector de idioma (PU-203).
///
/// El cambio es en caliente: `setLanguage` mueve el estado antes de tocar
/// disco, `MaterialApp` recibe el locale nuevo y todo el arbol —esta pantalla
/// incluida— se repinta traducido. No hay que reiniciar la app.
class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final current = ref.watch(languageProvider);

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
        title: Text(t.languageTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        children: [
          for (final language in AppLanguage.values)
            _LanguageOption(
              label: language.label(t),
              detail: language.detail(t),
              selected: current == language,
              onTap: () =>
                  ref.read(settingsProvider.notifier).setLanguage(language),
            ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String detail;
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
