import 'package:dio/dio.dart';
import 'package:paceup/core/error/failure.dart';
import 'package:paceup/core/network/api_config.dart';
import 'package:paceup/core/network/interceptors.dart';
import 'package:paceup/core/network/server_clock.dart';
import 'package:paceup/core/network/session_controller.dart';

BaseOptions _options(String baseUrl) => BaseOptions(
  baseUrl: baseUrl,
  connectTimeout: connectTimeout,
  receiveTimeout: receiveTimeout,
  headers: const {'Accept': 'application/json'},
  // Los 4xx no son excepciones de transporte: el sobre de error trae el codigo
  // y quien lo interpreta es [ErrorInterceptor].
  validateStatus: (s) => s != null && s < 400,
);

/// Dio pelado para el refresh. Sin interceptores a proposito: si los tuviera,
/// un 401 de `/auth/refresh` dispararia otro refresh en bucle.
Dio buildRefreshClient({String? baseUrl}) =>
    Dio(_options(baseUrl ?? apiBaseUrl));

/// El Dio de toda la app. Un solo cliente, con los interceptores en orden:
/// auth, refresh, reintento, sobre, errores y log.
Dio buildApiClient({
  required SessionController session,
  required ServerClock clock,
  String? baseUrl,
}) {
  final dio = Dio(_options(baseUrl ?? apiBaseUrl));
  dio.interceptors.addAll([
    AuthInterceptor(session),
    RefreshInterceptor(session, dio),
    RetryInterceptor(dio),
    EnvelopeInterceptor(clock),
    ErrorInterceptor(),
    DebugLogInterceptor(),
  ]);
  return dio;
}

/// Lo que usan los datasources: ejecuta la llamada y deja salir solo
/// [Failure]s. Un `DioException` no cruza la capa de datos.
Future<T> apiCall<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on DioException catch (e) {
    throw e.error is Failure ? e.error! as Failure : const UnexpectedFailure();
  }
}
