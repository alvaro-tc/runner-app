import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/train/domain/entities/workout_log.dart';
import 'package:camrun/features/train/presentation/hub/providers/train_hub_providers.dart';
import 'package:camrun/features/train/presentation/hub/widgets/goal_ring.dart';
import 'package:camrun/features/train/presentation/hub/widgets/hub_motion.dart';
import 'package:camrun/features/train/presentation/hub/widgets/hub_stat.dart';
import 'package:camrun/features/train/presentation/hub/widgets/week_bars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Las ultimas semanas, una por pagina.
///
/// Un `PageView` y no una lista horizontal: las semanas se comparan de una en
/// una, y el enganche de pagina es lo que hace que el gesto termine siempre
/// sobre una semana entera y nunca a medio camino entre dos.
class WeekSwiper extends ConsumerStatefulWidget {
  const WeekSwiper({super.key});

  /// Alto fijo: dentro va un `PageView`, que necesita un hueco acotado. Sale
  /// de sumar lo que mide el panel —anillo, dos datos y la tira— y no de
  /// probar numeros: si crece el contenido, crece aqui.
  static const height = 300.0;

  @override
  ConsumerState<WeekSwiper> createState() => _WeekSwiperState();
}

class _WeekSwiperState extends ConsumerState<WeekSwiper> {
  PageController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// El controlador no se puede crear hasta saber cuantas semanas hay: abre en
  /// la ultima, que es la semana en curso.
  PageController _controllerFor(int pages) =>
      _controller ??= PageController(initialPage: pages - 1);

  @override
  Widget build(BuildContext context) {
    final weeks = ref.watch(hubWeeksProvider);
    final goal = ref.watch(weeklyGoalKmProvider);
    final miles = ref.watch(useMilesProvider);

    return SizedBox(
      height: WeekSwiper.height,
      child: weeks.when(
        skipLoadingOnReload: true,
        loading: () => const _WeekSkeleton(),
        error: (_, _) => const SizedBox.shrink(),
        data: (list) {
          if (list.isEmpty) return const SizedBox.shrink();
          final controller = _controllerFor(list.length);
          return PageView.builder(
            controller: controller,
            itemCount: list.length,
            onPageChanged: (index) =>
                ref.read(selectedWeekIndexProvider.notifier).select(index),
            itemBuilder: (context, index) =>
                _WeekPanel(week: list[index], goalKm: goal, miles: miles),
          );
        },
      ),
    );
  }
}

class _WeekPanel extends StatelessWidget {
  const _WeekPanel({
    required this.week,
    required this.goalKm,
    required this.miles,
  });

  final WeekStats week;
  final double goalKm;
  final bool miles;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          border: Border.all(color: c.border),
          boxShadow: c.cardShadow,
        ),
        child: Column(
          children: [
            Row(
              children: [
                GoalRing(
                  progress: goalKm <= 0 ? 0 : week.distanceKm / goalKm,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CountUp(
                        value: week.distanceKm,
                        builder: (context, value) => Text(
                          Fmt.distanceValue(value, miles: miles, decimals: 1),
                          style: context.text.headingLg,
                        ),
                      ),
                      Text(
                        t.trainHubOfGoal(Fmt.distance(goalKm, miles: miles)),
                        style: context.text.labelSm.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        week.isCurrent
                            ? t.trainHubWeekCurrent
                            : t.trainHubWeekOf(Fmt.dayMonth(week.startsAt)),
                        style: context.text.titleMd,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      HubStat(
                        icon: Icons.schedule_rounded,
                        value: Fmt.durationShort(week.movingTime),
                        label: t.trainHubMovingTime,
                        tint: c.accentBlue,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      HubStat(
                        icon: Icons.speed_rounded,
                        value: week.avgPace == null
                            ? '--'
                            : Fmt.paceWithUnit(week.avgPace!, miles: miles),
                        label: t.commonAveragePace,
                        tint: c.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            WeekBars(days: week.days, miles: miles),
          ],
        ),
      ),
    );
  }
}

class _WeekSkeleton extends StatelessWidget {
  const _WeekSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        border: Border.all(color: context.colors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PulseBox(width: 128, height: 128, radius: 64),
              SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PulseBox(width: 120, height: 18),
                    SizedBox(height: AppSpacing.sm),
                    PulseBox(width: 80, height: 14),
                    SizedBox(height: AppSpacing.base),
                    PulseBox(height: 34),
                    SizedBox(height: AppSpacing.sm),
                    PulseBox(height: 34),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Expanded(child: PulseBox(radius: AppRadius.lg)),
        ],
      ),
    ),
  );
}
