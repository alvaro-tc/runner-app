/// Domain-level error. Data sources translate whatever they throw into one of
/// these so exceptions never cross a layer boundary.
sealed class Failure implements Exception {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message =
        'We could not reach the server. Check your connection and try again.',
  ]);
}

class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Stored data could not be read. Pull to refresh.',
  ]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'We could not find what you asked for.',
  ]);
}

class PermissionFailure extends Failure {
  const PermissionFailure([
    super.message =
        'Location permission is off. Enable it to record your route.',
  ]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
    super.message = 'Something broke on our side. Try again in a moment.',
  ]);
}

/// Error del backend que la UI todavia tiene que distinguir por su codigo.
///
/// `code` es estable; `message` es texto humano que puede cambiar de redaccion
/// o traducirse sin aviso. Nunca se ramifica por el mensaje.
class ApiFailure extends Failure {
  const ApiFailure({
    required this.code,
    required String message,
    this.details = const [],
    this.requestId,
    this.statusCode,
  }) : super(message);

  final String code;

  /// Un mensaje por campo en `VALIDATION_ERROR`; objetos con contexto en el
  /// resto (`activePlanId`, `sessionId`, `reason`...).
  final List<Object?> details;

  /// Viaja tambien en la cabecera `x-request-id` y esta en cada linea de log
  /// del servidor. Vale la pena mostrarlo en las pantallas de error.
  final String? requestId;

  final int? statusCode;

  Map<String, Object?>? get firstDetail =>
      details.isEmpty ? null : details.first as Map<String, Object?>?;

  @override
  String toString() => 'ApiFailure($code): $message';
}

/// La sesion no se puede recuperar: hay que limpiar el storage e ir a Welcome.
class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([
    super.message = 'Tu sesion caduco. Vuelve a iniciar sesion.',
  ]);
}

/// Codigos que el cliente trata de forma especifica. El catalogo completo esta
/// en `docs/api.md`; aqui solo los que cambian el comportamiento de la app.
abstract final class ApiErrorCode {
  static const validationError = 'VALIDATION_ERROR';
  static const unauthorized = 'UNAUTHORIZED';
  static const forbidden = 'FORBIDDEN';
  static const notFound = 'NOT_FOUND';
  static const rateLimited = 'RATE_LIMITED';
  static const serviceUnavailable = 'SERVICE_UNAVAILABLE';
  static const internalError = 'INTERNAL_ERROR';

  static const invalidCredentials = 'INVALID_CREDENTIALS';
  static const emailAlreadyRegistered = 'EMAIL_ALREADY_REGISTERED';
  static const invalidRefreshToken = 'INVALID_REFRESH_TOKEN';
  static const tokenReuseDetected = 'TOKEN_REUSE_DETECTED';
  static const invalidResetToken = 'INVALID_RESET_TOKEN';

  static const marathonFull = 'MARATHON_FULL';
  static const registrationClosed = 'REGISTRATION_CLOSED';
  static const alreadyRegistered = 'ALREADY_REGISTERED';

  static const planAlreadyActive = 'PLAN_ALREADY_ACTIVE';
  static const planDoesNotFit = 'PLAN_DOES_NOT_FIT';
  static const sessionAlreadyActive = 'SESSION_ALREADY_ACTIVE';
  static const sessionNotActive = 'SESSION_NOT_ACTIVE';

  static const paymentDeclined = 'PAYMENT_DECLINED';
  static const idempotencyKeyConflict = 'IDEMPOTENCY_KEY_CONFLICT';

  /// Un refresh con estos codigos no se reintenta: la cadena ya esta revocada.
  static const unrecoverableSession = {invalidRefreshToken, tokenReuseDetected};
}
