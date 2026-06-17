import 'package:flutter/material.dart';

/// A single module entry for the Dashboard.
class ModuleEntry {
  const ModuleEntry({
    required this.name,
    required this.icon,
    required this.route,
  });

  /// Display name (non-empty, max 50 chars).
  final String name;

  /// Material icon displayed on the card.
  final IconData icon;

  /// Route path (non-empty, starts with '/').
  final String route;

  /// Whether this entry passes validation rules.
  bool get isValid =>
      name.trim().isNotEmpty &&
      name.length <= 50 &&
      route.trim().isNotEmpty &&
      route.startsWith('/');
}
