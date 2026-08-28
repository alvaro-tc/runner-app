import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/constants/legal_urls.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/profile/domain/entities/user_profile.dart';
import 'package:camrun/features/profile/presentation/providers/profile_provider.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_icon_button.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/molecules/tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileSettingsPage extends ConsumerWidget {
  const ProfileSettingsPage({super.key});

  /// Guarda el cambio y avisa si el servidor lo rechaza: el interruptor ya ha
  /// vuelto solo a su sitio, pero sin mensaje pareceria que no se pulso.
  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    ProfilePreferences next,
  ) async {
    final t = context.l10n;
    final error = await ref
        .read(profilePreferencesProvider.notifier)
        .save(next);
    if (error != null && context.mounted) context.showSnack(error.localized(t));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.l10n;
    final unit = ref.watch(distanceUnitProvider);
    // Mientras cargan (o si fallan) los interruptores salen apagados y sin
    // tocar: mejor que enseñar un estado inventado y guardarlo.
    final prefs = ref.watch(profilePreferencesProvider).value;

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
        title: Text(t.commonSettings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        children: [
          Text(t.settingsNotifications, style: context.text.headingMd),
          _Group(
            children: [
              _SwitchRow(
                icon: Icons.event_available_rounded,
                title: t.settingsPlanReminders,
                subtitle: t.settingsPlanRemindersSubtitle,
                value: prefs?.planReminders ?? false,
                onChanged: prefs == null
                    ? null
                    : (v) =>
                          _save(context, ref, prefs.copyWith(planReminders: v)),
              ),
              const AppDivider(),
              _SwitchRow(
                icon: Icons.emoji_events_outlined,
                title: t.settingsRaceUpdates,
                subtitle: t.settingsRaceUpdatesSubtitle,
                value: prefs?.raceUpdates ?? false,
                onChanged: prefs == null
                    ? null
                    : (v) =>
                          _save(context, ref, prefs.copyWith(raceUpdates: v)),
              ),
              const AppDivider(),
              _SwitchRow(
                icon: Icons.insights_rounded,
                title: t.settingsWeeklyReport,
                subtitle: t.settingsWeeklyReportSubtitle,
                value: prefs?.weeklyReport ?? false,
                onChanged: prefs == null
                    ? null
                    : (v) =>
                          _save(context, ref, prefs.copyWith(weeklyReport: v)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(t.settingsPrivacy, style: context.text.headingMd),
          _Group(
            children: [
              _SwitchRow(
                icon: Icons.public_rounded,
                title: t.settingsShareActivity,
                subtitle: t.settingsShareActivitySubtitle,
                value: prefs?.shareActivity ?? false,
                onChanged: prefs == null
                    ? null
                    : (v) =>
                          _save(context, ref, prefs.copyWith(shareActivity: v)),
              ),
              const AppDivider(),
              StatRow(
                icon: Icons.download_rounded,
                title: t.settingsExportData,
                onTap: () => context.showSnack(t.settingsExportComingSoon),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(t.settingsPreferences, style: context.text.headingMd),
          _Group(
            children: [
              StatRow(
                icon: Icons.straighten_rounded,
                title: t.settingsDistanceUnit,
                value: unit == DistanceUnit.km
                    ? t.settingsKilometres
                    : t.settingsMiles,
                onTap: () => ref
                    .read(settingsProvider.notifier)
                    .setUnit(
                      unit == DistanceUnit.km
                          ? DistanceUnit.mi
                          : DistanceUnit.km,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(t.settingsAccount, style: context.text.headingMd),
          _Group(
            children: [
              StatRow(
                icon: Icons.delete_forever_outlined,
                title: t.deleteAccountTitle,
                subtitle: t.deleteAccountRowSubtitle,
                tone: c.error,
                onTap: () => context.push(Routes.profileDeleteAccount),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(t.settingsHelp, style: context.text.headingMd),
          _Group(
            children: [
              StatRow(
                icon: Icons.privacy_tip_outlined,
                title: t.settingsPrivacyPolicy,
                subtitle: t.settingsPrivacyPolicySubtitle,
                onTap: () => context.openExternal(LegalUrls.privacyPolicy),
              ),
              const AppDivider(),
              StatRow(
                icon: Icons.help_outline_rounded,
                title: t.settingsHelpCentre,
                onTap: () => context.showSnack(t.settingsHelpComingSoon),
              ),
              const AppDivider(),
              StatRow(
                icon: Icons.mail_outline_rounded,
                title: t.settingsContactSupport,
                value: 'alvarocallet@gmail.com',
                onTap: () => context.showSnack(t.settingsContactComingSoon),
              ),
              const AppDivider(),
              StatRow(
                icon: Icons.info_outline_rounded,
                title: t.settingsVersion,
                value: '1.0.0',
                tone: c.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => StatRow(
    icon: icon,
    title: title,
    subtitle: subtitle,
    trailing: Switch(value: value, onChanged: onChanged),
  );
}
