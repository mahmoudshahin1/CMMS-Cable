/// Typed failure hierarchy for clean error propagation.
///
/// Use [Failure] subclasses instead of raw String error messages
/// to enable typed error handling in Cubits and UI layers.
sealed class Failure {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const Failure({
    required this.message,
    this.code,
    this.stackTrace,
  });

  @override
  String toString() => 'Failure($code): $message';
}

/// Server / remote API failures (Supabase, REST, etc.)
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    this.statusCode,
    super.code = 'SERVER_ERROR',
    super.stackTrace,
  });
}

/// Local database / cache failures (Hive read/write errors)
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code = 'CACHE_ERROR',
    super.stackTrace,
  });
}

/// Network connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection available',
    super.code = 'NETWORK_ERROR',
    super.stackTrace,
  });
}

/// RBAC / authorization failures
class AuthorizationFailure extends Failure {
  final String requiredRole;
  final String actualRole;

  const AuthorizationFailure({
    required this.requiredRole,
    required this.actualRole,
    required super.message,
    super.code = 'UNAUTHORIZED',
    super.stackTrace,
  });
}

/// Illegal state machine transition failures
class StateTransitionFailure extends Failure {
  final String fromStatus;
  final String toStatus;

  const StateTransitionFailure({
    required this.fromStatus,
    required this.toStatus,
    super.message = 'Invalid state transition',
    super.code = 'INVALID_TRANSITION',
    super.stackTrace,
  });
}

/// Validation failures (form input, business rules)
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    this.fieldErrors,
    super.code = 'VALIDATION_ERROR',
    super.stackTrace,
  });
}

/// Generic / unexpected failures
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    required super.message,
    super.code = 'UNEXPECTED_ERROR',
    super.stackTrace,
  });
}
