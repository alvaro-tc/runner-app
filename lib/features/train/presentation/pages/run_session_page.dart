import 'dart:async';

import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/services/location_service.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/train/presentation/providers/history_provider.dart';
import 'package:camrun/features/train/presentation/providers/run_session_provider.dart';
import 'package:camrun/features/train/presentation/widgets/hold_to_finish_button.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_icon_button.dart';
import 'package:camrun/shared/widgets/molecules/progress_widgets.dart';
import 'package:camrun/shared/widgets/organisms/route_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class RunSessionPage extends ConsumerStatefulWidget {
  const RunSessionPage({super.key});

  @override
  ConsumerState<RunSessionPage> createState() => _RunSessionPageState();
}

class _RunSessionPageState extends ConsumerState<RunSessionPage> {
  final _mapKey = GlobalKey<RouteMapViewState>();

  @override
  void initState() {
    super.initState();
    // The screen must stay awake for the whole run.
    unawaited(WakelockPlus.enable());
  }

  @override
  void dispose() {
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    final state = ref.read(runSessionProvider);
    if (!state.isActive) return true;

    final t = context.l10n;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.runDiscardTitle),
        content: Text(t.runDiscardBody),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(t.runKeepRunning),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(
              t.commonDiscard,
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
    if (discard ?? false) {
      await ref.read(runSessionProvider.notifier).discard();
      return true;
    }
    return false;
  }

  Future<void> _finish() async {
    final run = await ref.read(runSessionProvider.notifier).finish();
    if (!mounted) return;
    final error = await ref.read(historyProvider.notifier).save(run);
    if (!mounted) return;
    if (error != null) {
      context.showSnack(error.localized(context.l10n));
      return;
    }
    context.pushReplacement(Routes.trainSummaryOf(run.id));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(runSessionProvider);
    final c = context.colors;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) context.pop();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: RouteMapView(
                key: _mapKey,
                route: state.route,
                // En carrera, el circuito oficial va debajo: es como se ve si
                // uno se salio del recorrido.
                guideRoute: state.goal.officialRoute,
                follow: state.lastPoint,
                showStartFinish: state.goal.isRace,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    onBack: () async {
                      if (await _confirmDiscard() && context.mounted) {
                        context.pop();
                      }
                    },
                  ),
                  if (state.error != null) _ErrorBanner(outcome: state.error!),
                  if (state.goal.laps != null) _LapCard(state: state),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: AppSpacing.base,
                        bottom: AppSpacing.base,
                      ),
                      child: AppIconButton(
                        icon: Icons.my_location_rounded,
                        style: AppIconButtonStyle.ink,
                        semanticsLabel: context.l10n.runRecentre,
                        onPressed: () => _mapKey.currentState?.recenter(),
                      ),
                    ),
                  ),
                  SizedBox(height: context.screenSize.height * 0.28),
                ],
              ),
            ),
            _StatsSheet(onFinish: _finish),
            if (state.status == RunStatus.countdown)
              _Countdown(value: state.countdownValue, background: c.background),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final Future<void> Function() onBack;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          AppIconButton(
            icon: Icons.arrow_back_rounded,
            semanticsLabel: t.runLeaveSemantics,
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              t.runSessionTitle,
              textAlign: TextAlign.center,
              style: context.text.titleMd,
            ),
          ),
          AppIconButton(
            icon: Icons.more_horiz_rounded,
            semanticsLabel: t.commonMoreOptions,
            onPressed: () => context.showSnack(t.runSettingsComingSoon),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.outcome});

  final LocationPermissionOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.errorBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off_rounded, size: 18, color: c.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              outcome.message(context.l10n),
              style: context.text.bodySm.copyWith(color: c.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _LapCard extends StatelessWidget {
  const _LapCard({required this.state});

  final RunSessionState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final laps = state.goal.laps!;
    final done = state.completedLaps.clamp(0, laps);
    final withinLap = state.distanceKm - done;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
        boxShadow: c.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.runLapProgress(done + 1, laps),
            style: context.text.bodySm.copyWith(color: c.textSecondary),
          ),
          Text(
            t.runNextLap(
              ((1 - withinLap) * 1000).round(),
              Fmt.paceWithUnit(state.goal.lapPace ?? state.avgPace),
            ),
            style: context.text.headingMd,
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedProgressBar(
            total: laps,
            completed: done,
            currentProgress: withinLap.clamp(0.0, 1.0),
          ),
        ],
      ),
    );
  }
}

class _StatsSheet extends ConsumerWidget {
  const _StatsSheet({required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.l10n;
    final state = ref.watch(runSessionProvider);
    final miles = ref.watch(useMilesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.28,
      minChildSize: 0.28,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.28, 0.55, 0.9],
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
          boxShadow: c.floatingShadow,
          border: c.isDark ? Border.all(color: c.border) : null,
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            AppSpacing.md,
            AppSpacing.base,
            AppSpacing.xl,
          ),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            _BigDistanceCard(distanceKm: state.distanceKm, miles: miles),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _SmallStat(
                    value: Fmt.paceWithUnit(state.avgPace, miles: miles),
                    label: t.commonAveragePace,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SmallStat(
                    value: Fmt.clock(state.elapsed),
                    label: t.runElapsedTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _SmallStat(
                    value: Fmt.paceWithUnit(state.currentPace, miles: miles),
                    label: t.runCurrentPace,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SmallStat(
                    value: Fmt.paceWithUnit(state.lastKmPace, miles: miles),
                    label: t.runLastKm,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _SmallStat(
                    value: Fmt.elevation(state.elevationGainM),
                    label: t.runElevation,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SmallStat(
                    value: '${state.calories}',
                    label: t.commonCalories,
                  ),
                ),
              ],
            ),
            if (state.splits.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(t.commonSplits, style: context.text.titleMd),
              const SizedBox(height: AppSpacing.sm),
              for (final split in state.splits)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          t.runSplitKm(split.km),
                          style: context.text.bodySm.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          Fmt.paceWithUnit(split.pace, miles: miles),
                          style: context.text.bodyMd,
                        ),
                      ),
                      Text(
                        Fmt.durationShort(split.duration),
                        style: context.text.bodySm.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _Controls(state: state, onFinish: onFinish),
          ],
        ),
      ),
    );
  }
}

class _BigDistanceCard extends StatelessWidget {
  const _BigDistanceCard({required this.distanceKm, required this.miles});

  final double distanceKm;
  final bool miles;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.surface),
            child: Icon(Icons.route_rounded, size: 22, color: c.primary),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${Fmt.distanceValue(distanceKm, miles: miles)} '
                    '${miles ? 'MI' : 'KM'}',
                    style: context.text.displayLg,
                  ),
                ),
                Text(
                  context.l10n.runTotalDistance,
                  style: context.text.labelSm.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedSwitcher(
              duration: AppDurations.fast,
              child: Text(
                value,
                key: ValueKey(value),
                style: context.text.headingMd,
              ),
            ),
          ),
          Text(
            label,
            style: context.text.labelSm.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls({required this.state, required this.onFinish});

  final RunSessionState state;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final notifier = ref.read(runSessionProvider.notifier);

    if (state.status == RunStatus.paused) {
      return Column(
        children: [
          AppButton(label: t.runResume, onPressed: notifier.resume),
          const SizedBox(height: AppSpacing.sm),
          HoldToFinishButton(onFinish: onFinish),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: t.runPause,
            variant: AppButtonVariant.outline,
            onPressed: state.status == RunStatus.running
                ? notifier.pause
                : null,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        AppIconButton(
          icon: Icons.music_note_rounded,
          style: AppIconButtonStyle.brand,
          size: AppSizes.controlHeight,
          semanticsLabel: t.runMusicSemantics,
          onPressed: () => context.showSnack(t.runMusicComingSoon),
        ),
      ],
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.value, required this.background});

  final int value;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned.fill(
      child: ColoredBox(
        color: background.withValues(alpha: 0.94),
        child: Center(
          child: TweenAnimationBuilder<double>(
            key: ValueKey(value),
            tween: Tween(begin: 0.6, end: 1),
            duration: AppDurations.base,
            curve: AppDurations.curve,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Text(
              value > 0 ? '$value' : context.l10n.runCountdownGo,
              style: context.text.displayLg.copyWith(
                fontSize: 96,
                color: c.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
