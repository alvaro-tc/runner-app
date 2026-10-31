import 'package:meta/meta.dart';

/// Lo que el servidor llama `WorkoutType`.
///
/// El valor de alambre va en la propia constante: el historial se filtra por
/// `?type=` y una tabla de conversion aparte es una cosa mas que se olvida de
/// actualizar cuando el backend suma un tipo.
enum WorkoutKind {
  freeRun('free_run'),
  planSession('plan_session'),
  goalDistance('goal_distance'),
  goalTime('goal_time'),
  race('race');

  const WorkoutKind(this.wire);
  final String wire;

  static WorkoutKind fromWire(String? value) => values.firstWhere(
    (kind) => kind.wire == value,
    orElse: () => WorkoutKind.freeRun,
  );
}

/// `WorkoutSource` del servidor. `external` es palabra reservada en Dart, de
/// ahi [imported].
enum WorkoutOrigin {
  app('app'),
  manual('manual'),
  imported('external');

  const WorkoutOrigin(this.wire);
  final String wire;

  static WorkoutOrigin fromWire(String? value) => values.firstWhere(
    (origin) => origin.wire == value,
    orElse: () => WorkoutOrigin.app,
  );

  /// Sin recorrido: los numeros son los que declaro el usuario.
  bool get isManual => this == WorkoutOrigin.manual;
}

/// Como se sintio la salida, 1 a 5 como lo guarda el servidor.
enum RunMood {
  awful(1, '\u{1F616}'),
  tired(2, '\u{1F615}'),
  okay(3, '\u{1F610}'),
  good(4, '\u{1F642}'),
  great(5, '\u{1F525}');

  const RunMood(this.score, this.emoji);
  final int score;
  final String emoji;

  static RunMood? fromScore(int? score) {
    if (score == null) return null;
    for (final mood in values) {
      if (mood.score == score) return mood;
    }
    return null;
  }
}

/// Una salida ya terminada, tal como la devuelve `GET /workouts`.
///
/// Sin recorrido a proposito: el listado del servidor no trae puntos y pedir
/// el trazado de cada fila para pintar una miniatura costaria una llamada por
/// tarjeta.
@immutable
class WorkoutLog {
  const WorkoutLog({
    required this.id,
    required this.kind,
    required this.origin,
    required this.startedAt,
    required this.distanceKm,
    required this.duration,
    required this.movingTime,
    required this.elevationGainM,
    this.clientUuid,
    this.endedAt,
    this.avgPace,
    this.calories,
    this.mood,
    this.planSessionId,
    this.registrationId,
  });

  final String id;
  final String? clientUuid;
  final WorkoutKind kind;
  final WorkoutOrigin origin;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double distanceKm;

  /// Reloj de pared, del primer al ultimo punto.
  final Duration duration;

  /// Descontado el tiempo parado.
  final Duration movingTime;
  final double elevationGainM;

  /// Nulo cuando la salida no llego ni a un kilometro.
  final Duration? avgPace;
  final int? calories;
  final RunMood? mood;
  final String? planSessionId;
  final String? registrationId;

  bool get isRace => kind == WorkoutKind.race;

  /// Si esto fue de verdad una salida.
  ///
  /// El servidor guarda un entrenamiento al **arrancar** la sesion, asi que
  /// una que se abrio y se descarto —o que se cerro sin una sola posicion—
  /// queda en el historial con cero metros y, si nunca se cerro, sin
  /// [endedAt]. Eso no es una salida de 0,0 km: es una salida que no paso, y
  /// en la lista no pinta nada.
  ///
  /// El minuto de margen deja pasar lo que si cuenta: una entrada a mano de
  /// cinta, que trae tiempo y no trae metros.
  bool get isRecorded =>
      endedAt != null &&
      (distanceKm >= 0.01 || duration >= const Duration(minutes: 1));

  double get avgSpeedKmh => movingTime.inSeconds == 0
      ? 0
      : distanceKm / (movingTime.inSeconds / 3600);
}

/// Un kilometro del recorrido. `index` es base 0: el 0 es el primer kilometro.
@immutable
class WorkoutSplit {
  const WorkoutSplit({
    required this.index,
    required this.distanceKm,
    required this.duration,
    required this.pace,
    required this.elevationGainM,
  });

  final int index;
  final double distanceKm;
  final Duration duration;
  final Duration pace;
  final double elevationGainM;

  /// El ultimo parcial casi nunca es un kilometro entero.
  bool get isPartial => distanceKm < 0.95;
}

/// El detalle de `GET /workouts/:id`: la salida mas sus parciales.
@immutable
class WorkoutDetail {
  const WorkoutDetail({
    required this.log,
    required this.splits,
    this.bestKmIndex,
    this.avgSpeedKmh,
    this.notes,
  });

  final WorkoutLog log;
  final List<WorkoutSplit> splits;
  final int? bestKmIndex;
  final double? avgSpeedKmh;
  final String? notes;

  WorkoutSplit? get slowestSplit {
    final full = [
      for (final split in splits)
        if (!split.isPartial) split,
    ];
    if (full.isEmpty) return null;
    return full.reduce((a, b) => a.pace >= b.pace ? a : b);
  }
}

/// Una pagina del historial. El cursor es opaco: viaja tal cual al servidor.
@immutable
class WorkoutPage {
  const WorkoutPage({required this.items, this.nextCursor});

  final List<WorkoutLog> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}

/// Una casilla de la tira lunes-domingo.
@immutable
class DayStat {
  const DayStat({
    required this.weekday,
    required this.distanceKm,
    required this.movingTime,
    required this.workouts,
  });

  /// 1 = lunes … 7 = domingo.
  final int weekday;
  final double distanceKm;
  final Duration movingTime;
  final int workouts;
}

/// Los totales de una semana, con sus siete casillas (los ceros incluidos).
@immutable
class WeekStats {
  const WeekStats({
    required this.startsAt,
    required this.endsAt,
    required this.distanceKm,
    required this.movingTime,
    required this.duration,
    required this.workouts,
    required this.days,
    this.avgPace,
  });

  final DateTime startsAt;

  /// El lunes siguiente. Exclusivo.
  final DateTime endsAt;
  final double distanceKm;
  final Duration movingTime;
  final Duration duration;
  final int workouts;
  final Duration? avgPace;
  final List<DayStat> days;

  bool get isCurrent {
    final now = DateTime.now();
    return now.isAfter(startsAt) && now.isBefore(endsAt);
  }

  double get bestDayKm => days.fold<double>(
    0,
    (max, day) => day.distanceKm > max ? day.distanceKm : max,
  );
}
