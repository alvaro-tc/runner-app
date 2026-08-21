import 'package:dio/dio.dart';
import 'package:paceup/core/network/api_client.dart';
import 'package:paceup/core/utils/uuid.dart';

/// Habla con `/races/*`, `/registrations/*` y `/payments/*`.
///
/// Los tres van juntos porque son un solo recorrido del usuario: inscribirse
/// (tres pasos), pagar y, cuando llega el dia, correr. Partirlo en tres
/// clientes obligaria al repositorio a coserlos igual, con una capa mas.
///
/// Devuelve el JSON crudo: quien lo convierte en entidades es el repositorio.
class RacesApi {
  RacesApi(this._dio);

  final Dio _dio;

  // ─── Mis carreras ────────────────────────────────────────────────────────

  /// Solo inscripciones **confirmadas**: un borrador a medias no es una carrera.
  Future<List<Map<String, dynamic>>> myRaces() => apiCall(() async {
    final res = await _dio.get<dynamic>('/races/me');
    return (res.data as List).cast<Map<String, dynamic>>();
  });

  /// Cuantas se corrieron, cuanto suman y cuanto se gasto.
  ///
  /// El gasto sale de los **cobros**, no de los precios de catalogo: un precio
  /// cambia y un cobro no, asi que sumar precios mostraria un total que nadie
  /// pago. Por eso no se deriva de la lista.
  Future<Map<String, dynamic>> summary() => apiCall(() async {
    final res = await _dio.get<dynamic>('/races/me/summary');
    return res.data as Map<String, dynamic>;
  });

  /// Detalle con recorrido y parciales. La clave es el id de la **inscripcion**.
  Future<Map<String, dynamic>> race(String registrationId) => apiCall(() async {
    final res = await _dio.get<dynamic>('/races/$registrationId');
    return res.data as Map<String, dynamic>;
  });

  /// Intentos de cobro de una inscripcion, del mas nuevo al mas viejo.
  /// Rechazos incluidos: es lo que se pinta junto al estado del pago.
  Future<List<Map<String, dynamic>>> paymentsOf(String registrationId) =>
      apiCall(() async {
        final res = await _dio.get<dynamic>(
          '/registrations/$registrationId/payments',
        );
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  // ─── Inscripcion, en tres pasos ──────────────────────────────────────────

  /// Paso 1. Idempotente del lado del servidor: si ya hay un borrador para esa
  /// maraton lo devuelve actualizado en vez de abrir un segundo.
  Future<Map<String, dynamic>> createDraft({
    required String marathonId,
    required Map<String, Object?> personalData,
  }) => apiCall(() async {
    final res = await _dio.post<dynamic>(
      '/registrations',
      data: {'marathonId': marathonId, 'personalData': personalData},
    );
    return res.data as Map<String, dynamic>;
  });

  /// Paso 2. La lista de extras **reemplaza** a la anterior: se manda entera.
  Future<Map<String, dynamic>> setCategoryAndExtras({
    required String registrationId,
    String? categoryId,
    required List<Map<String, Object?>> extras,
  }) => apiCall(() async {
    final res = await _dio.patch<dynamic>(
      '/registrations/$registrationId/category-extras',
      data: {'categoryId': categoryId, 'extras': extras},
    );
    return res.data as Map<String, dynamic>;
  });

  /// El total en vivo. **El movil no suma precios**: los calcula el servidor,
  /// que es el que despues cobra.
  Future<Map<String, dynamic>> quote(String registrationId) =>
      apiCall(() async {
        final res = await _dio.get<dynamic>(
          '/registrations/$registrationId/quote',
        );
        return res.data as Map<String, dynamic>;
      });

  /// Paso 3: acepta terminos, cobra, reserva cupo y asigna dorsal.
  ///
  /// [idempotencyKey] la genera el cliente y **tiene que sobrevivir** a un
  /// reintento: repetir el cobro con la misma clave devuelve el mismo resultado
  /// en vez de cobrar dos veces. Por eso se recibe en vez de generarse aqui.
  Future<Map<String, dynamic>> checkout({
    required String registrationId,
    required String method,
    required String idempotencyKey,
    Map<String, Object?>? card,
  }) => apiCall(() async {
    final res = await _dio.post<dynamic>(
      '/registrations/$registrationId/checkout',
      data: {'termsAccepted': true, 'method': method, 'card': ?card},
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return res.data as Map<String, dynamic>;
  });

  /// Sondeo del QR y de la transferencia: cada lectura resuelve el cobro si ya
  /// toca. Se deja de sondear cuando `status` sale de `pending`.
  Future<Map<String, dynamic>> payment(String paymentId) => apiCall(() async {
    final res = await _dio.get<dynamic>('/payments/$paymentId');
    return res.data as Map<String, dynamic>;
  });

  Future<void> cancel(String registrationId) =>
      apiCall(() => _dio.delete<dynamic>('/registrations/$registrationId'));

  /// Clave de idempotencia para un cobro. Un uuid v4 sirve: lo unico que se le
  /// pide es no repetirse entre intentos distintos.
  static String newIdempotencyKey() => uuidV4();
}
