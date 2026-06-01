import 'dart:convert';
import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/middleware/error_handler.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  group('errorHandler middleware', () {
    late _MockRequestContext context;

    setUp(() {
      context = _MockRequestContext();
    });

    test('passes through successful responses unchanged', () async {
      final successResponse = Response.json(
        body: {'data': {'id': '123'}, 'meta': null},
      );

      final middleware = errorHandler();
      final handler = middleware((_) async => successResponse);
      final response = await handler(context);

      expect(response.statusCode, equals(200));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['data'], equals({'id': '123'}));
    });

    test('catches ApiException and returns error envelope', () async {
      final middleware = errorHandler();
      final handler = middleware((_) async {
        throw const InvalidRequestException('Bad JSON');
      });
      final response = await handler(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['error']['code'], equals('INVALID_REQUEST'));
      expect(body['error']['message'], equals('Bad JSON'));
    });

    test('catches NotFoundException and returns 404 envelope', () async {
      final middleware = errorHandler();
      final handler = middleware((_) async {
        throw const NotFoundException('Resource not found.');
      });
      final response = await handler(context);

      expect(response.statusCode, equals(HttpStatus.notFound));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['error']['code'], equals('NOT_FOUND'));
    });

    test('catches ValidationException and returns 400 envelope', () async {
      final middleware = errorHandler();
      final handler = middleware((_) async {
        throw const ValidationException('Title is required.');
      });
      final response = await handler(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['error']['code'], equals('VALIDATION_ERROR'));
      expect(body['error']['message'], equals('Title is required.'));
    });

    test('catches unexpected exceptions as 500 INTERNAL_ERROR', () async {
      final middleware = errorHandler();
      final handler = middleware((_) async {
        throw Exception('Something went wrong');
      });
      final response = await handler(context);

      expect(response.statusCode, equals(HttpStatus.internalServerError));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['error']['code'], equals('INTERNAL_ERROR'));
      expect(
        body['error']['message'],
        equals('An unexpected error occurred.'),
      );
    });

    test('intercepts non-JSON 404 responses as NOT_FOUND envelope', () async {
      // Simulate Dart Frog's default 404 (plain text, no content-type json)
      final plainText404 = Response(statusCode: HttpStatus.notFound);

      final middleware = errorHandler();
      final handler = middleware((_) async => plainText404);
      final response = await handler(context);

      expect(response.statusCode, equals(HttpStatus.notFound));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['error']['code'], equals('NOT_FOUND'));
      expect(
        body['error']['message'],
        equals('The requested endpoint does not exist.'),
      );
    });

    test('passes through JSON 404 responses unchanged', () async {
      // A route handler that intentionally returns a JSON 404
      final json404 = Response.json(
        statusCode: HttpStatus.notFound,
        body: {
          'error': {
            'code': 'NOT_FOUND',
            'message': 'Announcement not found.',
          },
        },
      );

      final middleware = errorHandler();
      final handler = middleware((_) async => json404);
      final response = await handler(context);

      expect(response.statusCode, equals(HttpStatus.notFound));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['error']['code'], equals('NOT_FOUND'));
      expect(body['error']['message'], equals('Announcement not found.'));
    });
  });
}
