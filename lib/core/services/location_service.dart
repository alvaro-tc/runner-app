import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:paceup/core/utils/route_generator.dart';
import 'package:paceup/features/train/domain/entities/training_run.dart';

enum LocationPermissionOutcome {
  granted,
  denied('Location permission was declined. Grant it to record your route.'),
  deniedForever(
    'Location is blocked for PaceUp. Turn it on in system settings, then come '
    'back.',
  ),
  backgroundDenied(
    'Background location is off. Recording keeps working while PaceUp is on '
    'screen, but may stop if you switch apps.',
  ),
  serviceDisabled(
    'Location services are off on this device. Switch them on to start a run.',
  );

  const LocationPermissionOutcome([this.message = '']);
  final String message;

  bool get isGranted => this == LocationPermissionOutcome.granted;
}

abstract interface class LocationService {
  Future<LocationPermissionOutcome> ensurePermission();

  /// Sube el permiso a `always`, que es el que deja seguir grabando con la app
  /// fuera de pantalla. Se pide **despues** de tener el basico y de que haya
  /// una razon visible para pedirlo: al reves, el sistema lo entierra.
  Future<LocationPermissionOutcome> ensureBackgroundPermission();

  /// Para el estado `deniedForever`, donde volver a preguntar ya no abre nada.
  Future<void> openSettings({bool locationSettings = false});

  /// Emits filtered positions for the duration of a run.
  Stream<GeoPoint> track();
}

class GeolocatorLocationService implements LocationService {
  /// Anything less accurate than this is noise and gets dropped.
  static const _maxAccuracyM = 30.0;

  /// Un punto por segundo mientras se corre. Sin `distanceFilter`: en pausa el
  /// stream se para entero, que ahorra mas que filtrar por distancia.
  static LocationSettings get _settings {
    if (kIsWeb) return const LocationSettings(accuracy: LocationAccuracy.high);
    if (Platform.isAndroid) {
      return AndroidSettings(
        intervalDuration: const Duration(seconds: 1),
        // Sin servicio en primer plano, Android mata el stream a los pocos
        // minutos de salir de pantalla y el entrenamiento se corta solo.
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'PaceUp is recording your run',
          notificationText: 'Tap to go back to your session.',
          enableWakeLock: true,
        ),
      );
    }
    if (Platform.isIOS || Platform.isMacOS) {
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
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationPermissionOutcome.granted,
      LocationPermission.deniedForever =>
        LocationPermissionOutcome.deniedForever,
      _ => LocationPermissionOutcome.denied,
    };
  }

  @override
  Future<LocationPermissionOutcome> ensureBackgroundPermission() async {
    final actual = await Geolocator.checkPermission();
    if (actual == LocationPermission.always) {
      return LocationPermissionOutcome.granted;
    }
    // En Android el sistema no deja pedir `always` en el mismo dialogo: la
    // segunda peticion abre la pantalla de ajustes de la app.
    final pedido = await Geolocator.requestPermission();
    return pedido == LocationPermission.always
        ? LocationPermissionOutcome.granted
        : LocationPermissionOutcome.backgroundDenied;
  }

  @override
  Future<void> openSettings({bool locationSettings = false}) async {
    locationSettings
        ? await Geolocator.openLocationSettings()
        : await Geolocator.openAppSettings();
  }

  @override
  Stream<GeoPoint> track() =>
      Geolocator.getPositionStream(locationSettings: _settings)
          .where((p) => p.accuracy <= _maxAccuracyM)
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
          );
}

/// Replays a pre-generated loop so a run can be exercised on a simulator, or
/// anywhere without stepping outside. Enabled by default in debug builds.
class SimulatedLocationService implements LocationService {
  SimulatedLocationService({this.speedUp = 20});

  /// How many times faster than real life the replay runs.
  final int speedUp;

  @override
  Future<LocationPermissionOutcome> ensurePermission() async =>
      LocationPermissionOutcome.granted;

  @override
  Future<LocationPermissionOutcome> ensureBackgroundPermission() async =>
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

/// Debug builds simulate by default; flip this override to test real GPS on a
/// device without changing any call site.
final useSimulatedLocationProvider = Provider<bool>((ref) => kDebugMode);

final locationServiceProvider = Provider<LocationService>(
  (ref) => ref.watch(useSimulatedLocationProvider)
      ? SimulatedLocationService()
      : GeolocatorLocationService(),
);
