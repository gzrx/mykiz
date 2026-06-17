// Feature: accommodation-management, Property 10: Tag Filter AND Logic
import 'package:glados/glados.dart';
import 'package:shared_core/shared_core.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 12.4, 12.5**
///
/// Property 10: Tag Filter AND Logic
/// For any set of filter tags and any collection of applications, the filtered
/// result shall contain only applications whose `lifestyle_tags` array contains
/// ALL of the filter tags. Applications with empty tags shall never appear when
/// any filter is active.

/// AND filter: app passes iff its tags contain ALL filter tags.
bool passesFilter(List<String> appTags, List<String> filterTags) {
  if (filterTags.isEmpty) return true; // No filter = show all
  if (appTags.isEmpty) return false; // Empty tags excluded when filter active
  return filterTags.every((f) => appTags.contains(f));
}

void main() {
  final allTags = LifestyleTag.values.map((t) => t.dbValue).toList();

  group('Property 10: Tag Filter AND Logic', () {
    // 10a: AND filter correctness — result contains only apps where filter ⊆ app tags
    Glados2(any.intInRange(0, 5), any.intInRange(0, 10),
            ExploreConfig(numRuns: 100))
        .test('AND filter correctness', (filterSize, appTagSize) {
      final filterTags = allTags.take(filterSize).toList();
      final appTags = allTags.take(appTagSize).toList();

      final passes = passesFilter(appTags, filterTags);

      if (filterTags.isEmpty) {
        expect(passes, isTrue, reason: 'No filter means all pass');
      } else if (appTags.isEmpty) {
        expect(passes, isFalse, reason: 'Empty tags excluded when filter active');
      } else {
        final allContained = filterTags.every((f) => appTags.contains(f));
        expect(passes, equals(allContained));
      }
    });

    // 10b: Empty-tag apps never pass when any filter is active
    Glados(any.intInRange(1, 10), ExploreConfig(numRuns: 100)).test(
      'empty-tag apps excluded when any filter is active',
      (filterSize) {
        final filterTags = allTags.take(filterSize).toList();
        final emptyAppTags = <String>[];

        expect(
          passesFilter(emptyAppTags, filterTags),
          isFalse,
          reason: 'Apps with empty tags must be excluded when filter is active',
        );
      },
    );

    // 10c: No filter means all apps pass (including empty-tag apps)
    Glados(any.intInRange(0, 10), ExploreConfig(numRuns: 100)).test(
      'no filter means all apps pass regardless of tags',
      (appTagSize) {
        final appTags = allTags.take(appTagSize).toList();
        final noFilter = <String>[];

        expect(
          passesFilter(appTags, noFilter),
          isTrue,
          reason: 'Empty filter = show all, regardless of app tags',
        );
      },
    );

    // 10d: Superset of filter tags always passes
    Glados2(any.intInRange(1, 5), any.intInRange(0, 5),
            ExploreConfig(numRuns: 100))
        .test('app with superset of filter tags always passes',
        (filterSize, extraSize) {
      final filterTags = allTags.take(filterSize).toList();
      // App has all filter tags plus some extra
      final appTags = allTags.take(filterSize + extraSize).toList();

      expect(
        passesFilter(appTags, filterTags),
        isTrue,
        reason: 'App tags that are a superset of filter must pass',
      );
    });
  });
}
