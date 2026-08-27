import 'package:camrun/core/error/failure.dart';

/// Repository return type. Dart 3 sealed classes give exhaustive `switch`
/// without a code generator.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure failure) = FailureResult<T>;

  /// Unwraps for consumers that already run inside an error-capturing boundary
  /// (an `AsyncNotifier` build, for instance).
  T unwrap() => switch (this) {
    Success<T>(:final value) => value,
    FailureResult<T>(:final failure) => throw failure,
  };

  R fold<R>(R Function(T value) onSuccess, R Function(Failure f) onFailure) =>
      switch (this) {
        Success<T>(:final value) => onSuccess(value),
        FailureResult<T>(:final failure) => onFailure(failure),
      };
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  final Failure failure;
}

/// Runs [body] and funnels anything it throws into a [Failure].
Future<Result<T>> guard<T>(Future<T> Function() body) async {
  try {
    return Result.success(await body());
  } on Failure catch (f) {
    return Result.failure(f);
  } catch (e) {
    return Result.failure(UnexpectedFailure(e.toString()));
  }
}
