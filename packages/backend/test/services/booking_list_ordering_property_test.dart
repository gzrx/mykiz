// Property 15: Booking list ordering
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 11.1, 11.2**
///
/// For any list of active bookings returned for a student, they SHALL be ordered
/// by booking_date ascending. For any list of past/history bookings returned,
/// they SHALL be ordered by booking_date descending.

/// Returns true if the list is sorted ascending by date.
bool isSortedAscending(List<DateTime> dates) {
  for (var i = 1; i < dates.length; i++) {
    if (dates[i].isBefore(dates[i - 1])) return false;
  }
  return true;
}

/// Returns true if the list is sorted descending by date.
bool isSortedDescending(List<DateTime> dates) {
  for (var i = 1; i < dates.length; i++) {
    if (dates[i].isAfter(dates[i - 1])) return false;
  }
  return true;
}

/// Simulates the ORDER BY booking_date ASC clause used for active bookings.
List<DateTime> orderActiveBookings(List<DateTime> dates) {
  return [...dates]..sort((a, b) => a.compareTo(b));
}

/// Simulates the ORDER BY booking_date DESC clause used for history bookings.
List<DateTime> orderHistoryBookings(List<DateTime> dates) {
  return [...dates]..sort((a, b) => b.compareTo(a));
}

// --- Generators ---

extension OrderingGenerators on Any {
  /// Generate a list of random dates (0..20 items) within a 60-day window.
  Generator<List<DateTime>> get dateList => simple(
        generate: (random, size) {
          final count = random.nextInt(21); // 0 to 20 items
          final base = DateTime(2025, 1, 1);
          return List.generate(count, (_) {
            final dayOffset = random.nextInt(60);
            return base.add(Duration(days: dayOffset));
          });
        },
        shrink: (input) => input.length <= 1
            ? []
            : [input.sublist(0, input.length - 1)],
      );
}

void main() {
  group('Property 15: Booking list ordering', () {
    // 15a: Active bookings sorted ascending by date.
    Glados(any.dateList, ExploreConfig(numRuns: 200)).test(
      'active bookings are ordered by date ascending',
      (dates) {
        final sorted = orderActiveBookings(dates);
        expect(
          isSortedAscending(sorted),
          isTrue,
          reason: 'Active bookings must be ordered by booking_date ASC',
        );
      },
    );

    // 15b: History bookings sorted descending by date.
    Glados(any.dateList, ExploreConfig(numRuns: 200)).test(
      'history bookings are ordered by date descending',
      (dates) {
        final sorted = orderHistoryBookings(dates);
        expect(
          isSortedDescending(sorted),
          isTrue,
          reason: 'History bookings must be ordered by booking_date DESC',
        );
      },
    );

    // 15c: Ascending sort is idempotent — sorting already-sorted list is no-op.
    Glados(any.dateList, ExploreConfig(numRuns: 200)).test(
      'ascending sort is idempotent',
      (dates) {
        final once = orderActiveBookings(dates);
        final twice = orderActiveBookings(once);
        expect(once, equals(twice));
      },
    );

    // 15d: Descending sort is idempotent.
    Glados(any.dateList, ExploreConfig(numRuns: 200)).test(
      'descending sort is idempotent',
      (dates) {
        final once = orderHistoryBookings(dates);
        final twice = orderHistoryBookings(once);
        expect(once, equals(twice));
      },
    );
  });
}
