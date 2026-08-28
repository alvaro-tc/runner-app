import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paceup/app/router/app_routes.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/formatters/formatters.dart';
import 'package:paceup/core/services/location_service.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/features/home/domain/entities/training_plan.dart';
import 'package:paceup/features/home/presentation/providers/home_provider.dart';
import 'package:paceup/features/train/presentation/providers/run_session_provider.dart';
import 'package:paceup/l10n/l10n_labels.dart';
import 'package:paceup/shared/widgets/atoms/app_button.dart';
import 'package:paceup/shared/widgets/atoms/app_icon_button.dart';
import 'package:paceup/shared/widgets/atoms/app_indicators.dart';
import 'package:paceup/shared/widgets/molecules/tiles.dart';

/// Picks what the next run is for, and explains why location is needed before
/// the system prompt appears.
class TrainSetupPage extends ConsumerStatefulWidget {
  const TrainSetupPage({this.sessionId, super.key});

  final String? sessionId;

  @override
  ConsumerState<TrainSetupPage> createState() => _TrainSetupPageState();
}

class _TrainSetupPageState extends ConsumerState<TrainSetupPage> {
  static const _distanceOptions = [3.0, 5.0, 10.0, 15.0, 21.1];
  static const _timeOptions = [
    Duration(minutes: 20),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(hours: 1),
  ];

  RunGoalType _type = RunGoalType.free;
  double _distanceKm = 5;
  Duration _duration = const Duration(minutes: 30);
  LocationPermissionOutcome? _permission;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    if (widget.sessionId != null) _type = RunGoalType.planSession;
  }

  PlannedSession? get _plannedSession {
    final data = ref.watch(homeProvider).value;
    if (data == null) return null;
    // Solo la semana cargada: una sesion se arranca desde el Home, y el Home
    // ensena una semana cada vez.
    for (final session in data.week.sessions) {
      if (session.id == widget.sessionId) return session;
    }
    return null;
  }

  RunGoal _buildGoal() {
    final t = context.l10n;
    final planned = _plannedSession;
    return switch (_type) {
      RunGoalType.planSession when planned != null => RunGoal(
        type: RunGoalType.planSession,
        distanceKm: planned.targetDistanceKm,
        duration: planned.targetDuration,
        sessionId: planned.id,
        laps: planned.type == SessionType.intervals ? 10 : null,
        lapPace: planned.targetPace.min,
        title: planned.title(t),
      ),
      RunGoalType.distance => RunGoal(
        type: RunGoalType.distance,
        distanceKm: _distanceKm,
        title: t.goalDistanceTitle(Fmt.distance(_distanceKm)),
      ),
      RunGoalType.time => RunGoal(
        type: RunGoalType.time,
        duration: _duration,
        title: t.goalTimeTitle(Fmt.durationShort(_duration)),
      ),
      _ => RunGoal.free,
    };
  }

  Future<void> _checkPermission() async {
    setState(() => _checking = true);
    final outcome = await ref.read(locationServiceProvider).ensurePermission();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _permission = outcome;
    });
  }

  Future<void> _start() async {
    final t = context.l10n;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.setupBackgroundLocationTitle),
        content: Text(t.setupBackgroundLocationBody),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(t.commonCancel),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: Text(t.setupBackgroundLocationContinue),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    unawaited(ref.read(runSessionProvider.notifier).start(_buildGoal()));
    if (context.mounted) unawaited(context.push(Routes.trainSession));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final planned = _plannedSession;
    final granted = _permission?.isGranted ?? false;

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
        title: Text(t.setupTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        children: [
          SectionHeader(title: t.setupWhatAreYouRunning),
          const SizedBox(height: AppSpacing.md),
          _GoalTile(
            icon: Icons.bolt_rounded,
            title: t.trainFreeRun,
            subtitle: t.setupFreeRunSubtitle,
            selected: _type == RunGoalType.free,
            onTap: () => setState(() => _type = RunGoalType.free),
          ),
          if (planned != null)
            _GoalTile(
              icon: Icons.event_available_rounded,
              title: t.setupPlanSession,
              subtitle:
                  '${planned.title(t)} · '
                  '${Fmt.paceRange(planned.targetPace.min, planned.targetPace.max)}',
              selected: _type == RunGoalType.planSession,
              onTap: () => setState(() => _type = RunGoalType.planSession),
            ),
          _GoalTile(
            icon: Icons.straighten_rounded,
            title: t.setupDistanceGoal,
            subtitle: t.setupDistanceGoalSubtitle,
            selected: _type == RunGoalType.distance,
            onTap: () => setState(() => _type = RunGoalType.distance),
          ),
          if (_type == RunGoalType.distance)
            _OptionRow(
              children: [
                for (final km in _distanceOptions)
                  AppChip(
                    label: Fmt.distance(km),
                    selected: _distanceKm == km,
                    onTap: () => setState(() => _distanceKm = km),
                  ),
              ],
            ),
          _GoalTile(
            icon: Icons.timer_outlined,
            title: t.setupTimeGoal,
            subtitle: t.setupTimeGoalSubtitle,
            selected: _type == RunGoalType.time,
            onTap: () => setState(() => _type = RunGoalType.time),
          ),
          if (_type == RunGoalType.time)
            _OptionRow(
              children: [
                for (final d in _timeOptions)
                  AppChip(
                    label: Fmt.durationShort(d),
                    selected: _duration == d,
                    onTap: () => setState(() => _duration = d),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: granted ? c.successBg : c.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      granted
                          ? Icons.check_circle_rounded
                          : Icons.my_location_rounded,
                      size: 20,
                      color: granted ? c.success : c.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      granted ? t.setupLocationReady : t.setupLocationAccess,
                      style: context.text.titleMd,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _permission != null && !granted
                      ? _permission!.message(t)
                      : granted
                      ? t.setupLocationGrantedBody
                      : t.setupLocationRationale,
                  style: context.text.bodySm.copyWith(color: c.textSecondary),
                ),
                if (!granted) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: t.setupAllowLocation,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.sm,
                    isFullWidth: false,
                    isLoading: _checking,
                    onPressed: _checkPermission,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: t.setupStartRun,
            onPressed: () => unawaited(_start()),
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                Icon(
                  icon,
                  size: 22,
                  color: selected ? c.primary : c.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.text.titleMd),
                      Text(
                        subtitle,
                        style: context.text.bodySm.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: children,
    ),
  );
}
