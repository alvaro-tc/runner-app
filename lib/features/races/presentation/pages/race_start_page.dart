import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paceup/app/router/app_routes.dart';
import 'package:paceup/core/error/failure.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/formatters/formatters.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/features/home/presentation/providers/marathon_providers.dart';
import 'package:paceup/features/races/domain/entities/race_entry.dart';
import 'package:paceup/features/races/presentation/providers/races_provider.dart';
import 'package:paceup/features/train/domain/entities/training_run.dart';
import 'package:paceup/features/train/presentation/providers/run_session_provider.dart';
import 'package:paceup/shared/widgets/atoms/app_button.dart';
import 'package:paceup/shared/widgets/atoms/app_icon_button.dart';
import 'package:paceup/shared/widgets/atoms/app_indicators.dart';
import 'package:paceup/shared/widgets/atoms/skeleton.dart';
import 'package:paceup/shared/widgets/molecules/countdown_pill.dart';
import 'package:paceup/shared/widgets/molecules/states.dart';
import 'package:paceup/shared/widgets/molecules/tiles.dart';
import 'package:paceup/shared/widgets/organisms/route_map_view.dart';

/// Antesala de la largada.
///
/// Existe en vez de un boton que arranque directo porque aqui es donde se
/// carga el **recorrido oficial**: la lista de carreras no lo trae, y sin el la
/// pantalla de carrera seria un mapa en blanco hasta el primer punto de GPS.
/// De paso deja ver el dorsal y la cuenta atras, que es lo que se mira en la
/// linea de salida.
class RaceStartPage extends ConsumerWidget {
  const RaceStartPage({required this.registrationId, super.key});

  final String registrationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carrera = ref.watch(raceDetailProvider(registrationId));

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: AppIconButton(
            icon: Icons.arrow_back_rounded,
            semanticsLabel: 'Go back',
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(Routes.raceDetailOf(registrationId)),
          ),
        ),
        title: const Text('Race day'),
      ),
      body: carrera.when(
        loading: () => const Center(child: Skeleton(width: 180, height: 20)),
        error: (error, _) => ErrorStateView(
          message: error is Failure
              ? error.message
              : 'We could not load that race.',
          onRetry: () => ref.invalidate(raceDetailProvider(registrationId)),
        ),
        data: (entry) => _Body(entry: entry),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.entry});

  final RaceEntry entry;

  /// Arranca la carrera y salta a la pantalla de sesion.
  ///
  /// La sesion se abre con el id de la **inscripcion**: es lo que hace que el
  /// servidor trate los puntos como carrera —mapa en vivo, resultado oficial— y
  /// no como un entrenamiento suelto. El servidor la rechaza si la inscripcion
  /// no esta confirmada, asi que el boton solo aparece cuando lo esta.
  void _start(BuildContext context, WidgetRef ref, List<GeoPoint> recorrido) {
    ref
        .read(runSessionProvider.notifier)
        .start(
          RunGoal.race(
            registrationId: entry.id,
            title: entry.marathon.name,
            distanceKm: entry.marathon.distanceKm,
            officialRoute: recorrido,
          ),
        );
    context.push(Routes.trainSession);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    // El recorrido oficial vive en el catalogo, no en la inscripcion: es de la
    // carrera, no de quien corre.
    final maraton = ref.watch(marathonProvider(entry.marathon.id));
    final recorrido = [
      for (final p
          in maraton.value?.routePreview ??
              const <({double lat, double lng})>[])
        GeoPoint(lat: p.lat, lng: p.lng, timestamp: DateTime(2000)),
    ];
    final faltan = entry.marathon.date.difference(DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        AppSpacing.xxl,
      ),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: SizedBox(
            height: 260,
            child: maraton.isLoading
                ? const Skeleton(width: double.infinity, height: 260)
                : RouteMapView(
                    route: const [],
                    guideRoute: recorrido,
                    interactive: false,
                    markerEveryKm: 5,
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Text(entry.marathon.name, style: context.text.headingLg),
        Text(
          '${Fmt.fullDate(entry.marathon.date)} · ${entry.marathon.location}',
          style: context.text.bodySm.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppBadge(
              label: 'BIB ${entry.bibNumber}',
              icon: Icons.confirmation_num_outlined,
            ),
            AppBadge(
              label: Fmt.distance(entry.marathon.distanceKm),
              icon: Icons.straighten_rounded,
            ),
            if (!faltan.isNegative) CountdownPill(remaining: faltan),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: c.border),
          ),
          child: const Column(
            children: [
              StatRow(
                icon: Icons.route_outlined,
                title: 'The official course is on the map',
                subtitle: 'Your live track is drawn on top of it as you run',
              ),
              AppDivider(),
              StatRow(
                icon: Icons.sensors_rounded,
                title: 'Your position is sent while you run',
                subtitle: 'In batches, so the battery lasts the whole race',
              ),
              AppDivider(),
              StatRow(
                icon: Icons.wifi_off_rounded,
                title: 'Losing signal is fine',
                subtitle: 'Points are stored on the phone and uploaded later',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (entry.canStart)
          AppButton(
            label: 'Start the race',
            icon: Icons.play_arrow_rounded,
            onPressed: () => _start(context, ref, recorrido),
          )
        else
          Text(
            entry.hasResult
                ? 'You already finished this race.'
                : 'This race is not ready to start. Check that your entry is '
                      'paid and confirmed.',
            style: context.text.bodySm.copyWith(color: c.textSecondary),
          ),
      ],
    );
  }
}
