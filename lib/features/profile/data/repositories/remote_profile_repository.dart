import 'package:paceup/core/db/app_database.dart';
import 'package:paceup/core/sync/offline_first.dart';
import 'package:paceup/core/utils/result.dart';
import 'package:paceup/features/profile/data/datasources/profile_api.dart';
import 'package:paceup/features/profile/data/profile_mappers.dart';
import 'package:paceup/features/profile/domain/entities/user_profile.dart';
import 'package:paceup/features/profile/domain/repositories/profile_repository.dart';

class RemoteProfileRepository implements ProfileRepository {
  RemoteProfileRepository(this.api, this.db);

  final ProfileApi api;
  final AppDatabase db;

  @override
  Future<Result<UserProfile>> fetch() => guard(
    () => readThrough(
      db: db,
      key: 'profile.current',
      fetch: api.me,
      parse: profileFromApi,
    ).last,
  );

  @override
  Future<Result<UserProfile>> save(UserProfile profile) => guard(() async {
    final response = await api.updateMe(profilePatch(profile));
    await db.writeDoc('profile.current', response);
    return profileFromApi(response);
  });
}
