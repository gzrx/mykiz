import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart'; // apiClientProvider

/// Actionable counts surfaced on the Overview landing page.
class OverviewCounts {
  const OverviewCounts({
    required this.submittedComplaints,
    required this.pendingBookings,
    required this.submittedApplications,
    required this.pendingCheckIns,
    required this.nearFullBlocks,
  });

  final int submittedComplaints;
  final int pendingBookings;
  final int submittedApplications;
  final int pendingCheckIns;
  final int nearFullBlocks;

  int get total =>
      submittedComplaints +
      pendingBookings +
      submittedApplications +
      pendingCheckIns +
      nearFullBlocks;
}

/// Fetches all actionable counts. Each source is fetched independently so one
/// failing source degrades to 0 rather than failing the whole page.
final overviewCountsProvider = FutureProvider<OverviewCounts>((ref) async {
  final api = ref.watch(apiClientProvider);

  Future<int> safe(Future<int> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return 0;
    }
  }

  final complaints = await safe(() async {
    // meta.totalItems is the total; but we need submitted-only.
    // Fetch a page filtered client-side is not supported; use a dedicated
    // count via listComplaints then filter. For simplicity, fetch page 1
    // (limit 100) and count status == 'submitted'.
    final page = await api.listComplaints(limit: 100);
    return page.items.where((c) => c.status == 'submitted').length;
  });

  final pendingBookings = await safe(() async {
    final r = await api.listAllBookings(status: 'pending', limit: 1);
    return r.meta.totalItems;
  });

  final submittedApps = await safe(() async {
    final resp = await api.listApplications(status: 'submitted', limit: 1);
    final meta = resp['meta'] as Map<String, dynamic>?;
    return (meta?['totalItems'] as int?) ?? 0;
  });

  final pendingCheckIns = await safe(() async {
    final resp = await api.listApplications(status: 'approved', limit: 1);
    final meta = resp['meta'] as Map<String, dynamic>?;
    return (meta?['totalItems'] as int?) ?? 0;
  });

  final nearFullBlocks = await safe(() async {
    final blocks = await api.listBlocks();
    var count = 0;
    for (final b in blocks) {
      final rooms = await api.getOccupancy(b.id);
      final total = rooms.fold<int>(0, (s, r) => s + r.total);
      final occupied = rooms.fold<int>(0, (s, r) => s + r.occupied);
      if (total > 0 && occupied / total >= 0.8) count++;
    }
    return count;
  });

  return OverviewCounts(
    submittedComplaints: complaints,
    pendingBookings: pendingBookings,
    submittedApplications: submittedApps,
    pendingCheckIns: pendingCheckIns,
    nearFullBlocks: nearFullBlocks,
  );
});
