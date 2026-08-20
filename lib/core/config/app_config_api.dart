import 'package:dio/dio.dart';
import 'package:paceup/core/config/app_config.dart';
import 'package:paceup/core/network/api_client.dart';

/// Publico, sin token. Es lo primero que se pide al arrancar.
class AppConfigApi {
  AppConfigApi(this._dio);

  final Dio _dio;

  Future<AppConfig> fetch() => apiCall(() async {
    final res = await _dio.get<dynamic>('/config/app');
    return AppConfig.fromJson(res.data as Map<String, dynamic>);
  });
}
