import 'package:dart_frog/dart_frog.dart';

import 'api_exceptions.dart';

/// Helper class for building standard API response envelopes.
///
/// All successful responses follow: `{ "data": ..., "meta": ... }`
/// All error responses follow: `{ "error": { "code": "...", "message": "..." } }`
class ApiResponse {
  /// Creates a successful response with the standard envelope.
  ///
  /// [data] is the resource or array to return.
  /// [meta] is the optional pagination metadata (null for non-list responses).
  /// [statusCode] defaults to 200.
  static Response success({
    required Object? data,
    Map<String, dynamic>? meta,
    int statusCode = 200,
  }) {
    return Response.json(
      statusCode: statusCode,
      body: {
        'data': data,
        'meta': meta,
      },
    );
  }

  /// Creates a successful response for a created resource (201).
  static Response created({
    required Object? data,
    Map<String, dynamic>? meta,
  }) {
    return success(data: data, meta: meta, statusCode: 201);
  }

  /// Creates a successful response with no content (204-like but with envelope).
  static Response noContent() {
    return success(data: null, meta: null);
  }

  /// Creates an error response from an [ApiException].
  static Response fromException(ApiException exception) {
    return error(
      statusCode: exception.statusCode,
      code: exception.code,
      message: exception.message,
    );
  }

  /// Creates an error response with the standard error envelope.
  ///
  /// [statusCode] is the HTTP status code.
  /// [code] is the machine-readable error code.
  /// [message] is the human-readable error description.
  static Response error({
    required int statusCode,
    required String code,
    required String message,
  }) {
    return Response.json(
      statusCode: statusCode,
      body: {
        'error': {
          'code': code,
          'message': message,
        },
      },
    );
  }
}
