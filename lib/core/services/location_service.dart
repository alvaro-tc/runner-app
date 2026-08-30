import 'dart:async';
import 'dart:math' as math;

import 'package:camrun/core/utils/route_generator.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Sin mensaje: la explicacion sale del ARB, via
/// `LocationPermissionOutcomeL10n`.
enum LocationPermissionOutcome {
  granted,
  denied,
  deniedForever,
  serviceDisabled;

  bool get isGranted => this == LocationPermissionOutcome.granted;
}

abstract interface class LocationService {
  /// Se pide **en el momento de usar el GPS** —al arrancar la grabacion— y no
  /// antes: un permiso que se pide sin una salida delante se deniega.
  Future<LocationPermissionOutcome> ensurePermission();

  /// Para el estado `deniedForever`, donde volver a preguntar ya no abre nada.
  Future<void> openSettings({bool locationSettings = false});

  /// Emits filtered positions for the duration of a run.
  Stream<GeoPoint> track();
}

class GeolocatorLocationService implements LocationService {
  GeolocatorLocationService({
    this.maxAccuracyM = 30,
    this.interval = const Duration(seconds: 1),
    this.minMoveM = 6,
    this.maxSpeedMs = 12,
  });

  /// Anything less accurate than this is noise and gets dropped.
  final int maxAccuracyM;
  final Duration interval;

  /// Cuanto hay que haberse movido desde el ultimo punto valido para que el
  /// siguiente cuente. Ver [_soloMovimiento].
  final double minMoveM;

  /// 43 km/h. Por encima no es una zancada, es un salto del sensor.
  final double maxSpeedMs;

  /// Un punto por segundo mientras se corre. Sin `distanceFilter`: en pausa el
  /// stream se para entero, que ahorra mas que filtrar por distancia.
  LocationSettings get _settings {
    if (kIsWeb) return const LocationSettings(accuracy: LocationAccuracy.high);
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        intervalDuration: interval,
        // Sin servicio en primer plano, Android mata el stream a los pocos
        // minutos de salir de pantalla y el entrenamiento se corta solo.
        // ponytail: en espanol fijo. `LocationSettings` se construye sin
        // `BuildContext`, asi que no hay `AppLocalizations` a mano; si algun
        // dia importa el ingles, pasarle el `AppLocalizations` desde quien
        // arranca el tracking.
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'CamRun está grabando tu salida',
          notificationText: 'Toca para volver a tu sesión.',
          enableWakeLock: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      // `allowBackgroundLocationUpdates` y no pausar solo ya son el default de
      // geolocator; explicitarlos aqui es repetirlos.
      return AppleSettings(
        activityType: ActivityType.fitness,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high);
  }

  @override
  Future<LocationPermissionOutcome> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationPermissionOutcome.serviceDisabled;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final outcome = switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationPermissionOutcome.granted,
      LocationPermission.deniedForever =>
        LocationPermissionOutcome.deniedForever,
      _ => LocationPermissionOutcome.denied,
    };
    if (outcome.isGranted) await _pedirNotificaciones();
    return outcome;
  }

  /// Pide POST_NOTIFICATIONS, que en Android 13+ es lo que hace visible la
  /// notificacion del servicio en primer plano: sin ella el sistema se lleva
  /// por delante la grabacion en cuanto la salida se alarga fuera de pantalla.
  ///
  /// Va detras del permiso de ubicacion y no bloquea: denegarlo no impide
  /// correr, solo hace la salida larga mas fragil.
  Future<void> _pedirNotificaciones() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (await Permission.notification.isGranted) return;
    await Permission.notification.request();
  }

  @override
  Future<void> openSettings({bool locationSettings = false}) async {
    locationSettings
        ? await Geolocator.openLocationSettings()
        : await Geolocator.openAppSettings();
  }

  @override
  Stream<GeoPoint> track() => soloMovimiento(
    minMoveM: minMoveM,
    maxSpeedMs: maxSpeedMs,
    Geolocator.getPositionStream(locationSettings: _settings)
        .where((p) => p.accuracy <= maxAccuracyM)
        .map(
          (p) => GeoPoint(
            lat: p.latitude,
            lng: p.longitude,
            timestamp: p.timestamp,
            altitude: p.altitude,
            accuracy: p.accuracy,
            speed: p.speed,
            heading: p.heading,
          ),
        ),
  );
}

/// Deja pasar solo los puntos que son movimiento de verdad.
///
/// Parado en un semaforo el GPS sigue emitiendo, y cada lectura cae unos
/// metros al lado de la anterior: sin este filtro esos metros se suman como
/// distancia recorrida, el ritmo sale de la nada y el recorrido del mapa es
/// un garabato encima del semaforo.
///
/// La referencia es el ultimo punto **aceptado**, no el anterior: comparar
/// con el anterior deja pasar el ruido acumulado. El umbral sube con el error
/// declarado por el sensor, que es lo que dice cuanto puede haberse movido
/// solo.
Stream<GeoPoint> soloMovimiento(
  Stream<GeoPoint> origen, {
  double minMoveM = 6,
  double maxSpeedMs = 12,
}) async* {
  GeoPoint? ancla;
  await for (final p in origen) {
    final anterior = ancla;
    if (anterior == null) {
      ancla = p;
      yield p;
      continue;
    }
    final segundos =
        p.timestamp.difference(anterior.timestamp).inMilliseconds / 1000;
    // Repetido o fuera de orden: no aporta nada y descuadra el ritmo.
    if (segundos <= 0) continue;
    final metros = anterior.distanceTo(p);
    if (metros > maxSpeedMs * segundos) continue;
    if (metros < math.max(minMoveM, p.accuracy)) continue;
    ancla = p;
    yield p;
  }
}

/// Replays a pre-generated loop so a run can be exercised on a simulator, or
/// anywhere without stepping outside. Ver [useSimulatedLocationProvider].
class SimulatedLocationService implements LocationService {
  SimulatedLocationService({this.speedUp = 20});

  /// How many times faster than real life the replay runs.
  final int speedUp;

  @override
  Future<LocationPermissionOutcome> ensurePermission() async =>
      LocationPermissionOutcome.granted;

  @override
  Future<void> openSettings({bool locationSettings = false}) async {}

  @override
  Stream<GeoPoint> track() async* {
    final started = DateTime.now();
    final route = RouteGenerator.loop(
      distanceKm: 8,
      centerLat: -6.2088,
      centerLng: 106.8456,
      startedAt: started,
      pacePerKm: const Duration(minutes: 6, seconds: 5),
      seed: DateTime.now().millisecond,
      samples: 240,
    );

    for (var i = 0; i < route.length; i++) {
      if (i > 0) {
        final gap = route[i].timestamp.difference(route[i - 1].timestamp);
        await Future<void>.delayed(
          Duration(milliseconds: (gap.inMilliseconds / speedUp).round()),
        );
      }
      // Re-stamp with wall-clock time so elapsed time matches the replay.
      yield GeoPoint(
        lat: route[i].lat,
        lng: route[i].lng,
        timestamp: DateTime.now(),
        altitude: route[i].altitude,
      );
    }
  }
}

/// GPS falso, para probar en un simulador o sin salir a la calle. Apagado
/// tambien en debug: si no, probar una carrera reproduce una ruta inventada y
/// el permiso real nunca se pide. Se enciende con
/// `--dart-define=SIMULATE_GPS=true`.
final useSimulatedLocationProvider = Provider<bool>(
  (ref) => const bool.fromEnvironment('SIMULATE_GPS'),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => ref.watch(useSimulatedLocationProvider)
      ? SimulatedLocationService()
      : GeolocatorLocationService(),
);
