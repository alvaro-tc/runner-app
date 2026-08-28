import 'package:camrun/core/network/network_providers.dart';
import 'package:camrun/core/services/preferences_provider.dart';
import 'package:camrun/core/sync/sync_providers.dart';
import 'package:camrun/features/auth/data/repositories/remote_auth_repository.dart';
import 'package:camrun/features/auth/domain/repositories/auth_repository.dart';
import 'package:camrun/features/home/data/datasources/home_api.dart';
import 'package:camrun/features/home/data/repositories/remote_home_repositories.dart';
import 'package:camrun/features/home/domain/repositories/home_repositories.dart';
import 'package:camrun/features/profile/data/repositories/local_profile_repository.dart';
import 'package:camrun/features/profile/domain/repositories/profile_repository.dart';
import 'package:camrun/features/races/data/datasources/races_api.dart';
import 'package:camrun/features/races/data/repositories/remote_race_repository.dart';
import 'package:camrun/features/races/domain/repositories/race_repository.dart';
import 'package:camrun/features/train/domain/repositories/training_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The dependency container. Every provider here is typed against a domain
/// interface, so pointing the app at a real backend is a one-line change per
/// repository — `FakeMarathonRepository()` becomes `RemoteMarathonRepository(client)`
/// and nothing above the data layer moves.

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => RemoteAuthRepository(
    api: ref.watch(authApiProvider),
    session: ref.watch(sessionControllerProvider),
    storage: ref.watch(tokenStorageProvider),
    db: ref.watch(appDatabaseProvider),
  ),
);

final homeApiProvider = Provider<HomeApi>(
  (ref) => HomeApi(ref.watch(dioProvider)),
);

final marathonRepositoryProvider = Provider<MarathonRepository>(
  (ref) => RemoteMarathonRepository(
    ref.watch(homeApiProvider),
    ref.watch(appDatabaseProvider),
  ),
);

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => RemoteHomeRepository(
    ref.watch(homeApiProvider),
    ref.watch(appDatabaseProvider),
  ),
);

final racesApiProvider = Provider<RacesApi>(
  (ref) => RacesApi(ref.watch(dioProvider)),
);

final raceRepositoryProvider = Provider<RaceRepository>(
  (ref) => RemoteRaceRepository(ref.watch(racesApiProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => RemoteProfileRepository(
    ProfileApi(ref.watch(dioProvider)),
    ref.watch(appDatabaseProvider),
  ),
);

/// Backed by Hive, whose box has to be opened before the first frame — the
/// concrete instance is injected from `bootstrap()`.
final trainingRepositoryProvider = Provider<TrainingRepository>(
  (ref) => throw StateError(
    'trainingRepositoryProvider must be overridden in bootstrap()',
  ),
);
