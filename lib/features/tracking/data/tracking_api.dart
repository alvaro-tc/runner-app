import 'package:dio/dio.dart';
import 'package:paceup/core/network/api_client.dart';
import 'package:paceup/core/storage/token_storage.dart';
import 'package:paceup/features/tracking/data/models/tracking_models.dart';

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

}
