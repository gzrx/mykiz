import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/dashboard_providers.dart';

/// A single module entry on the dashboard grid.
class ModuleRegistryEntry {
  const ModuleRegistryEntry({
    required this.label,
    required this.icon,
    required this.routePath,
    this.badgeProvider,
  });

  final String label;
  final IconData icon;
  final String routePath;

  /// Optional async callback returning badge text, or null for no badge.
  /// If it throws, the tile renders without a badge.
  final Future<String?> Function(WidgetRef ref)? badgeProvider;

  bool get isValid => label.isNotEmpty && routePath.isNotEmpty;
}

/// Deduplicates entries by routePath, keeping first occurrence.
/// ponytail: O(n²) scan is fine for a handful of modules.
/// Upgrade path: use a Set<String> if registry grows past ~20 entries.
List<ModuleRegistryEntry> dedupRegistry(List<ModuleRegistryEntry> entries) {
  final seen = <String>{};
  return [
    for (final e in entries)
      if (seen.add(e.routePath)) e,
  ];
}

/// The master list of dashboard modules.
/// Add new modules here — no widget changes needed.
final List<ModuleRegistryEntry> moduleRegistry = dedupRegistry([
  ModuleRegistryEntry(
    label: 'Announcements',
    icon: Icons.campaign_outlined,
    routePath: '/announcements',
    badgeProvider: announcementsBadgeProvider,
  ),
  ModuleRegistryEntry(
    label: 'Complaints',
    icon: Icons.report_problem_outlined,
    routePath: '/complaints',
    badgeProvider: complaintsBadgeProvider,
  ),
  ModuleRegistryEntry(
    label: 'Accommodation',
    icon: Icons.hotel_outlined,
    routePath: '/accommodation',
    badgeProvider: accommodationBadgeProvider,
  ),
]);
