import 'package:dio/dio.dart';
import 'package:paceup/core/network/api_client.dart';
import 'package:paceup/core/storage/token_storage.dart';
import 'package:paceup/features/auth/data/models/auth_models.dart';

/// Habla con `/auth/*`. No decide nada: guardar tokens y navegar es del
/// repositorio (Fase 22).
class AuthApi {
  AuthApi(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  Future<Map<String, dynamic>> _device() async => {
    'deviceId': await _storage.deviceId(),
  };

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) => apiCall(() async {
    final res = await _dio.post<dynamic>(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        ...await _device(),
      },
    );
    return AuthSession.fromJson(res.data as Map<String, dynamic>);
  });

  Future<AuthSession> login({
    required String email,
    required String password,
  }) => apiCall(() async {
    final res = await _dio.post<dynamic>(
      '/auth/login',
      data: {'email': email, 'password': password, ...await _device()},
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
}
