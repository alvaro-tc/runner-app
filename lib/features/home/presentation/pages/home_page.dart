import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/home/presentation/providers/home_provider.dart';
import 'package:camrun/features/home/presentation/providers/marathon_providers.dart';
import 'package:camrun/features/home/presentation/widgets/featured_race.dart';
import 'package:camrun/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_icon_button.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/layout/responsive.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:camrun/shared/widgets/molecules/tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            // Un refresco de fondo no vacia una pantalla que ya tiene datos.
            skipLoadingOnReload: true,
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

/// Las carreras por delante, la mas proxima primero.
///
/// La destacada del resumen —la del usuario, si tiene una— y el catalogo, sin
/// repetir. Que carreras siguen por delante lo decide el servidor: aqui no se
/// descarta ninguna por `liveFinishedAt`, que puede haber quedado puesto de
/// una largada de prueba en una carrera que todavia no se corrio.
@visibleForTesting
List<Marathon> upcomingRaces(Marathon? destacada, List<Marathon> catalogo) =>
    <Marathon>[
      ?destacada,
      for (final m in catalogo)
        if (m.id != destacada?.id) m,
    ]..sort((a, b) => a.date.compareTo(b.date));

class _HomeBody extends ConsumerStatefulWidget {
  const _HomeBody({required this.data});

  final HomeData data;

  @override
  ConsumerState<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends ConsumerState<_HomeBody>
    with SingleTickerProviderStateMixin {
  /// La entrada de la pantalla: una sola animacion que reparte cada seccion
  /// en su tramo (ver [_Reveal]). Corre una vez; un refresco no la repite.
  late final _intro = AnimationController(
    vsync: this,
    duration: AppDurations.showcase,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_intro.isDismissed) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carreras = upcomingRaces(
      widget.data.nextMarathon,
      ref.watch(upcomingMarathonsProvider).value ?? const [],
    );
    final proxima = carreras.firstOrNull;
    final resto = carreras.skip(1).toList();
    final porDelante = {for (final m in carreras) m.id};
    final pasadas = [
      for (final m
          in ref.watch(pastMarathonsProvider).value ?? const <Marathon>[])
        if (!porDelante.contains(m.id)) m,
    ];

    return PageInsets(
      maxWidth: AppSizes.wideMaxWidth,
      builder: (context, inset) => LayoutBuilder(
        builder: (context, box) {
          // En tablet el afiche y su ficha van lado a lado: apilados, el
          // afiche solo ya llenaria la pantalla. Home es la portada: plazas,
          // programa, recorrido y afiche estan en el detalle, a un toque.
          final ancho = box.maxWidth >= AppSizes.readableMaxWidth;
          return ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              inset,
              AppSpacing.base,
              inset,
              AppSpacing.xxxl,
            ),
            children: [
              _Reveal(animation: _intro, slot: 0, child: const _Header()),
              const SizedBox(height: AppSpacing.xl),
              if (proxima == null)
                _Reveal(
                  animation: _intro,
                  slot: 1,
                  child: EmptyState(
                    icon: Icons.event_available_rounded,
                    title: context.l10n.homeNoRacesTitle,
                    message: context.l10n.homeNoRacesMessage,
                  ),
                )
              else if (ancho)
                _Reveal(
                  animation: _intro,
                  slot: 1,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: FeaturedRacePoster(
                          marathon: proxima,
                          intro: _intro,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxl),
                      Expanded(
                        flex: 6,
                        child: FeaturedRaceSummary(marathon: proxima),
                      ),
                    ],
                  ),
                )
              else ...[
                _Reveal(
                  animation: _intro,
                  slot: 1,
                  child: FeaturedRacePoster(marathon: proxima, intro: _intro),
                ),
                const SizedBox(height: AppSpacing.xl),
                _Reveal(
                  animation: _intro,
                  slot: 2,
                  child: FeaturedRaceSummary(marathon: proxima),
                ),
              ],
              if (resto.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                _Reveal(
                  animation: _intro,
                  slot: 3,
                  child: _MoreRaces(marathons: resto),
                ),
              ],
              if (pasadas.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                _Reveal(
                  animation: _intro,
                  slot: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(title: context.l10n.homePastRaces),
                      const SizedBox(height: AppSpacing.md),
                      PastRacesStrip(marathons: pasadas),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// El titulo dice para que se corre antes que que se corre.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.homeHeroTitle, style: context.text.headingLg),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.homeHeroSubtitle,
                style: context.text.bodyMd.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const NotificationBell(style: AppIconButtonStyle.bordered),
      ],
    );
  }
}

class _MoreRaces extends StatelessWidget {
  const _MoreRaces({required this.marathons});

  final List<Marathon> marathons;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeader(title: context.l10n.homeMoreRaces),
      const SizedBox(height: AppSpacing.md),
      RaceBannerCarousel(marathons: marathons),
    ],
  );
}

/// Una seccion que entra subiendo y apareciendo en su tramo de [animation].
/// Los tramos se solapan: la pantalla se arma como una cascada, no por turnos.
class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.animation,
    required this.slot,
    required this.child,
  });

  final Animation<double> animation;
  final int slot;
  final Widget child;

  static const _paso = 0.1;
  static const _tramo = 0.5;

  @override
  Widget build(BuildContext context) {
    final inicio = (slot * _paso).clamp(0.0, 1 - _tramo);
    final curva = CurvedAnimation(
      parent: animation,
      curve: Interval(inicio, inicio + _tramo, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curva,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curva),
        child: child,
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return PageInsets(
      maxWidth: AppSizes.wideMaxWidth,
      builder: (context, inset) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          inset,
          AppSpacing.base,
          inset,
          AppSpacing.xxl,
        ),
        children: [
          const Skeleton(width: 240, height: 28),
          const SizedBox(height: AppSpacing.sm),
          const Skeleton(width: double.infinity, height: 18),
          const SizedBox(height: AppSpacing.xl),
          // La forma del afiche, con su mismo tope de alto.
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    context.screenSize.height *
                    FeaturedRacePoster.maxHeightShare,
              ),
              child: const AspectRatio(
                aspectRatio: FeaturedRacePoster.aspectRatio,
                child: Skeleton(
                  width: double.infinity,
                  height: double.infinity,
                  radius: AppRadius.sheet,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Skeleton(width: 260, height: 32),
          const SizedBox(height: AppSpacing.lg),
          const Row(
            children: [
              Expanded(child: Skeleton(width: double.infinity, height: 84)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Skeleton(width: double.infinity, height: 84)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Skeleton(width: double.infinity, height: 84)),
            ],
          ),
        ],
      ),
    );
  }
}
