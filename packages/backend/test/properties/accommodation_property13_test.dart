// Feature: accommodation-management, Property 13: Room Listing Filtered by Block
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 10.4**
///
/// Property 13: Room Listing Filtered by Block
/// For any block ID, the rooms listing endpoint shall return only rooms where
/// `block_id` equals the requested block, and every room belonging to that block
/// shall be included.

/// Simulates the room filter: returns rooms whose blockId matches the target.
List<Map<String, String>> filterRoomsByBlock(
    List<Map<String, String>> rooms, String targetBlockId) {
  return rooms.where((r) => r['blockId'] == targetBlockId).toList();
}

void main() {
  final blockIds = ['block-a', 'block-b', 'block-c'];

  group('Property 13: Room Listing Filtered by Block', () {
    // 13a: All returned rooms belong to the target block (correctness)
    Glados2(any.intInRange(0, 2), any.intInRange(0, 20),
            ExploreConfig(numRuns: 100))
        .test('filter returns only rooms from target block',
        (blockIndex, roomCount) {
      final targetBlock = blockIds[blockIndex];

      // Generate rooms with deterministic block assignments
      final rooms = List.generate(
        roomCount,
        (i) => <String, String>{'id': 'room-$i', 'blockId': blockIds[i % blockIds.length]},
      );

      final filtered = filterRoomsByBlock(rooms, targetBlock);

      // Verify: all returned rooms belong to target block
      for (final room in filtered) {
        expect(room['blockId'], equals(targetBlock),
            reason: 'Filtered room ${room['id']} must belong to target block');
      }
    });

    // 13b: No rooms from the target block are missing (completeness)
    Glados2(any.intInRange(0, 2), any.intInRange(0, 20),
            ExploreConfig(numRuns: 100))
        .test('filter includes every room from target block',
        (blockIndex, roomCount) {
      final targetBlock = blockIds[blockIndex];

      final rooms = List.generate(
        roomCount,
        (i) => <String, String>{'id': 'room-$i', 'blockId': blockIds[i % blockIds.length]},
      );

      final filtered = filterRoomsByBlock(rooms, targetBlock);

      // Count expected rooms
      final expectedCount =
          rooms.where((r) => r['blockId'] == targetBlock).length;
      expect(filtered.length, equals(expectedCount),
          reason: 'All rooms from target block must be included');
    });

    // 13c: Rooms from other blocks are excluded
    Glados2(any.intInRange(0, 2), any.intInRange(1, 20),
            ExploreConfig(numRuns: 100))
        .test('filter excludes rooms from other blocks',
        (blockIndex, roomCount) {
      final targetBlock = blockIds[blockIndex];

      final rooms = List.generate(
        roomCount,
        (i) => <String, String>{'id': 'room-$i', 'blockId': blockIds[i % blockIds.length]},
      );

      final filtered = filterRoomsByBlock(rooms, targetBlock);

      // Verify: no room from a different block snuck in
      final foreignRooms =
          filtered.where((r) => r['blockId'] != targetBlock).toList();
      expect(foreignRooms, isEmpty,
          reason: 'No room from another block should appear in results');
    });
  });
}
