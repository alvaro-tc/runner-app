import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/layout/breakpoints.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/train/domain/entities/workout_log.dart';
import 'package:camrun/features/train/presentation/hub/providers/train_hub_providers.dart';
import 'package:camrun/features/train/presentation/hub/widgets/hub_motion.dart';
import 'package:camrun/features/train/presentation/hub/widgets/run_card.dart';
import 'package:camrun/features/train/presentation/hub/widgets/start_cta.dart';
import 'package:camrun/features/train/presentation/hub/widgets/week_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// La pestana Entrenar.
///
/// Se lee de arriba abajo en el orden en que se decide: que voy a hacer hoy
/// (el boton), como voy esta semana (el anillo y la tira) y que he hecho
/// (el historial). Todo lo que se pinta debajo del boton sale de `/workouts`,
/// o sea de lo que midio el servidor, no de la caja local.
class TrainHubPage extends ConsumerStatefulWidget {
  const TrainHubPage({super.key});

  @override
  ConsumerState<TrainHubPage> createState() => _TrainHubPageState();
}

class _TrainHubPageState extends ConsumerState<TrainHubPage> {
  final _scroll = ScrollController();

  /// A que distancia del final se pide la pagina siguiente. Medio alto de
  /// pantalla: llega cargada antes de que el usuario vea el hueco.
  static const _loadMoreMargin = 600.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_maybeLoadMore)
      ..dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreMargin) {
      ref.read(runHistoryProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    ref
      ..invalidate(hubWeeksProvider)
      ..invalidate(runHistoryProvider);
    await ref.read(runHistoryProvider.future);
  }

  Future<void> _delete(WorkoutLog run) async {
    final t = context.l10n;
    final ok = await ref.read(runHistoryProvider.notifier).delete(run.id);
    if (!mounted) return;
    if (ok) {
      context.showSnack(t.trainHubDeleted);
    } else {
      context.showSnack(t.trainHubDeleteFailed);
      // El borrado fallo: la fila que se acaba de ir del dibujo tiene que
      // volver, y la unica fuente fiable de si sigue ahi es el servidor.
      ref.invalidate(runHistoryProvider);
    }
  }

  Future<bool> _confirmDelete() async {
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
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: context.colors.primary,
          onRefresh: _refresh,
          child: LayoutBuilder(
            builder: (context, box) {
              // Cada bloque trae su propio margen de telefono; en una tablet
              // se le suma lo que falte para centrar la columna, y el scroll
              // sigue ocupando todo el ancho.
              final inset = AppLayout.inset(
                box.maxWidth,
                maxWidth: AppSizes.readableMaxWidth,
              );
              return CustomScrollView(
                controller: _scroll,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: inset - AppSpacing.screenH,
                    ),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        const SliverToBoxAdapter(child: _Header()),
                        const SliverToBoxAdapter(
                          child: Reveal(
                            delay: Duration(milliseconds: 60),
                            child: StartCta(),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: AppSpacing.lg),
                        ),
                        const SliverToBoxAdapter(
                          child: Reveal(
                            delay: Duration(milliseconds: 140),
                            child: WeekSwiper(),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: AppSpacing.xl),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screenH,
                              0,
                              AppSpacing.screenH,
                              AppSpacing.md,
                            ),
                            child: Text(
                              context.l10n.trainHubRuns,
                              style: context.text.headingMd,
                            ),
                          ),
                        ),
                        ..._historySlivers(),
                      ],
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxxl),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _historySlivers() {
    final history = ref.watch(runHistoryProvider);
    return history.when(
      // Un refresco de fondo no vacia una lista que ya tiene datos.
      skipLoadingOnReload: true,
      loading: () => const [SliverToBoxAdapter(child: _RunsSkeleton())],
      error: (_, _) => [
        SliverToBoxAdapter(
          child: _Message(
            icon: Icons.cloud_off_rounded,
            title: context.l10n.trainHubLoadError,
            actionLabel: context.l10n.commonRetry,
            onAction: () => ref.invalidate(runHistoryProvider),
          ),
        ),
      ],
      data: (state) {
        final groups = ref.watch(monthGroupsProvider);
        if (groups.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: _Message(
                icon: Icons.directions_run_rounded,
                title: context.l10n.trainHubEmptyTitle,
                message: context.l10n.trainHubEmptyBody,
              ),
            ),
          ];
        }

        final miles = ref.watch(useMilesProvider);
        var absoluteIndex = 0;
        return [
          for (final group in groups) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  AppSpacing.sm,
                  AppSpacing.screenH,
                  AppSpacing.sm,
                ),
                child: Text(
                  Fmt.monthYear(group.month),
                  style: context.text.labelSm.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
              ),
              sliver: SliverList.separated(
                itemCount: group.runs.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final run = group.runs[index];
                  // El escalonado solo vale para las primeras filas: mas
                  // abajo nadie lo ve entrar y la espera solo retrasa el
                  // dibujo.
                  final delay = 40 * (absoluteIndex++).clamp(0, 6);
                  return Reveal(
                    key: ValueKey(run.id),
                    delay: Duration(milliseconds: delay),
                    offset: 18,
                    child: Dismissible(
                      key: ValueKey('dismiss-${run.id}'),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => _confirmDelete(),
                      onDismissed: (_) => _delete(run),
                      background: const _DeleteBackground(),
                      child: RunCard(
                        run: run,
                        miles: miles,
                        onTap: () =>
                            context.push(Routes.trainHistoryOf(run.id)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (state.hasMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ];
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screenH,
      AppSpacing.base,
      AppSpacing.screenH,
      AppSpacing.lg,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.trainHubTitle, style: context.text.displayMd),
        Text(
          Fmt.fullDate(DateTime.now()),
          style: context.text.bodySm.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: AppSpacing.lg),
    decoration: BoxDecoration(
      color: context.colors.errorBg,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
    ),
    child: Icon(Icons.delete_outline_rounded, color: context.colors.error),
  );
}

class _RunsSkeleton extends StatelessWidget {
  const _RunsSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
    child: Column(
      children: [
        for (var i = 0; i < 4; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: PulseBox(height: 104, radius: AppRadius.xxl),
          ),
      ],
    ),
  );
}

/// Vacio y error comparten forma: un icono, una frase y, como mucho, un boton.
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.xl,
        AppSpacing.screenH,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: c.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: c.primary, size: 28),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(title, textAlign: TextAlign.center, style: context.text.titleMd),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: context.text.bodySm.copyWith(color: c.textSecondary),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.base),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
