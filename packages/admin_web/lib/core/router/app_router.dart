import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/accommodation/presentation/accommodation_shell.dart';
import '../../features/bookings/presentation/bookings_screen.dart';
import '../../features/announcements/presentation/announcement_detail_screen.dart';
import '../../features/announcements/presentation/announcement_form_screen.dart';
import '../../features/announcements/presentation/announcements_screen.dart';
import '../../features/auth/application/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/complaints/presentation/complaint_detail_screen.dart';
import '../../features/complaints/presentation/complaints_screen.dart';
import '../../features/overview/presentation/overview_screen.dart';
import '../widgets/app_shell.dart';

/// Route paths used throughout the application.
abstract final class AppRoutes {
  static const String login = '/login';

  /// Legacy dashboard path — redirected to [overview].
  static const String dashboard = '/dashboard';
  static const String overview = '/overview';
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
/// - Authenticated users on /login, /, or the legacy /dashboard path are
///   redirected to /overview
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

      // If authenticated and on login, root, or the legacy dashboard path,
      // redirect to the overview landing page.
      if (isAuthenticated &&
          (isOnLogin ||
              state.matchedLocation == '/' ||
              state.matchedLocation == AppRoutes.dashboard)) {
        return AppRoutes.overview;
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: navigationShell.goBranch,
          child: navigationShell,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.overview,
                builder: (context, state) => const OverviewScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.announcements,
                builder: (context, state) => const AnnouncementsScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (context, state) =>
                        const AnnouncementFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return AnnouncementDetailScreen(announcementId: id);
                    },
                  ),
                  GoRoute(
                    path: ':id/edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return AnnouncementFormScreen(announcementId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.complaints,
                builder: (context, state) => const ComplaintsScreen(),
                routes: [
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
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.accommodation,
                builder: (context, state) => const AccommodationShell(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.bookings,
                builder: (context, state) => const BookingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
