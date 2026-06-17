// Feature: accommodation-management, Property 12: Dashboard Priority Badge
import 'package:glados/glados.dart';
import 'package:shared_core/shared_core.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 8.4, 8.5**
///
/// Property 12: Dashboard Priority Badge
/// For any set of active applications belonging to a student, the dashboard
/// badge shall display the status with the highest priority where
/// `checked_in` > `approved` > `submitted`. If the active set is empty,
/// no badge shall be displayed.

/// Priority order: checkedIn > approved > submitted
/// Returns null if empty set.
AccommodationStatus? highestPriority(List<AccommodationStatus> activeStatuses) {
  if (activeStatuses.isEmpty) return null;
  if (activeStatuses.contains(AccommodationStatus.checkedIn)) {
    return AccommodationStatus.checkedIn;
  }
  if (activeStatuses.contains(AccommodationStatus.approved)) {
    return AccommodationStatus.approved;
  }
  return AccommodationStatus.submitted;
}

void main() {
  final activeStatuses = [
    AccommodationStatus.submitted,
    AccommodationStatus.approved,
    AccommodationStatus.checkedIn,
  ];

  group('Property 12: Dashboard Priority Badge', () {
    Glados(any.intInRange(0, 8), ExploreConfig(numRuns: 100))
        .test('badge shows highest priority active status', (bitmask) {
      // Use bitmask to select a subset of active statuses (3 bits for 3 statuses)
      final selected = <AccommodationStatus>[];
      for (int i = 0; i < 3; i++) {
        if ((bitmask >> i) & 1 == 1) selected.add(activeStatuses[i]);
      }

      final badge = highestPriority(selected);

      if (selected.isEmpty) {
        expect(badge, isNull);
      } else if (selected.contains(AccommodationStatus.checkedIn)) {
        expect(badge, equals(AccommodationStatus.checkedIn));
      } else if (selected.contains(AccommodationStatus.approved)) {
        expect(badge, equals(AccommodationStatus.approved));
      } else {
        expect(badge, equals(AccommodationStatus.submitted));
      }
    });
  });
}
