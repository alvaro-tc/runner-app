import 'dart:async';

import 'package:camrun/app/dependencies.dart';
import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/features/races/presentation/providers/live_marathon_provider.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:camrun/features/train/presentation/providers/run_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Abre la pantalla de carrera cuando el organizador da la largada.
///
/// Envuelve la app del corredor entera y no una pantalla concreta: la largada
/// puede pillar a alguien mirando su perfil, y el aviso tiene que llegarle
/// igual. Es lo unico que hace —no pinta nada— y por eso no vive dentro de
/// ninguna pagina.
class MarathonStartWatcher extends ConsumerStatefulWidget {
  const MarathonStartWatcher({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<MarathonStartWatcher> createState() =>
      _MarathonStartWatcherState();
}

class _MarathonStartWatcherState extends ConsumerState<MarathonStartWatcher> {
  /// Ya se abrio la pantalla para esta maraton. Sin esto, cada aviso repetido
  /// —una reconexion del socket manda el estado otra vez— apilaria una pantalla
  /// de carrera encima de la anterior.
  String? _abierta;

  Future<void> _largar(LiveMarathon viva) async {
    final sesion = ref.read(runSessionProvider);
    if (sesion.isActive || _abierta == viva.entry.marathon.id) return;
    _abierta = viva.entry.marathon.id;

    // El trazado oficial no viene en la lista de carreras: son miles de
    // coordenadas que solo hacen falta este momento exacto. Si la peticion
    // falla se corre igual, con el mapa sin linea de referencia — perder la
    // largada por un corte de red seria mucho peor.
    final maraton = await ref
        .read(marathonRepositoryProvider)
        .fetchById(viva.entry.marathon.id);
    final recorrido = maraton.fold(
      (m) => [
        for (final p in m.routePreview)
          GeoPoint(lat: p.lat, lng: p.lng, timestamp: DateTime(2000)),
      ],
      (_) => const <GeoPoint>[],
    );

    if (!mounted) return;

    // `start` corre el 3-2-1 y despues abre el GPS. La pantalla se empuja ya,
    // para que la cuenta atras se vea: es lo que le dice al corredor que la
    // carrera arranco de verdad.
    unawaited(
      ref
          .read(runSessionProvider.notifier)
          .start(
            RunGoal.marathon(
              marathonId: viva.entry.marathon.id,
              registrationId: viva.entry.id,
              title: viva.entry.marathon.name,
              distanceKm: viva.entry.marathon.distanceKm,
              officialRoute: recorrido,
            ),
          ),
    );
    // `push` devuelve el resultado de la pantalla, que aqui no interesa: la
    // carrera no se cierra volviendo, se cierra cuando el organizador corta.
    if (mounted) unawaited(context.push(Routes.trainSession));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(liveMarathonProvider, (_, viva) {
      if (viva == null) {
        _abierta = null;
        return;
      }
      unawaited(_largar(viva));
    });

    // La primera lectura no dispara `listen`: quien abre la app con la carrera
    // ya empezada tiene que acabar en la misma pantalla que quien estaba dentro.
    final viva = ref.watch(liveMarathonProvider);
    if (viva != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_largar(viva)),
      );
    }

    return widget.child;
  }
}
