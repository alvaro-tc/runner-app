import 'package:camrun/core/network/api_client.dart';
import 'package:camrun/core/utils/result.dart';
import 'package:camrun/features/notifications/domain/notifications.dart';
import 'package:dio/dio.dart';

/// Habla con `/notifications`. Tres llamadas: no justifican un `Api` aparte.
class RemoteNotificationRepository implements NotificationRepository {
  const RemoteNotificationRepository(this._dio);

  final Dio _dio;

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
}
