import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paceup/core/services/preferences_provider.dart';
import 'package:paceup/features/auth/data/repositories/fake_auth_repository.dart';
import 'package:paceup/features/auth/domain/repositories/auth_repository.dart';
import 'package:paceup/features/home/data/repositories/fake_home_repositories.dart';
import 'package:paceup/features/home/domain/repositories/home_repositories.dart';
import 'package:paceup/features/profile/data/repositories/local_profile_repository.dart';
import 'package:paceup/features/profile/domain/repositories/profile_repository.dart';
import 'package:paceup/features/races/data/repositories/fake_race_repository.dart';
import 'package:paceup/features/races/domain/repositories/race_repository.dart';
import 'package:paceup/features/train/domain/repositories/training_repository.dart';

/// The dependency container. Every provider here is typed against a domain
/// interface, so pointing the app at a real backend is a one-line change per
/// repository — `FakeMarathonRepository()` becomes `RemoteMarathonRepository(client)`
/// and nothing above the data layer moves.

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FakeAuthRepository(ref.watch(sharedPreferencesProvider)),
);

final marathonRepositoryProvider = Provider<MarathonRepository>(
  (ref) => FakeMarathonRepository(),
);

final trainingPlanRepositoryProvider = Provider<TrainingPlanRepository>(
  (ref) => FakeTrainingPlanRepository(),
);

final raceRepositoryProvider = Provider<RaceRepository>(
  (ref) => FakeRaceRepository(),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => LocalProfileRepository(ref.watch(sharedPreferencesProvider)),
);

/// Backed by Hive, whose box has to be opened before the first frame — the
/// concrete instance is injected from `bootstrap()`.
final trainingRepositoryProvider = Provider<TrainingRepository>(
  (ref) => throw StateError(
    'trainingRepositoryProvider must be overridden in bootstrap()',
  ),
);
