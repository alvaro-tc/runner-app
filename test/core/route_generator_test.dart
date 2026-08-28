import 'package:camrun/core/utils/route_generator.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 8, 1, 6);

  group('haversine', () {
    test('one degree of latitude is about 111 km', () {
      final a = GeoPoint(lat: 0, lng: 0, timestamp: start);
      final b = GeoPoint(lat: 1, lng: 0, timestamp: start);
      expect(a.distanceTo(b), closeTo(111195, 500));
    });

    test('the same point is zero metres away', () {
      final a = GeoPoint(lat: -6.2, lng: 106.8, timestamp: start);
      expect(a.distanceTo(a), 0);
    });
  });

  group('loop generation', () {
    test('produces a route of the requested length', () {
      final route = RouteGenerator.loop(
        distanceKm: 10,
        centerLat: -6.2088,
        centerLng: 106.8456,
        startedAt: start,
        pacePerKm: const Duration(minutes: 6),
        seed: 4,
      );
      // Haversine over a sampled polygon is slightly under the flat-plane
      // perimeter the generator scales to, so allow a small tolerance.
      expect(RouteGenerator.distanceKmOf(route), closeTo(10, 0.3));
    });

    test('is deterministic for a given seed', () {
      List<GeoPoint> build() => RouteGenerator.loop(
        distanceKm: 5,
        centerLat: 0,
        centerLng: 0,
        startedAt: start,
        pacePerKm: const Duration(minutes: 6),
        seed: 9,
      );
      expect(build().first.lat, build().first.lat);
      expect(build().last.lng, build().last.lng);
    });

    test('timestamps advance monotonically', () {
      final route = RouteGenerator.loop(
        distanceKm: 5,
        centerLat: 0,
        centerLng: 0,
        startedAt: start,
        pacePerKm: const Duration(minutes: 6),
        seed: 1,
      );
      for (var i = 1; i < route.length; i++) {
        expect(
          route[i].timestamp.isBefore(route[i - 1].timestamp),
          isFalse,
          reason: 'point $i went backwards in time',
        );
      }
    });
  });

  group('splits', () {
    test('yields one split per completed kilometre', () {
      final route = RouteGenerator.loop(
        distanceKm: 5,
        centerLat: -6.2,
        centerLng: 106.8,
        startedAt: start,
        pacePerKm: const Duration(minutes: 6),
        seed: 2,
      );
      final splits = RouteGenerator.splitsOf(route);
      expect(splits.length, inInclusiveRange(4, 5));
      expect(splits.first.km, 1);
      expect(splits.last.km, splits.length);
    });

    test('each split lasts roughly the target pace', () {
      final route = RouteGenerator.loop(
        distanceKm: 5,
        centerLat: -6.2,
        centerLng: 106.8,
        startedAt: start,
        pacePerKm: const Duration(minutes: 6),
        seed: 3,
      );
      // 6:00/km target; the generator applies a deliberate pace drift, so
      // individual splits swing roughly +/-15% around it.
      for (final split in RouteGenerator.splitsOf(route)) {
        expect(split.duration.inSeconds, inInclusiveRange(306, 414));
      }
    });

    test('a route shorter than a kilometre has no splits', () {
      final route = RouteGenerator.loop(
        distanceKm: 0.4,
        centerLat: 0,
        centerLng: 0,
        startedAt: start,
        pacePerKm: const Duration(minutes: 6),
        seed: 5,
      );
      expect(RouteGenerator.splitsOf(route), isEmpty);
    });

    test('an empty route is handled without throwing', () {
      expect(RouteGenerator.splitsOf(const []), isEmpty);
      expect(RouteGenerator.distanceKmOf(const []), 0);
      expect(RouteGenerator.elevationGainOf(const []), 0);
    });
  });

  test('elevation gain counts only the climbs', () {
    final points = [
      GeoPoint(lat: 0, lng: 0, timestamp: start, altitude: 10),
      GeoPoint(lat: 0, lng: 0.001, timestamp: start, altitude: 25),
      GeoPoint(lat: 0, lng: 0.002, timestamp: start, altitude: 15),
      GeoPoint(lat: 0, lng: 0.003, timestamp: start, altitude: 20),
    ];
    expect(RouteGenerator.elevationGainOf(points), 20);
  });
}
