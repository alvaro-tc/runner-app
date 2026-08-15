import 'dart:async';

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
  serviceDisabled(
    'Location services are off on this device. Switch them on to start a run.',
  );

  const LocationPermissionOutcome([this.message = '']);
  final String message;

  bool get isGranted => this == LocationPermissionOutcome.granted;
}

abstract interface class LocationService {
  Future<LocationPermissionOutcome> ensurePermission();

  /// Emits filtered positions for the duration of a run.
  Stream<GeoPoint> track();
}

class GeolocatorLocationService implements LocationService {
  /// Anything less accurate than this is noise and gets dropped.
  static const _maxAccuracyM = 25.0;

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
  Stream<GeoPoint> track() =>
      Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          )
          .where((p) => p.accuracy <= _maxAccuracyM)
          .map(
            (p) => GeoPoint(
              lat: p.latitude,
              lng: p.longitude,
              timestamp: p.timestamp,
              altitude: p.altitude,
              accuracy: p.accuracy,
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
