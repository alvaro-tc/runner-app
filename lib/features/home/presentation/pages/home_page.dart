import 'dart:async';

import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/home/presentation/providers/home_provider.dart';
import 'package:camrun/features/home/presentation/providers/marathon_providers.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/countdown_pill.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:camrun/shared/widgets/molecules/tiles.dart';
import 'package:camrun/shared/widgets/organisms/marathon_hero_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.data});

  final HomeData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La del usuario abre el carrusel —es la que tiene una cuenta atras que le
    // importa—; detras van las del catalogo, sin repetirla.
    final destacada = data.nextMarathon;
    final catalogo = ref.watch(upcomingMarathonsProvider).value ?? const [];
    final marathons = <Marathon>[
      ?destacada,
      for (final m in catalogo)
        if (m.id != destacada?.id) m,
    ];

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
        SectionHeader(title: context.l10n.homeCamTitle),
        const SizedBox(height: AppSpacing.md),
        const _CamCard(),
      ],
    );
  }
}

/// Quien esta detras de la app: el CAM y lo que hace, en dos lineas.
class _CamCard extends StatelessWidget {
  const _CamCard();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
        boxShadow: c.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.primary.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.volunteer_activism_rounded, color: c.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.homeCamSubtitle,
                  style: context.text.headingMd,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.homeCamBody,
                  style: context.text.bodyMd.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
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
  // `viewportFraction` deja asomar la siguiente: se ve que hay mas carreras
  // sin tener que descubrirlo deslizando.
  final _controller = PageController(viewportFraction: 0.92);
  int _index = 0;
  Timer? _autoplay;

  @override
  void initState() {
    super.initState();
    _restartAutoplay();
  }

  /// Pasa sola cada 5 s. Al tocar el carrusel se reinicia la cuenta, para que
  /// no se mueva bajo el dedo de quien lo esta mirando.
  void _restartAutoplay() {
    _autoplay?.cancel();
    if (widget.marathons.length < 2) return;
    _autoplay = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage(
        (_index + 1) % widget.marathons.length,
        duration: AppDurations.slow,
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void didUpdateWidget(_UpcomingMarathons old) {
    super.didUpdateWidget(old);
    if (old.marathons.length != widget.marathons.length) _restartAutoplay();
  }

  @override
  void dispose() {
    _autoplay?.cancel();
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
                    ? context.l10n.homeUpcomingMarathon
                    : context.l10n.homeUpcomingMarathons,
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
            child: NotificationListener<ScrollStartNotification>(
              onNotification: (n) {
                if (n.dragDetails != null) _restartAutoplay();
                return false;
              },
              child: PageView.builder(
                controller: _controller,
                itemCount: marathons.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: MarathonHeroCard(
                    marathon: marathons[i],
                    onTap: () =>
                        context.push(Routes.marathonDetailOf(marathons[i].id)),
                  ),
                ),
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
                GestureDetector(
                  onTap: () {
                    _restartAutoplay();
                    _controller.animateToPage(
                      i,
                      duration: AppDurations.base,
                      curve: Curves.easeInOut,
                    );
                  },
                  // Un punto de 6pt no se acierta: el area de toque va aparte.
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: AnimatedContainer(
                      duration: AppDurations.fast,
                      height: 6,
                      width: i == index ? 18 : 6,
                      decoration: BoxDecoration(
                        color: i == index ? c.primary : c.border,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
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
      children: const [
        Row(
          children: [
            Expanded(child: Skeleton(width: double.infinity, height: 28)),
            SizedBox(width: AppSpacing.sm),
            Skeleton(width: 130, height: 38, radius: AppRadius.pill),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        AspectRatio(
          aspectRatio: 16 / 11,
          child: Skeleton(
            width: double.infinity,
            height: double.infinity,
            radius: AppRadius.xxl,
          ),
        ),
        SizedBox(height: AppSpacing.xxl + AppSpacing.base),
        Skeleton(width: 220, height: 24),
        SizedBox(height: AppSpacing.lg),
        Skeleton(width: double.infinity, height: 110, radius: AppRadius.xl),
      ],
    );
  }
}
