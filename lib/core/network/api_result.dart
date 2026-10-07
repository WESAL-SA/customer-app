/// A lightweight Result type so callers handle success and failure explicitly
/// instead of relying on thrown exceptions crossing layers.
///
/// Usage:
/// ```dart
/// final result = await repo.requestRide(...);
/// switch (result) {
///   case Ok(:final value): ...
///   case Err(:final failure): ...
/// }
/// ```
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  R fold<R>(
    R Function(T value) onOk,
    R Function(Failure failure) onErr,
  ) {
    final self = this;
    if (self is Ok<T>) return onOk(self.value);
    return onErr((self as Err<T>).failure);
  }
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

/// Domain-level failure categories. The UI maps these to user-friendly,
/// localized messages (never raw backend errors / stack traces — spec §26).
enum FailureKind {
  network, // no connection / DNS / socket
  timeout,
  server, // 5xx
  unauthorized, // 401 — session expired, trigger refresh/login
  forbidden, // 403 — e.g. risk/fraud decision, service-area restriction
  validation, // 4xx with field errors
  notFound,
  conflict, // e.g. duplicate ride request
  paymentFailed,
  noDriversAvailable,
  locationUnavailable,
  rateLimited,
  unknown,
}

class Failure {
  const Failure({
    required this.kind,
    this.code,
    this.debugMessage,
    this.fieldErrors = const {},
  });

  /// Stable category used to pick a localized message.
  final FailureKind kind;

  /// Optional machine-readable code from the backend (e.g. "RIDE_DUPLICATE").
  final String? code;

  /// Developer-facing detail. NEVER show this to the user directly and NEVER
  /// log sensitive content through it.
  final String? debugMessage;

  /// Per-field validation errors keyed by field name.
  final Map<String, String> fieldErrors;

  const Failure.network([this.debugMessage])
      : kind = FailureKind.network,
        code = null,
        fieldErrors = const {};

  const Failure.timeout([this.debugMessage])
      : kind = FailureKind.timeout,
        code = null,
        fieldErrors = const {};

  const Failure.unknown([this.debugMessage])
      : kind = FailureKind.unknown,
        code = null,
        fieldErrors = const {};

  @override
  String toString() => 'Failure(kind: $kind, code: $code)';
}
