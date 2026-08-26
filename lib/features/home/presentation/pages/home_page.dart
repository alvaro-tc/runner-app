import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paceup/app/router/app_routes.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/features/home/presentation/providers/home_provider.dart';
import 'package:paceup/features/home/presentation/widgets/today_session_card.dart';
import 'package:paceup/features/home/presentation/widgets/weekly_plan_strip.dart';
import 'package:paceup/features/profile/presentation/providers/profile_provider.dart';
import 'package:paceup/l10n/l10n_labels.dart';
import 'package:paceup/shared/widgets/atoms/skeleton.dart';
import 'package:paceup/shared/widgets/molecules/countdown_pill.dart';
import 'package:paceup/shared/widgets/molecules/states.dart';
import 'package:paceup/shared/widgets/molecules/tiles.dart';
import 'package:paceup/shared/widgets/organisms/marathon_hero_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: context.colors.primary,
          onRefresh: () => ref.read(homeProvider.notifier).refresh(),
          child: home.when(
            loading: () => const _HomeSkeleton(),
            error: (error, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: context.screenSize.height * 0.2),
                ErrorStateView(
                  message: error.localized(context.l10n),
                  onRetry: () => ref.invalidate(homeProvider),
                ),
              ],
            ),
            data: (data) => _HomeBody(data: data),
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.data});

  final HomeData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final planTitle = ref
        .watch(profileProvider)
        .maybeWhen(
          data: (p) => context.l10n.homePlanTitleOf(p.firstName),
          orElse: () => context.l10n.homePlanTitleGeneric,
        );
    final marathon = data.nextMarathon;
    // Fall back to a freshly computed value so the pill never flashes zeroes
    // while the ticker's first event is in flight.
    final remaining = marathon == null
        ? Duration.zero
        : ref.watch(countdownProvider(marathon.date)).value ??
              marathon.date.difference(ref.watch(nowProvider)());
    final session = data.focusSession;
    final plan = data.plan;

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.base,
        AppSpacing.screenH,
        AppSpacing.xxl,
      ),
      children: [
        // Sin ninguna carrera por delante no hay cuenta atras que enseñar.
        if (marathon != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.homeUpcomingMarathon,
                  style: context.text.headingLg,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CountdownPill(remaining: remaining),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          MarathonHeroCard(
            marathon: marathon,
            onTap: () => context.push(Routes.marathonDetailOf(marathon.id)),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        SectionHeader(
          title: planTitle,
          action: plan == null
              ? null
              : _WeekPicker(
                  weekCount: plan.totalWeeks,
                  selected: data.selectedWeekIndex,
                  onSelected: (i) =>
                      ref.read(homeProvider.notifier).selectWeek(i),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        // La tira existe con plan y sin el: lo corrido se pinta igual.
        WeeklyPlanStrip(week: data.week),
        const SizedBox(height: AppSpacing.xl),
        if (session != null)
          TodaySessionCard(
            session: session,
            onToggleCompleted: (value) => ref
                .read(homeProvider.notifier)
                .toggleSession(session.id, completed: value),
            onReschedule: () =>
                context.showSnack(context.l10n.homeRescheduleComingSoon),
            onStart: () =>
                context.push('${Routes.trainSetup}?session=${session.id}'),
          ),
        SizedBox(height: c.isDark ? AppSpacing.base : AppSpacing.base),
      ],
    );
  }
}

class _WeekPicker extends StatelessWidget {
  const _WeekPicker({
    required this.weekCount,
    required this.selected,
    required this.onSelected,
  });

  final int weekCount;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PopupMenuButton<int>(
      onSelected: onSelected,
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      itemBuilder: (context) => [
        for (var i = 1; i <= weekCount; i++)
          PopupMenuItem(
            value: i,
            child: Text(
              context.l10n.homeTrainingWeek(i),
              style: context.text.bodyMd.copyWith(
                color: i == selected ? c.primary : c.textPrimary,
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: c.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.homeTrainingWeek(selected),
              style: context.text.labelSm.copyWith(color: c.primary),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.expand_more_rounded, size: 16, color: c.primary),
          ],
        ),
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.base,
        AppSpacing.screenH,
        AppSpacing.xxl,
      ),
      children: [
        const Row(
          children: [
            Expanded(child: Skeleton(width: double.infinity, height: 28)),
            SizedBox(width: AppSpacing.sm),
            Skeleton(width: 130, height: 38, radius: AppRadius.pill),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const AspectRatio(
          aspectRatio: 16 / 11,
          child: Skeleton(
            width: double.infinity,
            height: double.infinity,
            radius: AppRadius.xxl,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl + AppSpacing.base),
        const Skeleton(width: 220, height: 24),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Skeleton.circle(size: 48),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const Skeleton(
          width: double.infinity,
          height: 180,
          radius: AppRadius.xl,
        ),
      ],
    );
  }
}
