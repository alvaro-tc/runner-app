import 'package:camrun/core/network/network_providers.dart';
import 'package:camrun/core/services/location_service.dart';
import 'package:camrun/core/sync/sync_providers.dart';
import 'package:camrun/features/tracking/data/live_uploader.dart';
import 'package:camrun/features/tracking/data/tracking_api.dart';
import 'package:camrun/features/tracking/data/tracking_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final trackingApiProvider = Provider<TrackingApi>(
  (ref) => TrackingApi(ref.watch(dioProvider), ref.watch(tokenStorageProvider)),
);

/// Quien sube posiciones en vivo, o `null` si en esta app no hay ninguna.
///
/// Suelto y no dentro de [trackingServiceProvider] porque lo usan dos: la
/// sesion de carrera y el faro de la preparacion, que empieza a mandar la
/// posicion **antes** de que haya ninguna sesion abierta.
final liveUploaderProvider = Provider<LiveUploader?>(
  // Con GPS simulado no hay nada real que seguir, y Traccar subiria la
  // posicion de verdad del que esta probando la app.
  (ref) => ref.watch(useSimulatedLocationProvider)
      ? null
      : TraccarUploader(ref.watch(tokenStorageProvider)),
);

/// Vive mientras viva la app: una grabacion no puede depender de que una
/// pantalla siga montada.
final trackingServiceProvider = Provider<TrackingService>((ref) {
  final service = TrackingService(
    ref.watch(appDatabaseProvider),
    ref.watch(trackingApiProvider),
    ref.watch(locationServiceProvider),
    ref.watch(syncServiceProvider),
    liveUploader: ref.watch(liveUploaderProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
