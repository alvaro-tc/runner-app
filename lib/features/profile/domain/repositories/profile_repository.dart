import 'package:camrun/core/utils/result.dart';
import 'package:camrun/features/profile/domain/entities/user_profile.dart';

abstract interface class ProfileRepository {
  Future<Result<UserProfile>> fetch();
  Future<Result<UserProfile>> save(UserProfile profile);

  /// Sube la foto de perfil y devuelve el perfil ya con su nueva `avatarUrl`.
  Future<Result<UserProfile>> uploadAvatar(String filePath);

  Future<Result<UserProfile>> saveHealth({
    required List<Injury> injuries,
    required Duration sleep,
  });

  Future<Result<ProfilePreferences>> fetchPreferences();
  Future<Result<ProfilePreferences>> savePreferences(ProfilePreferences prefs);
}
