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
}

class TraccarUploader implements LiveUploader {
  TraccarUploader(this._storage);

  final TokenStorage _storage;
  final _sdk = TraccarClientSdk();

  @override
  Future<bool> start() async {
    try {
      // El mismo `deviceId` que la app registra al abrir sesion: es lo que el
      // backend usa para resolver `id` → dispositivo → sesion activa.
      final config = Config(
        serverUrl: '$apiBaseUrl/tracking/osmand',
        deviceId: await _storage.deviceId(),
        wakeLock: true,
        location: const LocationConfig(
          accuracy: Accuracy.high,
          intervalSeconds: 5,
          distanceMeters: 10,
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
      await _sdk.start();
      return true;
    } on Object catch (e) {
      // Sin plugin o sin permiso de fondo se corre igual, subiendo por lotes
      // como un entrenamiento normal: peor seguimiento en vivo, pero la carrera
      // no se pierde.
      developer.log('traccar no arranco, sube la app: $e', name: 'tracking');
      return false;
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
