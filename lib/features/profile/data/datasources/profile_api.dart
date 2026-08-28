import 'package:camrun/core/network/api_client.dart';
import 'package:dio/dio.dart';

class ProfileApi {
  ProfileApi(this._dio);

  final Dio _dio;

  /// El perfil completo de la pantalla. El servidor lo reparte en tres
  /// endpoints (`/users/me`, `/highlights`, `/health`) y aqui se juntan en un
  /// solo documento, que es lo que la cache guarda y el mapper entiende.
  ///
  /// Solo `/users/me` es obligatorio: si falla uno de los dos complementos, la
  /// pantalla sale igual con sus tarjetas a cero en vez de con un error.
  Future<Map<String, dynamic>> me() => apiCall(() async {
    final results = await Future.wait([
      _get('/users/me'),
      _optional('/users/me/highlights'),
      _optional('/users/me/health'),
    ]);
    return {
      ...(results[0]! as Map).cast<String, dynamic>(),
      'highlights': results[1],
      'health': results[2],
    };
  });

  Future<Map<String, dynamic>> updateMe(Map<String, Object?> patch) =>
      apiCall(() async {
        final data = await _get('/users/me', method: 'PATCH', body: patch);
        return (data! as Map).cast<String, dynamic>();
      });

  /// Sube la foto de perfil. Devuelve solo `{avatarUrl}`, no el perfil entero.
  Future<String> uploadAvatar(String filePath) => apiCall(() async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post<dynamic>('/users/me/avatar', data: form);
    return ((res.data as Map)['avatarUrl'] as String?) ?? '';
  });

  Future<Map<String, dynamic>> updateHealth(Map<String, Object?> patch) =>
      apiCall(() async {
        final data = await _get(
          '/users/me/health',
          method: 'PATCH',
          body: patch,
        );
        return (data! as Map).cast<String, dynamic>();
      });

  Future<Map<String, dynamic>> preferences() => apiCall(() async {
    final data = await _get('/users/me/preferences');
    return (data! as Map).cast<String, dynamic>();
  });

  Future<Map<String, dynamic>> updatePreferences(Map<String, Object?> patch) =>
      apiCall(() async {
        final data = await _get(
          '/users/me/preferences',
          method: 'PATCH',
          body: patch,
        );
        return (data! as Map).cast<String, dynamic>();
      });

  Future<Object?> _get(
    String path, {
    String method = 'GET',
    Object? body,
  }) async {
    final res = await _dio.request<dynamic>(
      path,
      data: body,
      options: Options(method: method),
    );
    return res.data;
  }

  /// Un complemento que no vale un error de pantalla.
  Future<Object?> _optional(String path) async {
    try {
      return await _get(path);
    } on Object {
      return null;
    }
  }
}
