import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paceup/app/router/app_routes.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/features/home/domain/entities/marathon.dart';
import 'package:paceup/features/home/presentation/providers/home_provider.dart';
import 'package:paceup/features/home/presentation/providers/marathon_providers.dart';
import 'package:paceup/features/home/presentation/widgets/today_session_card.dart';
import 'package:paceup/features/home/presentation/widgets/weekly_plan_strip.dart';
import 'package:paceup/features/profile/presentation/providers/profile_provider.dart';
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
                  message: error.toString(),
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
          data: (p) => "${p.firstName}'s Training Plan",
          orElse: () => 'Your Training Plan',
        );
    // La del usuario abre el carrusel —es la que tiene una cuenta atras que le
    // importa—; detras van las del catalogo, sin repetirla.
    final destacada = data.nextMarathon;
    final catalogo = ref.watch(upcomingMarathonsProvider).value ?? const [];
    final marathons = <Marathon>[
      ?destacada,
      for (final m in catalogo)
        if (m.id != destacada?.id) m,
    ];
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
        if (marathons.isNotEmpty) ...[
          _UpcomingMarathons(marathons: marathons),
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
            onReschedule: () => context.showSnack(
              'Rescheduling arrives with the plan editor. '
              'Start the run whenever suits you today.',
            ),
            onStart: () =>
                context.push('${Routes.trainSetup}?session=${session.id}'),
          ),
        SizedBox(height: c.isDark ? AppSpacing.base : AppSpacing.base),
      ],
    );
  }
}

/// El carrusel de proximas carreras. La cuenta atras es la de la tarjeta que se
/// esta mirando, no la de la primera: si no, marca los dias de una carrera que
/// no esta en pantalla.
class _UpcomingMarathons extends ConsumerStatefulWidget {
  const _UpcomingMarathons({required this.marathons});

  final List<Marathon> marathons;

  @override
  ConsumerState<_UpcomingMarathons> createState() => _UpcomingMarathonsState();
}

class _UpcomingMarathonsState extends ConsumerState<_UpcomingMarathons> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // La lista puede encoger entre refrescos y dejar el indice fuera.
    final marathons = widget.marathons;
    final index = _index.clamp(0, marathons.length - 1);
    final actual = marathons[index];
    // Se recalcula tambien aqui para que la pastilla no parpadee en cero
    // mientras llega el primer tic del reloj.
    final remaining =
        ref.watch(countdownProvider(actual.date)).value ??
        actual.date.difference(ref.watch(nowProvider)());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                marathons.length == 1
                    ? 'Upcoming Marathon In'
                    : 'Upcoming Marathons',
                style: context.text.headingLg,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            CountdownPill(remaining: remaining),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, box) => SizedBox(
            // El alto de la tarjeta: el afiche (16/11) mas el saliente de la
            // ficha, que es lo que `MarathonHeroCard` reserva por debajo.
            height: box.maxWidth * 11 / 16 + _heroOverhang,
            child: PageView.builder(
              controller: _controller,
              itemCount: marathons.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => MarathonHeroCard(
                marathon: marathons[i],
                onTap: () =>
                    context.push(Routes.marathonDetailOf(marathons[i].id)),
              ),
            ),
          ),
        ),
        if (marathons.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < marathons.length; i++)
                AnimatedContainer(
                  duration: AppDurations.fast,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs / 2,
                  ),
                  height: 6,
                  width: i == index ? 18 : 6,
                  decoration: BoxDecoration(
                    color: i == index ? c.primary : c.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Lo que `MarathonHeroCard` deja libre por debajo del afiche para la ficha.
const _heroOverhang = 44.0;

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
              'Training Week $i',
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
              'Training Week $selected',
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
