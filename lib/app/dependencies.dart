import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paceup/core/network/network_providers.dart';
import 'package:paceup/core/sync/sync_providers.dart';
import 'package:paceup/features/auth/data/repositories/remote_auth_repository.dart';
import 'package:paceup/features/auth/domain/repositories/auth_repository.dart';
import 'package:paceup/features/home/data/datasources/home_api.dart';
import 'package:paceup/features/home/data/repositories/remote_home_repositories.dart';
import 'package:paceup/features/home/domain/repositories/home_repositories.dart';
import 'package:paceup/features/profile/data/datasources/profile_api.dart';
import 'package:paceup/features/profile/data/repositories/remote_profile_repository.dart';
import 'package:paceup/features/profile/domain/repositories/profile_repository.dart';
import 'package:paceup/features/races/data/datasources/races_api.dart';
import 'package:paceup/features/races/data/repositories/remote_race_repository.dart';
import 'package:paceup/features/races/domain/repositories/race_repository.dart';
import 'package:paceup/features/train/domain/repositories/training_repository.dart';

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
