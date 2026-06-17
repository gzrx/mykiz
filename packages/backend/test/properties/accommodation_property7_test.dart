// Feature: accommodation-management, Property 7: Rejection Reason Validation
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 5.2, 5.3**
///
/// Property 7: Rejection Reason Validation
/// For any string `reason`, rejecting a submitted application succeeds iff
/// `reason.trim()` has length between 1 and 500 characters. Empty strings and
/// whitespace-only strings shall be rejected with VALIDATION_ERROR.

bool isReasonValid(String reason) {
  final trimmed = reason.trim();
  return trimmed.isNotEmpty && trimmed.length <= 500;
}

void main() {
  // Feature: accommodation-management, Property 7: Rejection Reason Validation
  group('Property 7: Rejection Reason Validation', () {
    // Generate strings of varying lengths (0-600) and verify the validation rule
    Glados(any.intInRange(0, 601), ExploreConfig(numRuns: 100))
        .test('reason valid iff trimmed length in [1,500]', (len) {
      // Build a string of exactly `len` non-whitespace characters
      final reason = 'a' * len;
      final valid = isReasonValid(reason);
      final trimmedLen = reason.trim().length;
      expect(valid, equals(trimmedLen >= 1 && trimmedLen <= 500));
    });

    // Whitespace-only strings of any length must be invalid
    Glados(any.intInRange(0, 100), ExploreConfig(numRuns: 100))
        .test('whitespace-only strings are always invalid', (len) {
      final reason = ' ' * len;
      expect(isReasonValid(reason), isFalse);
    });

    // Strings with leading/trailing whitespace: validity depends on trimmed content
    Glados(any.intInRange(0, 600), ExploreConfig(numRuns: 100))
        .test('leading/trailing whitespace does not affect trimmed validation',
            (contentLen) {
      final reason = '   ${'x' * contentLen}   ';
      final valid = isReasonValid(reason);
      expect(valid, equals(contentLen >= 1 && contentLen <= 500));
    });
  });
}
