/// Exception thrown by [AccommodationService] for domain-specific errors.
class AccommodationException implements Exception {
  const AccommodationException({
    required this.code,
    required this.message,
    this.statusCode = 400,
  });

  final String code;
  final String message;
  final int statusCode;

  // -- Named constructors for each error code --

  /// Student submits while application window is closed.
  const AccommodationException.windowClosed({
    this.message = 'The application window is currently closed.',
  })  : code = 'WINDOW_CLOSED',
        statusCode = 403;

  /// Student already has an active application of the same type.
  const AccommodationException.activeApplicationExists({
    this.message = 'An active application of this type already exists.',
  })  : code = 'ACTIVE_APPLICATION_EXISTS',
        statusCode = 409;

  /// Student exceeded re-application limit for this window.
  const AccommodationException.reapplicationLimit({
    this.message =
        'Re-application limit reached for this application window.',
  })  : code = 'REAPPLICATION_LIMIT',
        statusCode = 409;

  /// Invalid input (dates, tags, empty fields, reason).
  const AccommodationException.validationError({
    required this.message,
  })  : code = 'VALIDATION_ERROR',
        statusCode = 400;

  /// Resource not found.
  const AccommodationException.notFound({
    this.message = 'Resource not found.',
  })  : code = 'NOT_FOUND',
        statusCode = 404;

  /// Status transition not allowed.
  const AccommodationException.invalidTransition({
    this.message = 'This status transition is not allowed.',
  })  : code = 'INVALID_TRANSITION',
        statusCode = 400;

  /// Bed was taken (race condition).
  const AccommodationException.bedUnavailable({
    this.message = 'The selected bed is no longer available.',
  })  : code = 'BED_UNAVAILABLE',
        statusCode = 409;

  /// Wrong role for the action.
  const AccommodationException.forbidden({
    this.message = 'You do not have permission to perform this action.',
  })  : code = 'FORBIDDEN',
        statusCode = 403;

  @override
  String toString() => 'AccommodationException($code): $message';
}
