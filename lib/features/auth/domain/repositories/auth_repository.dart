import 'package:paceup/core/utils/result.dart';
import 'package:paceup/features/auth/data/models/auth_models.dart';

abstract interface class AuthRepository {
  /// Devuelve el usuario porque trae `onboardingSeenAt` —quien ya vio los
  /// slides en otro telefono no vuelve a verlos aqui— y `mustChangePassword`,
  /// que decide si lo primero que ve es la pantalla de cambio de contrasena.
  ///
  /// [identifier] es email **o** CI: quien lo distingue es el servidor.
  Future<Result<AuthUser>> signIn({
    required String identifier,
    required String password,
  });

  /// Hace falta **email o CI**, no los dos.
  Future<Result<AuthUser>> signUp({
    required String fullName,
    required String password,
    String? email,
    String? ci,
  });

  /// El usuario de la sesion guardada. Se pide al arrancar: `mustChangePassword`
  /// puede haber cambiado desde el ultimo login y no vive en el dispositivo.
  Future<Result<AuthUser>> currentUser();

  /// Cambia la contrasena de quien ya esta dentro. Devuelve el usuario ya con
  /// `mustChangePassword` en false.
  Future<Result<AuthUser>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<Result<void>> signOut();
}
