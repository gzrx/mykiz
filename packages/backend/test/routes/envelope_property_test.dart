// Feature: mykiz-platform, Property 18: Response envelope consistency
import 'dart:convert';

import 'package:backend/helpers/response_helpers.dart';
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 10.2, 10.3**
///
/// Property 18: Response envelope consistency
/// For any successful API response, the body SHALL conform to
/// `{ "data": ..., "meta": ... }`.
/// For any error API response, the body SHALL conform to
/// `{ "error": { "code": "...", "message": "..." } }`.

/// Custom generators for envelope testing.
extension EnvelopeGenerators on Any {
  /// Generates a random data object (Map with string keys and various values).
  Generator<Map<String, dynamic>> get randomDataMap => simple(
        generate: (random, size) {
          final numKeys = 1 + random.nextInt(5);
          final map = <String, dynamic>{};
          for (var i = 0; i < numKeys; i++) {
            final keyLength = 1 + random.nextInt(10);
            final key = String.fromCharCodes(
              List.generate(keyLength, (_) => 97 + random.nextInt(26)),
            );
            // Generate random value types: string, int, bool, null
            final valueType = random.nextInt(4);
            switch (valueType) {
              case 0:
                final valLength = 1 + random.nextInt(50);
                map[key] = String.fromCharCodes(
                  List.generate(valLength, (_) => 32 + random.nextInt(95)),
                );
                break;
              case 1:
                map[key] = random.nextInt(100000);
                break;
              case 2:
                map[key] = random.nextBool();
                break;
              case 3:
                map[key] = null;
                break;
            }
          }
          return map;
        },
        shrink: (input) => [
          {'a': 'b'}
        ],
      );

  /// Generates a random list of data objects.
  Generator<List<Map<String, dynamic>>> get randomDataList => simple(
        generate: (random, size) {
          final numItems = random.nextInt(5);
          return List.generate(numItems, (_) {
            final numKeys = 1 + random.nextInt(3);
            final map = <String, dynamic>{};
            for (var i = 0; i < numKeys; i++) {
              final keyLength = 1 + random.nextInt(8);
              final key = String.fromCharCodes(
                List.generate(keyLength, (_) => 97 + random.nextInt(26)),
              );
              map[key] = random.nextInt(1000);
            }
            return map;
          });
        },
        shrink: (input) => [
          <Map<String, dynamic>>[]
        ],
      );

  /// Generates a random pagination meta map.
  Generator<Map<String, dynamic>> get randomMeta => simple(
        generate: (random, size) {
          final currentPage = 1 + random.nextInt(50);
          final limit = 1 + random.nextInt(100);
          final totalItems = random.nextInt(500);
          final totalPages = totalItems == 0 ? 1 : (totalItems / limit).ceil();
          return {
            'currentPage': currentPage,
            'limit': limit,
            'totalItems': totalItems,
            'totalPages': totalPages,
          };
        },
        shrink: (input) => [
          {
            'currentPage': 1,
            'limit': 20,
            'totalItems': 0,
            'totalPages': 1,
          }
        ],
      );

  /// Generates a random non-empty error code (uppercase with underscores).
  Generator<String> get randomErrorCode => simple(
        generate: (random, size) {
          final codes = [
            'INVALID_REQUEST',
            'VALIDATION_ERROR',
            'UNAUTHORIZED',
            'TOKEN_EXPIRED',
            'FORBIDDEN',
            'NOT_FOUND',
            'INVALID_TRANSITION',
            'FILE_TOO_LARGE',
            'INVALID_FILE_TYPE',
            'INTERNAL_ERROR',
          ];
          return codes[random.nextInt(codes.length)];
        },
        shrink: (input) => ['ERROR'],
      );

  /// Generates a random non-empty error message.
  Generator<String> get randomErrorMessage => simple(
        generate: (random, size) {
          final length = 5 + random.nextInt(100);
          return String.fromCharCodes(
            List.generate(length, (_) => 32 + random.nextInt(95)),
          );
        },
        shrink: (input) => ['An error occurred.'],
      );

  /// Generates a random HTTP status code for success responses.
  Generator<int> get randomSuccessStatusCode => simple(
        generate: (random, size) {
          final codes = [200, 201];
          return codes[random.nextInt(codes.length)];
        },
        shrink: (input) => [200],
      );

  /// Generates a random HTTP status code for error responses.
  Generator<int> get randomErrorStatusCode => simple(
        generate: (random, size) {
          final codes = [400, 401, 403, 404, 500];
          return codes[random.nextInt(codes.length)];
        },
        shrink: (input) => [400],
      );
}

void main() {
  group('Property 18: Response envelope consistency', () {
    // Property 18a: For any successful API response with a data map,
    // the body SHALL contain exactly "data" and "meta" keys.
    Glados2(any.randomDataMap, any.randomMeta, ExploreConfig(numRuns: 100))
        .test(
      'success response with data map conforms to { "data": ..., "meta": ... }',
      (dataMap, meta) async {
        final response = ApiResponse.success(data: dataMap, meta: meta);
        final body =
            jsonDecode(await response.body()) as Map<String, dynamic>;

        // Must have "data" key
        expect(body.containsKey('data'), isTrue,
            reason: 'Success response must contain "data" key');
        // Must have "meta" key
        expect(body.containsKey('meta'), isTrue,
            reason: 'Success response must contain "meta" key');
        // Must NOT have "error" key
        expect(body.containsKey('error'), isFalse,
            reason: 'Success response must not contain "error" key');
        // "data" should match what was passed
        expect(body['data'], equals(dataMap));
        // "meta" should match what was passed
        expect(body['meta'], equals(meta));
      },
    );

    // Property 18b: For any successful API response with a data list,
    // the body SHALL contain exactly "data" and "meta" keys.
    Glados2(any.randomDataList, any.randomMeta, ExploreConfig(numRuns: 100))
        .test(
      'success response with data list conforms to { "data": ..., "meta": ... }',
      (dataList, meta) async {
        final response = ApiResponse.success(data: dataList, meta: meta);
        final body =
            jsonDecode(await response.body()) as Map<String, dynamic>;

        // Must have "data" key
        expect(body.containsKey('data'), isTrue,
            reason: 'Success response must contain "data" key');
        // Must have "meta" key
        expect(body.containsKey('meta'), isTrue,
            reason: 'Success response must contain "meta" key');
        // Must NOT have "error" key
        expect(body.containsKey('error'), isFalse,
            reason: 'Success response must not contain "error" key');
        // "data" should be a list
        expect(body['data'], isList);
      },
    );

    // Property 18c: For any successful API response with null meta,
    // the body SHALL still contain both "data" and "meta" keys.
    Glados(any.randomDataMap, ExploreConfig(numRuns: 100)).test(
      'success response with null meta still has "data" and "meta" keys',
      (dataMap) async {
        final response = ApiResponse.success(data: dataMap, meta: null);
        final body =
            jsonDecode(await response.body()) as Map<String, dynamic>;

        // Must have "data" key
        expect(body.containsKey('data'), isTrue,
            reason: 'Success response must contain "data" key');
        // Must have "meta" key (even if null)
        expect(body.containsKey('meta'), isTrue,
            reason: 'Success response must contain "meta" key even when null');
        // Must NOT have "error" key
        expect(body.containsKey('error'), isFalse,
            reason: 'Success response must not contain "error" key');
        // "meta" should be null
        expect(body['meta'], isNull);
      },
    );

    // Property 18d: For any error API response, the body SHALL conform to
    // { "error": { "code": "...", "message": "..." } }.
    Glados3(any.randomErrorStatusCode, any.randomErrorCode,
            any.randomErrorMessage, ExploreConfig(numRuns: 100))
        .test(
      'error response conforms to { "error": { "code": "...", "message": "..." } }',
      (statusCode, code, message) async {
        final response = ApiResponse.error(
          statusCode: statusCode,
          code: code,
          message: message,
        );
        final body =
            jsonDecode(await response.body()) as Map<String, dynamic>;

        // Must have "error" key
        expect(body.containsKey('error'), isTrue,
            reason: 'Error response must contain "error" key');
        // Must NOT have "data" key
        expect(body.containsKey('data'), isFalse,
            reason: 'Error response must not contain "data" key');
        // Must NOT have "meta" key
        expect(body.containsKey('meta'), isFalse,
            reason: 'Error response must not contain "meta" key');

        // "error" must be a map with "code" and "message"
        final errorObj = body['error'] as Map<String, dynamic>;
        expect(errorObj.containsKey('code'), isTrue,
            reason: 'Error object must contain "code" key');
        expect(errorObj.containsKey('message'), isTrue,
            reason: 'Error object must contain "message" key');
        // "code" must be a non-empty string
        expect(errorObj['code'], isA<String>());
        expect((errorObj['code'] as String).isNotEmpty, isTrue,
            reason: 'Error code must be non-empty');
        // "message" must be a non-empty string
        expect(errorObj['message'], isA<String>());
        expect((errorObj['message'] as String).isNotEmpty, isTrue,
            reason: 'Error message must be non-empty');
        // Values should match what was passed
        expect(errorObj['code'], equals(code));
        expect(errorObj['message'], equals(message));
      },
    );

    // Property 18e: For any successful response regardless of status code,
    // the envelope structure is consistent.
    Glados2(any.randomSuccessStatusCode, any.randomDataMap,
            ExploreConfig(numRuns: 100))
        .test(
      'success envelope structure is consistent regardless of status code',
      (statusCode, dataMap) async {
        final response =
            ApiResponse.success(data: dataMap, statusCode: statusCode);
        final body =
            jsonDecode(await response.body()) as Map<String, dynamic>;

        // Envelope must always have exactly "data" and "meta" keys
        final keys = body.keys.toSet();
        expect(keys, equals({'data', 'meta'}),
            reason:
                'Success envelope must have exactly "data" and "meta" keys, '
                'got: $keys');
      },
    );

    // Property 18f: For any error response regardless of status code,
    // the envelope structure is consistent.
    Glados3(any.randomErrorStatusCode, any.randomErrorCode,
            any.randomErrorMessage, ExploreConfig(numRuns: 100))
        .test(
      'error envelope structure is consistent regardless of status code',
      (statusCode, code, message) async {
        final response = ApiResponse.error(
          statusCode: statusCode,
          code: code,
          message: message,
        );
        final body =
            jsonDecode(await response.body()) as Map<String, dynamic>;

        // Envelope must always have exactly "error" key
        final keys = body.keys.toSet();
        expect(keys, equals({'error'}),
            reason: 'Error envelope must have exactly "error" key, '
                'got: $keys');

        // Error object must have exactly "code" and "message" keys
        final errorObj = body['error'] as Map<String, dynamic>;
        final errorKeys = errorObj.keys.toSet();
        expect(errorKeys, equals({'code', 'message'}),
            reason:
                'Error object must have exactly "code" and "message" keys, '
                'got: $errorKeys');
      },
    );
  });
}
