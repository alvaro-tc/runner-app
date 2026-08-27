import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/shared/widgets/atoms/app_icon_button.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/molecules/tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() =>
      _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  bool _planReminders = true;
  bool _raceUpdates = true;
  bool _weeklyReport = false;
  bool _shareActivity = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final unit = ref.watch(distanceUnitProvider);

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
                value: _planReminders,
                onChanged: (v) => setState(() => _planReminders = v),
              ),
              const AppDivider(),
              _SwitchRow(
                icon: Icons.emoji_events_outlined,
                title: t.settingsRaceUpdates,
                subtitle: t.settingsRaceUpdatesSubtitle,
                value: _raceUpdates,
                onChanged: (v) => setState(() => _raceUpdates = v),
              ),
              const AppDivider(),
              _SwitchRow(
                icon: Icons.insights_rounded,
                title: t.settingsWeeklyReport,
                subtitle: t.settingsWeeklyReportSubtitle,
                value: _weeklyReport,
                onChanged: (v) => setState(() => _weeklyReport = v),
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
                value: _shareActivity,
                onChanged: (v) => setState(() => _shareActivity = v),
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
          Text(t.settingsHelp, style: context.text.headingMd),
          _Group(
            children: [
              StatRow(
                icon: Icons.help_outline_rounded,
                title: t.settingsHelpCentre,
                onTap: () => context.showSnack(t.settingsHelpComingSoon),
              ),
              const AppDivider(),
              StatRow(
                icon: Icons.mail_outline_rounded,
                title: t.settingsContactSupport,
                value: 'support@camrun.app',
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
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => StatRow(
    icon: icon,
    title: title,
    subtitle: subtitle,
    trailing: Switch(value: value, onChanged: onChanged),
  );
}
