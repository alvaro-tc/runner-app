import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceup/app/app.dart';
import 'package:paceup/app/dependencies.dart';
import 'package:paceup/core/constants/fake_data_seed.dart';
import 'package:paceup/core/services/location_service.dart';
import 'package:paceup/core/services/preferences_provider.dart';
import 'package:paceup/core/utils/result.dart';
import 'package:paceup/features/home/presentation/providers/home_provider.dart';
import 'package:paceup/features/train/domain/entities/training_run.dart';
import 'package:paceup/features/train/domain/repositories/training_repository.dart';
import 'package:paceup/shared/widgets/atoms/app_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory stand-in for the Hive-backed repository, so widget tests never
/// touch the file system.
class InMemoryTrainingRepository implements TrainingRepository {
  InMemoryTrainingRepository([List<TrainingRun>? seed])
    : _runs = {for (final run in seed ?? FakeDataSeed.runs) run.id: run};

  final Map<String, TrainingRun> _runs;

  @override
  Future<Result<List<TrainingRun>>> fetchHistory() async => Result.success(
    _runs.values.toList()..sort((a, b) => b.startedAt.compareTo(a.startedAt)),
  );

  @override
  Future<Result<TrainingRun>> fetchById(String id) async =>
      Result.success(_runs[id]!);

  @override
  Future<Result<TrainingRun>> save(TrainingRun run) async {
    _runs[run.id] = run;
    return Result.success(run);
  }

  @override
  Future<Result<void>> delete(String id) async {
    _runs.remove(id);
    return const Result.success(null);
  }
}

/// Boots the real app with test doubles for anything that needs a platform.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(instance),
      trainingRepositoryProvider.overrideWithValue(
        InMemoryTrainingRepository(),
      ),
      // Replay a canned route instead of asking the device for GPS.
      useSimulatedLocationProvider.overrideWithValue(true),
      // A live clock would make the Home countdown golden change every minute.
      nowProvider.overrideWithValue(() => DateTime(2026, 8, 15, 9, 30)),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const PaceUpApp()),
  );
  return container;
}

/// Home runs a one-second countdown and the fake repositories add latency, so
/// the tree never goes quiet. Navigating away lets both wind down before the
/// test framework checks for pending timers.
Future<void> drainHome(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

/// Scrolls the primary CTA into view and taps it. Auth screens are taller than
/// the test surface, so a blind tap would miss.
Future<void> tapSubmit(WidgetTester tester, String label) async {
  final button = find.byWidgetPredicate(
    (w) => w is AppButton && w.label == label && w.onPressed != null,
  );
  await tester.ensureVisible(button.last);
  await tester.pumpAndSettle();
  await tester.tap(button.last);
}
