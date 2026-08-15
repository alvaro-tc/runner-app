import 'package:paceup/core/utils/result.dart';

abstract interface class AuthRepository {
  bool get isAuthenticated;

  Future<Result<void>> signIn({
    required String email,
    required String password,
  });

  Future<Result<void>> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();
}
