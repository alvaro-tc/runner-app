import 'dart:convert';

import 'package:paceup/core/constants/fake_data_seed.dart';
import 'package:paceup/core/utils/result.dart';
import 'package:paceup/features/profile/domain/entities/user_profile.dart';
import 'package:paceup/features/profile/domain/repositories/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Profile edits persist to shared preferences, so a restart shows whatever the
/// user last saved rather than the seed.
class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(this._prefs);

  static const _key = 'profile.current';

  final SharedPreferences _prefs;

  @override
  Future<Result<UserProfile>> fetch() => guard(() async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final raw = _prefs.getString(_key);
    if (raw == null) return FakeDataSeed.profile;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  });

  @override
  Future<Result<UserProfile>> save(UserProfile profile) => guard(() async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    await _prefs.setString(_key, jsonEncode(profile.toJson()));
    return profile;
  });
}
