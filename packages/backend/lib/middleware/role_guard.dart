import 'dart:io';

import 'package:backend/models/user_payload.dart';
import 'package:dart_frog/dart_frog.dart';

/// Response returned when a user lacks the required role.
Response _forbiddenResponse() {
  return Response.json(
    statusCode: HttpStatus.forbidden,
    body: {
      'error': {
        'code': 'FORBIDDEN',
        'message': 'You do not have permission to perform this action.',
      },
    },
  );
}

/// Checks if the authenticated user has the admin role.
///
/// Call this at the start of route handlers that require admin access.
/// Throws nothing — returns a [Response] with 403 FORBIDDEN if the user
/// is not an admin, or `null` if access is granted.
///
/// Usage in a route handler:
/// ```dart
/// Future<Response> onRequest(RequestContext context) async {
///   final forbidden = requireAdmin(context);
///   if (forbidden != null) return forbidden;
///   // ... admin-only logic
/// }
/// ```
Response? requireAdmin(RequestContext context) {
  final user = context.read<UserPayload>();
  if (!user.isAdmin) {
    return _forbiddenResponse();
  }
  return null;
}

/// Checks if the authenticated user has the specified [role].
///
/// Returns a 403 FORBIDDEN response if the user's role does not match,
/// or `null` if access is granted.
Response? requireRole(RequestContext context, String role) {
  final user = context.read<UserPayload>();
  if (user.role != role) {
    return _forbiddenResponse();
  }
  return null;
}

/// Middleware that restricts access to admin users only.
///
/// Apply this to route directories where all endpoints are admin-only.
/// Any non-admin request will receive a 403 FORBIDDEN response.
///
/// Usage as a Dart Frog middleware:
/// ```dart
/// Handler middleware(Handler handler) {
///   return handler.use(adminOnly());
/// }
/// ```
Middleware adminOnly() {
  return (handler) {
    return (context) async {
      final user = context.read<UserPayload>();
      if (!user.isAdmin) {
        return _forbiddenResponse();
      }
      return handler(context);
    };
  };
}
