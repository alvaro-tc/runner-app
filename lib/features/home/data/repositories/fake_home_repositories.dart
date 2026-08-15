import 'package:paceup/core/constants/fake_data_seed.dart';
import 'package:paceup/core/error/failure.dart';
import 'package:paceup/core/utils/result.dart';
import 'package:paceup/features/home/domain/entities/marathon.dart';
import 'package:paceup/features/home/domain/entities/training_plan.dart';
import 'package:paceup/features/home/domain/repositories/home_repositories.dart';

/// Simulated network latency, so loading states are actually exercised.
const _latency = Duration(milliseconds: 550);

class FakeMarathonRepository implements MarathonRepository {
  @override
  Future<Result<List<Marathon>>> fetchAll() => guard(() async {
    await Future<void>.delayed(_latency);
    return FakeDataSeed.marathons;
  });

  @override
  Future<Result<Marathon>> fetchById(String id) => guard(() async {
    await Future<void>.delayed(_latency);
    final match = FakeDataSeed.marathons.where((m) => m.id == id);
    if (match.isEmpty) {
      throw const NotFoundFailure('That event is no longer listed.');
    }
    return match.first;
  });

  @override
  Future<Result<Marathon>> fetchFeatured() => guard(() async {
    await Future<void>.delayed(_latency);
    return FakeDataSeed.featuredMarathon;
  });
}

class FakeTrainingPlanRepository implements TrainingPlanRepository {
  TrainingPlan _plan = FakeDataSeed.plan;

  @override
  Future<Result<TrainingPlan>> fetchPlan() => guard(() async {
    await Future<void>.delayed(_latency);
    return _plan;
  });

  @override
  Future<Result<TrainingPlan>> setSessionCompleted({
    required String sessionId,
    required bool completed,
  }) => guard(() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    _plan = TrainingPlan(
      id: _plan.id,
      name: _plan.name,
      activeWeekIndex: _plan.activeWeekIndex,
      weeks: [
        for (final week in _plan.weeks)
          TrainingWeek(
            index: week.index,
            startDate: week.startDate,
            sessions: [
              for (final session in week.sessions)
                if (session.id == sessionId)
                  session.copyWith(
                    isCompleted: completed,
                    completionRatio: completed ? 1 : 0,
                  )
                else
                  session,
            ],
          ),
      ],
    );
    return _plan;
  });
}
