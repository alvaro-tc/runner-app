import 'package:camrun/core/network/api_client.dart';
import 'package:dio/dio.dart';

/// Habla con `/workouts`: el historial ya consolidado por el servidor.
///
/// La ingesta de la sesion en curso no esta aqui —vive en `TrackingApi`—: esto
/// es solo lectura mas el borrado de una salida.
///
/// Devuelve el JSON crudo; quien lo convierte en entidades es el repositorio.
class WorkoutsApi {
  WorkoutsApi(this._dio);

  final Dio _dio;

  /// Una pagina del historial. El `nextCursor` viaja en el `meta` del sobre,
  /// que el interceptor deja en `response.extra` al abrirlo.
  Future<({List<Map<String, dynamic>> items, String? nextCursor})> list({
    String? type,
    String? cursor,
    int limit = 20,
  }) => apiCall(() async {
    final res = await _dio.get<dynamic>(
      '/workouts',
      queryParameters: {'limit': limit, 'type': ?type, 'cursor': ?cursor},
    );
    final meta = res.extra['meta'];
    return (
      items: (res.data as List).cast<Map<String, dynamic>>(),
      nextCursor: meta is Map ? meta['nextCursor'] as String? : null,
    );
  });

  /// Detalle con los parciales por kilometro.
  Future<Map<String, dynamic>> detail(String id) => apiCall(() async {
    final res = await _dio.get<dynamic>('/workouts/$id');
    return res.data as Map<String, dynamic>;
  });

  /// Resumen semanal, de la semana mas vieja a la actual.
  Future<Map<String, dynamic>> weekly({int weeks = 8}) => apiCall(() async {
    final res = await _dio.get<dynamic>(
      '/workouts/stats/weekly',
      queryParameters: {'weeks': weeks},
    );
    return res.data as Map<String, dynamic>;
  });

  /// Borrado logico del lado del servidor.
  Future<void> delete(String id) =>
      apiCall(() => _dio.delete<dynamic>('/workouts/$id'));
}
