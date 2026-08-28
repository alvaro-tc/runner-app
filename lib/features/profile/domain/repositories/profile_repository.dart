import 'package:camrun/core/utils/result.dart';
import 'package:camrun/features/profile/domain/entities/user_profile.dart';

abstract interface class ProfileRepository {
  Future<Result<UserProfile>> fetch();
  Future<Result<UserProfile>> save(UserProfile profile);

  /// Sube la foto de perfil y devuelve el perfil ya con su nueva `avatarUrl`.
  Future<Result<UserProfile>> uploadAvatar(String filePath);

  /// Anade una zapatilla y devuelve el perfil con la lista ya al dia.
  Future<Result<UserProfile>> addShoe({
    required String brand,
    required String model,
    required double retireAtKm,
  });

  /// Retira una zapatilla: en el servidor deja de existir.
  Future<Result<UserProfile>> removeShoe(String id);

  Future<Result<UserProfile>> saveHealth({
    required List<Injury> injuries,
    required Duration sleep,
    required HydrationHabit hydration,
  });

  Future<Result<ProfilePreferences>> fetchPreferences();
  Future<Result<ProfilePreferences>> savePreferences(ProfilePreferences prefs);
}
