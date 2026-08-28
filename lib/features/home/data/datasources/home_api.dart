import 'package:camrun/core/network/api_client.dart';
import 'package:dio/dio.dart';

/// `/home/*`, `/marathons/*` y las sesiones del plan. Devuelve el JSON crudo:
/// quien lo convierte en entidades es el repositorio, que ademas lo cachea tal
/// cual llego.
class HomeApi {
  HomeApi(this.dio);

  final Dio dio;

  Future<Map<String, dynamic>> summary({bool fresco = false}) =>
      apiCall(() async {
        final res = await dio.get<dynamic>(
          '/home/summary',
          options: fresco
              ? Options(headers: {'Cache-Control': 'no-cache'})
              : null,
        );
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> planWeek(int week) => apiCall(() async {
    final res = await dio.get<dynamic>(
      '/training-plans/me/current',
      queryParameters: {'week': week},
    );
    return res.data as Map<String, dynamic>;
  });

  Future<void> completeSession(String id) => apiCall(() async {
    await dio.patch<dynamic>('/training-plans/sessions/$id/complete');
  });

  /// Las que todavia no largaron, de la mas cercana a la mas lejana. Es lo que
  /// pide el carrusel de Home: el catalogo entero viene paginado y con las
  /// pasadas dentro.
  Future<List<Map<String, dynamic>>> upcomingMarathons({int limit = 8}) =>
      apiCall(() async {
        final res = await dio.get<dynamic>(
          '/marathons/upcoming',
          queryParameters: {'limit': limit},
        );
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  /// Acepta id o slug: la API resuelve los dos.
  Future<Map<String, dynamic>> marathon(String idOrSlug) => apiCall(() async {
    final res = await dio.get<dynamic>('/marathons/$idOrSlug');
    return res.data as Map<String, dynamic>;
  });
}
