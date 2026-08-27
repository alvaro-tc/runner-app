import 'dart:async';

import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/network/live_socket.dart';
import 'package:camrun/core/network/network_providers.dart';
import 'package:camrun/core/services/location_service.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/races/presentation/providers/live_marathon_provider.dart';
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
  StreamSubscription<MarathonLiveState>? _corte;

  @override
  void initState() {
    super.initState();
    // The screen must stay awake for the whole run.
    unawaited(WakelockPlus.enable());
  }

  @override
  void dispose() {
    unawaited(_corte?.cancel());
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

  /// La maraton se corto desde el panel: se cierra la grabacion y se sale al
  /// resumen, como cualquier carrera terminada.
  ///
  /// El aviso llega por el socket y no por el provider de carreras: aquel dice
  /// exactamente "esta maraton termino" mientras que el otro puede quedarse en
  /// `null` un instante por una recarga de la lista, y eso cortaria la carrera
  /// de alguien que sigue corriendo.
  void _escucharCorte(String marathonId) {
    _corte ??= ref.read(liveSocketProvider).states.listen((estado) {
      if (estado.marathonId != marathonId || estado.finishedAt == null) return;
      if (ref.read(runSessionProvider).isActive) unawaited(_finish());
    });
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

    // Maraton oficial: la pantalla es una puerta cerrada. Ni atras, ni pausa,
    // ni descartar. El unico que la abre es el organizador, cortando la carrera.
    final bloqueada = state.goal.isLiveMarathon;
    if (bloqueada) {
      _escucharCorte(state.goal.marathonId!);
      // Mantiene vivo al que lleva las salas del socket mientras dure la
      // carrera: sin nadie mirandolo, se cerraria la sala por la que llega el
      // corte y la pantalla se quedaria bloqueada para siempre.
      ref.watch(liveMarathonProvider);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || bloqueada) return;
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
                    locked: bloqueada,
                    title: bloqueada ? state.goal.title : null,
                    onBack: () async {
                      if (await _confirmDiscard() && context.mounted) {
                        context.pop();
                      }
                    },
                  ),
                  if (bloqueada) _Restante(state: state),
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
            _StatsSheet(onFinish: _finish, locked: bloqueada),
            if (state.status == RunStatus.countdown)
              _Countdown(value: state.countdownValue, background: c.background),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, this.locked = false, this.title});

  final Future<void> Function() onBack;

  /// Sin botones. No estan escondidos por estetica: en maraton oficial no hay
  /// nada que puedan hacer, y un boton que no hace nada se pulsa igual.
  final bool locked;

  final String? title;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          if (!locked)
            AppIconButton(
              icon: Icons.arrow_back_rounded,
              semanticsLabel: t.runLeaveSemantics,
              onPressed: onBack,
            ),
          Expanded(
            child: Text(
              title ?? t.runSessionTitle,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleMd,
            ),
          ),
          if (!locked)
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

/// Lo recorrido y lo que falta, en grande y arriba.
///
/// Es lo unico que se mira corriendo una maraton, y por eso no vive dentro de
/// la hoja de estadisticas: esa hay que arrastrarla, y a mitad de carrera no se
/// arrastra nada.
class _Restante extends StatelessWidget {
  const _Restante({required this.state});

  final RunSessionState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final total = state.goal.distanceKm;
    final falta = total == null ? null : (total - state.distanceKm);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
        boxShadow: c.floatingShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.commonDistance,
                  style: context.text.bodySm.copyWith(color: c.textSecondary),
                ),
                Text(
                  Fmt.distance(state.distanceKm),
                  style: context.text.headingMd,
                ),
              ],
            ),
          ),
          if (falta != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  t.runRemaining,
                  style: context.text.bodySm.copyWith(color: c.textSecondary),
                ),
                Text(
                  // Pasarse de la distancia oficial es normal —el GPS suma y el
                  // recorrido nunca es exacto—: entonces no falta nada.
                  falta <= 0 ? t.runAlmostThere : Fmt.distance(falta),
                  style: context.text.headingMd.copyWith(color: c.primary),
                ),
              ],
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
  const _StatsSheet({required this.onFinish, this.locked = false});

  final VoidCallback onFinish;

  /// Sin pausa ni "terminar": en maraton oficial el final lo da el organizador.
  final bool locked;

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
            if (!locked) ...[
              const SizedBox(height: AppSpacing.lg),
              _Controls(state: state, onFinish: onFinish),
            ],
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
