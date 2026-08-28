import 'package:dio/dio.dart';
import 'package:paceup/core/network/api_client.dart';

class ProfileApi {
  ProfileApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> me() => apiCall(() async {
    final response = await _dio.get<dynamic>('/me');
    return (response.data as Map).cast<String, dynamic>();
  });

  Future<Map<String, dynamic>> updateMe(Map<String, Object?> patch) =>
      apiCall(() async {
        final response = await _dio.patch<dynamic>('/me', data: patch);
        return (response.data as Map).cast<String, dynamic>();
      });
}
