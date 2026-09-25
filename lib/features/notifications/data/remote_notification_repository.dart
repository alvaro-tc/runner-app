import 'package:camrun/core/network/api_client.dart';
import 'package:camrun/core/storage/token_storage.dart';
import 'package:camrun/core/utils/result.dart';
import 'package:camrun/features/notifications/domain/notifications.dart';
import 'package:dio/dio.dart';

/// Habla con `/notifications`. Cuatro llamadas: no justifican un `Api` aparte.
class RemoteNotificationRepository implements NotificationRepository {
  const RemoteNotificationRepository(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  @override
  Future<Result<NotificationInbox>> fetchInbox() => guard(
    () => apiCall(() async {
      final res = await _dio.get<dynamic>('/notifications');
      final data = res.data as Map<String, dynamic>;
      return (
        items: [
          for (final j in (data['items'] as List).cast<Map<String, dynamic>>())
            AppNotification.fromJson(j),
        ],
        unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
      );
    }),
  );

  @override
  Future<Result<void>> markRead(String id) =>
      guard(() => apiCall(() => _dio.post<dynamic>('/notifications/$id/read')));

  @override
  Future<Result<void>> markAllRead() =>
      guard(() => apiCall(() => _dio.post<dynamic>('/notifications/read-all')));

  @override
  Future<Result<void>> registerPushToken(String token) => guard(
    () => apiCall(
      () async => _dio.put<dynamic>(
        '/notifications/push-token',
        data: {'deviceId': await _storage.deviceId(), 'token': token},
      ),
    ),
  );
}
