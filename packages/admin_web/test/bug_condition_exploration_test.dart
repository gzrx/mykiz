// Bug condition exploration test — confirms the three root-cause bugs exist.
// **Validates: Requirements 1.1, 1.2, 1.5**
//
// EXPECTED: This test FAILS on unfixed code (failure = bugs confirmed).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bug Condition Exploration', () {
    test('admin_web pubspec.yaml contains uses-material-design: true', () {
      final content = File('pubspec.yaml').readAsStringSync();
      // Must have a `flutter:` section with `uses-material-design: true`
      final hasFlag = RegExp(
        r'flutter:\s*\n\s+uses-material-design:\s*true',
      ).hasMatch(content);
      expect(hasFlag, isTrue,
          reason: 'admin_web pubspec.yaml is missing '
              '"flutter:\\n  uses-material-design: true"');
    });

    test('student_app pubspec.yaml contains uses-material-design: true', () {
      final content =
          File('../student_app/pubspec.yaml').readAsStringSync();
      final hasFlag = RegExp(
        r'flutter:\s*\n\s+uses-material-design:\s*true',
      ).hasMatch(content);
      expect(hasFlag, isTrue,
          reason: 'student_app pubspec.yaml is missing '
              '"flutter:\\n  uses-material-design: true"');
    });

    test('apiClientProvider baseUrl is non-empty', () {
      // Read the source directly — avoids needing to spin up Riverpod.
      // ponytail: direct file-read is simpler than importing + mocking the provider container
      final source = File(
        'lib/features/auth/data/auth_repository.dart',
      ).readAsStringSync();

      // The bug: MyKizApiClient(baseUrl: '') — an empty string literal.
      final hasEmptyBaseUrl = source.contains("baseUrl: ''") ||
          source.contains('baseUrl: ""');

      expect(hasEmptyBaseUrl, isFalse,
          reason: 'apiClientProvider uses an empty baseUrl '
              '(found baseUrl: \'\')');
    });
  });
}
