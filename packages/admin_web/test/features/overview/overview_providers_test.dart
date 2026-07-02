import 'package:admin_web/features/overview/application/overview_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OverviewCounts holds the five actionable metrics', () {
    const c = OverviewCounts(
      submittedComplaints: 2,
      pendingBookings: 1,
      submittedApplications: 3,
      pendingCheckIns: 0,
      nearFullBlocks: 1,
    );
    expect(c.submittedComplaints, 2);
    expect(c.total, 7); // sum of actionable items
  });
}
