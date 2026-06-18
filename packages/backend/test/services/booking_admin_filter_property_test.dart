// Feature: booking-services, Property 19: Admin booking filter correctness
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 13.2**
///
/// Property 19: Admin booking filter correctness
/// For any filter combination (facility, status, date range) applied to the
/// bookings list, the returned results SHALL contain only bookings matching ALL
/// specified filter criteria.

/// Minimal booking representation for filter testing.
class _Booking {
  final String id;
  final String facilityId;
  final String status;
  final DateTime bookingDate;

  _Booking({
    required this.id,
    required this.facilityId,
    required this.status,
    required this.bookingDate,
  });

  @override
  String toString() =>
      '_Booking(id=$id, facility=$facilityId, status=$status, date=$bookingDate)';
}

/// Pure filter function matching the design's listAllBookings filter logic.
List<_Booking> applyFilters({
  required List<_Booking> allBookings,
  String? facilityId,
  String? status,
  DateTime? fromDate,
  DateTime? toDate,
}) {
  return allBookings.where((b) {
    if (facilityId != null && b.facilityId != facilityId) return false;
    if (status != null && b.status != status) return false;
    if (fromDate != null && b.bookingDate.isBefore(fromDate)) return false;
    if (toDate != null && b.bookingDate.isAfter(toDate)) return false;
    return true;
  }).toList();
}

// --- Generators ---

const _facilities = ['fac-A', 'fac-B', 'fac-C'];
const _statuses = [
  'pending',
  'confirmed',
  'cancelled',
  'completed',
  'no_show',
  'rejected',
];

_Booking _randomBooking(int index, Random random) {
  final date = DateTime(2025, 1, 1).add(Duration(days: random.nextInt(60)));
  return _Booking(
    id: 'bk-$index',
    facilityId: _facilities[random.nextInt(_facilities.length)],
    status: _statuses[random.nextInt(_statuses.length)],
    bookingDate: DateTime(date.year, date.month, date.day),
  );
}

final _bookingListGen = any.simple<List<_Booking>>(
  generate: (random, size) {
    final length = 1 + random.nextInt(15); // 1..15 bookings
    return List.generate(length, (i) => _randomBooking(i, random));
  },
  shrink: (input) => [if (input.length > 1) input.sublist(1)],
);

/// Generates a filter combination: (facilityId?, status?, fromDate?, toDate?).
typedef _Filters = ({String? facilityId, String? status, DateTime? fromDate, DateTime? toDate});

final _filterGen = any.simple<_Filters>(
  generate: (random, size) {
    final facilityId =
        random.nextBool() ? _facilities[random.nextInt(_facilities.length)] : null;
    final status =
        random.nextBool() ? _statuses[random.nextInt(_statuses.length)] : null;
    DateTime? fromDate;
    DateTime? toDate;
    if (random.nextBool()) {
      fromDate = DateTime(2025, 1, 1).add(Duration(days: random.nextInt(30)));
      fromDate = DateTime(fromDate.year, fromDate.month, fromDate.day);
    }
    if (random.nextBool()) {
      toDate = DateTime(2025, 1, 15).add(Duration(days: random.nextInt(45)));
      toDate = DateTime(toDate.year, toDate.month, toDate.day);
    }
    return (facilityId: facilityId, status: status, fromDate: fromDate, toDate: toDate);
  },
  shrink: (input) => [],
);

void main() {
  group('Property 19: Admin booking filter correctness', () {
    // 19a: All returned results match every specified filter criterion.
    Glados2(_bookingListGen, _filterGen, ExploreConfig(numRuns: 300)).test(
      'returned results match ALL filter criteria',
      (bookings, filters) {
        final results = applyFilters(
          allBookings: bookings,
          facilityId: filters.facilityId,
          status: filters.status,
          fromDate: filters.fromDate,
          toDate: filters.toDate,
        );

        for (final b in results) {
          if (filters.facilityId != null) {
            expect(b.facilityId, equals(filters.facilityId),
                reason: 'Booking ${b.id} should match facility filter');
          }
          if (filters.status != null) {
            expect(b.status, equals(filters.status),
                reason: 'Booking ${b.id} should match status filter');
          }
          if (filters.fromDate != null) {
            expect(b.bookingDate.isBefore(filters.fromDate!), isFalse,
                reason: 'Booking ${b.id} date should not be before fromDate');
          }
          if (filters.toDate != null) {
            expect(b.bookingDate.isAfter(filters.toDate!), isFalse,
                reason: 'Booking ${b.id} date should not be after toDate');
          }
        }
      },
    );

    // 19b: No excluded bookings would have matched all criteria (completeness).
    Glados2(_bookingListGen, _filterGen, ExploreConfig(numRuns: 300)).test(
      'no excluded booking matches all filter criteria',
      (bookings, filters) {
        final results = applyFilters(
          allBookings: bookings,
          facilityId: filters.facilityId,
          status: filters.status,
          fromDate: filters.fromDate,
          toDate: filters.toDate,
        );

        final resultIds = results.map((b) => b.id).toSet();
        final excluded = bookings.where((b) => !resultIds.contains(b.id));

        for (final b in excluded) {
          // At least one filter must NOT match for excluded bookings.
          final matchesFacility =
              filters.facilityId == null || b.facilityId == filters.facilityId;
          final matchesStatus =
              filters.status == null || b.status == filters.status;
          final matchesFrom =
              filters.fromDate == null || !b.bookingDate.isBefore(filters.fromDate!);
          final matchesTo =
              filters.toDate == null || !b.bookingDate.isAfter(filters.toDate!);

          expect(matchesFacility && matchesStatus && matchesFrom && matchesTo,
              isFalse,
              reason:
                  'Excluded booking ${b.id} matches ALL criteria but was filtered out');
        }
      },
    );
  });
}
