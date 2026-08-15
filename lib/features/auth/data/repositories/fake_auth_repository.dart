import 'package:paceup/core/error/failure.dart';
import 'package:paceup/core/utils/result.dart';
import 'package:paceup/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Accepts any well-formed credentials and remembers the session locally.
/// Replacing this with a real backend means implementing the same interface.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._prefs);

  static const _key = 'auth.signedIn';

  final SharedPreferences _prefs;

  @override
  bool get isAuthenticated => _prefs.getBool(_key) ?? false;

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) => guard(() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (password.length < 8) {
      throw const ValidationFailure(
        'That password is too short. Use at least 8 characters.',
      );
    }
    await _prefs.setBool(_key, true);
  });

  @override
  Future<Result<void>> signUp({
    required String fullName,
    required String email,
    required String password,
  }) => guard(() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    await _prefs.setBool(_key, true);
  });

  @override
  Future<Result<void>> signOut() => guard(() => _prefs.setBool(_key, false));
}
