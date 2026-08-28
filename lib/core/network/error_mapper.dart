import 'package:camrun/core/error/failure.dart';
import 'package:dio/dio.dart';

/// Traduce lo que sale de Dio a un [Failure] del dominio, mapeando **por
/// `error.code`**. Nada por encima de la capa de datos ve un `DioException`.
Failure mapDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.cancel:
      return const UnexpectedFailure('La peticion se cancelo.');
    case DioExceptionType.badCertificate:
      return const NetworkFailure('El certificado del servidor no es valido.');
    default:
      break;
  }

  final response = e.response;
  if (response == null) return const NetworkFailure();

  final body = response.data;
  final error = body is Map ? body['error'] : null;
  if (error is! Map) {
    // El servidor no respondio con el sobre: proxy caido, HTML de error, 502...
    return response.statusCode != null && response.statusCode! >= 500
        ? const UnexpectedFailure('El servidor no esta disponible.')
        : const UnexpectedFailure();
  }

  final meta = body is Map ? body['meta'] : null;
  final failure = ApiFailure(
    code: (error['code'] as String?) ?? ApiErrorCode.internalError,
    message: (error['message'] as String?) ?? 'Error inesperado.',
    details: (error['details'] as List?)?.cast<Object?>() ?? const [],
    requestId: meta is Map ? meta['requestId'] as String? : null,
    statusCode: response.statusCode,
  );

  // Los codigos que la UI ya sabe tratar como caso generico se degradan al
  // Failure que las pantallas existentes esperan; el resto viaja con su codigo.
  return switch (failure.code) {
    ApiErrorCode.validationError => ValidationFailure(
      failure.details.isEmpty ? failure.message : failure.details.join('\n'),
    ),
    ApiErrorCode.notFound => NotFoundFailure(failure.message),
    ApiErrorCode.invalidRefreshToken ||
    ApiErrorCode.tokenReuseDetected => const SessionExpiredFailure(),
    _ => failure,
  };
}
