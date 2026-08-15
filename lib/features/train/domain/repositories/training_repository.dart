import 'package:paceup/core/utils/result.dart';
import 'package:paceup/features/train/domain/entities/training_run.dart';

abstract interface class TrainingRepository {
  /// Newest first.
  Future<Result<List<TrainingRun>>> fetchHistory();

  Future<Result<TrainingRun>> fetchById(String id);

  Future<Result<TrainingRun>> save(TrainingRun run);

  Future<Result<void>> delete(String id);
}
