import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/services/settings_provider.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/shared/widgets/atoms/app_button.dart';
import 'package:paceup/shared/widgets/atoms/app_icon_button.dart';
import 'package:paceup/shared/widgets/atoms/app_indicators.dart';
import 'package:paceup/shared/widgets/atoms/app_progress_ring.dart';
import 'package:paceup/shared/widgets/atoms/app_text_field.dart';
import 'package:paceup/shared/widgets/atoms/blob_illustration.dart';
import 'package:paceup/shared/widgets/atoms/skeleton.dart';
import 'package:paceup/shared/widgets/molecules/countdown_pill.dart';
import 'package:paceup/shared/widgets/molecules/progress_widgets.dart';
import 'package:paceup/shared/widgets/molecules/states.dart';
import 'package:paceup/shared/widgets/molecules/tiles.dart';

/// Debug-only catalogue of every atom and molecule, in both themes. This is the
/// screen used to check the design system without walking the whole app.
class ShowcasePage extends ConsumerStatefulWidget {
  const ShowcasePage({super.key});

  @override
  ConsumerState<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends ConsumerState<ShowcasePage> {
  bool _checked = true;
  bool _chipSelected = true;
  final _field = TextEditingController(text: 'pandu@paceup.app');

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Component showcase'),
        leading: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: AppIconButton(
            icon: Icons.arrow_back_rounded,
            semanticsLabel: 'Go back',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              mode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: 'Toggle theme',
            onPressed: () => ref
                .read(settingsProvider.notifier)
                .setThemeMode(
                  mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
                ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        children: [
          _Group(
            title: 'Buttons',
            children: [
              for (final variant in AppButtonVariant.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppButton(
                    label: variant.name,
                    variant: variant,
                    onPressed: () {},
                  ),
                ),
              const AppButton(label: 'Disabled', onPressed: null),
              const SizedBox(height: AppSpacing.sm),
              const AppButton(
                label: 'Loading',
                isLoading: true,
                onPressed: null,
              ),
            ],
          ),
          _Group(
            title: 'Inputs',
            children: [
              AppTextField(label: 'Email', controller: _field),
              const SizedBox(height: AppSpacing.md),
              const AppTextField(
                label: 'Password',
                hint: 'At least 8 characters',
                isPassword: true,
              ),
              const SizedBox(height: AppSpacing.md),
              const AppTextField(
                label: 'With error',
                hint: 'Something went wrong',
                errorText: 'Use at least 8 characters.',
              ),
            ],
          ),
          _Group(
            title: 'Badges and chips',
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final tone in AppTone.values)
                    AppBadge(label: tone.name, tone: tone),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  AppChip(
                    label: 'Selected',
                    selected: _chipSelected,
                    onTap: () => setState(() => _chipSelected = !_chipSelected),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppChip(label: 'Idle', selected: false, onTap: () {}),
                  const SizedBox(width: AppSpacing.sm),
                  AppCheckbox(
                    value: _checked,
                    onChanged: (v) => setState(() => _checked = v),
                  ),
                ],
              ),
            ],
          ),
          _Group(
            title: 'Icon buttons and avatar',
            children: [
              Row(
                children: [
                  for (final style in AppIconButtonStyle.values) ...[
                    AppIconButton(
                      icon: Icons.arrow_back_rounded,
                      style: style,
                      semanticsLabel: style.name,
                      onPressed: () {},
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  const AppAvatar(initials: 'PW'),
                ],
              ),
            ],
          ),
          _Group(
            title: 'Progress',
            children: [
              const Row(
                children: [
                  AppProgressRing(progress: 0.35, label: '5K'),
                  SizedBox(width: AppSpacing.md),
                  AppProgressRing(progress: 1, label: '14K', emphasised: true),
                  SizedBox(width: AppSpacing.md),
                  RestDayDot(),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CountdownPill(
                      remaining: Duration(days: 34, hours: 10, minutes: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const SegmentedProgressBar(
                total: 10,
                completed: 5,
                currentProgress: 0.45,
              ),
              const SizedBox(height: AppSpacing.lg),
              DayProgressItem(
                weekday: 'Thu',
                progress: 0.7,
                isRest: false,
                isToday: true,
                label: '14K',
                onTap: () {},
              ),
            ],
          ),
          _Group(
            title: 'Tiles',
            children: [
              const Row(
                children: [
                  Expanded(
                    child: MetricTile(
                      icon: Icons.straighten_rounded,
                      value: '52.3 km',
                      label: 'Weekly mileage',
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: MetricTile(
                      icon: Icons.schedule_rounded,
                      value: '04:32:16',
                      label: 'Elapsed time',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              StatRow(
                icon: Icons.directions_walk_rounded,
                title: 'Primary Shoes',
                value: 'Pegasus 41 • 612 km',
                onTap: () {},
              ),
              const AppDivider(),
              const SessionSummaryRow(label: 'Entry fee', value: r'$85.00'),
              const SessionSummaryRow(
                label: 'Total',
                value: r'$89.50',
                emphasise: true,
              ),
            ],
          ),
          _Group(
            title: 'Skeletons and states',
            children: [
              const SkeletonLines(),
              const SizedBox(height: AppSpacing.md),
              const Row(
                children: [
                  Skeleton.circle(size: 48),
                  SizedBox(width: AppSpacing.md),
                  Skeleton(width: 120, height: 48, radius: AppRadius.pill),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 260,
                child: EmptyState(
                  icon: Icons.emoji_events_outlined,
                  title: 'No races yet',
                  message: 'Find one and pin your first bib.',
                  actionLabel: 'Browse events',
                  onAction: () {},
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SocialAuthButton(
                    icon: Icons.g_mobiledata_rounded,
                    provider: 'Google',
                    onPressed: () {},
                  ),
                  const SizedBox(width: AppSpacing.base),
                  SocialAuthButton(
                    icon: Icons.facebook_rounded,
                    provider: 'Facebook',
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
          _Group(
            title: 'Illustration',
            children: [
              const Center(
                child: BlobIllustration(
                  icon: Icons.directions_run_rounded,
                  size: 180,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: c.brandGradient,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: c.routeGradient,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.headingMd),
        const SizedBox(height: AppSpacing.md),
        ...children,
      ],
    ),
  );
}
