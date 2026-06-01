import 'package:dart_frog/dart_frog.dart';

import 'api_exceptions.dart';

/// Parses the request body as JSON.
///
/// Throws [InvalidRequestException] if the body is not valid JSON.
Future<Map<String, dynamic>> parseJsonBody(RequestContext context) async {
  try {
    final body = await context.request.json();
    if (body is! Map<String, dynamic>) {
      throw const InvalidRequestException(
        'Request body must be a JSON object.',
      );
    }
    return body;
  } on InvalidRequestException {
    rethrow;
  } catch (e) {
    throw const InvalidRequestException(
      'Request body must be valid JSON.',
    );
  }
}
