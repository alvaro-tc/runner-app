import 'package:camrun/core/utils/result.dart';
import 'package:camrun/features/train/data/datasources/workouts_api.dart';
import 'package:camrun/features/train/data/mappers/workout_mappers.dart';
import 'package:camrun/features/train/domain/entities/workout_log.dart';
import 'package:camrun/features/train/domain/repositories/workout_log_repository.dart';

class RemoteWorkoutLogRepository implements WorkoutLogRepository {
  const RemoteWorkoutLogRepository(this._api);

  final WorkoutsApi _api;

  @override
  Future<Result<WorkoutPage>> history({
    WorkoutKind? kind,
    String? cursor,
    int limit = 20,
  }) => guard(() async {
    final page = await _api.list(
      type: kind?.wire,
      cursor: cursor,
      limit: limit,
    );
    return WorkoutPage(
      // Las sesiones que no grabaron nada se caen aqui y no en la pantalla:
      // asi tampoco las cuenta la que pida el historial despues.
      items: [
        for (final raw in page.items)
          if (WorkoutMappers.log(raw) case final log when log.isRecorded) log,
      ],
      nextCursor: page.nextCursor,
    );
  });

  @override
  Future<Result<WorkoutDetail>> detail(String id) =>
      guard(() async => WorkoutMappers.detail(await _api.detail(id)));

  @override
  Future<Result<List<WeekStats>>> weeklyStats({int count = 8}) =>
      guard(() async => WorkoutMappers.weeks(await _api.weekly(weeks: count)));

  @override
  Future<Result<void>> delete(String id) => guard(() => _api.delete(id));
}
