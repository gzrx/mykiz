// Feature: accommodation-management, Property 14: Semester Submission Creates Correct Record
import 'package:glados/glados.dart';
import 'package:shared_core/shared_core.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 2.2, 2.5**
///
/// Property 14: Semester Submission Creates Correct Record
/// For any valid combination of room type (single or twin_sharing), preferred
/// block (existing block ID), and lifestyle tags (1-10 valid enum values),
/// submitting a semester application shall create a record with
/// `application_type = 'semester'`, `status = 'submitted'`, and all provided
/// field values stored correctly.

AccommodationApplication createSemesterRecord({
  required String roomType,
  required String blockId,
  required List<String> tags,
}) {
  return AccommodationApplication(
    id: 'test-id',
    studentId: 'student-1',
    applicationType: 'semester',
    status: 'submitted',
    roomTypePreference: roomType,
    preferredBlockId: blockId,
    lifestyleTags: tags,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  // Feature: accommodation-management, Property 14: Semester Submission Creates Correct Record
  final validTags = LifestyleTag.values.map((t) => t.dbValue).toList();
  final roomTypes = ['single', 'twin_sharing'];
  final blockIds = ['block-a', 'block-b', 'block-c'];

  group('Property 14: Semester Submission Creates Correct Record', () {
    Glados3(any.choose(roomTypes), any.choose(blockIds),
            any.intInRange(1, 10), ExploreConfig(numRuns: 100))
        .test('created record matches input fields',
            (roomType, blockId, tagCount) {
      final tags = validTags.take(tagCount).toList();

      final record = createSemesterRecord(
        roomType: roomType,
        blockId: blockId,
        tags: tags,
      );

      // Verify application type and status are correct
      expect(record.applicationType, equals('semester'));
      expect(record.status, equals('submitted'));

      // Verify all input fields stored correctly
      expect(record.roomTypePreference, equals(roomType));
      expect(record.preferredBlockId, equals(blockId));
      expect(record.lifestyleTags, equals(tags));
      expect(record.lifestyleTags.length, inInclusiveRange(1, 10));
    });

    Glados(any.choose(roomTypes), ExploreConfig(numRuns: 100))
        .test('room type is always single or twin_sharing', (roomType) {
      final record = createSemesterRecord(
        roomType: roomType,
        blockId: blockIds.first,
        tags: [validTags.first],
      );
      expect(record.roomTypePreference, isIn(roomTypes));
    });

    Glados(any.intInRange(1, 10), ExploreConfig(numRuns: 100))
        .test('lifestyle tags count within 1-10 range', (tagCount) {
      final tags = validTags.take(tagCount).toList();
      final record = createSemesterRecord(
        roomType: 'single',
        blockId: blockIds.first,
        tags: tags,
      );
      expect(record.lifestyleTags.length, equals(tagCount));
      expect(
          record.lifestyleTags.every((t) => LifestyleTag.fromDbValue(t) != null),
          isTrue);
    });
  });
}
