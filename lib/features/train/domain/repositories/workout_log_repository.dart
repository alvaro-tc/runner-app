import 'package:camrun/core/utils/result.dart';
import 'package:camrun/features/train/domain/entities/workout_log.dart';

/// El historial de entrenamientos que vive en el servidor (`/workouts`).
///
/// Aparte de [TrainingRepository], que es la caja local donde la grabacion en
/// curso cae antes de tener red: aqui solo se lee lo que ya esta consolidado,
/// con las metricas que calculo el servidor.
abstract interface class WorkoutLogRepository {
  /// Del mas reciente al mas viejo. [cursor] nulo = primera pagina.
  Future<Result<WorkoutPage>> history({
    WorkoutKind? kind,
    String? cursor,
    int limit,
  });

  Future<Result<WorkoutDetail>> detail(String id);

  /// De la mas vieja a la mas reciente; la ultima es la semana en curso.
  Future<Result<List<WeekStats>>> weeklyStats({int count});

  Future<Result<void>> delete(String id);
}
