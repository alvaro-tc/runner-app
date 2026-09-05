import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/home/presentation/providers/marathon_providers.dart';
import 'package:camrun/features/races/presentation/providers/races_provider.dart';
import 'package:camrun/features/races/presentation/widgets/pending_validation.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_icon_button.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/event_image.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final route = [
      for (final p in marathon.routePreview)
        GeoPoint(lat: p.lat, lng: p.lng, timestamp: marathon.date),
    ];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          leading: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: AppIconButton(
              icon: Icons.arrow_back_rounded,
              semanticsLabel: context.l10n.commonBack,
              onPressed: () => context.pop(),
            ),
          ),
          backgroundColor: c.background,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              marathon.name,
              style: context.text.titleMd,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            titlePadding: const EdgeInsets.symmetric(
              horizontal: 56,
              vertical: AppSpacing.base,
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'marathon-${marathon.id}',
                  child: EventImage(imageUrl: marathon.heroImageUrl),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(gradient: c.heroOverlay),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.lg,
            AppSpacing.screenH,
            AppSpacing.xxl,
          ),
          sliver: SliverList.list(
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppBadge(
                    label: Fmt.distance(marathon.distanceKm),
                    icon: Icons.straighten_rounded,
                  ),
                  AppBadge(
                    label: Fmt.fullDate(marathon.date),
                    icon: Icons.event_rounded,
                  ),
                  AppBadge(
                    label: marathon.location,
                    icon: Icons.place_outlined,
                  ),
                  AppBadge(
                    label: marathon.status.label(context.l10n),
                    tone: switch (marathon.status) {
                      RegistrationStatus.open => AppTone.success,
                      RegistrationStatus.closingSoon => AppTone.warning,
                      RegistrationStatus.full ||
                      RegistrationStatus.closed => AppTone.error,
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _Section(
                title: context.l10n.marathonAbout,
                child: Text(
                  marathon.about,
                  style: context.text.bodyMd.copyWith(color: c.textSecondary),
                ),
              ),
              _Section(
                title: context.l10n.marathonRoute,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: SizedBox(
                    height: 190,
                    child: RouteMapView(route: route, interactive: false),
                  ),
                ),
              ),
              if (marathon.schedule.isNotEmpty)
                _Section(
                  title: context.l10n.marathonSchedule,
                  child: Column(
                    children: [
                      for (final item in marathon.schedule)
                        _TimelineRow(
                          item: item,
                          isLast: item == marathon.schedule.last,
                        ),
                    ],
                  ),
                ),
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
                            Expanded(
                              child: Text(line, style: context.text.bodyMd),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              _Section(
                title: context.l10n.marathonEntryFee,
                child: Row(
                  children: [
                    Text(
                      Fmt.money(
                        marathon.entryFee.amount,
                        marathon.entryFee.currency,
                      ),
                      style: context.text.displayMd,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        context.l10n.marathonPlacesLeft(
                          marathon.slotsLeft,
                          marathon.slotsTotal,
                        ),
                        style: context.text.bodySm.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.marathonEntryFee,
                  style: context.text.labelSm.copyWith(color: c.textSecondary),
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
                    ? () => context.push(Routes.marathonRegisterOf(marathon.id))
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
