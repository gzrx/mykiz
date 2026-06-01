// Feature: mykiz-platform, Property 6: Announcement validation
import 'package:backend/services/announcement_service.dart';
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 3.4, 3.5, 5.4, 5.5**
///
/// Property 6: Announcement validation
/// For any announcement creation or update request where the title is empty or
/// exceeds 200 characters, OR the body is empty or exceeds 5000 characters,
/// the Announcement_Service SHALL reject the request with a 400 status and
/// code "VALIDATION_ERROR", leaving the data unchanged.

/// Custom generators for announcement validation testing.
extension AnnouncementValidationGenerators on Any {
  /// Generates an invalid title: either empty or exceeding 200 characters.
  Generator<String> get invalidTitle => either(
        // Empty title
        simple(
          generate: (random, size) => '',
          shrink: (input) => [],
        ),
        // Title exceeding 200 characters (201 to 500 chars)
        simple(
          generate: (random, size) {
            final length = 201 + random.nextInt(300);
            return String.fromCharCodes(
              List.generate(length, (_) => 97 + random.nextInt(26)),
            );
          },
          shrink: (input) => [if (input.length > 201) 'a' * 201],
        ),
      );

  /// Generates a valid title: between 1 and 200 characters.
  Generator<String> get validTitle => simple(
        generate: (random, size) {
          final length = 1 + random.nextInt(200);
          return String.fromCharCodes(
            List.generate(length, (_) => 97 + random.nextInt(26)),
          );
        },
        shrink: (input) => [if (input.length > 1) 'a'],
      );

  /// Generates an invalid body: either empty or exceeding 5000 characters.
  Generator<String> get invalidBody => either(
        // Empty body
        simple(
          generate: (random, size) => '',
          shrink: (input) => [],
        ),
        // Body exceeding 5000 characters (5001 to 6000 chars)
        simple(
          generate: (random, size) {
            final length = 5001 + random.nextInt(1000);
            return String.fromCharCodes(
              List.generate(length, (_) => 97 + random.nextInt(26)),
            );
          },
          shrink: (input) => [if (input.length > 5001) 'b' * 5001],
        ),
      );

  /// Generates a valid body: between 1 and 5000 characters.
  Generator<String> get validBody => simple(
        generate: (random, size) {
          final length = 1 + random.nextInt(5000);
          return String.fromCharCodes(
            List.generate(length, (_) => 97 + random.nextInt(26)),
          );
        },
        shrink: (input) => [if (input.length > 1) 'b'],
      );
}

void main() {
  final service = AnnouncementService();

  group('Property 6: Announcement validation', () {
    // Property 6a: For any creation request with an invalid title (empty or
    // >200 chars), the service SHALL throw ValidationException with code
    // "VALIDATION_ERROR".
    Glados2(any.invalidTitle, any.validBody, ExploreConfig(numRuns: 100)).test(
      'create rejects invalid title with VALIDATION_ERROR',
      (invalidTitle, validBody) {
        expect(
          () => service.create(
            title: invalidTitle,
            body: validBody,
            authorId: 'test-author-id',
          ),
          throwsA(
            isA<ValidationException>()
                .having((e) => e.code, 'code', 'VALIDATION_ERROR'),
          ),
          reason: 'Title "${invalidTitle.length > 50 ? '${invalidTitle.substring(0, 50)}...' : invalidTitle}" '
              '(length=${invalidTitle.length}) should be rejected',
        );
      },
    );

    // Property 6b: For any creation request with an invalid body (empty or
    // >5000 chars), the service SHALL throw ValidationException with code
    // "VALIDATION_ERROR".
    Glados2(any.validTitle, any.invalidBody, ExploreConfig(numRuns: 100)).test(
      'create rejects invalid body with VALIDATION_ERROR',
      (validTitle, invalidBody) {
        expect(
          () => service.create(
            title: validTitle,
            body: invalidBody,
            authorId: 'test-author-id',
          ),
          throwsA(
            isA<ValidationException>()
                .having((e) => e.code, 'code', 'VALIDATION_ERROR'),
          ),
          reason: 'Body of length ${invalidBody.length} should be rejected',
        );
      },
    );

    // Property 6c: For any update request with an invalid title (empty or
    // >200 chars), the service SHALL throw ValidationException with code
    // "VALIDATION_ERROR".
    Glados(any.invalidTitle, ExploreConfig(numRuns: 100)).test(
      'update rejects invalid title with VALIDATION_ERROR',
      (invalidTitle) {
        expect(
          () => service.update('some-id', title: invalidTitle),
          throwsA(
            isA<ValidationException>()
                .having((e) => e.code, 'code', 'VALIDATION_ERROR'),
          ),
          reason: 'Update with title of length ${invalidTitle.length} should be rejected',
        );
      },
    );

    // Property 6d: For any update request with an invalid body (empty or
    // >5000 chars), the service SHALL throw ValidationException with code
    // "VALIDATION_ERROR".
    Glados(any.invalidBody, ExploreConfig(numRuns: 100)).test(
      'update rejects invalid body with VALIDATION_ERROR',
      (invalidBody) {
        expect(
          () => service.update('some-id', body: invalidBody),
          throwsA(
            isA<ValidationException>()
                .having((e) => e.code, 'code', 'VALIDATION_ERROR'),
          ),
          reason: 'Update with body of length ${invalidBody.length} should be rejected',
        );
      },
    );

    // Property 6e: For any creation request with BOTH invalid title AND
    // invalid body, the service SHALL still throw ValidationException.
    Glados2(any.invalidTitle, any.invalidBody, ExploreConfig(numRuns: 100))
        .test(
      'create rejects when both title and body are invalid',
      (invalidTitle, invalidBody) {
        expect(
          () => service.create(
            title: invalidTitle,
            body: invalidBody,
            authorId: 'test-author-id',
          ),
          throwsA(
            isA<ValidationException>()
                .having((e) => e.code, 'code', 'VALIDATION_ERROR'),
          ),
          reason: 'Both title (length=${invalidTitle.length}) and body '
              '(length=${invalidBody.length}) are invalid — should be rejected',
        );
      },
    );

    // Property 6f: For any creation request with valid title (1-200 chars)
    // and valid body (1-5000 chars), the service SHALL NOT throw
    // ValidationException (it may throw other errors due to no DB).
    Glados2(any.validTitle, any.validBody, ExploreConfig(numRuns: 100)).test(
      'create does NOT throw ValidationException for valid inputs',
      (validTitle, validBody) async {
        try {
          await service
              .create(
                title: validTitle,
                body: validBody,
                authorId: 'test-author-id',
              )
              .timeout(const Duration(milliseconds: 50));
        } on ValidationException {
          fail(
            'Should not throw ValidationException for valid title '
            '(length=${validTitle.length}) and valid body '
            '(length=${validBody.length})',
          );
        } catch (_) {
          // Expected: other errors (e.g., DB connection timeout,
          // SocketException) are fine — we only care that
          // ValidationException is NOT thrown.
        }
      },
    );

    // Property 6g: For any update request with valid title (1-200 chars),
    // the service SHALL NOT throw ValidationException.
    Glados(any.validTitle, ExploreConfig(numRuns: 100)).test(
      'update does NOT throw ValidationException for valid title',
      (validTitle) async {
        try {
          await service
              .update('some-id', title: validTitle)
              .timeout(const Duration(milliseconds: 50));
        } on ValidationException {
          fail(
            'Should not throw ValidationException for valid title '
            '(length=${validTitle.length})',
          );
        } catch (_) {
          // Expected: other errors (e.g., DB connection timeout) are fine.
        }
      },
    );

    // Property 6h: For any update request with valid body (1-5000 chars),
    // the service SHALL NOT throw ValidationException.
    Glados(any.validBody, ExploreConfig(numRuns: 100)).test(
      'update does NOT throw ValidationException for valid body',
      (validBody) async {
        try {
          await service
              .update('some-id', body: validBody)
              .timeout(const Duration(milliseconds: 50));
        } on ValidationException {
          fail(
            'Should not throw ValidationException for valid body '
            '(length=${validBody.length})',
          );
        } catch (_) {
          // Expected: other errors (e.g., DB connection timeout) are fine.
        }
      },
    );
  });
}
