import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:paceup/core/constants/fake_data_seed.dart';
import 'package:paceup/core/error/failure.dart';
import 'package:paceup/core/utils/result.dart';
import 'package:paceup/features/train/domain/entities/training_run.dart';
import 'package:paceup/features/train/domain/repositories/training_repository.dart';

/// Run history lives in a Hive box keyed by run id, with each run stored as a
/// JSON string. It is seeded once on first launch so the app has a history to
/// show, and every later save survives a restart.
class HiveTrainingRepository implements TrainingRepository {
  HiveTrainingRepository(this._box);

  static const boxName = 'training_runs';
  static const _seededKey = '__seeded__';

  final Box<String> _box;

  static Future<HiveTrainingRepository> open() async {
    final box = await Hive.openBox<String>(boxName);
    final repo = HiveTrainingRepository(box);
    if (!box.containsKey(_seededKey)) {
      await box.put(_seededKey, 'v1');
      for (final run in FakeDataSeed.runs) {
        await box.put(run.id, jsonEncode(run.toJson()));
      }
    }
    return repo;
  }

  @override
  Future<Result<List<TrainingRun>>> fetchHistory() => guard(() async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final runs =
        _box.keys
            .whereType<String>()
            .where((k) => k != _seededKey)
            .map((k) => _decode(_box.get(k)!))
            .toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return runs;
  });

  @override
  Future<Result<TrainingRun>> fetchById(String id) => guard(() async {
    final raw = _box.get(id);
    if (raw == null) {
      throw const NotFoundFailure('That run is not in your history any more.');
    }
    return _decode(raw);
  });

  @override
  Future<Result<TrainingRun>> save(TrainingRun run) => guard(() async {
    await _box.put(run.id, jsonEncode(run.toJson()));
    return run;
  });

  @override
  Future<Result<void>> delete(String id) => guard(() => _box.delete(id));

  TrainingRun _decode(String raw) =>
      TrainingRun.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
