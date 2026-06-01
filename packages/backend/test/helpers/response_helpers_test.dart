import 'dart:convert';
import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:test/test.dart';

void main() {
  group('ApiResponse', () {
    group('success', () {
      test('wraps data and meta in standard envelope', () async {
        final response = ApiResponse.success(
          data: {'id': '123', 'name': 'Test'},
          meta: {
            'currentPage': 1,
            'limit': 20,
            'totalItems': 5,
            'totalPages': 1,
          },
        );

        expect(response.statusCode, equals(200));

        final body =
            jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(body, containsPair('data', {'id': '123', 'name': 'Test'}));
        expect(
          body,
          containsPair('meta', {
            'currentPage': 1,
            'limit': 20,
            'totalItems': 5,
            'totalPages': 1,
          }),
        );
      });

      test('returns null meta when not provided', () async {
        final response = ApiResponse.success(data: {'id': '123'});

        final body =
            jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(body['meta'], isNull);
      });

      test('supports custom status code', () {
        final response = ApiResponse.success(
          data: {'id': '123'},
          statusCode: 201,
        );

        expect(response.statusCode, equals(201));
      });

      test('wraps array data correctly', () async {
        final response = ApiResponse.success(
          data: [
            {'id': '1'},
            {'id': '2'},
          ],
        );

        final body =
            jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(body['data'], isList);
        expect((body['data'] as List).length, equals(2));
      });
    });

    group('created', () {
      test('returns 201 with standard envelope', () async {
        final response = ApiResponse.created(data: {'id': 'new-id'});

        expect(response.statusCode, equals(201));
        final body =
            jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(body['data'], equals({'id': 'new-id'}));
        expect(body['meta'], isNull);
      });
    });

    group('noContent', () {
      test('returns envelope with null data and meta', () async {
        final response = ApiResponse.noContent();

        expect(response.statusCode, equals(200));
        final body =
            jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(body['data'], isNull);
        expect(body['meta'], isNull);
      });
    });

    group('error', () {
      test('wraps error in standard error envelope', () async {
        final response = ApiResponse.error(
          statusCode: 400,
          code: 'INVALID_REQUEST',
          message: 'Request body must be valid JSON.',
        );

        expect(response.statusCode, equals(400));

        final body =
            jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(body.containsKey('error'), isTrue);
        expect(body['error']['code'], equals('INVALID_REQUEST'));
        expect(
          body['error']['message'],
          equals('Request body must be valid JSON.'),
        );
      });

      test('does not include data or meta keys', () async {
        final response = ApiResponse.error(
          statusCode: 404,
          code: 'NOT_FOUND',
          message: 'Resource not found.',
        );

        final body =
            jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(body.containsKey('data'), isFalse);
        expect(body.containsKey('meta'), isFalse);
      });
    });

    group('fromException', () {
      test('maps InvalidRequestException correctly', () async {
        const exception = InvalidRequestException('Bad JSON');
        final response = ApiResponse.fromException(exception);

        expect(response.statusCode, equals(HttpStatus.badRequest));
        final body =
            jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(body['error']['code'], equals('INVALID_REQUEST'));
        expect(body['error']['message'], equals('Bad JSON'));
      });

      test('maps NotFoundException correctly', () async {
        const exception = NotFoundException('Endpoint not found.');
        final response = ApiResponse.fromException(exception);

        expect(response.statusCode, equals(HttpStatus.notFound));
        final body =
            jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(body['error']['code'], equals('NOT_FOUND'));
        expect(body['error']['message'], equals('Endpoint not found.'));
      });

      test('maps InternalErrorException correctly', () async {
        const exception = InternalErrorException();
        final response = ApiResponse.fromException(exception);

        expect(response.statusCode, equals(HttpStatus.internalServerError));
        final body =
            jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(body['error']['code'], equals('INTERNAL_ERROR'));
      });
    });
  });

  group('PaginationParams', () {
    test('calculates offset correctly', () {
      const params = PaginationParams(page: 1, limit: 20);
      expect(params.offset, equals(0));

      const params2 = PaginationParams(page: 3, limit: 10);
      expect(params2.offset, equals(20));

      const params3 = PaginationParams(page: 2, limit: 50);
      expect(params3.offset, equals(50));
    });
  });

  group('buildPaginationMeta', () {
    test('calculates totalPages correctly', () {
      final meta = buildPaginationMeta(
        currentPage: 1,
        limit: 20,
        totalItems: 55,
      );

      expect(meta['currentPage'], equals(1));
      expect(meta['limit'], equals(20));
      expect(meta['totalItems'], equals(55));
      expect(meta['totalPages'], equals(3)); // ceil(55/20) = 3
    });

    test('returns totalPages=1 when totalItems is 0', () {
      final meta = buildPaginationMeta(
        currentPage: 1,
        limit: 20,
        totalItems: 0,
      );

      expect(meta['totalPages'], equals(1));
    });

    test('handles exact division', () {
      final meta = buildPaginationMeta(
        currentPage: 1,
        limit: 10,
        totalItems: 30,
      );

      expect(meta['totalPages'], equals(3));
    });
  });

  group('ApiException subclasses', () {
    test('InvalidRequestException has correct defaults', () {
      const e = InvalidRequestException();
      expect(e.statusCode, equals(HttpStatus.badRequest));
      expect(e.code, equals('INVALID_REQUEST'));
      expect(e.message, equals('Invalid request.'));
    });

    test('ValidationException has correct defaults', () {
      const e = ValidationException();
      expect(e.statusCode, equals(HttpStatus.badRequest));
      expect(e.code, equals('VALIDATION_ERROR'));
    });

    test('InvalidTransitionException has correct defaults', () {
      const e = InvalidTransitionException();
      expect(e.statusCode, equals(HttpStatus.badRequest));
      expect(e.code, equals('INVALID_TRANSITION'));
    });

    test('FileTooLargeException has correct defaults', () {
      const e = FileTooLargeException();
      expect(e.statusCode, equals(HttpStatus.badRequest));
      expect(e.code, equals('FILE_TOO_LARGE'));
    });

    test('InvalidFileTypeException has correct defaults', () {
      const e = InvalidFileTypeException();
      expect(e.statusCode, equals(HttpStatus.badRequest));
      expect(e.code, equals('INVALID_FILE_TYPE'));
    });

    test('UnauthorizedException has correct defaults', () {
      const e = UnauthorizedException();
      expect(e.statusCode, equals(HttpStatus.unauthorized));
      expect(e.code, equals('UNAUTHORIZED'));
    });

    test('TokenExpiredException has correct defaults', () {
      const e = TokenExpiredException();
      expect(e.statusCode, equals(HttpStatus.unauthorized));
      expect(e.code, equals('TOKEN_EXPIRED'));
    });

    test('ForbiddenException has correct defaults', () {
      const e = ForbiddenException();
      expect(e.statusCode, equals(HttpStatus.forbidden));
      expect(e.code, equals('FORBIDDEN'));
    });

    test('NotFoundException has correct defaults', () {
      const e = NotFoundException();
      expect(e.statusCode, equals(HttpStatus.notFound));
      expect(e.code, equals('NOT_FOUND'));
    });

    test('InternalErrorException has correct defaults', () {
      const e = InternalErrorException();
      expect(e.statusCode, equals(HttpStatus.internalServerError));
      expect(e.code, equals('INTERNAL_ERROR'));
    });

    test('custom messages are preserved', () {
      const e = InvalidRequestException('Custom message');
      expect(e.message, equals('Custom message'));
    });

    test('toString includes code and message', () {
      const e = NotFoundException('Item not found');
      expect(e.toString(), equals('ApiException(NOT_FOUND: Item not found)'));
    });
  });
}
