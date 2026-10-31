import 'package:camrun/features/train/data/mappers/workout_mappers.dart';
import 'package:camrun/features/train/domain/entities/workout_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutMappers.log', () {
    test('pasa metros y segundos del servidor a km y Duration', () {
      final log = WorkoutMappers.log({
        'id': 'w1',
        'clientUuid': 'uuid-1',
        'type': 'goal_distance',
        'source': 'app',
        'startedAt': '2026-10-25T13:00:00.000Z',
        'endedAt': '2026-10-25T13:50:05.000Z',
        'distanceMeters': 10_043,
        'durationSeconds': 3005,
        'movingSeconds': 2980,
        'avgPaceSecPerKm': 297,
        'elevationGainMeters': 148,
        'calories': 412,
        'feeling': 4,
      });

      expect(log.distanceKm, closeTo(10.043, 0.0001));
      expect(log.duration, const Duration(seconds: 3005));
      expect(log.movingTime, const Duration(seconds: 2980));
      expect(log.avgPace, const Duration(seconds: 297));
      expect(log.kind, WorkoutKind.goalDistance);
      expect(log.mood, RunMood.good);
    });

    test('aguanta los nulos del resumen y un tipo que no conoce', () {
      final log = WorkoutMappers.log({
        'id': 'w2',
        'type': 'something_new',
        'startedAt': '2026-10-25T13:00:00.000Z',
        'endedAt': null,
        'distanceMeters': 0,
        'durationSeconds': 0,
        'movingSeconds': 0,
        'elevationGainMeters': 0,
        'avgPaceSecPerKm': null,
        'calories': null,
        'feeling': null,
      });

      expect(log.kind, WorkoutKind.freeRun);
      expect(log.avgPace, isNull);
      expect(log.mood, isNull);
      expect(log.avgSpeedKmh, 0);
    });
  });

  test('WorkoutMappers.week rellena los dias que el servidor no manda', () {
    final week = WorkoutMappers.week({
      'weekStartsAt': '2026-10-19T04:00:00.000Z',
      'weekEndsAt': '2026-10-26T04:00:00.000Z',
      'distanceMeters': 21_000,
      'movingSeconds': 7200,
      'durationSeconds': 7400,
      'workouts': 2,
      'avgPaceSecPerKm': 342,
      'days': [
        {
          'weekday': 3,
          'startsAt': '2026-10-21T04:00:00.000Z',
          'distanceMeters': 11_000,
          'movingSeconds': 3600,
          'workouts': 1,
        },
      ],
    });

    expect(week.days, hasLength(7));
    expect(week.days.map((day) => day.weekday), [1, 2, 3, 4, 5, 6, 7]);
    expect(week.days[2].distanceKm, 11);
    expect(week.days[0].distanceKm, 0);
    expect(week.days[0].workouts, 0);
    expect(week.bestDayKm, 11);
  });

  group('WorkoutLog.isRecorded', () {
    WorkoutLog log({
      double km = 0,
      Duration duration = Duration.zero,
      bool finished = true,
    }) => WorkoutLog(
      id: 'w',
      kind: WorkoutKind.freeRun,
      origin: WorkoutOrigin.app,
      startedAt: DateTime(2026, 10, 25, 7),
      endedAt: finished ? DateTime(2026, 10, 25, 8) : null,
      distanceKm: km,
      duration: duration,
      movingTime: duration,
      elevationGainM: 0,
    );

    test('una sesion abierta y descartada no es una salida', () {
      expect(log().isRecorded, isFalse);
      expect(log(km: 8, finished: false).isRecorded, isFalse);
    });

    test('pasa lo que si se corrio, y la entrada a mano sin metros', () {
      expect(
        log(km: 0.4, duration: const Duration(minutes: 3)).isRecorded,
        isTrue,
      );
      expect(log(duration: const Duration(minutes: 30)).isRecorded, isTrue);
    });
  });

  test('WorkoutDetail.slowestSplit ignora el parcial incompleto', () {
    final detail = WorkoutDetail(
      log: _log,
      splits: const [
        WorkoutSplit(
          index: 0,
          distanceKm: 1,
          duration: Duration(seconds: 300),
          pace: Duration(seconds: 300),
          elevationGainM: 0,
        ),
        WorkoutSplit(
          index: 1,
          distanceKm: 1,
          duration: Duration(seconds: 320),
          pace: Duration(seconds: 320),
          elevationGainM: 0,
        ),
        // Los ultimos 300 m a ritmo imposible: no es el km mas lento ni el mas
        // rapido, es un kilometro que no existe.
        WorkoutSplit(
          index: 2,
          distanceKm: 0.3,
          duration: Duration(seconds: 150),
          pace: Duration(seconds: 500),
          elevationGainM: 0,
        ),
      ],
    );

    expect(detail.slowestSplit?.index, 1);
  });
}

final _log = WorkoutLog(
  id: 'w3',
  kind: WorkoutKind.freeRun,
  origin: WorkoutOrigin.app,
  startedAt: _startedAt,
  distanceKm: 2.3,
  duration: const Duration(seconds: 770),
  movingTime: const Duration(seconds: 770),
  elevationGainM: 0,
);

final _startedAt = DateTime(2026, 10, 25, 7);
