import 'dart:async';

import 'package:camrun/core/services/location_service.dart';
import 'package:camrun/features/races/presentation/providers/live_marathon_provider.dart';
import 'package:camrun/features/tracking/tracking_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Empieza a mandar la posicion en cuanto el organizador pone la maraton "en
/// preparacion", sin esperar a la largada.
///
/// **Por que antes de correr.** El organizador cierra el kiosko y a partir de
/// ahi tiene que ver en su mapa quien esta ya en la salida y quien no ha
/// llegado: es lo que decide si se larga o se espera. Con el seguimiento
/// empezando en la largada, ese mapa esta vacio justo cuando hace falta.
///
/// **Por Traccar y no por el socket.** El corredor se guarda el telefono, la
/// pantalla se apaga y el sistema suspende la app: un socket de Dart se muere
/// ahi, y el servicio nativo de Traccar —que ya sube durante la carrera— no.
/// Es el mismo camino, encendido antes.
///
/// El servidor resuelve el dispositivo a la inscripcion del corredor en la
/// maraton en preparacion y publica la posicion en su sala. Mientras el backend
/// no haga esa parte, esto no rompe nada: los puntos se mandan y se descartan.
class PreRaceBeacon extends ConsumerStatefulWidget {
  const PreRaceBeacon({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PreRaceBeacon> createState() => _PreRaceBeaconState();
}

class _PreRaceBeaconState extends ConsumerState<PreRaceBeacon> {
  /// Ya se encendio —o se intento— para esta preparacion. Sin esto, cada aviso
  /// repetido del socket volveria a pedir el permiso de ubicacion.
  bool _activo = false;

  Future<void> _aplicar(MarathonGate puerta) async {
    switch (puerta) {
      case GatePreparing():
        if (_activo) return;
        _activo = true;
        final permiso = await ref
            .read(locationServiceProvider)
            .ensurePermission();
        // Sin permiso no se insiste: el corredor ya dijo que no y volver a
        // preguntar cada aviso le taparia la pantalla del organizador.
        if (!permiso.isGranted || !mounted) return;
        await ref.read(liveUploaderProvider)?.start();

      case GateRunning():
        // La sesion de carrera se hace cargo del mismo Traccar. Apagarlo aqui
        // borraria al corredor del mapa justo en la largada.
        break;

      case GateOpen() || GateFinished():
        if (!_activo) return;
        _activo = false;
        await ref.read(liveUploaderProvider)?.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      marathonGateProvider,
      (_, puerta) => unawaited(_aplicar(puerta)),
    );
    return widget.child;
  }
}
