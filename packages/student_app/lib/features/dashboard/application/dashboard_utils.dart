import 'dart:math';

/// Returns the number of grid columns for a given screen width.
///
/// - width < 360 → 2
/// - 360 ≤ width < 600 → 3
/// - width ≥ 600 → max(4, floor(width / 120))
int computeColumnCount(double screenWidth) {
  if (screenWidth < 360) return 2;
  if (screenWidth < 600) return 3;
  return max(4, (screenWidth / 120).floor());
}

/// Returns a greeting string for the dashboard header.
///
/// - null/blank name → "Hi, Student"
/// - Non-blank → "Hi, [firstName]" (first space-delimited token, truncated at 20 chars with "…")
String formatGreeting(String? name) {
  if (name == null || name.trim().isEmpty) return 'Hi, Student';
  final firstName = name.split(' ').first;
  if (firstName.length > 20) return 'Hi, ${firstName.substring(0, 20)}…';
  return 'Hi, $firstName';
}
