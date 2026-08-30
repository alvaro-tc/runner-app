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

  // ─── Categorias y extras ─────────────────────────────────────────────────
  //
  // Son tablas propias, no campos de la maraton: se crean y se borran al
  // momento con su propio endpoint, como el afiche. Meterlas en el boton de
  // guardar obligaria a inventar ids en el movil para algo que solo el
  // servidor puede numerar.

  Future<void> createCategory(String marathonId, Map<String, dynamic> body) =>
      apiCall(
        () async => _dio.post<dynamic>(
          '/admin/marathons/$marathonId/categories',
          data: body,
        ),
      );

  Future<void> updateCategory(String categoryId, Map<String, dynamic> body) =>
      apiCall(
        () async =>
            _dio.put<dynamic>('/admin/categories/$categoryId', data: body),
      );

  /// Las inscripciones que la usaban no se borran: se quedan sin categoria,
  /// con su dorsal y su pago intactos.
  Future<void> deleteCategory(String categoryId) => apiCall(
    () async => _dio.delete<dynamic>('/admin/categories/$categoryId'),
  );

  Future<void> createExtra(String marathonId, Map<String, dynamic> body) =>
      apiCall(
        () async => _dio.post<dynamic>(
          '/admin/marathons/$marathonId/extras',
          data: body,
        ),
      );

  Future<void> updateExtra(String extraId, Map<String, dynamic> body) =>
      apiCall(
        () async => _dio.put<dynamic>('/admin/extras/$extraId', data: body),
      );

  /// Lo ya vendido no se pierde —vive copiado en cada inscripcion—: borrarlo
  /// solo significa que deja de poder comprarse.
  Future<void> deleteExtra(String extraId) =>
      apiCall(() async => _dio.delete<dynamic>('/admin/extras/$extraId'));

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

  /// Una pagina de usuarios, con el total que cumple el filtro.
  ///
  /// El rol, la busqueda y la pagina van al servidor: la lista no viene entera
  /// —son 20 por defecto—, asi que filtrar o cortar aqui dejaria fuera a quien
  /// no entre en la primera pagina. La busqueda cubre nombre, correo, CI y el
  /// celular que la persona dejo al inscribirse.
  Future<({List<Map<String, dynamic>> filas, int total})> users({
    String? search,
    String? role,
    int page = 1,
    int pageSize = 20,
  }) => apiCall(() async {
    final res = await _dio.get<dynamic>(
      '/admin/users',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'q': search,
        'role': ?role,
        'page': page,
        'pageSize': pageSize,
      },
    );
    final filas = (res.data as List).cast<Map<String, dynamic>>();
    final meta = res.extra['meta'];
    // Sin `meta.total` no se puede pintar el rango; que haya una pagina llena
    // es lo unico que se sabe, y eso es lo que se dice.
    final total = meta is Map ? (meta['total'] as num?)?.toInt() : null;
    return (filas: filas, total: total ?? filas.length);
  });

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
