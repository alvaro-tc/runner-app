import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceup/app/app.dart';
import 'package:paceup/app/dependencies.dart';
import 'package:paceup/core/constants/fake_data_seed.dart';
import 'package:paceup/core/db/app_database.dart';
import 'package:paceup/core/network/api_client.dart';
import 'package:paceup/core/network/network_providers.dart';
import 'package:paceup/core/services/location_service.dart';
import 'package:paceup/core/services/preferences_provider.dart';
import 'package:paceup/core/storage/token_storage.dart';
import 'package:paceup/core/sync/sync_providers.dart';
import 'package:paceup/core/utils/result.dart';
import 'package:paceup/features/auth/presentation/providers/auth_provider.dart';
import 'package:paceup/features/home/presentation/providers/home_provider.dart';
import 'package:paceup/features/train/domain/entities/training_run.dart';
import 'package:paceup/features/train/domain/repositories/training_repository.dart';
import 'package:paceup/shared/widgets/atoms/app_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/fake_http.dart';
import 'fake_api.dart';

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

/// Tokens en memoria: en los tests no hay Keychain ni Keystore.
class MemoryTokenStorage implements TokenStorage {
  String? access;
  String? refresh;

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    access = null;
    refresh = null;
  }

  @override
  Future<String> deviceId() async => 'device-test';
}

/// Boots the real app with test doubles for anything that needs a platform.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  bool signedIn = false,
  Future<ResponseBody> Function(RequestOptions)? api,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(instance),
      initialSessionProvider.overrideWithValue(signedIn),
      // En memoria: `driftDatabase` pide un directorio al sistema y en un test
      // de widget no hay plataforma que lo de.
      appDatabaseProvider.overrideWith((ref) {
        final db = AppDatabase(NativeDatabase.memory());
        ref.onDispose(db.close);
        return db;
      }),
      tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
      // Ni un socket sale de un test de widget.
      dioProvider.overrideWith((ref) {
        return buildApiClient(
          session: ref.watch(sessionControllerProvider),
          clock: ref.watch(serverClockProvider),
        )..httpClientAdapter = FakeAdapter(api ?? fakeBackend);
      }),
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
