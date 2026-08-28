import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/home/domain/entities/training_plan.dart';
import 'package:camrun/features/home/presentation/providers/home_provider.dart';
import 'package:camrun/features/train/presentation/providers/history_provider.dart';
import 'package:camrun/features/train/presentation/widgets/training_history_tile.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:camrun/shared/widgets/molecules/tiles.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TrainPage extends ConsumerWidget {
  const TrainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: context.colors.primary,
          onRefresh: () async => ref.invalidate(historyProvider),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(child: _QuickStart()),
              const SliverToBoxAdapter(child: _WeeklySummaryBlock()),
              const SliverToBoxAdapter(child: _Filters()),
              ...history.when(
                loading: () => [
                  const SliverToBoxAdapter(child: _HistorySkeleton()),
                ],
                error: (error, _) => [
                  SliverToBoxAdapter(
                    child: ErrorStateView(
                      message: error.toString(),
                      onRetry: () => ref.invalidate(historyProvider),
                    ),
                  ),
                ],
                data: (_) => _historySlivers(context, ref),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _historySlivers(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final sections = ref.watch(historySectionsProvider);
    if (sections.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxl),
            child: EmptyState(
              icon: Icons.directions_run_rounded,
              title: t.trainNoRunsTitle,
              message: ref.watch(historyFilterProvider).isEmpty
                  ? t.trainNoRunsMessage
                  : t.trainNoMatchesMessage,
              actionLabel: ref.watch(historyFilterProvider).isEmpty
                  ? t.trainStartTraining
                  : t.trainClearFilters,
              onAction: ref.watch(historyFilterProvider).isEmpty
                  ? () => context.push(Routes.trainSetup)
                  : ref.read(historyFilterProvider.notifier).clear,
            ),
          ),
        ),
      ];
    }

    return [
      for (final section in sections) ...[
        SliverStickyHeader(label: section.label(t)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          sliver: SliverList.builder(
            itemCount: section.runs.length,
            itemBuilder: (context, i) => TrainingHistoryTile(
              run: section.runs[i],
              onTap: () =>
                  context.push(Routes.trainHistoryOf(section.runs[i].id)),
            ),
          ),
        ),
      ],
    ];
  }
}

/// Pinned section label for the grouped history list.
class SliverStickyHeader extends StatelessWidget {
  const SliverStickyHeader({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeaderDelegate(label: label),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({required this.label});

  final String label;

  @override
  double get minExtent => 44;

  @override
  double get maxExtent => 44;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: context.colors.background,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenH,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        label,
        style: context.text.labelSm.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_HeaderDelegate old) => old.label != label;
}

class _QuickStart extends ConsumerWidget {
  const _QuickStart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.l10n;
    final session = ref.watch(homeProvider).value?.focusSession;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.base,
        AppSpacing.screenH,
        AppSpacing.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: c.brandGradient,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: c.floatingShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.trainReadyToRun,
              style: context.text.headingLg.copyWith(color: c.onPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              session == null || session.type.isRest
                  ? t.trainNothingScheduled
                  : t.trainTodaysPlan(
                      session.title(t),
                      Fmt.durationShort(session.targetDuration),
                    ),
              style: context.text.bodyMd.copyWith(
                color: c.onPrimary.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: t.trainStartTraining,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.md,
                    onBrand: true,
                    onPressed: () => context.push(
                      session == null
                          ? Routes.trainSetup
                          : '${Routes.trainSetup}?session=${session.id}',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: t.trainFreeRun,
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.md,
                    onBrand: true,
                    onPressed: () => context.push(Routes.trainSession),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklySummaryBlock extends ConsumerWidget {
  const _WeeklySummaryBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.l10n;
    final summary = ref.watch(weeklySummaryProvider);
    final miles = ref.watch(useMilesProvider);
    final maxY = summary.dailyDistanceKm.fold<double>(
      0,
      (m, v) => v > m ? v : m,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: t.trainThisWeek),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.straighten_rounded,
                  value: Fmt.distance(summary.distanceKm, miles: miles),
                  label: t.commonDistance,
                  compact: true,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: MetricTile(
                  icon: Icons.schedule_rounded,
                  value: Fmt.durationShort(summary.duration),
                  label: t.commonTime,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.speed_rounded,
                  value: Fmt.paceWithUnit(summary.avgPace, miles: miles),
                  label: t.commonAveragePace,
                  compact: true,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: MetricTile(
                  icon: Icons.check_circle_outline_rounded,
                  value: '${summary.sessions}',
                  label: t.trainSessions,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: maxY == 0 ? 10 : maxY * 1.25,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: c.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          Fmt.weekdayInitials()[value.toInt().clamp(0, 6)],
                          style: context.text.labelSm.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                barTouchData: const BarTouchData(enabled: false),
                barGroups: [
                  for (var i = 0; i < 7; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: summary.dailyDistanceKm[i],
                          width: 16,
                          color: summary.dailyDistanceKm[i] == 0
                              ? c.ringTrack
                              : c.primary,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: t.trainHistory),
        ],
      ),
    );
  }
}

class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final filter = ref.watch(historyFilterProvider);
    final notifier = ref.read(historyFilterProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        child: Row(
          children: [
            for (final range in DateRangeFilter.values) ...[
              AppChip(
                label: range.label(t),
                selected: filter.range == range,
                onTap: () => notifier.setRange(range),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              color: context.colors.border,
            ),
            for (final type in SessionType.values)
              if (type != SessionType.rest) ...[
                AppChip(
                  label: type.label(t),
                  icon: iconForSessionType(type),
                  selected: filter.types.contains(type),
                  onTap: () => notifier.toggleType(type),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              color: context.colors.border,
            ),
            // Dia de la semana: sin filtro no habia forma de comparar, por
            // ejemplo, todas las tiradas largas del domingo.
            AppChip(
              label: t.filterWeekdayAll,
              selected: filter.weekdays.isEmpty,
              onTap: () {
                for (final d in {...filter.weekdays}) {
                  notifier.toggleWeekday(d);
                }
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            for (var day = 1; day <= 7; day++) ...[
              AppChip(
                label: Fmt.weekdayShortOf(day),
                selected: filter.weekdays.contains(day),
                onTap: () => notifier.toggleWeekday(day),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
    child: Column(
      children: [
        for (var i = 0; i < 4; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Skeleton(
              width: double.infinity,
              height: 92,
              radius: AppRadius.xl,
            ),
          ),
      ],
    ),
  );
}
