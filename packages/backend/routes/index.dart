import 'package:dart_frog/dart_frog.dart';

/// Root route handler.
///
/// Returns a simple health check response.
Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'status': 'ok',
      'service': 'MyKIZ Backend',
      'version': '0.1.0',
    },
  );
}
