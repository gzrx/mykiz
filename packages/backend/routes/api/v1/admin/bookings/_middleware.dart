import 'dart:io';

import 'package:backend/models/user_payload.dart';
import 'package:dart_frog/dart_frog.dart';

/// Middleware for /api/v1/admin/bookings/* — rejects non-admin users with 403.
Handler middleware(Handler handler) {
  return (context) async {
    final user = context.read<UserPayload>();
    if (!user.isAdmin) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {
          'error': {
            'code': 'FORBIDDEN',
            'message': 'Admin access required.',
          },
        },
      );
    }
    return handler(context);
  };
}
