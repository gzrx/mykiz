import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/core/router/app_router.dart';
import 'package:student_app/features/auth/application/auth_provider.dart';

/// Feature: student-dashboard, Property 1: Router redirect determinism
///
/// **Validates: Requirements 1.1, 1.2, 1.3, 1.4**
///
/// For any combination of auth state and current route path, computeRedirect
/// returns the correct target per the redirect truth table.

// -- Generators --

final _statuses = AuthStatus.values;

String _randomRoutePath(Random rng) {
  // Mix of the login route, dashboard route, and random paths
  const knownPaths = [
    '/login',
    '/dashboard',
    '/announcements',
    '/complaints',
    '/complaints/new',
    '/complaints/123',
    '/settings',
    '/profile',
  ];
  if (rng.nextBool()) {
    return knownPaths[rng.nextInt(knownPaths.length)];
  }
  // Generate a random path
  final segments = 1 + rng.nextInt(3);
  final path = List.generate(segments, (_) {
    final len = 1 + rng.nextInt(10);
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789-_';
    return List.generate(len, (_) => chars[rng.nextInt(chars.length)]).join();
  }).join('/');
  return '/$path';
}

void main() {
  final random = Random(42); // deterministic seed for reproducibility

  // -- Property 1: Router redirect determinism --
  // **Validates: Requirements 1.1, 1.2, 1.3, 1.4**
  group('Property 1: Router redirect determinism', () {
    test('loading status always returns null (no redirect)', () {
      for (var i = 0; i < 100; i++) {
        final route = _randomRoutePath(random);
        final result = computeRedirect(AuthStatus.loading, route);
        expect(result, isNull,
            reason: 'Loading + route "$route" should produce no redirect');
      }
    });

    test('authenticated on /login always redirects to /dashboard', () {
      // Req 1.3: authenticated on /login → /dashboard
      for (var i = 0; i < 100; i++) {
        final result = computeRedirect(AuthStatus.authenticated, '/login');
        expect(result, '/dashboard',
            reason: 'Authenticated + /login should redirect to /dashboard');
      }
    });

    test('authenticated on non-login route returns null', () {
      // Req 1.1 (implicit): authenticated on other routes → no redirect
      for (var i = 0; i < 100; i++) {
        String route;
        do {
          route = _randomRoutePath(random);
        } while (route == '/login');

        final result = computeRedirect(AuthStatus.authenticated, route);
        expect(result, isNull,
            reason:
                'Authenticated + route "$route" (not /login) should produce no redirect');
      }
    });

    test('unauthenticated on /login returns null', () {
      // Req 1.2 (implicit): unauthenticated on /login → stay on login
      for (var i = 0; i < 100; i++) {
        final result = computeRedirect(AuthStatus.unauthenticated, '/login');
        expect(result, isNull,
            reason:
                'Unauthenticated + /login should produce no redirect (stay on login)');
      }
    });

    test('unauthenticated on non-login route always redirects to /login', () {
      // Req 1.2: unauthenticated on protected route → /login
      for (var i = 0; i < 100; i++) {
        String route;
        do {
          route = _randomRoutePath(random);
        } while (route == '/login');

        final result = computeRedirect(AuthStatus.unauthenticated, route);
        expect(result, '/login',
            reason:
                'Unauthenticated + route "$route" should redirect to /login');
      }
    });

    test(
        'exhaustive: random (status, route) pairs match truth table across 200 iterations',
        () {
      for (var i = 0; i < 200; i++) {
        final status = _statuses[random.nextInt(_statuses.length)];
        final route = _randomRoutePath(random);

        final result = computeRedirect(status, route);

        // Compute expected per truth table
        final String? expected;
        if (status == AuthStatus.unknown) {
          expected = null;
        } else if (status == AuthStatus.loading) {
          expected = null;
        } else if (status == AuthStatus.authenticated &&
            route == '/login') {
          expected = '/dashboard';
        } else if (status == AuthStatus.authenticated) {
          expected = null;
        } else if (status == AuthStatus.unauthenticated &&
            route == '/login') {
          expected = null;
        } else {
          // unauthenticated + non-login
          expected = '/login';
        }

        expect(result, expected,
            reason:
                'computeRedirect($status, "$route") = $result, expected $expected');
      }
    });

    test('redirect result is always null, /login, or /dashboard', () {
      for (var i = 0; i < 100; i++) {
        final status = _statuses[random.nextInt(_statuses.length)];
        final route = _randomRoutePath(random);

        final result = computeRedirect(status, route);
        expect(
          result == null || result == '/login' || result == '/dashboard',
          isTrue,
          reason:
              'computeRedirect($status, "$route") = "$result" — must be null, /login, or /dashboard',
        );
      }
    });
  });
}
