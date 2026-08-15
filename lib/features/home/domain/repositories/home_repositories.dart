import 'package:paceup/core/utils/result.dart';
import 'package:paceup/features/home/domain/entities/marathon.dart';
import 'package:paceup/features/home/domain/entities/training_plan.dart';

abstract interface class MarathonRepository {
  Future<Result<List<Marathon>>> fetchAll();
  Future<Result<Marathon>> fetchById(String id);

  /// The marathon the countdown on Home points at.
  Future<Result<Marathon>> fetchFeatured();
}

abstract interface class TrainingPlanRepository {
  Future<Result<TrainingPlan>> fetchPlan();

  /// Marks the session complete (or not) and returns the updated plan.
  Future<Result<TrainingPlan>> setSessionCompleted({
    required String sessionId,
    required bool completed,
  });
}
