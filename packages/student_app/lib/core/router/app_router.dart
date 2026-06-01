import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/complaints/presentation/complaint_detail_screen.dart';
import '../../features/complaints/presentation/complaint_submit_screen.dart';
import '../../features/complaints/presentation/complaints_list_screen.dart';

/// Application route paths.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String announcements = '/announcements';
  static const String complaints = '/complaints';
  static const String complaintDetail = '/complaints/:id';
  static const String complaintSubmit = '/complaints/new';
}

/// GoRouter configuration provider with auth redirect guard.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isOnLogin = state.matchedLocation == AppRoutes.login;

      // If not authenticated and not on login page, redirect to login.
      if (!isAuthenticated && !isOnLogin) {
        return AppRoutes.login;
      }

      // If authenticated and on login page, redirect to announcements.
      if (isAuthenticated && isOnLogin) {
        return AppRoutes.announcements;
      }

      // No redirect needed.
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.announcements,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Announcements')),
        ),
      ),
      GoRoute(
        path: AppRoutes.complaints,
        builder: (context, state) => const ComplaintsListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ComplaintSubmitScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ComplaintDetailScreen(complaintId: id);
            },
          ),
        ],
      ),
    ],
  );
});
