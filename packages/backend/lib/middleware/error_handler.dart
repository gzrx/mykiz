import 'dart:io';

import 'package:backend/helpers/api_exceptions.dart';
import 'package:backend/helpers/response_helpers.dart';
import 'package:dart_frog/dart_frog.dart';

/// Middleware that catches [ApiException]s and unhandled errors,
/// converting them into standard error envelope responses.
///
/// This should be applied early in the middleware pipeline so it can
/// catch exceptions from all downstream handlers.
///
/// Also intercepts framework-generated 404 responses (plain text "Route not
/// found") and reformats them into the standard error envelope.
Middleware errorHandler() {
  return (handler) {
    return (context) async {
      try {
        final response = await handler(context);

        // Intercept Dart Frog's default 404 responses and wrap in envelope
        if (response.statusCode == HttpStatus.notFound) {
          final contentType = response.headers['content-type'] ?? '';
          // Only intercept non-JSON 404s (framework-generated ones)
          if (!contentType.contains('application/json')) {
            return ApiResponse.error(
              statusCode: HttpStatus.notFound,
              code: 'NOT_FOUND',
              message: 'The requested endpoint does not exist.',
            );
          }
        }

        return response;
      } on ApiException catch (e) {
        return ApiResponse.fromException(e);
      } catch (e) {
        // Unexpected errors become 500 INTERNAL_ERROR
        return ApiResponse.error(
          statusCode: HttpStatus.internalServerError,
          code: 'INTERNAL_ERROR',
          message: 'An unexpected error occurred.',
        );
      }
    };
  };
}
