import 'dart:io';

/// Base class for all API exceptions that map to specific HTTP error responses.
abstract class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  /// HTTP status code to return.
  final int statusCode;

  /// Machine-readable error code (e.g., "INVALID_REQUEST", "NOT_FOUND").
  final String code;

  /// Human-readable error message.
  final String message;

  @override
  String toString() => 'ApiException($code: $message)';
}

/// 400 - Malformed JSON or invalid pagination parameters.
class InvalidRequestException extends ApiException {
  const InvalidRequestException([String message = 'Invalid request.'])
      : super(
          statusCode: HttpStatus.badRequest,
          code: 'INVALID_REQUEST',
          message: message,
        );
}

/// 400 - Input validation failure (field constraints).
class ValidationException extends ApiException {
  const ValidationException([String message = 'Validation failed.'])
      : super(
          statusCode: HttpStatus.badRequest,
          code: 'VALIDATION_ERROR',
          message: message,
        );
}

/// 400 - Invalid complaint status transition.
class InvalidTransitionException extends ApiException {
  const InvalidTransitionException(
      [String message = 'Invalid status transition.'])
      : super(
          statusCode: HttpStatus.badRequest,
          code: 'INVALID_TRANSITION',
          message: message,
        );
}

/// 400 - Uploaded file exceeds size limit.
class FileTooLargeException extends ApiException {
  const FileTooLargeException(
      [String message = 'File exceeds the maximum allowed size of 5 MB.'])
      : super(
          statusCode: HttpStatus.badRequest,
          code: 'FILE_TOO_LARGE',
          message: message,
        );
}

/// 400 - Uploaded file has unsupported format.
class InvalidFileTypeException extends ApiException {
  const InvalidFileTypeException(
      [String message = 'Only JPEG and PNG image formats are supported.'])
      : super(
          statusCode: HttpStatus.badRequest,
          code: 'INVALID_FILE_TYPE',
          message: message,
        );
}

/// 401 - Missing or invalid authentication token.
class UnauthorizedException extends ApiException {
  const UnauthorizedException(
      [String message = 'Missing or invalid authentication token.'])
      : super(
          statusCode: HttpStatus.unauthorized,
          code: 'UNAUTHORIZED',
          message: message,
        );
}

/// 401 - Expired authentication token.
class TokenExpiredException extends ApiException {
  const TokenExpiredException(
      [String message = 'The authentication token has expired.'])
      : super(
          statusCode: HttpStatus.unauthorized,
          code: 'TOKEN_EXPIRED',
          message: message,
        );
}

/// 403 - Insufficient permissions.
class ForbiddenException extends ApiException {
  const ForbiddenException(
      [String message = 'You do not have permission to perform this action.'])
      : super(
          statusCode: HttpStatus.forbidden,
          code: 'FORBIDDEN',
          message: message,
        );
}

/// 404 - Resource or endpoint not found.
class NotFoundException extends ApiException {
  const NotFoundException([String message = 'Resource not found.'])
      : super(
          statusCode: HttpStatus.notFound,
          code: 'NOT_FOUND',
          message: message,
        );
}

/// 500 - Unexpected server error.
class InternalErrorException extends ApiException {
  const InternalErrorException(
      [String message = 'An unexpected error occurred.'])
      : super(
          statusCode: HttpStatus.internalServerError,
          code: 'INTERNAL_ERROR',
          message: message,
        );
}
