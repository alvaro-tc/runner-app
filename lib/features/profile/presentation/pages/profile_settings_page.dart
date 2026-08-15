import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/services/settings_provider.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/shared/widgets/atoms/app_icon_button.dart';
import 'package:paceup/shared/widgets/atoms/app_indicators.dart';
import 'package:paceup/shared/widgets/molecules/tiles.dart';

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
    final unit = ref.watch(distanceUnitProvider);

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
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        children: [
          Text('Notifications', style: context.text.headingMd),
          _Group(
            children: [
              _SwitchRow(
                icon: Icons.event_available_rounded,
                title: 'Plan reminders',
                subtitle: 'A nudge the morning of each session',
                value: _planReminders,
                onChanged: (v) => setState(() => _planReminders = v),
              ),
              const AppDivider(),
              _SwitchRow(
                icon: Icons.emoji_events_outlined,
                title: 'Race updates',
                subtitle: 'Kit collection, start times and results',
                value: _raceUpdates,
                onChanged: (v) => setState(() => _raceUpdates = v),
              ),
              const AppDivider(),
              _SwitchRow(
                icon: Icons.insights_rounded,
                title: 'Weekly report',
                subtitle: 'Your mileage summary every Monday',
                value: _weeklyReport,
                onChanged: (v) => setState(() => _weeklyReport = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Privacy', style: context.text.headingMd),
          _Group(
            children: [
              _SwitchRow(
                icon: Icons.public_rounded,
                title: 'Share activity',
                subtitle: 'Let other runners see your finished runs',
                value: _shareActivity,
                onChanged: (v) => setState(() => _shareActivity = v),
              ),
              const AppDivider(),
              StatRow(
                icon: Icons.download_rounded,
                title: 'Export my data',
                onTap: () => context.showSnack(
                  'Data export runs from the account service, coming soon.',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Preferences', style: context.text.headingMd),
          _Group(
            children: [
              StatRow(
                icon: Icons.straighten_rounded,
                title: 'Distance unit',
                value: unit == DistanceUnit.km ? 'Kilometres' : 'Miles',
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
          Text('Help', style: context.text.headingMd),
          _Group(
            children: [
              StatRow(
                icon: Icons.help_outline_rounded,
                title: 'Help centre',
                onTap: () => context.showSnack(
                  'The help centre opens in your browser once support is live.',
                ),
              ),
              const AppDivider(),
              StatRow(
                icon: Icons.mail_outline_rounded,
                title: 'Contact support',
                value: 'support@paceup.app',
                onTap: () => context.showSnack(
                  'Write to support@paceup.app and we will answer within a day.',
                ),
              ),
              const AppDivider(),
              StatRow(
                icon: Icons.info_outline_rounded,
                title: 'Version',
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
