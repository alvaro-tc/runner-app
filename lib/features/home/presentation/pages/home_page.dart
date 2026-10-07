import 'dart:async';
import 'dart:math' as math;

import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/home/presentation/providers/home_provider.dart';
import 'package:camrun/features/home/presentation/providers/marathon_providers.dart';
import 'package:camrun/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_icon_button.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/layout/responsive.dart';
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

    return PageInsets(
      maxWidth: AppSizes.wideMaxWidth,
      builder: (context, inset) => ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          inset,
          AppSpacing.base,
          inset,
          AppSpacing.xxl,
        ),
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: NotificationBell(style: AppIconButtonStyle.bordered),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Sin ninguna carrera por delante no hay cuenta atras que enseñar.
          if (marathons.isNotEmpty) ...[
            _UpcomingMarathons(marathons: marathons),
            const SizedBox(height: AppSpacing.xl),
          ],
          SectionHeader(title: context.l10n.homeCamTitle),
          const SizedBox(height: AppSpacing.md),
          const _CamCard(),
        ],
      ),
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
  // sin tener que descubrirlo deslizando. Depende del ancho, asi que el
  // controlador se rehace cuando la pantalla gira (ver `_controllerFor`).
  PageController? _controller;
  double? _fraction;
  int _index = 0;
  Timer? _autoplay;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: _restartAutoplay,
      onInactive: () => _autoplay?.cancel(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restartAutoplay();
  }

  /// Pasa sola cada 5 s. Al tocar el carrusel se reinicia la cuenta, para que
  /// no se mueva bajo el dedo de quien lo esta mirando.
  void _restartAutoplay() {
    _autoplay?.cancel();
    if (!mounted ||
        widget.marathons.length < 2 ||
        !TickerMode.valuesOf(context).enabled ||
        (WidgetsBinding.instance.lifecycleState != null &&
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed)) {
      return;
    }
    _autoplay = Timer.periodic(const Duration(seconds: 5), (_) {
      final controller = _controller;
      if (!mounted || controller == null || !controller.hasClients) return;
      controller.animateToPage(
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
    _lifecycle?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  /// El controlador para esta fraccion. Al girar la pantalla la fraccion
  /// cambia y `PageController` no deja cambiarla en caliente: se hace otro
  /// que arranca en la misma carrera, y el viejo se suelta tras el frame,
  /// cuando el `PageView` ya no lo tiene enganchado.
  PageController _controllerFor(double fraction) {
    final actual = _controller;
    if (actual != null && _fraction == fraction) return actual;
    _fraction = fraction;
    if (actual != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => actual.dispose());
    }
    return _controller = PageController(
      viewportFraction: fraction,
      initialPage: _index,
    );
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
        (TickerMode.valuesOf(context).enabled
            ? ref.watch(countdownProvider(actual.date)).value
            : null) ??
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
          builder: (context, box) {
            final fraction = heroViewportFraction(
              box.maxWidth,
              context.screenSize.height,
            );
            return SizedBox(
              // El alto de la tarjeta: el afiche (16/11) mas el saliente de la
              // ficha, que es lo que `MarathonHeroCard` reserva por debajo. En
              // telefono la pagina es casi todo el ancho y se mide por el.
              height:
                  (fraction < heroPhoneFraction
                          ? box.maxWidth * fraction
                          : box.maxWidth) *
                      11 /
                      16 +
                  _heroOverhang,
              child: NotificationListener<ScrollStartNotification>(
                onNotification: (n) {
                  if (n.dragDetails != null) _restartAutoplay();
                  return false;
                },
                child: PageView.builder(
                  controller: _controllerFor(fraction),
                  // En telefono la tarjeta va centrada con un asomo a cada
                  // lado. Cuando caben casi dos, centrar la primera dejaria
                  // media pantalla vacia a su izquierda: arranca alineada con
                  // el titulo, como una fila.
                  padEnds: fraction >= heroPhoneFraction,
                  itemCount: marathons.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: MarathonHeroCard(
                      marathon: marathons[i],
                      onTap: () => context.push(
                        Routes.marathonDetailOf(marathons[i].id),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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
                    _controller?.animateToPage(
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

/// La fraccion del carrusel en telefono: la tarjeta casi entera y un asomo de
/// la siguiente.
@visibleForTesting
const heroPhoneFraction = 0.92;

/// Tope de ancho de una tarjeta: mas alla el afiche no gana nada y empuja el
/// resto de la pantalla fuera de vista.
const _heroMaxWidth = AppSizes.contentMaxWidth;

/// Cuanto del alto de la pantalla puede llevarse el carrusel.
const _heroMaxHeightShare = 0.7;

/// Que parte del hueco ocupa cada tarjeta del carrusel.
///
/// En telefono, casi todo. En una tablet la tarjeta se queda en un ancho que
/// se lee de un vistazo y las vecinas asoman a los lados; en una ventana baja
/// la limita el alto, para que la tarjeta entera quepa en pantalla.
@visibleForTesting
double heroViewportFraction(double available, double screenHeight) {
  final byHeight =
      (screenHeight * _heroMaxHeightShare - _heroOverhang) * 16 / 11;
  final card = math.min(
    available * heroPhoneFraction,
    math.min(_heroMaxWidth, byHeight),
  );
  // Redondeada: si no, cada pixel de una animacion de cambio de tamano
  // rehace el controlador.
  return (card / available * 100).roundToDouble() / 100;
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
        children: const [
          Row(
            children: [
              Expanded(child: Skeleton(width: double.infinity, height: 28)),
              SizedBox(width: AppSpacing.sm),
              Skeleton(width: 130, height: 38, radius: AppRadius.pill),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          // La forma de la tarjeta, no la del hueco: en una tablet el
          // carrusel no ocupa todo el ancho. El tope de `ContentWidth` es el
          // mismo que el de la tarjeta.
          ContentWidth(
            child: AspectRatio(
              aspectRatio: 16 / 11,
              child: Skeleton(
                width: double.infinity,
                height: double.infinity,
                radius: AppRadius.xxl,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.xxl + AppSpacing.base),
          Skeleton(width: 220, height: 24),
          SizedBox(height: AppSpacing.lg),
          Skeleton(width: double.infinity, height: 110, radius: AppRadius.xl),
        ],
      ),
    );
  }
}
