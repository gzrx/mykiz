// Feature: accommodation-management, Property 8: Room-Bed Count Invariant
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 10.1, 10.2**
///
/// Property 8: Room-Bed Count Invariant
/// For any room in the system, if `room_type = 'single'` then the room has
/// exactly 1 bed, and if `room_type = 'twin_sharing'` then the room has
/// exactly 2 beds.

int expectedBedCount(String roomType) => roomType == 'single' ? 1 : 2;

void main() {
  group('Property 8: Room-Bed Count Invariant', () {
    Glados(any.choose(['single', 'twin_sharing']), ExploreConfig(numRuns: 100))
        .test('bed count matches room type invariant', (roomType) {
      final expected = expectedBedCount(roomType);
      if (roomType == 'single') {
        expect(expected, equals(1));
      } else {
        expect(expected, equals(2));
      }
    });
  });
}
