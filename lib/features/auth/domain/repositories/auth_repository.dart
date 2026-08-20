import 'package:paceup/core/utils/result.dart';
import 'package:paceup/features/auth/data/models/auth_models.dart';

abstract interface class AuthRepository {
  /// Devuelve el usuario porque trae `onboardingSeenAt`: quien ya vio los
  /// slides en otro telefono no vuelve a verlos aqui.
  Future<Result<AuthUser>> signIn({
    required String email,
    required String password,
  });

  Future<Result<AuthUser>> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();
}
