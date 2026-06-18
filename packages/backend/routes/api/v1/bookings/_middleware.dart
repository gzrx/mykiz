import 'dart:io';

import 'package:backend/models/user_payload.dart';
import 'package:dart_frog/dart_frog.dart';

/// Middleware for /api/v1/bookings/* — student role guard.
Handler middleware(Handler handler) {
  return (context) async {
    final user = context.read<UserPayload>();

    if (user.role != 'student') {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {
          'error': {
            'code': 'FORBIDDEN',
            'message': 'Only students can access booking endpoints.',
          },
        },
      );
    }

    return handler(context);
  };
}
