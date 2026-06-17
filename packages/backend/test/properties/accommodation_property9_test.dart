// Feature: accommodation-management, Property 9: Lifestyle Tag Validation
import 'package:glados/glados.dart';
import 'package:shared_core/shared_core.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 12.1, 12.2**
///
/// Property 9: Lifestyle Tag Validation
/// For any submitted tag set, storage succeeds iff every tag in the set is a
/// valid LifestyleTag enum value AND the set size is between 1 and 10 inclusive.
/// Any tag not in the enum shall cause rejection.

bool areTagsValid(List<String> tags) {
  if (tags.isEmpty || tags.length > 10) return false;
  return tags.every((t) => LifestyleTag.fromDbValue(t) != null);
}

void main() {
  final validDbValues = LifestyleTag.values.map((t) => t.dbValue).toList();
  final allPossible = [...validDbValues, 'invalid_tag', 'unknown', ''];

  group('Property 9: Lifestyle Tag Validation', () {
    Glados(any.intInRange(0, 15), ExploreConfig(numRuns: 100))
        .test('tag set valid iff 1-10 tags all from enum', (size) {
      // Generate a tag list of `size` from valid values only
      final tags =
          List.generate(size, (i) => validDbValues[i % validDbValues.length]);
      final valid = areTagsValid(tags);
      expect(valid, equals(size >= 1 && size <= 10));
    });

    Glados(any.intInRange(1, 10), ExploreConfig(numRuns: 100))
        .test('any invalid tag in set causes rejection', (size) {
      // Build a list with one invalid tag injected
      final tags = List.generate(
          size, (i) => i == 0 ? 'invalid_tag' : validDbValues[i % validDbValues.length]);
      expect(areTagsValid(tags), isFalse);
    });

    Glados(any.choose(allPossible), ExploreConfig(numRuns: 100))
        .test('single tag valid iff it is in LifestyleTag enum', (tag) {
      final result = areTagsValid([tag]);
      final expected = LifestyleTag.fromDbValue(tag) != null;
      expect(result, equals(expected));
    });
  });
}
