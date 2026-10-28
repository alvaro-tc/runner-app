import 'dart:math' as math;

import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/layout/breakpoints.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/core/theme/system_ui_style.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/home/presentation/providers/marathon_providers.dart';
import 'package:camrun/features/races/presentation/providers/races_provider.dart';
import 'package:camrun/features/races/presentation/widgets/pending_validation.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_icon_button.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/marathon_artwork.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/layout/responsive.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:camrun/shared/widgets/organisms/route_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MarathonDetailPage extends ConsumerWidget {
  const MarathonDetailPage({required this.marathonId, super.key});

  final String marathonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marathon = ref.watch(marathonProvider(marathonId));
    return Scaffold(
      body: marathon.when(
        // Un refresco de fondo no vacia una pantalla que ya tiene datos.
        skipLoadingOnReload: true,
        loading: () => const Center(child: Skeleton(width: 200, height: 20)),
        error: (error, _) => SafeArea(
          child: ErrorStateView(
            message: error.localized(context.l10n),
            onRetry: () => ref.invalidate(marathonProvider(marathonId)),
          ),
        ),
        data: (data) => _Content(marathon: data),
      ),
      bottomNavigationBar: marathon.maybeWhen(
        data: (data) => _BottomBar(marathon: data),
        orElse: () => null,
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.marathon});

  final Marathon marathon;

  /// Forma del banner: la del logo horizontal, que es el que va aqui.
  static const _bannerAspect = 16 / 9;

  /// Tope del banner respecto del alto de pantalla: en una ventana baja o una
  /// tablet apaisada no puede comerse toda la ficha.
  static const _bannerShare = 0.4;

  static const _mapHeight = 190.0;
  static const _mapHeightWide = 300.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final route = [
      for (final p in marathon.routePreview)
        GeoPoint(lat: p.lat, lng: p.lng, timestamp: marathon.date),
    ];
    // El banner mide lo que pide su forma al ancho de la pantalla, con tope
    // de alto. La cabecera es el banner mas la barra y un margen.
    final pantalla = context.screenSize;
    final anchoBanner = math.min(
      pantalla.width - 2 * AppSpacing.screenH,
      AppSizes.readableMaxWidth,
    );
    final altoBanner = math.min(
      anchoBanner / _bannerAspect,
      pantalla.height * _bannerShare,
    );
    final headerHeight = kToolbarHeight + altoBanner + AppSpacing.base;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final collapsed =
                constraints.scrollOffset >= headerHeight - kToolbarHeight;
            return SliverAppBar(
              // Ya no hay foto bajo la barra de estado: el banner flota sobre
              // el fondo del tema y la barra se lee como en cualquier pantalla.
              systemOverlayStyle: systemUiStyleFor(c.background),
              expandedHeight: headerHeight,
              pinned: true,
              backgroundColor: c.background,
              surfaceTintColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: AppIconButton(
                  icon: Icons.arrow_back_rounded,
                  semanticsLabel: context.l10n.commonBack,
                  onPressed: () => context.pop(),
                ),
              ),
              title: AnimatedOpacity(
                opacity: collapsed ? 1 : 0,
                duration: AppDurations.base,
                child: Text(
                  marathon.name,
                  style: context.text.titleMd,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              flexibleSpace: _Banner(
                marathon: marathon,
                expandedHeight: headerHeight,
              ),
            );
          },
        ),
        SliverLayoutBuilder(
          builder: (context, constraints) => SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.inset(
                constraints.crossAxisExtent,
                maxWidth: AppSizes.wideMaxWidth,
              ),
            ).copyWith(top: AppSpacing.lg, bottom: AppSpacing.xxl),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, box) {
                  final wide = box.maxWidth >= _twoColumnsMinWidth;
                  final badges = _badges(context);
                  // En una tablet, lo que se lee a la izquierda y el mapa y
                  // el horario a la derecha; en telefono, el orden de
                  // siempre, de arriba abajo.
                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _escalonado([
                        badges,
                        const SizedBox(height: AppSpacing.xl),
                        ..._about(context),
                        ..._route(context, route, wide: wide),
                        ..._schedule(context),
                        ..._included(context),
                        ..._fee(context),
                      ]),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _escalonado([
                      badges,
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ..._about(context),
                                ..._included(context),
                                ..._fee(context),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xl),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ..._route(context, route, wide: wide),
                                ..._schedule(context),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ]),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Cada seccion entra subiendo un poco despues de la anterior.
  static List<Widget> _escalonado(List<Widget> secciones) => [
    for (var i = 0; i < secciones.length; i++)
      _Entrada(orden: i, child: secciones[i]),
  ];

  /// Ancho a partir del cual la ficha se parte en dos columnas.
  static const _twoColumnsMinWidth = 720.0;

  /// El nombre en grande y, debajo, de un vistazo: distancia, vueltas, fecha,
  /// lugar y estado. El nombre ya no va sobre la imagen: tapaba el logo.
  Widget _badges(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(marathon.name, style: context.text.displayMd),
      const SizedBox(height: AppSpacing.md),
      _chips(context),
    ],
  );

  Widget _chips(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      AppBadge(
        label: Fmt.distance(marathon.distanceKm),
        icon: Icons.straighten_rounded,
      ),
      // En un circuito el mapa de abajo dibuja una sola vuelta:
      // decirlo aqui, junto a la distancia total, es lo que evita
      // que parezca que el trazado se quedo corto.
      if (marathon.laps > 1)
        AppBadge(
          label: context.l10n.raceCircuitLaps(
            Fmt.distance(marathon.distanceKm / marathon.laps),
            '${marathon.laps}',
          ),
          icon: Icons.loop_rounded,
        ),
      AppBadge(label: Fmt.fullDate(marathon.date), icon: Icons.event_rounded),
      AppBadge(label: marathon.location, icon: Icons.place_outlined),
      AppBadge(
        label: marathon.status.label(context.l10n),
        tone: switch (marathon.status) {
          RegistrationStatus.open => AppTone.success,
          RegistrationStatus.closingSoon => AppTone.warning,
          RegistrationStatus.full || RegistrationStatus.closed => AppTone.error,
        },
      ),
    ],
  );

  List<Widget> _about(BuildContext context) {
    final c = context.colors;
    return [
      _Section(
        title: context.l10n.marathonAbout,
        child: Text(
          marathon.about,
          style: context.text.bodyMd.copyWith(color: c.textSecondary),
        ),
      ),
    ];
  }

  List<Widget> _route(
    BuildContext context,
    List<GeoPoint> route, {
    required bool wide,
  }) => [
    _Section(
      title: context.l10n.marathonRoute,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: SizedBox(
          height: wide ? _mapHeightWide : _mapHeight,
          child: RouteMapView(route: route, interactive: false),
        ),
      ),
    ),
  ];

  List<Widget> _schedule(BuildContext context) => [
    if (marathon.schedule.isNotEmpty)
      _Section(
        title: context.l10n.marathonSchedule,
        child: Column(
          children: [
            for (final item in marathon.schedule)
              _TimelineRow(item: item, isLast: item == marathon.schedule.last),
          ],
        ),
      ),
  ];

  List<Widget> _included(BuildContext context) {
    final c = context.colors;
    return [
      _Section(
        title: context.l10n.marathonWhatsIncluded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in marathon.included)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: c.success,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(line, style: context.text.bodyMd)),
                  ],
                ),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _fee(BuildContext context) {
    final c = context.colors;
    return [
      _Section(
        title: context.l10n.marathonEntryFee,
        child: Row(
          children: [
            Text(
              Fmt.money(marathon.entryFee.amount, marathon.entryFee.currency),
              style: context.text.displayMd,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                context.l10n.marathonPlacesLeft(
                  marathon.slotsLeft,
                  marathon.slotsTotal,
                ),
                style: context.text.bodySm.copyWith(color: c.textSecondary),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.headingMd),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    ),
  );
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.isLast});

  final ScheduleItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: AppSpacing.xs),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.primary,
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: c.border)),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.time,
                    style: context.text.labelSm.copyWith(color: c.primary),
                  ),
                  Text(item.title, style: context.text.titleMd),
                  Text(
                    item.detail,
                    style: context.text.bodySm.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.marathon});

  final Marathon marathon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    // Con el comprobante ya subido no se vuelve a empezar: el servidor
    // reutilizaria la misma inscripcion y acabaria con dos cobros abiertos
    // para la misma plaza. Lo que falta aqui no es pagar, es esperar.
    final esperandoValidacion =
        (ref.watch(awaitingValidationProvider).value ?? const []).any(
          (registro) => registro.marathonId == marathon.id,
        );
    final canRegister = marathon.status.acceptsEntries && !esperandoValidacion;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: ContentWidth(
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.marathonEntryFee,
                    style: context.text.labelSm.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                  Text(
                    Fmt.money(
                      marathon.entryFee.amount,
                      marathon.entryFee.currency,
                    ),
                    style: context.text.headingMd,
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: AppButton(
                  label: esperandoValidacion
                      ? context.l10n.racesPendingValidation
                      : canRegister
                      ? context.l10n.marathonRegisterNow
                      : marathon.status.label(context.l10n),
                  // Esperando validacion el boton sigue vivo, pero no lleva al
                  // alta: lleva al motivo por el que no se puede repetir.
                  onPressed: esperandoValidacion
                      ? () => showPendingValidationDialog(context)
                      : canRegister
                      ? () =>
                            context.push(Routes.marathonRegisterOf(marathon.id))
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La cabecera: el banner de la carrera entero, en una tarjeta que flota sobre
/// el fondo. Nada encima de la imagen —ni titulo, ni degradado, ni la barra de
/// estado— y al subir la ficha se encoge y se desvanece en vez de quedar
/// cortada por la barra.
class _Banner extends StatelessWidget {
  const _Banner({required this.marathon, required this.expandedHeight});

  final Marathon marathon;
  final double expandedHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final arriba = MediaQuery.paddingOf(context).top;
    final alto = expandedHeight - kToolbarHeight - AppSpacing.base;
    final ancho = math.min(
      alto * _Content._bannerAspect,
      context.screenSize.width - 2 * AppSpacing.screenH,
    );

    return LayoutBuilder(
      builder: (context, box) {
        // 1 = desplegada, 0 = plegada en la barra.
        final minimo = arriba + kToolbarHeight;
        final t =
            ((box.maxHeight - minimo) / (expandedHeight + arriba - minimo))
                .clamp(0.0, 1.0);
        // Se va antes de llegar a la barra: el ultimo tramo, donde la barra lo
        // taparia, ya es transparente.
        final visible = Curves.easeIn.transform(
          ((t - 0.25) / 0.75).clamp(0.0, 1.0),
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [c.primaryContainer, c.background],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.base,
              height: alto,
              child: Opacity(
                opacity: visible,
                child: Transform.scale(
                  scale: 0.9 + 0.1 * t,
                  alignment: Alignment.bottomCenter,
                  child: Center(
                    child: Container(
                      width: ancho,
                      height: alto,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                        boxShadow: c.floatingShadow,
                      ),
                      child: MarathonArtworkHero(
                        marathon: marathon,
                        aspectRatio: _Content._bannerAspect,
                        radius: AppRadius.xxl,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Entra subiendo y apareciendo, [orden] pasos despues de la primera. Una sola
/// vez: un refresco no la repite. Sin movimiento si el sistema lo pide.
class _Entrada extends StatelessWidget {
  const _Entrada({required this.orden, required this.child});

  final int orden;
  final Widget child;

  static const _paso = Duration(milliseconds: 60);

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppDurations.slow + _paso * orden,
    curve: Curves.easeOutCubic,
    child: child,
    builder: (context, v, child) => Opacity(
      opacity: v,
      child: Transform.translate(
        offset: Offset(0, (1 - v) * AppSpacing.base),
        child: child,
      ),
    ),
  );
}
