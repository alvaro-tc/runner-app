import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/layout/breakpoints.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/train/domain/entities/workout_log.dart';
import 'package:camrun/features/train/presentation/hub/providers/train_hub_providers.dart';
import 'package:camrun/features/train/presentation/hub/train_labels.dart';
import 'package:camrun/features/train/presentation/hub/widgets/hub_motion.dart';
import 'package:camrun/features/train/presentation/hub/widgets/hub_stat.dart';
import 'package:camrun/features/train/presentation/hub/widgets/run_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Una salida ya corrida, con lo que el servidor midio de ella.
///
/// Sin mapa: `/workouts/:id` no devuelve el recorrido —las posiciones no se
/// publican por id de entrenamiento— asi que la pantalla cuenta la salida con
/// los parciales, que es lo que de verdad se mira despues de correr.
class RunLogPage extends ConsumerWidget {
  const RunLogPage({required this.runId, super.key});

  final String runId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(runDetailProvider(runId));
    final t = context.l10n;

    return Scaffold(
      body: detail.when(
        loading: () => const _DetailSkeleton(),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.trainHubLoadError, style: context.text.titleMd),
                const SizedBox(height: AppSpacing.base),
                TextButton(
                  onPressed: () => ref.invalidate(runDetailProvider(runId)),
                  child: Text(t.commonRetry),
                ),
              ],
            ),
          ),
        ),
        data: (data) => _Content(detail: data),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.detail});

  final WorkoutDetail detail;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final t = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.trainHubDeleteTitle),
        content: Text(t.trainHubDeleteBody),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(t.commonCancel),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(t.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await ref
        .read(runHistoryProvider.notifier)
        .delete(detail.log.id);
    if (!context.mounted) return;
    context.showSnack(ok ? t.trainHubDeleted : t.trainHubDeleteFailed);
    // Quedarse en el detalle de algo que ya no existe no lleva a ningun sitio.
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.l10n;
    final log = detail.log;
    final miles = ref.watch(useMilesProvider);

    return LayoutBuilder(
      builder: (context, box) {
        final inset = AppLayout.inset(
          box.maxWidth,
          maxWidth: AppSizes.readableMaxWidth,
        );
        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 240,
              backgroundColor: c.primary,
              foregroundColor: c.onPrimary,
              actions: [
                IconButton(
                  tooltip: t.commonDelete,
                  onPressed: () => _delete(context, ref),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
              flexibleSpace: _Header(log: log, miles: miles),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                inset,
                AppSpacing.lg,
                inset,
                AppSpacing.xxxl,
              ),
              sliver: SliverList.list(
                children: [
                  Reveal(
                    child: _Metrics(detail: detail, miles: miles),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Reveal(
                    delay: const Duration(milliseconds: 80),
                    child: Text(
                      t.trainHubSplits,
                      style: context.text.headingMd,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Splits(detail: detail, miles: miles),
                  if (log.mood != null || (detail.notes?.isNotEmpty ?? false))
                    _Feeling(detail: detail),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.log, required this.miles});

  final WorkoutLog log;
  final bool miles;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;

    return FlexibleSpaceBar(
      background: DecoratedBox(
        decoration: BoxDecoration(gradient: c.brandGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                DistanceBadge(
                  runId: log.id,
                  distanceKm: log.distanceKm,
                  miles: miles,
                  size: 104,
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        runTitle(log, t),
                        style: context.text.headingMd.copyWith(
                          color: c.onPrimary,
                        ),
                      ),
                      Text(
                        '${Fmt.weekdayDayMonth(log.startedAt)} · '
                        '${Fmt.timeOfDay(log.startedAt)}',
                        style: context.text.bodySm.copyWith(
                          color: c.onPrimary.withValues(alpha: 0.85),
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

class _Metrics extends StatelessWidget {
  const _Metrics({required this.detail, required this.miles});

  final WorkoutDetail detail;
  final bool miles;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final log = detail.log;

    final stats = <Widget>[
      HubStat(
        icon: Icons.schedule_rounded,
        value: Fmt.clock(log.duration),
        label: t.commonTime,
        tint: c.accentBlue,
      ),
      HubStat(
        icon: Icons.timer_outlined,
        value: Fmt.clock(log.movingTime),
        label: t.trainHubMovingTime,
        tint: c.accentBlue,
      ),
      HubStat(
        icon: Icons.speed_rounded,
        value: log.avgPace == null
            ? '--'
            : Fmt.paceWithUnit(log.avgPace!, miles: miles),
        label: t.commonAveragePace,
        tint: c.primary,
      ),
      HubStat(
        icon: Icons.bolt_rounded,
        value: Fmt.speed(detail.avgSpeedKmh ?? log.avgSpeedKmh, miles: miles),
        label: t.commonAverageSpeed,
        tint: c.primary,
      ),
      HubStat(
        icon: Icons.terrain_rounded,
        value: Fmt.elevation(log.elevationGainM),
        label: t.commonElevationGain,
        tint: c.success,
      ),
      if (log.calories != null)
        HubStat(
          icon: Icons.local_fire_department_rounded,
          value: '${log.calories}',
          label: t.commonCalories,
          tint: c.warning,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          for (var row = 0; row < (stats.length / 2).ceil(); row++) ...[
            if (row > 0) const SizedBox(height: AppSpacing.base),
            Row(
              children: [
                Expanded(child: stats[row * 2]),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: row * 2 + 1 < stats.length
                      ? stats[row * 2 + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Splits extends StatelessWidget {
  const _Splits({required this.detail, required this.miles});

  final WorkoutDetail detail;
  final bool miles;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    if (detail.splits.isEmpty) {
      return Text(
        t.trainHubNoSplits,
        style: context.text.bodySm.copyWith(color: c.textSecondary),
      );
    }

    // La barra se mide contra el kilometro mas lento: comparar contra cero
    // daria barras casi iguales, y lo que se busca mirando parciales es
    // justamente la diferencia entre uno y otro.
    final slowest = detail.slowestSplit?.pace ?? detail.splits.first.pace;
    final fastest = detail.splits
        .map((split) => split.pace)
        .reduce((a, b) => a <= b ? a : b);
    final spread = (slowest - fastest).inSeconds;

    return Column(
      children: [
        for (var i = 0; i < detail.splits.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _SplitRow(
            split: detail.splits[i],
            miles: miles,
            isBest: detail.bestKmIndex == detail.splits[i].index,
            // Entre 0.3 y 1 del ancho: el mas lento sigue teniendo barra, que
            // si no parece que falta el dato.
            factor: spread <= 0
                ? 1
                : 0.3 +
                      0.7 *
                          ((slowest - detail.splits[i].pace).inSeconds /
                              spread),
            delay: Duration(milliseconds: 60 * i.clamp(0, 10)),
          ),
        ],
      ],
    );
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.split,
    required this.miles,
    required this.isBest,
    required this.factor,
    required this.delay,
  });

  final WorkoutSplit split;
  final bool miles;
  final bool isBest;
  final double factor;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;

    return Reveal(
      delay: delay,
      offset: 12,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${split.index + 1}',
              style: context.text.labelSm.copyWith(
                color: isBest ? c.primary : c.textSecondary,
                fontWeight: isBest ? FontWeight.w700 : null,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: c.ringTrack.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: factor.clamp(0.08, 1.0)),
                  duration: context.reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: isBest ? c.brandGradient : null,
                        color: isBest
                            ? null
                            : c.primary.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Row(
                    children: [
                      Text(
                        Fmt.pace(split.pace, miles: miles),
                        style: context.text.labelSm.copyWith(
                          color: isBest ? c.onPrimary : c.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isBest) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.flash_on_rounded,
                          size: 14,
                          color: c.onPrimary,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          t.trainHubBestKm,
                          style: context.text.labelSm.copyWith(
                            color: c.onPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            Fmt.clock(split.duration),
            style: context.text.labelSm.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Feeling extends StatelessWidget {
  const _Feeling({required this.detail});

  final WorkoutDetail detail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final notes = detail.notes;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(t.trainHubFeeling, style: context.text.titleMd),
                const Spacer(),
                if (detail.log.mood != null)
                  Text(detail.log.mood!.emoji, style: context.text.headingMd),
              ],
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                t.trainHubNotes,
                style: context.text.labelSm.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(notes, style: context.text.bodyMd),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              PulseBox(width: 104, height: 104, radius: 52),
              SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PulseBox(width: 160, height: 20),
                    SizedBox(height: AppSpacing.sm),
                    PulseBox(width: 120, height: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const PulseBox(height: 180, radius: AppRadius.sheet),
          const SizedBox(height: AppSpacing.xl),
          for (var i = 0; i < 5; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: PulseBox(height: 28, radius: AppRadius.sm),
            ),
        ],
      ),
    ),
  );
}
