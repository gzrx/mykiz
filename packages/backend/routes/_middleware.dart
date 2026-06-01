import 'package:backend/middleware/error_handler.dart';
import 'package:dart_frog/dart_frog.dart';

/// Top-level middleware applied to all routes.
///
/// Applies error handling and CORS headers (all origins in development mode).
Handler middleware(Handler handler) {
  return handler.use(errorHandler()).use(_corsMiddleware());
}

/// CORS middleware that allows all origins (development mode).
///
/// Sets Access-Control-Allow-Origin, Allow-Methods, Allow-Headers,
/// and handles preflight OPTIONS requests.
Middleware _corsMiddleware() {
  return (handler) {
    return (context) async {
      // Handle preflight OPTIONS requests
      if (context.request.method == HttpMethod.options) {
        return Response(
          statusCode: 204,
          headers: _corsHeaders,
        );
      }

      final response = await handler(context);

      // Add CORS headers to all responses
      return response.copyWith(
        headers: {
          ...response.headers,
          ..._corsHeaders,
        },
      );
    };
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers':
      'Origin, Content-Type, Accept, Authorization, X-Requested-With',
  'Access-Control-Max-Age': '86400',
};
