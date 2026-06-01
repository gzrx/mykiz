// Feature: mykiz-platform, Property 11: Complaint validation
import 'dart:async';

import 'package:backend/services/complaint_service.dart';
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 6.2, 6.3**
///
/// Property 11: Complaint validation
/// For any complaint submission where the description is empty or exceeds 1000
/// characters, OR the location is empty or exceeds 200 characters, the
/// Complaint_Service SHALL reject the request with a 400 status and code
/// "VALIDATION_ERROR".

/// Custom generators for complaint validation testing.
extension ComplaintGenerators on Any {
  /// Generates an empty string (always invalid for both description and location).
  Generator<String> get emptyString => simple(
        generate: (random, size) => '',
        shrink: (input) => [],
      );

  /// Generates a string exceeding 1000 characters (invalid description).
  Generator<String> get descriptionTooLong => simple(
        generate: (random, size) {
          final length = 1001 + random.nextInt(500); // 1001 to 1500 chars
          return String.fromCharCodes(
            List.generate(length, (_) => 97 + random.nextInt(26)), // a-z
          );
        },
        shrink: (input) => [],
      );

  /// Generates a string exceeding 200 characters (invalid location).
  Generator<String> get locationTooLong => simple(
        generate: (random, size) {
          final length = 201 + random.nextInt(300); // 201 to 500 chars
          return String.fromCharCodes(
            List.generate(length, (_) => 97 + random.nextInt(26)), // a-z
          );
        },
        shrink: (input) => [],
      );

  /// Generates a valid description (1-1000 characters).
  Generator<String> get validDescription => simple(
        generate: (random, size) {
          final length = 1 + random.nextInt(1000); // 1 to 1000 chars
          return String.fromCharCodes(
            List.generate(length, (_) => 97 + random.nextInt(26)), // a-z
          );
        },
        shrink: (input) => [],
      );

  /// Generates a valid location (1-200 characters).
  Generator<String> get validLocation => simple(
        generate: (random, size) {
          final length = 1 + random.nextInt(200); // 1 to 200 chars
          return String.fromCharCodes(
            List.generate(length, (_) => 97 + random.nextInt(26)), // a-z
          );
        },
        shrink: (input) => [],
      );

  /// Generates an invalid description (either empty or >1000 chars).
  Generator<String> get invalidDescription => simple(
        generate: (random, size) {
          if (random.nextBool()) {
            // Empty string
            return '';
          } else {
            // Exceeds 1000 characters
            final length = 1001 + random.nextInt(500);
            return String.fromCharCodes(
              List.generate(length, (_) => 97 + random.nextInt(26)),
            );
          }
        },
        shrink: (input) => [],
      );

  /// Generates an invalid location (either empty or >200 chars).
  Generator<String> get invalidLocation => simple(
        generate: (random, size) {
          if (random.nextBool()) {
            // Empty string
            return '';
          } else {
            // Exceeds 200 characters
            final length = 201 + random.nextInt(300);
            return String.fromCharCodes(
              List.generate(length, (_) => 97 + random.nextInt(26)),
            );
          }
        },
        shrink: (input) => [],
      );
}

void main() {
  late ComplaintService service;

  setUp(() {
    service = ComplaintService();
  });

  group('Property 11: Complaint validation', () {
    // Property 11a: For any complaint with an invalid description (empty or
    // >1000 chars) and any location, the service SHALL throw
    // ComplaintException with code 'VALIDATION_ERROR'.
    Glados2(any.invalidDescription, any.validLocation,
            ExploreConfig(numRuns: 100))
        .test(
      'rejects complaint with invalid description (empty or >1000 chars)',
      (invalidDesc, location) async {
        expect(
          () => service.submit(
            description: invalidDesc,
            location: location,
            studentId: 'test-student-id',
          ),
          throwsA(
            isA<ComplaintException>()
                .having((e) => e.code, 'code', 'VALIDATION_ERROR')
                .having((e) => e.statusCode, 'statusCode', 400),
          ),
          reason: 'Description "${invalidDesc.length > 50 ? '${invalidDesc.substring(0, 50)}...' : invalidDesc}" '
              '(length=${invalidDesc.length}) should be rejected with VALIDATION_ERROR',
        );
      },
    );

    // Property 11b: For any complaint with a valid description but an invalid
    // location (empty or >200 chars), the service SHALL throw
    // ComplaintException with code 'VALIDATION_ERROR'.
    Glados2(any.validDescription, any.invalidLocation,
            ExploreConfig(numRuns: 100))
        .test(
      'rejects complaint with invalid location (empty or >200 chars)',
      (description, invalidLoc) async {
        expect(
          () => service.submit(
            description: description,
            location: invalidLoc,
            studentId: 'test-student-id',
          ),
          throwsA(
            isA<ComplaintException>()
                .having((e) => e.code, 'code', 'VALIDATION_ERROR')
                .having((e) => e.statusCode, 'statusCode', 400),
          ),
          reason: 'Location "${invalidLoc.length > 50 ? '${invalidLoc.substring(0, 50)}...' : invalidLoc}" '
              '(length=${invalidLoc.length}) should be rejected with VALIDATION_ERROR',
        );
      },
    );

    // Property 11c: For any complaint with both invalid description AND
    // invalid location, the service SHALL throw ComplaintException with
    // code 'VALIDATION_ERROR'.
    Glados2(any.invalidDescription, any.invalidLocation,
            ExploreConfig(numRuns: 100))
        .test(
      'rejects complaint with both invalid description and invalid location',
      (invalidDesc, invalidLoc) async {
        expect(
          () => service.submit(
            description: invalidDesc,
            location: invalidLoc,
            studentId: 'test-student-id',
          ),
          throwsA(
            isA<ComplaintException>()
                .having((e) => e.code, 'code', 'VALIDATION_ERROR')
                .having((e) => e.statusCode, 'statusCode', 400),
          ),
          reason: 'Both description (length=${invalidDesc.length}) and location '
              '(length=${invalidLoc.length}) are invalid — should be rejected',
        );
      },
    );

    // Property 11d: For any complaint with valid description (1-1000 chars)
    // and valid location (1-200 chars), the service SHALL NOT throw a
    // VALIDATION_ERROR. (It may throw other errors due to no DB connection,
    // but not a validation error.)
    Glados2(any.validDescription, any.validLocation,
            ExploreConfig(numRuns: 100))
        .test(
      'does NOT throw VALIDATION_ERROR for valid description and location',
      (description, location) async {
        try {
          await service
              .submit(
                description: description,
                location: location,
                studentId: 'test-student-id',
              )
              .timeout(const Duration(milliseconds: 200));
          // If it succeeds (unlikely without DB), that's fine — no validation error
        } on ComplaintException catch (e) {
          // If a ComplaintException is thrown, it must NOT be VALIDATION_ERROR
          expect(
            e.code,
            isNot('VALIDATION_ERROR'),
            reason: 'Valid description (length=${description.length}) and '
                'location (length=${location.length}) should not trigger '
                'VALIDATION_ERROR, but got: ${e.message}',
          );
        } catch (_) {
          // Any other exception (e.g., DB connection error, timeout) is
          // acceptable — it means validation passed and the service moved on
          // to infrastructure operations.
        }
      },
    );
  });
}
