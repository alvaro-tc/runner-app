import 'package:camrun/core/network/api_client.dart';
import 'package:camrun/core/storage/token_storage.dart';
import 'package:camrun/features/auth/data/models/auth_models.dart';
import 'package:dio/dio.dart';

/// Habla con `/auth/*`. No decide nada: guardar tokens y navegar es del
/// repositorio (Fase 22).
class AuthApi {
  AuthApi(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  Future<Map<String, dynamic>> _device() async => {
    'deviceId': await _storage.deviceId(),
  };

  /// Hace falta **email o CI**, no los dos. El correo es opcional porque hay
  /// corredores que no tienen; la CI es lo que despues cruza un pago hecho en
  /// la web con esta misma cuenta.
  Future<AuthSession> register({
    required String name,
    required String password,
    String? email,
    String? ci,
  }) => apiCall(() async {
    final res = await _dio.post<dynamic>(
      '/auth/register',
      data: {
        'name': name,
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
        if (ci != null && ci.isNotEmpty) 'ci': ci,
        ...await _device(),
      },
    );
    return AuthSession.fromJson(res.data as Map<String, dynamic>);
  });

  /// [identifier] es email **o** CI. Quien decide cual es el servidor, por el
  /// `@`: la app no tiene por que saber con cual se dio de alta el usuario.
  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) => apiCall(() async {
    final res = await _dio.post<dynamic>(
      '/auth/login',
      data: {
        'identifier': identifier,
        'password': password,
        ...await _device(),
      },
    );
    return AuthSession.fromJson(res.data as Map<String, dynamic>);
  });

  /// Cerrar sesion es idempotente: si el token ya no vale, tampoco pasa nada.
  Future<void> logout(String refreshToken) => apiCall(() async {
    await _dio.post<dynamic>(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  });

  Future<AuthUser> me() => apiCall(() async {
    final res = await _dio.get<dynamic>('/auth/me');
    return AuthUser.fromJson(res.data as Map<String, dynamic>);
  });

  Future<List<DeviceSession>> sessions() => apiCall(() async {
    final res = await _dio.get<dynamic>('/auth/sessions');
    return (res.data as List)
        .map((e) => DeviceSession.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  Future<void> revokeSession(String id) =>
      apiCall(() async => _dio.delete<dynamic>('/auth/sessions/$id'));

  Future<void> forgotPassword(String email) => apiCall(
    () async =>
        _dio.post<dynamic>('/auth/forgot-password', data: {'email': email}),
  );

  Future<void> resetPassword({
    required String token,
    required String password,
  }) => apiCall(
    () async => _dio.post<dynamic>(
      '/auth/reset-password',
      data: {'token': token, 'password': password},
    ),
  );

  /// Cambia la contrasena con la sesion abierta. Cierra **las demas** sesiones
  /// y deja viva esta, asi que no hay que volver a loguearse.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => apiCall(
    () async => _dio.post<dynamic>(
      '/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    ),
  );

  /// Borra la cuenta y todo lo del usuario en el servidor. Pide la contrasena
  /// otra vez porque es irreversible y el telefono puede estar en otras manos.
  Future<void> deleteAccount(String password) => apiCall(
    () async => _dio.delete<dynamic>(
      '/auth/me',
      data: {'password': password},
    ),
  );
}
