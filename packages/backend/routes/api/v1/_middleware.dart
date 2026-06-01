import 'dart:io';

import 'package:backend/models/user_payload.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Middleware applied to all /api/v1/* routes.
///
/// Verifies JWT Bearer token and injects [UserPayload] into the request
/// context. Skips authentication for the login endpoint.
Handler middleware(Handler handler) {
  return handler.use(_authMiddleware());
}

/// Auth middleware that extracts and verifies JWT from the Authorization header.
///
/// - Skips auth for POST /api/v1/auth/login
/// - Returns 401 UNAUTHORIZED for missing or invalid tokens
/// - Returns 401 TOKEN_EXPIRED for expired tokens
/// - On success, injects [UserPayload] into the request context
Middleware _authMiddleware() {
  return (handler) {
    return (context) async {
      // Skip auth for the login endpoint
      final path = context.request.uri.path;
      final method = context.request.method;

      if (method == HttpMethod.post &&
          (path == '/api/v1/auth/login' || path == '/api/v1/auth/login/')) {
        return handler(context);
      }

      // Extract Bearer token from Authorization header
      final authHeader = context.request.headers['Authorization'] ??
          context.request.headers['authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {
            'error': {
              'code': 'UNAUTHORIZED',
              'message': 'Missing or malformed authorization token.',
            },
          },
        );
      }

      final token = authHeader.substring(7); // Remove 'Bearer ' prefix

      // Verify JWT
      try {
        final jwtSecret = Platform.environment['JWT_SECRET'] ?? 'change-me-to-a-secure-random-string';
        final jwt = JWT.verify(token, SecretKey(jwtSecret));

        final payload = jwt.payload as Map<String, dynamic>;
        final sub = payload['sub'] as String?;
        final role = payload['role'] as String?;

        if (sub == null || role == null) {
          return Response.json(
            statusCode: HttpStatus.unauthorized,
            body: {
              'error': {
                'code': 'UNAUTHORIZED',
                'message': 'Invalid token payload.',
              },
            },
          );
        }

        final userPayload = UserPayload(id: sub, role: role);

        // Inject UserPayload into context
        final updatedContext = context.provide<UserPayload>(() => userPayload);
        return handler(updatedContext);
      } on JWTExpiredException {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {
            'error': {
              'code': 'TOKEN_EXPIRED',
              'message': 'The authentication token has expired.',
            },
          },
        );
      } on JWTException {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {
            'error': {
              'code': 'UNAUTHORIZED',
              'message': 'Invalid authentication token.',
            },
          },
        );
      } catch (e) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {
            'error': {
              'code': 'UNAUTHORIZED',
              'message': 'Authentication failed.',
            },
          },
        );
      }
    };
  };
}
