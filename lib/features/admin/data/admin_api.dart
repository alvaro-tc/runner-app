import 'package:camrun/core/network/api_client.dart';
import 'package:dio/dio.dart';

/// Habla con `/admin/*`. Un solo cliente para todo el panel: son secciones de
/// una misma pantalla de gestion y partirlo en tres obligaria a coserlos otra
/// vez una capa mas arriba.
///
/// Devuelve el JSON crudo; quien lo convierte en entidades es el provider.
class AdminApi {
  AdminApi(this._dio);

  final Dio _dio;

  // ─── Maratones ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> marathons() => apiCall(() async {
    final res = await _dio.get<dynamic>('/admin/marathons');
    return (res.data as List).cast<Map<String, dynamic>>();
  });

  Future<Map<String, dynamic>> marathon(String id) => apiCall(() async {
    final res = await _dio.get<dynamic>('/admin/marathons/$id');
    return res.data as Map<String, dynamic>;
  });

  Future<Map<String, dynamic>> createMarathon(Map<String, dynamic> body) =>
      apiCall(() async {
        final res = await _dio.post<dynamic>('/admin/marathons', data: body);
        return res.data as Map<String, dynamic>;
      });

  /// Parcial: lo que no venga en [body] no se toca.
  Future<Map<String, dynamic>> updateMarathon(
    String id,
    Map<String, dynamic> body,
  ) => apiCall(() async {
    final res = await _dio.put<dynamic>('/admin/marathons/$id', data: body);
    return res.data as Map<String, dynamic>;
  });

  Future<void> deleteMarathon(String id) =>
      apiCall(() async => _dio.delete<dynamic>('/admin/marathons/$id'));

  /// Publicar o retirar del catalogo. Retirar no cancela inscripciones.
  Future<void> setPublished(String id, bool published) => apiCall(() async {
    final accion = published ? 'publish' : 'unpublish';
    await _dio.post<dynamic>('/admin/marathons/$id/$accion');
  });

  /// Abrir o cerrar inscripciones.
  Future<void> setRegistrationsOpen(String id, bool open) => apiCall(() async {
    final accion = open ? 'reopen-registrations' : 'close-registrations';
    await _dio.post<dynamic>('/admin/marathons/$id/$accion');
  });

  /// Sube la foto de la maraton: el afiche que el corredor ve en el catalogo.
  ///
  /// Es la unica imagen que se sube. El QR de cobro no: de su foto se saca el
  /// texto en el movil y viaja como un campo mas por [updateMarathon].
  ///
  /// No hay variante con URL a proposito. Un enlace a un servidor ajeno se
  /// rompe sin avisar y deja la carrera sin cartel; subiendola, el archivo es
  /// nuestro. El servidor la reencoda y devuelve el detalle ya actualizado.
  Future<Map<String, dynamic>> uploadCover(String id, String filePath) =>
      apiCall(() async {
        final form = FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath),
        });
        final res = await _dio.post<dynamic>(
          '/admin/marathons/$id/cover',
          data: form,
        );
        return res.data as Map<String, dynamic>;
      });

  // ─── Largada en vivo ─────────────────────────────────────────────────────

  /// Da la largada. La hora la pone el servidor: si cada telefono arrancara
  /// con su reloj, dos corredores del mismo peloton tendrian tiempos distintos.
  Future<Map<String, dynamic>> startMarathon(String id) => apiCall(() async {
    final res = await _dio.post<dynamic>('/admin/marathons/$id/start');
    return res.data as Map<String, dynamic>;
  });

  Future<Map<String, dynamic>> finishMarathon(String id) => apiCall(() async {
    final res = await _dio.post<dynamic>('/admin/marathons/$id/finish');
    return res.data as Map<String, dynamic>;
  });

  /// Foto de donde va cada corredor. Es lo que llena el mapa al **abrirlo**;
  /// despues las posiciones llegan por el socket.
  Future<Map<String, dynamic>> live(String id) => apiCall(() async {
    final res = await _dio.get<dynamic>('/admin/marathons/$id/live');
    return res.data as Map<String, dynamic>;
  });

  // ─── Usuarios ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> users({String? search}) => apiCall(
    () async {
      final res = await _dio.get<dynamic>(
        '/admin/users',
        queryParameters: {if (search != null && search.isNotEmpty) 'q': search},
      );
      return (res.data as List).cast<Map<String, dynamic>>();
    },
  );

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> body) =>
      apiCall(() async {
        final res = await _dio.post<dynamic>('/admin/users', data: body);
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> updateUser(
    String id,
    Map<String, dynamic> body,
  ) => apiCall(() async {
    final res = await _dio.put<dynamic>('/admin/users/$id', data: body);
    return res.data as Map<String, dynamic>;
  });

  Future<void> setPassword(String id, String password) => apiCall(() async {
    await _dio.post<dynamic>(
      '/admin/users/$id/password',
      data: {'password': password},
    );
  });

  Future<void> deleteUser(String id) =>
      apiCall(() async => _dio.delete<dynamic>('/admin/users/$id'));
}
