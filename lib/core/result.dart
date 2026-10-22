/// A type-safe discriminated union for operation outcomes.
///
/// Use [Result] instead of throwing exceptions from repositories and
/// services.  Callers pattern-match on [Success] / [Failure] to handle
/// each case explicitly.
sealed class Result<T> {
  const Result();

  /// `true` when this is a [Success].
  bool get isSuccess => this is Success<T>;

  /// `true` when this is a [Failure].
  bool get isFailure => this is Failure<T>;

  /// Returns the success value or throws if this is a [Failure].
  T get value => switch (this) {
    Success(:final data) => data,
    Failure(:final error) => throw StateError(
      'Tried to access value on a Failure: $error',
    ),
  };

  /// Returns the error or `null` when this is a [Success].
  Object? get errorOrNull => switch (this) {
    Success() => null,
    Failure(:final error) => error,
  };

  /// Transforms the success value while preserving failures.
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    Success(:final data) => Success(transform(data)),
    Failure(:final error, :final stackTrace) => Failure(error, stackTrace),
  };

  /// Chains an asynchronous operation on success, short-circuiting on failure.
  Future<Result<R>> flatMap<R>(
    Future<Result<R>> Function(T data) transform,
  ) async => switch (this) {
    Success(:final data) => transform(data),
    Failure(:final error, :final stackTrace) => Failure(error, stackTrace),
  };

  /// Executes [onSuccess] or [onFailure] depending on the outcome.
  R when<R>({
    required R Function(T data) success,
    required R Function(Object error, StackTrace? stackTrace) failure,
  }) => switch (this) {
    Success(:final data) => success(data),
    Failure(:final error, :final stackTrace) => failure(error, stackTrace),
  };
}

/// Represents a successful operation carrying [data].
final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;

  @override
  String toString() => 'Success($data)';
}

/// Represents a failed operation carrying an [error] and optional [stackTrace].
final class Failure<T> extends Result<T> {
  const Failure(this.error, [this.stackTrace]);
  final Object error;
  final StackTrace? stackTrace;

  @override
  String toString() => 'Failure($error)';
}
