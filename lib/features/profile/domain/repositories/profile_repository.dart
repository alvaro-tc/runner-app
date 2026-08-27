import 'package:camrun/core/utils/result.dart';
import 'package:camrun/features/profile/domain/entities/user_profile.dart';

abstract interface class ProfileRepository {
  Future<Result<UserProfile>> fetch();
  Future<Result<UserProfile>> save(UserProfile profile);
}
