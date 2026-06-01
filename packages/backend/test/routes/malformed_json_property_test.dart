// Feature: mykiz-platform, Property 19: Malformed JSON rejection
import 'dart:convert';

import 'package:backend/helpers/api_exceptions.dart';
import 'package:backend/helpers/request_helpers.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:glados/glados.dart';
import 'package:mocktail/mocktail.dart' hide any;
import 'package:test/test.dart';

/// **Validates: Requirements 10.7**
///
/// Property 19: Malformed JSON rejection
/// For any request body that is not valid JSON sent to an endpoint expecting
/// a JSON body, the Backend SHALL return 400 with code "INVALID_REQUEST".
///
/// We test this by:
/// 1. Generating random non-JSON strings (random bytes, truncated JSON,
///    invalid syntax) and verifying that parseJsonBody throws
///    InvalidRequestException with code 'INVALID_REQUEST' and statusCode 400.
/// 2. Verifying that InvalidRequestException always has the correct code and
///    status regardless of the message provided.

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

/// Custom generators for malformed JSON strings.
extension MalformedJsonGenerators on Any {
  /// Generates a string that is definitely NOT valid JSON.
  /// Strategies:
  /// - Random ASCII characters that don't form valid JSON
  /// - Truncated JSON (opening brace/bracket without closing)
  /// - Invalid JSON syntax (missing quotes, trailing commas, etc.)
  Generator<String> get malformedJson => either(
        // Strategy 1: Random non-JSON strings (letters, symbols, etc.)
        simple(
          generate: (random, size) {
            final length = 1 + random.nextInt(100);
            // Use characters that cannot form valid JSON on their own
            const chars = 'abcdefghijklmnopqrstuvwxyz!@#%^&*;|~`';
            return List.generate(
              length,
              (_) => chars[random.nextInt(chars.length)],
            ).join();
          },
          shrink: (input) => [if (input.length > 1) 'abc'],
        ),
        either(
          // Strategy 2: Truncated JSON (opening without closing)
          simple(
            generate: (random, size) {
              final variants = [
                '{"key": "value"',
                '{"key": ',
                '[1, 2, 3',
                '{"nested": {"a": 1}',
                '{"arr": [1, 2',
                '{',
                '[',
                '{"key": "val',
              ];
              return variants[random.nextInt(variants.length)];
            },
            shrink: (input) => ['{'],
          ),
          // Strategy 3: Invalid JSON syntax
          simple(
            generate: (random, size) {
              final variants = [
                '{key: "value"}', // unquoted key
                "{'key': 'value'}", // single quotes
                '{"key": "value",}', // trailing comma
                '{"key": undefined}', // undefined value
                '{"key": NaN}', // NaN
                '{123: "value"}', // numeric key
                '{"a": 1} {"b": 2}', // multiple root values
                ',', // just a comma
                ':', // just a colon
                '}{', // reversed braces
                '][', // reversed brackets
                '{"key": "value" "key2": "value2"}', // missing comma
              ];
              return variants[random.nextInt(variants.length)];
            },
            shrink: (input) => ['{key: "value"}'],
          ),
        ),
      );

  /// Generates any arbitrary message string for InvalidRequestException.
  Generator<String> get arbitraryMessage => simple(
        generate: (random, size) {
          final length = 1 + random.nextInt(200);
          const chars =
              'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
              '0123456789 .,!?-_()';
          return List.generate(
            length,
            (_) => chars[random.nextInt(chars.length)],
          ).join();
        },
        shrink: (input) => [if (input.length > 1) 'error'],
      );
}

void main() {
  group('Property 19: Malformed JSON rejection', () {
    // Property 19a: For any malformed JSON string, parseJsonBody SHALL throw
    // InvalidRequestException with code 'INVALID_REQUEST' and statusCode 400.
    Glados(any.malformedJson, ExploreConfig(numRuns: 100)).test(
      'parseJsonBody throws InvalidRequestException for any malformed JSON',
      (malformedBody) async {
        // First, confirm the generated string is indeed not valid JSON
        bool isValidJson;
        try {
          jsonDecode(malformedBody);
          isValidJson = true;
        } catch (_) {
          isValidJson = false;
        }

        // Skip if the generated string happens to be valid JSON
        // (extremely unlikely with our generators, but be safe)
        if (isValidJson) return;

        // Set up mock context and request
        final mockContext = _MockRequestContext();
        final mockRequest = _MockRequest();

        when(() => mockContext.request).thenReturn(mockRequest);
        when(() => mockRequest.json()).thenThrow(
          FormatException('Invalid JSON: $malformedBody'),
        );

        // Verify parseJsonBody throws InvalidRequestException
        expect(
          () => parseJsonBody(mockContext),
          throwsA(
            isA<InvalidRequestException>()
                .having((e) => e.code, 'code', 'INVALID_REQUEST')
                .having((e) => e.statusCode, 'statusCode', 400),
          ),
          reason: 'Malformed JSON "$malformedBody" should be rejected '
              'with INVALID_REQUEST',
        );
      },
    );

    // Property 19b: InvalidRequestException SHALL always have statusCode 400
    // and code 'INVALID_REQUEST' regardless of the message provided.
    Glados(any.arbitraryMessage, ExploreConfig(numRuns: 100)).test(
      'InvalidRequestException always has statusCode 400 and code INVALID_REQUEST',
      (message) {
        final exception = InvalidRequestException(message);

        expect(exception.statusCode, equals(400));
        expect(exception.code, equals('INVALID_REQUEST'));
        expect(exception.message, equals(message));
      },
    );

    // Property 19c: For any malformed JSON, the generated string is confirmed
    // to be unparseable by dart:convert, and parseJsonBody correctly maps
    // the FormatException to InvalidRequestException.
    Glados(any.malformedJson, ExploreConfig(numRuns: 100)).test(
      'malformed JSON strings are unparseable and correctly rejected',
      (malformedBody) async {
        // Verify the string is indeed malformed JSON
        bool throwsFormatException = false;
        try {
          jsonDecode(malformedBody);
        } on FormatException {
          throwsFormatException = true;
        }

        // Skip if somehow valid JSON
        if (!throwsFormatException) return;

        // Set up mock that simulates what dart_frog does internally
        // when request body is not valid JSON
        final mockContext = _MockRequestContext();
        final mockRequest = _MockRequest();

        when(() => mockContext.request).thenReturn(mockRequest);
        when(() => mockRequest.json()).thenThrow(
          FormatException('Unexpected character', malformedBody, 0),
        );

        // The parseJsonBody function must catch this and throw
        // InvalidRequestException
        try {
          await parseJsonBody(mockContext);
          fail('Should have thrown InvalidRequestException');
        } on InvalidRequestException catch (e) {
          expect(e.code, equals('INVALID_REQUEST'));
          expect(e.statusCode, equals(400));
        }
      },
    );
  });
}
