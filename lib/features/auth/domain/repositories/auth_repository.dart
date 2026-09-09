import 'package:camrun/core/utils/result.dart';
import 'package:camrun/features/auth/data/models/auth_models.dart';

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
    required String password,
    String? fullName,
    String? email,
    String? ci,
    DateTime? birthDate,
    String? gender,
  });

  /// Entra —o se da de alta, que para Google es lo mismo— con la cuenta de
  /// Google que elija el usuario en el dialogo del sistema.
  ///
  /// `null` cuando cierra el dialogo sin elegir: cancelar no es un fallo.
  Future<Result<AuthUser?>> signInWithGoogle();

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

  /// Borra la cuenta en el servidor y deja el dispositivo como recien
  /// instalado. Irreversible: pide la contrasena para confirmar que es el
  /// dueno quien lo pide.
  ///
  /// [password] va en `null` en las cuentas de Google, que no tienen: el
  /// servidor solo la exige a quien tiene una.
  Future<Result<void>> deleteAccount(String? password);
}
