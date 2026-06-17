import 'package:flutter/material.dart';

import 'module_entry.dart';

/// Central registry of all dashboard modules.
/// Add an entry here to surface a new module on the Dashboard.
const List<ModuleEntry> moduleRegistry = [
  ModuleEntry(
    name: 'Announcements',
    icon: Icons.campaign,
    route: '/announcements',
  ),
  ModuleEntry(
    name: 'Complaints',
    icon: Icons.report_problem,
    route: '/complaints',
  ),
];
