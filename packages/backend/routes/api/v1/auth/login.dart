import 'dart:io';

import 'package:backend/services/auth_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// POST /api/v1/auth/login
///
/// Authenticates a user with identifier and password, returning a JWT token
/// on success.
///
/// Request body:
/// ```json
/// { "identifier": "A123456", "password": "password123" }
/// ```
///
/// Success response (200):
/// ```json
/// { "data": { "token": "jwt-string", "user": {...} }, "meta": null }
/// ```
///
/// Error response (401):
/// ```json
/// { "error": { "code": "INVALID_CREDENTIALS", "message": "..." } }
/// ```
Future<Response> onRequest(RequestContext context) async {
  // Only allow POST method
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {
        'error': {
          'code': 'METHOD_NOT_ALLOWED',
          'message': 'Only POST method is allowed for this endpoint.',
        },
      },
    );
  }

  // Parse JSON body
  final Map<String, dynamic> body;
  try {
    body = await context.request.json() as Map<String, dynamic>;
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'error': {
          'code': 'INVALID_REQUEST',
          'message': 'Request body must be valid JSON.',
        },
      },
    );
  }

  final identifier = body['identifier'] as String?;
  final password = body['password'] as String?;

  // Validate required fields
  if (identifier == null ||
      identifier.isEmpty ||
      password == null ||
      password.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': 'Both identifier and password are required.',
        },
      },
    );
  }

  // Attempt login
  try {
    final authService = AuthService();
    final result = await authService.login(identifier, password);

    return Response.json(
      body: {
        'data': {
          'token': result.token,
          'user': result.user,
        },
        'meta': null,
      },
    );
  } on AuthException catch (e) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {
        'error': {
          'code': e.code,
          'message': e.message,
        },
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'error': {
          'code': 'INTERNAL_ERROR',
          'message': 'An unexpected error occurred.',
        },
      },
    );
  }
}
