import 'dart:math' as math;

import 'package:paceup/features/train/domain/entities/training_run.dart';

/// Builds coherent synthetic GPS traces for the fake data layer: smooth closed
/// loops rather than random noise, so the map and the split chart both look
/// like a real run.
abstract final class RouteGenerator {
  /// Metres per degree of latitude — good enough at city scale.
  static const _mPerDegLat = 111320.0;

  /// Generates a closed loop of [distanceKm] centred on [centerLat]/[centerLng],
  /// starting at [startedAt] and run at [pacePerKm] with mild variation.
  static List<GeoPoint> loop({
    required double distanceKm,
    required double centerLat,
    required double centerLng,
    required DateTime startedAt,
    required Duration pacePerKm,
    int seed = 0,
    int samples = 160,
  }) {
    final rnd = math.Random(seed);
    final phase = rnd.nextDouble() * math.pi * 2;
    final lobes = 3 + rnd.nextInt(3);
    final wobble = 0.18 + rnd.nextDouble() * 0.16;

    // Unit-scale shape first, then scale it so its perimeter matches the target.
    final shape = <({double x, double y})>[];
    for (var i = 0; i < samples; i++) {
      final t = i / samples * math.pi * 2;
      final r =
          1 +
          wobble * math.sin(lobes * t + phase) +
          wobble * 0.5 * math.cos((lobes + 2) * t - phase);
      shape.add((x: r * math.cos(t), y: r * math.sin(t) * 0.72));
    }

    var perimeter = 0.0;
    for (var i = 0; i < shape.length; i++) {
      final a = shape[i];
      final b = shape[(i + 1) % shape.length];
      perimeter += math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2));
    }
    final scaleM = distanceKm * 1000 / perimeter;
    final mPerDegLng = _mPerDegLat * math.cos(centerLat * math.pi / 180);

    // Walk the shape accumulating distance so timestamps follow real pace.
    final points = <GeoPoint>[];
    var travelledM = 0.0;
    for (var i = 0; i <= samples; i++) {
      final p = shape[i % shape.length];
      if (i > 0) {
        final prev = shape[(i - 1) % shape.length];
        travelledM +=
            math.sqrt(math.pow(p.x - prev.x, 2) + math.pow(p.y - prev.y, 2)) *
            scaleM;
      }
      // ±4% pace drift keeps the split chart from being a flat line.
      final drift = 1 + math.sin(i / samples * math.pi * 2.5) * 0.04;
      final seconds = travelledM / 1000 * pacePerKm.inSeconds * drift;
      points.add(
        GeoPoint(
          lat: centerLat + p.y * scaleM / _mPerDegLat,
          lng: centerLng + p.x * scaleM / mPerDegLng,
          timestamp: startedAt.add(
            Duration(milliseconds: (seconds * 1000).round()),
          ),
          altitude: 20 + 12 * math.sin(i / samples * math.pi * 4),
        ),
      );
    }
    return points;
  }

  /// Total route length in kilometres, by Haversine over consecutive points.
  static double distanceKmOf(List<GeoPoint> route) {
    var metres = 0.0;
    for (var i = 1; i < route.length; i++) {
      metres += route[i - 1].distanceTo(route[i]);
    }
    return metres / 1000;
  }

  /// Cumulative positive elevation change.
  static double elevationGainOf(List<GeoPoint> route) {
    var gain = 0.0;
    for (var i = 1; i < route.length; i++) {
      final delta = route[i].altitude - route[i - 1].altitude;
      if (delta > 0) gain += delta;
    }
    return gain;
  }

  /// Slices a route into per-kilometre splits, interpolating the crossing time
  /// of each kilometre marker.
  static List<KmSplit> splitsOf(List<GeoPoint> route) {
    if (route.length < 2) return const [];

    final splits = <KmSplit>[];
    var metres = 0.0;
    var nextMarker = 1000.0;
    var lastCrossing = route.first.timestamp;
    Duration? previousDuration;

    for (var i = 1; i < route.length; i++) {
      final segment = route[i - 1].distanceTo(route[i]);
      if (segment <= 0) continue;

      while (metres + segment >= nextMarker) {
        final ratio = (nextMarker - metres) / segment;
        final segmentMs = route[i].timestamp
            .difference(route[i - 1].timestamp)
            .inMilliseconds;
        final crossing = route[i - 1].timestamp.add(
          Duration(milliseconds: (segmentMs * ratio).round()),
        );
        final duration = crossing.difference(lastCrossing);
        splits.add(
          KmSplit(
            km: splits.length + 1,
            duration: duration,
            pace: duration,
            deltaToPrevious: previousDuration == null
                ? Duration.zero
                : duration - previousDuration,
          ),
        );
        previousDuration = duration;
        lastCrossing = crossing;
        nextMarker += 1000;
      }
      metres += segment;
    }
    return splits;
  }
}
