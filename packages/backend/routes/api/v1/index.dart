import 'package:dart_frog/dart_frog.dart';

/// /api/v1 route handler.
///
/// Returns API version information.
Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'data': {
        'api': 'MyKIZ',
        'version': 'v1',
      },
      'meta': null,
    },
  );
}
