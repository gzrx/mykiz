// Preservation property tests — confirms baseline behavior that must NOT change.
// **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**
//
// EXPECTED: These tests PASS on unfixed code (establishing baseline to preserve).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Preservation — Student App API Unchanged', () {
    test('student_app apiClientProvider baseUrl defaults to https://api.isaacfurqan.dev', () {
      final source =
          File('../student_app/lib/features/auth/application/auth_provider.dart')
              .readAsStringSync();

      // ponytail: file-read avoids needing Riverpod container
      expect(
        source.contains("defaultValue: 'https://api.isaacfurqan.dev'"),
        isTrue,
        reason: 'student_app baseUrl must default to https://api.isaacfurqan.dev',
      );
    });
  });

  group('Preservation — admin_web pubspec dependencies intact', () {
    test('admin_web pubspec retains all expected dependencies', () {
      final content = File('pubspec.yaml').readAsStringSync();

      const expectedDeps = [
        'flutter:',
        'api_client:',
        'shared_core:',
        'flutter_riverpod:',
        'riverpod_annotation:',
        'go_router:',
        'google_fonts:',
      ];

      for (final dep in expectedDeps) {
        expect(content.contains(dep), isTrue,
            reason: 'admin_web pubspec missing dependency: $dep');
      }
    });
  });

  group('Preservation — student_app pubspec dependencies intact', () {
    test('student_app pubspec retains all expected dependencies', () {
      final content =
          File('../student_app/pubspec.yaml').readAsStringSync();

      const expectedDeps = [
        'flutter:',
        'api_client:',
        'shared_core:',
        'flutter_riverpod:',
        'riverpod_annotation:',
        'go_router:',
        'google_fonts:',
        'image_picker:',
        'qr_flutter:',
      ];

      for (final dep in expectedDeps) {
        expect(content.contains(dep), isTrue,
            reason: 'student_app pubspec missing dependency: $dep');
      }
    });
  });

  group('Preservation — Dashboard module registry unchanged', () {
    test('module_registry retains Announcements, Complaints, Accommodation cards', () {
      final source = File(
        'lib/features/dashboard/data/module_registry.dart',
      ).readAsStringSync();

      // Verify the three non-Bookings cards are still present
      expect(source.contains("name: 'Announcements'"), isTrue);
      expect(source.contains("name: 'Complaints'"), isTrue);
      expect(source.contains("name: 'Accommodation'"), isTrue);

      // Verify their routes
      expect(source.contains("route: '/announcements'"), isTrue);
      expect(source.contains("route: '/complaints'"), isTrue);
      expect(source.contains("route: '/accommodation'"), isTrue);
    });
  });

  group('Preservation — go_router configuration intact', () {
    test('admin_web app_router.dart still defines GoRouter with auth redirect', () {
      final source =
          File('lib/core/router/app_router.dart').readAsStringSync();

      expect(source.contains('GoRouter'), isTrue,
          reason: 'go_router configuration must remain');
      expect(source.contains('redirect:'), isTrue,
          reason: 'auth redirect guard must remain');
    });
  });
}
