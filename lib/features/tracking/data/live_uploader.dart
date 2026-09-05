import 'dart:developer' as developer;

import 'package:camrun/core/network/api_config.dart';
import 'package:camrun/core/storage/token_storage.dart';
import 'package:traccar_client_sdk/traccar_client_sdk.dart';

/// Quien sube las posiciones **solo durante una maraton oficial**.
///
/// En un entrenamiento suelto sube [TrackingService] y punto. En la largada
/// oficial no basta: ahi el corredor esta dos o tres horas con el telefono en
/// el bolsillo, el sistema mata procesos, la cobertura se cae y el mapa del
/// organizador tiene que seguir viendolo. Ese trabajo —servicio nativo, cola
/// offline y reintento— ya esta hecho y probado en el cliente de Traccar; se
/// usa tal cual en lugar de reescribirlo.
///
/// **Nunca suben los dos a la vez.** El servidor deduplica por
/// `clientPointId`, y el que manda Traccar es suyo: si corrieran en paralelo
/// cada posicion entraria dos veces. Por eso [start] devuelve si se hizo cargo,
/// y `TrackingService` deja de encolar puntos solo cuando dijo que si.
abstract interface class LiveUploader {
  /// `true` si a partir de ahora sube el. `false` deja el camino normal.
  Future<bool> start();

  Future<void> stop();

  /// Un punto suelto, ahora, sin depender del servicio de fondo.
  ///
  /// Es la red de seguridad de la sala de espera: si el servicio no arranco
  /// —permiso de fondo denegado, fabricante que lo mata, plugin sin
  /// registrar— el corredor no aparece en el mapa del organizador y ahi no hay
  /// sesion de carrera que lo recoja. Con la pantalla de preparacion delante
  /// la app esta viva por definicion, asi que un punto pedido a mano llega.
  Future<void> ping();
}

class TraccarUploader implements LiveUploader {
  TraccarUploader(this._storage);

  final TokenStorage _storage;
  final _sdk = TraccarClientSdk();

  /// Deja la configuracion puesta. Aparte de [start] porque [ping] tambien la
  /// necesita: `requestPosition` no sabe a donde subir sin ella.
  Future<void> _configurar() async {
    // El mismo `deviceId` que la app registra al abrir sesion: es lo que el
    // backend usa para resolver `id` → dispositivo → sesion activa.
    final config = Config(
      serverUrl: '$apiBaseUrl/tracking/osmand',
      deviceId: await _storage.deviceId(),
      wakeLock: true,
      location: const LocationConfig(
        accuracy: Accuracy.high,
        intervalSeconds: 5,
        // **Cero, no diez.** El filtro de distancia va en `and` con el
        // intervalo —tanto en el proveedor fusionado como en el nativo—, asi
        // que con un minimo de metros el telefono que no se mueve no emite
        // **nada**. Y no moverse es exactamente lo que hace todo el mundo en
        // la salida, que es cuando el organizador mira el mapa para decidir si
        // larga: el corral entero salia vacio. El techo de trafico lo pone el
        // intervalo, y el servidor publica como mucho una posicion cada 5 s
        // por corredor.
        distanceMeters: 0,
        // Un corredor parado en un avituallamiento sigue estando en carrera:
        // dejar de mandar puntos lo borraria del mapa.
        stopDetection: false,
      ),
      notification: const NotificationConfig(
        text: 'CamRun está siguiendo tu carrera.',
      ),
    );
    // `init` no reconfigura si ya estaba inicializado; `setConfig` si.
    await _sdk.init(config);
    await _sdk.setConfig(config);
  }

  @override
  Future<bool> start() async {
    try {
      await _configurar();
      await _sdk.start();
      // Se **pregunta**, no se supone. `start` puede volver sin excepcion y
      // dejar el servicio parado —permiso de fondo denegado, el fabricante que
      // lo mata—, y decir que si ahi es peor que decir que no: `TrackingService`
      // deja de encolar sus puntos y el corredor desaparece del mapa durante
      // toda la carrera sin que nadie se entere.
      return _sdk.isTracking();
    } on Object catch (e) {
      // Sin plugin o sin permiso de fondo se corre igual, subiendo por lotes
      // como un entrenamiento normal: peor seguimiento en vivo, pero la carrera
      // no se pierde.
      developer.log('traccar no arranco, sube la app: $e', name: 'tracking');
      return false;
    }
  }

  @override
  Future<void> ping() async {
    try {
      await _configurar();
      await _sdk.requestPosition();
    } on Object catch (e) {
      developer.log('traccar no dio un punto suelto: $e', name: 'tracking');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _sdk.stop();
    } on Object catch (e) {
      developer.log('traccar no paro: $e', name: 'tracking');
    }
  }
}
