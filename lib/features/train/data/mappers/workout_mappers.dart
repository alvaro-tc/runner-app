import 'package:camrun/features/train/domain/entities/workout_log.dart';

/// JSON de `/workouts` a entidades.
///
/// Las unidades se traducen aqui, una sola vez: el servidor habla en metros y
/// segundos, la app en kilometros y [Duration]. Que cada pantalla divida por
/// mil es como se cuela un cero de mas.
abstract final class WorkoutMappers {
  static WorkoutLog log(Map<String, dynamic> json) => WorkoutLog(
    id: json['id'] as String,
    clientUuid: json['clientUuid'] as String?,
    kind: WorkoutKind.fromWire(json['type'] as String?),
    origin: WorkoutOrigin.fromWire(json['source'] as String?),
    startedAt: _date(json['startedAt'])!,
    endedAt: _date(json['endedAt']),
    distanceKm: _num(json['distanceMeters']) / 1000,
    duration: _seconds(json['durationSeconds']),
    movingTime: _seconds(json['movingSeconds']),
    elevationGainM: _num(json['elevationGainMeters']),
    avgPace: _optionalSeconds(json['avgPaceSecPerKm']),
    calories: (json['calories'] as num?)?.round(),
    mood: RunMood.fromScore((json['feeling'] as num?)?.round()),
    planSessionId: json['planSessionId'] as String?,
    registrationId: json['registrationId'] as String?,
  );

  static WorkoutDetail detail(Map<String, dynamic> json) => WorkoutDetail(
    log: log(json),
    splits: [
      for (final raw in (json['splits'] as List? ?? const []))
        split(Map<String, dynamic>.from(raw as Map)),
    ],
    bestKmIndex: (json['bestKmIndex'] as num?)?.toInt(),
    avgSpeedKmh: json['avgSpeedMps'] == null
        ? null
        : _num(json['avgSpeedMps']) * 3.6,
    notes: json['notes'] as String?,
  );

  static WorkoutSplit split(Map<String, dynamic> json) => WorkoutSplit(
    index: (json['index'] as num).toInt(),
    distanceKm: _num(json['distanceMeters']) / 1000,
    duration: _seconds(json['durationSeconds']),
    pace: _seconds(json['paceSecPerKm']),
    elevationGainM: _num(json['elevationGainMeters']),
  );

  /// `GET /workouts/stats/weekly`. Llega de la semana mas vieja a la actual y
  /// se devuelve en ese mismo orden: la tira se lee de izquierda a derecha.
  static List<WeekStats> weeks(Map<String, dynamic> json) => [
    for (final raw in (json['weeks'] as List? ?? const []))
      week(Map<String, dynamic>.from(raw as Map)),
  ];

  static WeekStats week(Map<String, dynamic> json) {
    final days = {
      for (final raw in (json['days'] as List? ?? const []))
        (raw as Map)['weekday'] as int: DayStat(
          weekday: raw['weekday'] as int,
          distanceKm: _num(raw['distanceMeters']) / 1000,
          movingTime: _seconds(raw['movingSeconds']),
          workouts: (raw['workouts'] as num?)?.toInt() ?? 0,
        ),
    };
    return WeekStats(
      startsAt: _date(json['weekStartsAt'])!,
      endsAt: _date(json['weekEndsAt'])!,
      distanceKm: _num(json['distanceMeters']) / 1000,
      movingTime: _seconds(json['movingSeconds']),
      duration: _seconds(json['durationSeconds']),
      workouts: (json['workouts'] as num?)?.toInt() ?? 0,
      avgPace: _optionalSeconds(json['avgPaceSecPerKm']),
      // Siempre siete casillas: la que el servidor no manda es un cero, no un
      // hueco, y la barra vacia del martes es tan informativa como las otras.
      days: [
        for (var weekday = 1; weekday <= 7; weekday++)
          days[weekday] ??
              DayStat(
                weekday: weekday,
                distanceKm: 0,
                movingTime: Duration.zero,
                workouts: 0,
              ),
      ],
    );
  }

  static double _num(Object? value) => (value as num?)?.toDouble() ?? 0;

  static Duration _seconds(Object? value) =>
      Duration(seconds: (value as num?)?.round() ?? 0);

  static Duration? _optionalSeconds(Object? value) =>
      value == null ? null : Duration(seconds: (value as num).round());

  /// En horario local: el historial se agrupa por dia y por mes, y agrupar en
  /// UTC manda la salida del domingo por la tarde al lunes.
  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.parse(value as String).toLocal();
}
