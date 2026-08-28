import 'dart:math' as math;

import 'package:camrun/features/home/domain/entities/training_plan.dart';
import 'package:meta/meta.dart';

@immutable
class GeoPoint {
  const GeoPoint({
    required this.lat,
    required this.lng,
    required this.timestamp,
    this.altitude = 0,
    this.accuracy = 5,
    this.speed,
    this.heading,
  });

  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['t'] as int),
    altitude: (json['alt'] as num?)?.toDouble() ?? 0,
    accuracy: (json['acc'] as num?)?.toDouble() ?? 5,
  );

  final double lat;
  final double lng;
  final DateTime timestamp;
  final double altitude;
  final double accuracy;

  /// Lo que reporta el sensor, m/s y grados. Nulos cuando el dispositivo no lo
  /// da: el servidor los acepta opcionales y no se inventan aqui.
  final double? speed;
  final double? heading;

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    't': timestamp.millisecondsSinceEpoch,
    'alt': altitude,
    'acc': accuracy,
  };

  /// Great-circle distance in metres.
  double distanceTo(GeoPoint other) {
    const earthRadiusM = 6371000.0;
    final dLat = _rad(other.lat - lat);
    final dLng = _rad(other.lng - lng);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat)) *
            math.cos(_rad(other.lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadiusM * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}

@immutable
class KmSplit {
  const KmSplit({
    required this.km,
    required this.duration,
    required this.pace,
    required this.deltaToPrevious,
    this.elevationGainM = 0,
  });

  factory KmSplit.fromJson(Map<String, dynamic> json) => KmSplit(
    km: json['km'] as int,
    duration: Duration(seconds: json['dur'] as int),
    pace: Duration(seconds: json['pace'] as int),
    deltaToPrevious: Duration(seconds: json['delta'] as int),
    elevationGainM: (json['elev'] as num?)?.toDouble() ?? 0,
  );

  final int km;
  final Duration duration;
  final Duration pace;

  /// Negative means this km was faster than the previous one.
  final Duration deltaToPrevious;
  final double elevationGainM;

  Map<String, dynamic> toJson() => {
    'km': km,
    'dur': duration.inSeconds,
    'pace': pace.inSeconds,
    'delta': deltaToPrevious.inSeconds,
    'elev': elevationGainM,
  };
}

/// El emoji es el mismo en todos los idiomas; la etiqueta sale del ARB, via
/// `RunFeelingL10n`.
enum RunFeeling {
  rough('\u{1F616}'),
  okay('\u{1F610}'),
  good('\u{1F642}'),
  strong('\u{1F525}');

  const RunFeeling(this.emoji);
  final String emoji;
}

enum TrainingSyncStatus { synced, pending, rejected }

/// Titulos que genera la propia app para una salida.
///
/// Se guardan como identificador, no como texto: una salida grabada en ingles
/// tiene que leerse en espanol al cambiar el idioma. Lo que venga del servidor
/// llega ya como texto libre y se pinta tal cual.
abstract final class RunTitleKey {
  static const morning = 'run.morning';
  static const lunch = 'run.lunch';
  static const afternoon = 'run.afternoon';
  static const evening = 'run.evening';
  static const tempo = 'run.tempo';
  static const long = 'run.long';
  static const trackSession = 'run.track_session';
}

@immutable
class TrainingRun {
  const TrainingRun({
    required this.id,
    required this.startedAt,
    required this.finishedAt,
    required this.distanceKm,
    required this.elapsed,
    required this.movingTime,
    required this.avgPacePerKm,
    required this.elevationGainM,
    required this.avgSpeedKmh,
    required this.route,
    required this.splits,
    required this.type,
    this.title = RunTitleKey.morning,
    this.avgHeartRate,
    this.calories,
    this.feeling,
    this.notes,
    this.clientUuid,
    this.syncStatus = TrainingSyncStatus.synced,
    this.syncError,
  });

  factory TrainingRun.fromJson(Map<String, dynamic> json) => TrainingRun(
    id: json['id'] as String,
    startedAt: DateTime.fromMillisecondsSinceEpoch(json['startedAt'] as int),
    finishedAt: DateTime.fromMillisecondsSinceEpoch(json['finishedAt'] as int),
    distanceKm: (json['distanceKm'] as num).toDouble(),
    elapsed: Duration(seconds: json['elapsed'] as int),
    movingTime: Duration(seconds: json['movingTime'] as int),
    avgPacePerKm: Duration(seconds: json['avgPace'] as int),
    elevationGainM: (json['elevation'] as num).toDouble(),
    avgSpeedKmh: (json['avgSpeed'] as num).toDouble(),
    route: [
      for (final p in json['route'] as List<dynamic>)
        GeoPoint.fromJson(Map<String, dynamic>.from(p as Map)),
    ],
    splits: [
      for (final s in json['splits'] as List<dynamic>)
        KmSplit.fromJson(Map<String, dynamic>.from(s as Map)),
    ],
    type: SessionType.values.byName(json['type'] as String),
    title: json['title'] as String? ?? RunTitleKey.morning,
    avgHeartRate: json['hr'] as int?,
    calories: json['calories'] as int?,
    feeling: json['feeling'] == null
        ? null
        : RunFeeling.values.byName(json['feeling'] as String),
    notes: json['notes'] as String?,
    clientUuid: json['clientUuid'] as String?,
    syncStatus: TrainingSyncStatus.values.byName(
      json['syncStatus'] as String? ?? TrainingSyncStatus.synced.name,
    ),
    syncError: json['syncError'] as String?,
  );

  final String id;
  final DateTime startedAt;
  final DateTime finishedAt;
  final double distanceKm;
  final Duration elapsed;
  final Duration movingTime;
  final Duration avgPacePerKm;
  final double elevationGainM;
  final double avgSpeedKmh;
  final List<GeoPoint> route;
  final List<KmSplit> splits;
  final SessionType type;
  final String title;
  final int? avgHeartRate;
  final int? calories;
  final RunFeeling? feeling;
  final String? notes;
  final String? clientUuid;
  final TrainingSyncStatus syncStatus;
  final String? syncError;

  KmSplit? get fastestSplit =>
      splits.isEmpty ? null : splits.reduce((a, b) => a.pace <= b.pace ? a : b);

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.millisecondsSinceEpoch,
    'finishedAt': finishedAt.millisecondsSinceEpoch,
    'distanceKm': distanceKm,
    'elapsed': elapsed.inSeconds,
    'movingTime': movingTime.inSeconds,
    'avgPace': avgPacePerKm.inSeconds,
    'elevation': elevationGainM,
    'avgSpeed': avgSpeedKmh,
    'route': [for (final p in route) p.toJson()],
    'splits': [for (final s in splits) s.toJson()],
    'type': type.name,
    'title': title,
    'hr': avgHeartRate,
    'calories': calories,
    'feeling': feeling?.name,
    'notes': notes,
    'clientUuid': clientUuid,
    'syncStatus': syncStatus.name,
    'syncError': syncError,
  };

  TrainingRun copyWith({
    RunFeeling? feeling,
    String? notes,
    String? clientUuid,
    TrainingSyncStatus? syncStatus,
    String? syncError,
  }) => TrainingRun(
    id: id,
    startedAt: startedAt,
    finishedAt: finishedAt,
    distanceKm: distanceKm,
    elapsed: elapsed,
    movingTime: movingTime,
    avgPacePerKm: avgPacePerKm,
    elevationGainM: elevationGainM,
    avgSpeedKmh: avgSpeedKmh,
    route: route,
    splits: splits,
    type: type,
    title: title,
    avgHeartRate: avgHeartRate,
    calories: calories,
    feeling: feeling ?? this.feeling,
    notes: notes ?? this.notes,
    clientUuid: clientUuid ?? this.clientUuid,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError ?? this.syncError,
  );
}
