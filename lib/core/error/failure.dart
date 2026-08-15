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
