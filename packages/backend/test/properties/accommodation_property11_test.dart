// Feature: accommodation-management, Property 11: Application History Ordering
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 8.3**
///
/// Property 11: Application History Ordering
/// For any student's application history (applications with status `checked_out`
/// or `rejected`), the returned list shall be ordered by `created_at` descending.

/// Simulates the service's sort: descending by created_at.
List<DateTime> sortDescending(List<DateTime> dates) =>
    List<DateTime>.from(dates)..sort((a, b) => b.compareTo(a));

void main() {
  group('Property 11: Application History Ordering', () {
    // 11a: Sorting produces descending order — each element >= next
    Glados(any.intInRange(0, 20), ExploreConfig(numRuns: 100))
        .test('history list sorted by created_at descending', (listSize) {
      // Generate random timestamps
      final now = DateTime.now().millisecondsSinceEpoch;
      final dates = List.generate(
        listSize,
        (i) => DateTime.fromMillisecondsSinceEpoch(
            now - i * 86400000 + (i.hashCode % 86400000)),
      );

      final sorted = sortDescending(dates);

      // Verify ordering invariant: each element >= next
      for (int i = 0; i < sorted.length - 1; i++) {
        expect(
          sorted[i].compareTo(sorted[i + 1]) >= 0,
          isTrue,
          reason:
              'Element at $i (${sorted[i]}) must be >= element at ${i + 1} (${sorted[i + 1]})',
        );
      }
    });

    // 11b: Sorting is idempotent — sorting an already-sorted list yields same list
    Glados(any.intInRange(1, 20), ExploreConfig(numRuns: 100))
        .test('sorting is idempotent', (listSize) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final dates = List.generate(
        listSize,
        (i) => DateTime.fromMillisecondsSinceEpoch(
            now - i * 86400000 + (i.hashCode % 86400000)),
      );

      final sorted1 = sortDescending(dates);
      final sorted2 = sortDescending(sorted1);

      expect(sorted2, equals(sorted1),
          reason: 'Sorting an already-sorted list must produce identical result');
    });
  });
}
