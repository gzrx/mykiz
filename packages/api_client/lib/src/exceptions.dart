/// Typed exception hierarchy for API client errors.
///
/// Maps HTTP status codes to specific exception types:
/// - 401 → [UnauthorizedException]
/// - 403 → [ForbiddenException]
/// - 404 → [NotFoundException]
/// - 400 → [ValidationException]
/// - 500 → [ServerException]
/// - Timeout → [ApiTimeoutException]
sealed class ApiException implements Exception {
  const ApiException({required this.code, required this.message});

  /// Machine-readable error code from the backend (e.g. "UNAUTHORIZED").
  final String code;

  /// Human-readable error description.
  final String message;

  @override
  String toString() => 'ApiException($code): $message';
}

/// Thrown when the request lacks valid authentication (HTTP 401).
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    required super.code,
    required super.message,
  });
}

/// Thrown when the authenticated user lacks permission (HTTP 403).
class ForbiddenException extends ApiException {
  const ForbiddenException({
    required super.code,
    required super.message,
  });
}

/// Thrown when the requested resource does not exist (HTTP 404).
class NotFoundException extends ApiException {
  const NotFoundException({
    required super.code,
    required super.message,
  });
}

/// Thrown when request validation fails (HTTP 400).
class ValidationException extends ApiException {
  const ValidationException({
    required super.code,
    required super.message,
  });
}

/// Thrown when the backend does not respond within the timeout period.
class ApiTimeoutException extends ApiException {
  const ApiTimeoutException({
    super.code = 'TIMEOUT',
    super.message = 'Request timed out',
  });
}

/// Thrown when a conflict occurs (HTTP 409), e.g. BED_UNAVAILABLE.
class ConflictException extends ApiException {
  const ConflictException({
    required super.code,
    required super.message,
  });
}

/// Thrown when the server encounters an internal error (HTTP 500).
class ServerException extends ApiException {
  const ServerException({
    required super.code,
    required super.message,
  });
}
