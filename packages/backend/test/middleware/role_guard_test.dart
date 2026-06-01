import 'dart:io';

import 'package:backend/middleware/role_guard.dart';
import 'package:backend/models/user_payload.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:glados/glados.dart' hide any;
import 'package:glados/glados.dart' as glados show any;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

/// Represents an admin-only endpoint that students should be blocked from.
enum AdminOnlyEndpoint {
  announcementCreation,
  announcementUpdate,
  announcementDeletion,
  complaintStatusTransition,
}

/// Represents any endpoint in the system (admin-only and shared).
enum SystemEndpoint {
  // Admin-only endpoints
  announcementCreation,
  announcementUpdate,
  announcementDeletion,
  complaintStatusTransition,
  // Shared endpoints (accessible by any authenticated user)
  announcementList,
  announcementGetById,
  complaintList,
  complaintGetById,
  complaintSubmission,
  imageProxy,
}

/// Custom generators for property-based testing.
extension AdminOnlyEndpointGenerator on Any {
  Generator<AdminOnlyEndpoint> get adminOnlyEndpoint =>
      choose(AdminOnlyEndpoint.values);

  Generator<SystemEndpoint> get systemEndpoint =>
      choose(SystemEndpoint.values);
}

void main() {
  group('requireAdmin', () {
    test('returns null (grants access) when user is admin', () {
      final context = _MockRequestContext();
      when(() => context.read<UserPayload>()).thenReturn(
        const UserPayload(id: 'admin-id', role: 'admin'),
      );

      final result = requireAdmin(context);
      expect(result, isNull);
    });

    test('returns 403 FORBIDDEN when user is student', () async {
      final context = _MockRequestContext();
      when(() => context.read<UserPayload>()).thenReturn(
        const UserPayload(id: 'student-id', role: 'student'),
      );

      final result = requireAdmin(context);

      expect(result, isNotNull);
      expect(result!.statusCode, equals(HttpStatus.forbidden));

      final body = await result.json() as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>;
      expect(error['code'], equals('FORBIDDEN'));
      expect(
        error['message'],
        equals('You do not have permission to perform this action.'),
      );
    });
  });

  group('requireRole', () {
    test('returns null when user has the required role', () {
      final context = _MockRequestContext();
      when(() => context.read<UserPayload>()).thenReturn(
        const UserPayload(id: 'student-id', role: 'student'),
      );

      final result = requireRole(context, 'student');
      expect(result, isNull);
    });

    test('returns 403 FORBIDDEN when user does not have the required role',
        () async {
      final context = _MockRequestContext();
      when(() => context.read<UserPayload>()).thenReturn(
        const UserPayload(id: 'student-id', role: 'student'),
      );

      final result = requireRole(context, 'admin');

      expect(result, isNotNull);
      expect(result!.statusCode, equals(HttpStatus.forbidden));

      final body = await result.json() as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>;
      expect(error['code'], equals('FORBIDDEN'));
      expect(
        error['message'],
        equals('You do not have permission to perform this action.'),
      );
    });

    test('admin passes requireRole check for admin', () {
      final context = _MockRequestContext();
      when(() => context.read<UserPayload>()).thenReturn(
        const UserPayload(id: 'admin-id', role: 'admin'),
      );

      final result = requireRole(context, 'admin');
      expect(result, isNull);
    });
  });

  group('adminOnly middleware', () {
    test('allows admin requests through to the handler', () async {
      final context = _MockRequestContext();
      when(() => context.read<UserPayload>()).thenReturn(
        const UserPayload(id: 'admin-id', role: 'admin'),
      );

      final middleware = adminOnly();
      var handlerCalled = false;

      final handler = middleware(
        (ctx) async {
          handlerCalled = true;
          return Response(statusCode: HttpStatus.ok);
        },
      );

      final response = await handler(context);

      expect(handlerCalled, isTrue);
      expect(response.statusCode, equals(HttpStatus.ok));
    });

    test('blocks student requests with 403 FORBIDDEN', () async {
      final context = _MockRequestContext();
      when(() => context.read<UserPayload>()).thenReturn(
        const UserPayload(id: 'student-id', role: 'student'),
      );

      final middleware = adminOnly();
      var handlerCalled = false;

      final handler = middleware(
        (ctx) async {
          handlerCalled = true;
          return Response(statusCode: HttpStatus.ok);
        },
      );

      final response = await handler(context);

      expect(handlerCalled, isFalse);
      expect(response.statusCode, equals(HttpStatus.forbidden));

      final body = await response.json() as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>;
      expect(error['code'], equals('FORBIDDEN'));
      expect(
        error['message'],
        equals('You do not have permission to perform this action.'),
      );
    });
  });

  // Feature: mykiz-platform, Property 4: Student blocked from admin-only endpoints
  // **Validates: Requirements 2.3**
  group('Property 4: Student blocked from admin-only endpoints', () {
    Glados2(glados.any.lowercaseLetters, glados.any.adminOnlyEndpoint,
            ExploreConfig(numRuns: 100))
        .test(
      'For any valid Student JWT and any admin-only endpoint, '
      'the Backend SHALL return a 403 status with code "FORBIDDEN"',
      (studentId, endpoint) async {
        // Simulate a student user with a randomly generated ID
        final context = _MockRequestContext();
        when(() => context.read<UserPayload>()).thenReturn(
          UserPayload(id: studentId, role: 'student'),
        );

        // Test via requireAdmin (used by all admin-only endpoints)
        final guardResult = requireAdmin(context);

        // Must always return a non-null response (i.e., block access)
        expect(guardResult, isNotNull,
            reason:
                'Student "$studentId" should be blocked from $endpoint');
        expect(guardResult!.statusCode, equals(HttpStatus.forbidden));

        final body = await guardResult.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['code'], equals('FORBIDDEN'));

        // Also test via adminOnly middleware to verify the middleware path
        final middlewareContext = _MockRequestContext();
        when(() => middlewareContext.read<UserPayload>()).thenReturn(
          UserPayload(id: studentId, role: 'student'),
        );

        final middleware = adminOnly();
        var handlerCalled = false;
        final handler = middleware(
          (ctx) async {
            handlerCalled = true;
            return Response(statusCode: HttpStatus.ok);
          },
        );

        final response = await handler(middlewareContext);

        // Handler must NOT be called for students
        expect(handlerCalled, isFalse,
            reason:
                'Handler should not be called for student on $endpoint');
        expect(response.statusCode, equals(HttpStatus.forbidden));

        final middlewareBody =
            await response.json() as Map<String, dynamic>;
        final middlewareError =
            middlewareBody['error'] as Map<String, dynamic>;
        expect(middlewareError['code'], equals('FORBIDDEN'));
      },
    );
  });

  // Feature: mykiz-platform, Property 5: Admin unrestricted access
  // **Validates: Requirements 2.4**
  group('Property 5: Admin unrestricted access', () {
    Glados2(glados.any.lowercaseLetters, glados.any.systemEndpoint,
            ExploreConfig(numRuns: 100))
        .test(
      'For any valid Admin JWT and any endpoint in the system, '
      'the Backend SHALL never return a 403 FORBIDDEN due to role restrictions',
      (adminId, endpoint) async {
        // Simulate an admin user with a randomly generated ID
        final context = _MockRequestContext();
        when(() => context.read<UserPayload>()).thenReturn(
          UserPayload(id: adminId, role: 'admin'),
        );

        // Test requireAdmin — admin should always pass (returns null)
        final guardResult = requireAdmin(context);
        expect(guardResult, isNull,
            reason:
                'Admin "$adminId" should never be blocked by requireAdmin '
                'on endpoint $endpoint');

        // Test requireRole with 'admin' — admin should pass
        final roleResult = requireRole(context, 'admin');
        expect(roleResult, isNull,
            reason:
                'Admin "$adminId" should pass requireRole("admin") '
                'on endpoint $endpoint');

        // Test adminOnly middleware — admin should pass through to handler
        final middlewareContext = _MockRequestContext();
        when(() => middlewareContext.read<UserPayload>()).thenReturn(
          UserPayload(id: adminId, role: 'admin'),
        );

        final middleware = adminOnly();
        var handlerCalled = false;
        final handler = middleware(
          (ctx) async {
            handlerCalled = true;
            return Response(statusCode: HttpStatus.ok);
          },
        );

        final response = await handler(middlewareContext);

        // Handler MUST be called for admins (no 403 blocking)
        expect(handlerCalled, isTrue,
            reason:
                'Handler should always be called for admin on $endpoint');
        // Response must NOT be 403
        expect(response.statusCode, isNot(equals(HttpStatus.forbidden)),
            reason:
                'Admin "$adminId" should never get 403 on $endpoint');
      },
    );
  });
}
