import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../announcements/application/announcements_provider.dart';
import '../../complaints/application/complaints_provider.dart';

/// Pure badge text logic: 0 → null, 1–99 → count string, >99 → "99+".
/// ponytail: extracted for testability without Riverpod wiring.
String? formatBadgeCount(int count) {
  if (count <= 0) return null;
  return count > 99 ? '99+' : '$count';
}

/// Pure complaint status logic: returns first element's status, or null if empty.
/// ponytail: complaints list is already sorted newest-first by the API.
String? mostRecentComplaintStatus(List<String> statuses) {
  if (statuses.isEmpty) return null;
  return statuses.first;
}

/// Returns unread count as string, "99+" if > 99, null if 0.
/// ponytail: derives from totalItems in announcements list state.
/// Upgrade path: dedicated /announcements/unread-count endpoint.
Future<String?> announcementsBadgeProvider(WidgetRef ref) async {
  try {
    final state = ref.read(announcementsListProvider);
    return formatBadgeCount(state.totalItems);
  } catch (_) {
    return null;
  }
}

/// Returns most recent complaint status, or null if no complaints.
Future<String?> complaintsBadgeProvider(WidgetRef ref) async {
  try {
    final state = ref.read(complaintsListProvider);
    if (state.complaints.isEmpty) return null;
    return state.complaints.first.status;
  } catch (_) {
    return null;
  }
}
