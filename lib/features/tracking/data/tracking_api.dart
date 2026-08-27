import 'package:camrun/core/network/api_client.dart';
import 'package:camrun/core/storage/token_storage.dart';
import 'package:camrun/features/tracking/data/models/tracking_models.dart';
import 'package:dio/dio.dart';

/// Habla con `/workouts/sessions/*` y con la ingesta de posiciones.
class TrackingApi {
  TrackingApi(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  /// `clientUuid` lo genera el telefono antes de tener red: repetir la llamada
  /// con el mismo valor devuelve la sesion que ya existe, no una segunda.
  Future<StartedSession> start({
    required String clientUuid,
    String type = 'free_run',
    String? planSessionId,
    String? registrationId,
    DateTime? startedAt,
  }) => apiCall(() async {
    final res = await _dio.post<dynamic>(
      '/workouts/sessions',
      data: {
        'clientUuid': clientUuid,
        'type': type,
        'planSessionId': ?planSessionId,
        'registrationId': ?registrationId,
        if (startedAt != null) 'startedAt': startedAt.toUtc().toIso8601String(),
        'deviceId': await _storage.deviceId(),
      },
      options: Options(headers: {'Idempotency-Key': clientUuid}),
    );
    return StartedSession.fromApi(res.data as Map<String, dynamic>);
  });

  Future<void> pause(String sessionId) =>
      apiCall(() => _dio.patch<dynamic>('/workouts/sessions/$sessionId/pause'));

  Future<void> resume(String sessionId) => apiCall(
    () => _dio.patch<dynamic>('/workouts/sessions/$sessionId/resume'),
  );

  /// Los numeros del cliente se mandan para comparar; las metricas buenas las
  /// calcula el servidor con los puntos que recibio.
  Future<Map<String, dynamic>> finish(
    String sessionId, {
    Map<String, Object?>? clientReported,
    int? feeling,
    String? notes,
  }) => apiCall(() async {
    final res = await _dio.post<dynamic>(
      '/workouts/sessions/$sessionId/finish',
      data: {
        'clientReported': ?clientReported,
        'feeling': ?feeling,
        'notes': ?notes,
      },
      options: Options(headers: {'Idempotency-Key': 'finish-$sessionId'}),
    );
    return res.data as Map<String, dynamic>;
  });

  Future<void> discard(String sessionId) =>
      apiCall(() => _dio.delete<dynamic>('/workouts/sessions/$sessionId'));

  /// Sube un lote de puntos.
  ///
  /// Se autentica con el `ingestToken` de la sesion, **no** con el JWT: el
  /// credencial que sale del telefono cada veinte segundos durante una carrera
  /// tiene que ser el de menor alcance posible.
  Future<IngestResult> sendPositions({
    required String sessionId,
    required String ingestToken,
    required List<Map<String, Object?>> points,
  }) => apiCall(() async {
    final res = await _dio.post<dynamic>(
      '/tracking/sessions/$sessionId/positions',
      data: {'points': points},
      options: Options(headers: {'Authorization': 'Bearer $ingestToken'}),
    );
    return IngestResult.fromJson(res.data as Map<String, dynamic>);
  });
}
