// ignore_for_file: avoid_print

// Runs with the Dart SDK alone; no device, network or Flutter test socket.
import 'package:camrun/core/utils/append_only_list.dart';
import 'package:camrun/core/utils/route_generator.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';

void require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  var snapshot = AppendOnlyList<int>.empty();
  final saved = <AppendOnlyList<int>>[];
  for (var i = 0; i < 4097; i++) {
    snapshot = snapshot.appended(i);
    if (i % 64 == 0) saved.add(snapshot);
  }
  for (final old in saved) {
    require(old.last == old.length - 1, 'A previous snapshot changed');
    for (var i = 0; i < old.length; i++) {
      require(old[i] == i, 'Indexing failed at a block boundary');
    }
  }
  try {
    snapshot[0] = -1;
    throw StateError('Snapshot allowed mutation');
  } on UnsupportedError {
    // Expected: Riverpod selectors must see a new immutable snapshot.
  }

  final routes = [
    <GeoPoint>[],
    RouteGenerator.loop(
      distanceKm: 42.195,
      centerLat: -16.5,
      centerLng: -68.13,
      startedAt: DateTime.utc(2026),
      pacePerKm: const Duration(minutes: 6),
      samples: 12000,
    ),
    // A single segment can cross several kilometre markers.
    [
      for (var i = 0; i < 4; i++)
        GeoPoint(
          lat: -16.5 + i * 0.035,
          lng: -68.13,
          timestamp: DateTime.utc(2026).add(Duration(minutes: i * 20)),
        ),
    ],
  ];
  for (final route in routes) {
    final incremental = IncrementalSplits();
    var actual = const <KmSplit>[];
    for (final point in route) {
      actual = incremental.add(point);
      // Repeated GPS points must not change a split.
      actual = incremental.add(point);
    }
    final expected = RouteGenerator.splitsOf(route);
    require(actual.length == expected.length, 'Split count changed');
    for (var i = 0; i < actual.length; i++) {
      require(
        actual[i].km == expected[i].km &&
            actual[i].duration == expected[i].duration &&
            actual[i].deltaToPrevious == expected[i].deltaToPrevious,
        'Split interpolation changed at kilometre ${i + 1}',
      );
    }
  }
  print('Validated 4097 immutable snapshots and exact split interpolation.');

  const count = 12000;
  var copied = <int>[];
  final timer = Stopwatch()..start();
  for (var i = 0; i < count; i++) {
    copied = [...copied, i];
  }
  final copyUs = timer.elapsedMicroseconds;
  var blocked = AppendOnlyList<int>.empty();
  timer.reset();
  for (var i = 0; i < count; i++) {
    blocked = blocked.appended(i);
  }
  final blockUs = timer.elapsedMicroseconds;
  require(
    copied.last == blocked.last && copied.length == blocked.length,
    'The benchmark lost points',
  );
  print('12000 appends: full copies ${copyUs}us; shared blocks ${blockUs}us.');
  print('This measures Dart list updates, not device battery or rendering.');
}
