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
/// maraton en preparacion y publica la posicion en su sala.
class PreRaceBeaconNotifier extends Notifier<LocationPermissionOutcome?> {
  /// Ya sube posiciones. Sin esto, cada aviso repetido del socket reencenderia
  /// Traccar.
  bool _encendido = false;

  /// Ya se pidio el permiso en esta preparacion. Denegar no se reintenta solo
  /// —volver a preguntar en cada aviso le taparia la pantalla al corredor—,
  /// pero el boton de la sala de espera si puede ([encender] con `forzar`).
  bool _pedido = false;

  /// Puntos pedidos a mano, corra Traccar o no. Ver `LiveUploader.ping`: sin
  /// esto, un telefono donde el servicio de fondo no arranca —o dice que
  /// arranco y no sube— no aparece nunca en el mapa del organizador, y en
  /// preparacion no hay sesion de carrera detras que lo recoja.
  Timer? _latido;

  /// El permiso, o `null` mientras no haya nada que contar. Es lo que la sala
  /// de espera pinta para que el corredor sepa por que no sale en el mapa.
  @override
  LocationPermissionOutcome? build() {
    ref.onDispose(pararLatido);
    return null;
  }

  Future<void> encender({bool forzar = false}) async {
    if (_encendido || (_pedido && !forzar)) return;
    _pedido = true;
    final permiso = await ref.read(locationServiceProvider).ensurePermission();
    state = permiso;
    if (!permiso.isGranted || _encendido) return;
    _encendido = true;
    final subidor = ref.read(liveUploaderProvider);
    if (subidor == null) return;
    // Se arranca Traccar **y** se piden puntos a mano, no lo uno o lo otro.
    // `isTracking` puede decir que si y no subir nada —permiso de fondo a
    // medias, el fabricante congelando el servicio, el proveedor fusionado que
    // no emite con el telefono quieto en el bolsillo— y en preparacion no hay
    // sesion de carrera detras que recoja al corredor: el organizador decide si
    // larga mirando un mapa donde esa persona no sale. El punto a mano es lo
    // unico que depende solo de esta app, y la sala de espera la tiene en
    // primer plano por definicion.
    unawaited(subidor.start());
    // El primero sin esperar al temporizador: es lo que dice "estoy aqui, con
    // la app abierta y el GPS encendido" en el instante en que se entra.
    unawaited(subidor.ping());
    _latido = Timer.periodic(
      // Diez segundos: el servidor publica como mucho una posicion cada 5 s por
      // corredor, y esto es una red de seguridad con la pantalla encendida
      // delante, no el seguimiento de la carrera.
      const Duration(seconds: 10),
      (_) => unawaited(subidor.ping()),
    );
  }

  /// Deja de pedir puntos a mano sin apagar el faro. Es lo que toca en la
  /// largada: de ahi en adelante sube la sesion de carrera, y un punto suelto
  /// mas entraria en el resultado oficial por otra puerta.
  void pararLatido() {
    _latido?.cancel();
    _latido = null;
  }

  Future<void> apagar() async {
    _pedido = false;
    state = null;
    pararLatido();
    if (!_encendido) return;
    _encendido = false;
    await ref.read(liveUploaderProvider)?.stop();
  }

  Future<void> abrirAjustes() => ref
      .read(locationServiceProvider)
      .openSettings(
        locationSettings: state == LocationPermissionOutcome.serviceDisabled,
      );
}

final preRaceBeaconProvider =
    NotifierProvider<PreRaceBeaconNotifier, LocationPermissionOutcome?>(
      PreRaceBeaconNotifier.new,
    );

/// Enciende y apaga el faro segun la puerta. Sin estado propio: todo vive en
/// [preRaceBeaconProvider], que es tambien de donde la sala de espera saca si
/// falto el permiso.
class PreRaceBeacon extends ConsumerWidget {
  const PreRaceBeacon({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `watch` y no `listen`: el corredor puede abrir la app con la maraton ya
    // en preparacion —la dejo cerrada, o volvio de otra pantalla— y ahi no hay
    // ningun cambio de puerta que escuchar; con `listen` ese corredor no sale
    // nunca en el mapa del organizador. Encender y apagar son idempotentes, asi
    // que repetirlos en cada build no cuesta nada.
    final puerta = ref.watch(marathonGateProvider);
    final faro = ref.read(preRaceBeaconProvider.notifier);
    // En un microtask porque esto acaba tocando el estado del faro, y Riverpod
    // prohibe —con razon— mover un provider mientras el arbol se construye.
    unawaited(
      Future.microtask(
        () => switch (puerta) {
          GatePreparing() => faro.encender(),
          // La sesion de carrera se hace cargo del mismo Traccar. Apagarlo aqui
          // borraria al corredor del mapa justo en la largada.
          GateRunning() => Future<void>.sync(faro.pararLatido),
          GateOpen() || GateFinished() => faro.apagar(),
        },
      ),
    );
    return child;
  }
}
