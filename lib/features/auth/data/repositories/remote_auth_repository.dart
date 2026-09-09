import 'package:camrun/core/db/app_database.dart';
import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/network/session_controller.dart';
import 'package:camrun/core/services/google_sign_in_service.dart';
import 'package:camrun/core/storage/token_storage.dart';
import 'package:camrun/core/utils/result.dart';
import 'package:camrun/features/auth/data/datasources/auth_api.dart';
import 'package:camrun/features/auth/data/models/auth_models.dart';
import 'package:camrun/features/auth/domain/repositories/auth_repository.dart';

/// `/auth/*` de verdad. Aqui se decide lo que el [AuthApi] no decide: cuando se
/// guardan los tokens y cuando se borra lo local.
class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({
    required this.api,
    required this.session,
    required this.storage,
    required this.db,
    required this.google,
  });

  final AuthApi api;
  final SessionController session;
  final TokenStorage storage;
  final AppDatabase db;
  final GoogleSignInService google;

  @override
  Future<Result<AuthUser>> signIn({
    required String identifier,
    required String password,
  }) => guard(
    () => _entrar(() => api.login(identifier: identifier, password: password)),
  );

  @override
  Future<Result<AuthUser>> signUp({
    required String password,
    String? fullName,
    String? email,
    String? ci,
    DateTime? birthDate,
    String? gender,
  }) => guard(
    () => _entrar(
      () => api.register(
        name: fullName,
        password: password,
        email: email,
        ci: ci,
        birthDate: birthDate,
        gender: gender,
      ),
    ),
  );

  /// Cancelar el dialogo devuelve `null` sin tocar la sesion: no hay nada que
  /// guardar ni nada que contarle al usuario, que ya sabe lo que hizo.
  @override
  Future<Result<AuthUser?>> signInWithGoogle() => guard(() async {
    final idToken = await google.idToken();
    if (idToken == null) return null;
    return _entrar(() => api.google(idToken));
  });

  @override
  Future<Result<AuthUser>> currentUser() => guard(api.me);

  /// El cambio **no** cierra esta sesion —lo garantiza el servidor— asi que no
  /// hay que reescribir tokens: basta con releer el usuario para que
  /// `mustChangePassword` deje de bloquear la navegacion.
  @override
  Future<Result<AuthUser>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => guard(() async {
    await api.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    return api.me();
  });

  /// Los tokens se guardan **antes** de cualquier otra llamada: `/auth/me` ya
  /// necesita ir firmada.
  Future<AuthUser> _entrar(Future<AuthSession> Function() login) async {
    final sesion = await login();
    await session.saveTokens(
      accessToken: sesion.accessToken,
      refreshToken: sesion.refreshToken,
    );
    return sesion.user ?? await api.me();
  }

  /// Cerrar sesion **siempre** limpia el dispositivo, responda el servidor lo
  /// que responda: si falla la llamada, el peor caso es un refresh token vivo
  /// en el servidor que ya nadie tiene. Al reves —tokens que se quedan en el
  /// telefono porque no habia red— es la cache de un usuario visible para el
  /// siguiente.
  @override
  Future<Result<void>> signOut() => guard(() async {
    final refresh = await storage.readRefreshToken();
    try {
      if (refresh != null && refresh.isNotEmpty) await api.logout(refresh);
    } on Failure catch (_) {
      // Sin red o token ya muerto: da igual, lo local se borra igual.
    }
    // Sin esto la proxima vez Google entra sola con la cuenta anterior, sin
    // dar opcion a elegir otra.
    await google.signOut();
    await session.clear();
    await db.wipe();
  });

  /// El borrado local solo ocurre si el servidor confirmo el borrado remoto:
  /// al reves —limpiar y que la peticion falle— dejaria la cuenta viva y al
  /// usuario convencido de que ya no existe.
  @override
  Future<Result<void>> deleteAccount(String? password) => guard(() async {
    await api.deleteAccount(password);
    await session.clear();
    await db.wipe();
  });
}
