import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paceup/app/router/app_routes.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/formatters/formatters.dart';
import 'package:paceup/core/services/settings_provider.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/features/home/domain/entities/training_plan.dart';
import 'package:paceup/features/home/presentation/providers/home_provider.dart';
import 'package:paceup/features/train/presentation/providers/history_provider.dart';
import 'package:paceup/features/train/presentation/widgets/training_history_tile.dart';
import 'package:paceup/shared/widgets/atoms/app_button.dart';
import 'package:paceup/shared/widgets/atoms/app_indicators.dart';
import 'package:paceup/shared/widgets/atoms/skeleton.dart';
import 'package:paceup/shared/widgets/molecules/states.dart';
import 'package:paceup/shared/widgets/molecules/tiles.dart';

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
    final sections = ref.watch(historySectionsProvider);
    if (sections.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxl),
            child: EmptyState(
              icon: Icons.directions_run_rounded,
              title: 'No runs yet',
              message: ref.watch(historyFilterProvider).isEmpty
                  ? 'Your first one starts here. Pick a goal and head out.'
                  : 'Nothing matches those filters. Widen them to see more.',
              actionLabel: ref.watch(historyFilterProvider).isEmpty
                  ? 'Start training'
                  : 'Clear filters',
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
        SliverStickyHeader(label: section.label),
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
              'Ready to run?',
              style: context.text.headingLg.copyWith(color: c.onPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              session == null || session.type.isRest
                  ? 'Nothing scheduled today. A free run still counts.'
                  : "Today's plan: ${session.title} · "
                        '${Fmt.durationShort(session.targetDuration)}',
              style: context.text.bodyMd.copyWith(
                color: c.onPrimary.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Start training',
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.md,
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
                    label: 'Free run',
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.md,
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
          const SectionHeader(title: 'This week'),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.straighten_rounded,
                  value: Fmt.distance(summary.distanceKm, miles: miles),
                  label: 'Distance',
                  compact: true,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: MetricTile(
                  icon: Icons.schedule_rounded,
                  value: Fmt.durationShort(summary.duration),
                  label: 'Time',
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
                  label: 'Average pace',
                  compact: true,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: MetricTile(
                  icon: Icons.check_circle_outline_rounded,
                  value: '${summary.sessions}',
                  label: 'Sessions',
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
                          const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][value
                              .toInt()
                              .clamp(0, 6)],
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
          const SectionHeader(title: 'History'),
        ],
      ),
    );
  }
}

class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                label: range.label,
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
                  label: type.label,
                  icon: iconForSessionType(type),
                  selected: filter.types.contains(type),
                  onTap: () => notifier.toggleType(type),
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
