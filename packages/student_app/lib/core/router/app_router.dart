import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/accommodation/presentation/accommodation_screen.dart';
import '../../features/complaints/presentation/complaint_detail_screen.dart';
import '../../features/complaints/presentation/complaint_submit_screen.dart';
import '../../features/complaints/presentation/complaints_list_screen.dart';
import '../../features/announcements/presentation/announcements_list_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';

/// Application route paths.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String announcements = '/announcements';
  static const String complaints = '/complaints';
  static const String complaintDetail = '/complaints/:id';
  static const String complaintSubmit = '/complaints/new';
  static const String accommodation = '/accommodation';
}

/// Pure function implementing the router redirect truth table.
///
/// Returns the redirect path (or null for no redirect) given the current
/// [status] and the [currentRoute] the user is attempting to visit.
String? computeRedirect(AuthStatus status, String currentRoute) {
  if (status == AuthStatus.loading) return null;

  final isAuthenticated = status == AuthStatus.authenticated;
  final isOnLogin = currentRoute == AppRoutes.login;

  if (!isAuthenticated && !isOnLogin) return AppRoutes.login;
  if (isAuthenticated && isOnLogin) return AppRoutes.dashboard;

  return null;
}

/// GoRouter configuration provider with auth redirect guard.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    redirect: (context, state) =>
        computeRedirect(authState.status, state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.announcements,
        builder: (context, state) => const AnnouncementsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.accommodation,
        builder: (context, state) => const AccommodationScreen(),
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
