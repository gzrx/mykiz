import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/accommodation/presentation/accommodation_shell.dart';
import '../../features/bookings/presentation/bookings_screen.dart';
import '../../features/announcements/presentation/announcement_detail_screen.dart';
import '../../features/announcements/presentation/announcement_form_screen.dart';
import '../../features/announcements/presentation/announcements_screen.dart';
import '../../features/auth/application/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/complaints/presentation/complaint_detail_screen.dart';
import '../../features/complaints/presentation/complaints_screen.dart';

/// Route paths used throughout the application.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String announcements = '/announcements';
  static const String announcementCreate = '/announcements/create';
  static const String complaints = '/complaints';
  static const String complaintDetail = '/complaints/:id';
  static const String accommodation = '/accommodation';
  static const String bookings = '/bookings';

  /// Returns the path for viewing a single announcement.
  static String announcementDetail(String id) => '/announcements/$id';

  /// Returns the path for editing an announcement.
  static String announcementEdit(String id) => '/announcements/$id/edit';

  /// Returns the path for viewing a single complaint.
  static String complaintDetailPath(String id) => '/complaints/$id';
}

/// Provider for the GoRouter instance with auth redirect guard.
///
/// The router listens to auth state changes and redirects accordingly:
/// - Unauthenticated users are redirected to /login
/// - Authenticated users on /login or / are redirected to /dashboard
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final status = authState.status;

      // Auth state hasn't resolved yet (bootstrap in progress); stay put
      // while the app shows a splash screen.
      if (status == AuthStatus.unknown) {
        return null;
      }

      final isAuthenticated = status == AuthStatus.authenticated;
      final isOnLogin = state.matchedLocation == AppRoutes.login;

      // If not authenticated and not on login page, redirect to login
      if (!isAuthenticated && !isOnLogin) {
        return AppRoutes.login;
      }

      // If authenticated and on login or root, redirect to dashboard
      if (isAuthenticated && (isOnLogin || state.matchedLocation == '/')) {
        // TODO(B4): switch to AppRoutes.overview once the sidebar shell lands.
        return AppRoutes.dashboard;
      }

      // No redirect needed
      return null;
    },
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
        builder: (context, state) => const AnnouncementsScreen(),
      ),
      GoRoute(
        path: AppRoutes.announcementCreate,
        builder: (context, state) => const AnnouncementFormScreen(),
      ),
      GoRoute(
        path: '/announcements/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AnnouncementDetailScreen(announcementId: id);
        },
      ),
      GoRoute(
        path: '/announcements/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AnnouncementFormScreen(announcementId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.complaints,
        builder: (context, state) => const ComplaintsScreen(),
      ),
      GoRoute(
        path: AppRoutes.accommodation,
        builder: (context, state) => const AccommodationShell(),
      ),
      GoRoute(
        path: AppRoutes.bookings,
        builder: (context, state) => const BookingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.complaintDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ComplaintDetailScreen(complaintId: id);
        },
      ),
    ],
  );
});
