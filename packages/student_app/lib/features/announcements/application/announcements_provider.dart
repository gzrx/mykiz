import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../../auth/application/auth_provider.dart';
import '../data/announcements_repository.dart';

/// Provider for the [AnnouncementsRepository] instance.
final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AnnouncementsRepository(apiClient);
});

/// State for the announcements list including pagination.
class AnnouncementsListState {
  const AnnouncementsListState({
    this.announcements = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
  });

  final List<Announcement> announcements;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int totalItems;

  bool get hasMore => currentPage < totalPages;

  AnnouncementsListState copyWith({
    List<Announcement>? announcements,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalItems,
  }) {
    return AnnouncementsListState(
      announcements: announcements ?? this.announcements,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
    );
  }
}

/// Notifier that manages the announcements list state with pagination.
class AnnouncementsListNotifier extends StateNotifier<AnnouncementsListState> {
  // ponytail: load is triggered from the screen's initState (post-auth), not
  // here. Fetching in the constructor fires at provider-creation time — e.g.
  // when the dashboard badge first reads this provider — which can run before
  // the auth token is set and cache a 401 in this long-lived notifier. Mirror
  // the complaints module, which loads from the screen and works first try.
  AnnouncementsListNotifier(this._repository)
      : super(const AnnouncementsListState());

  final AnnouncementsRepository _repository;

  static const int _pageLimit = 20;

  /// Loads the first page of announcements.
  Future<void> loadAnnouncements() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.listAnnouncements(
        page: 1,
        limit: _pageLimit,
      );

      state = AnnouncementsListState(
        announcements: response.items,
        currentPage: response.meta.currentPage,
        totalPages: response.meta.totalPages,
        totalItems: response.meta.totalItems,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load announcements. Please try again.',
      );
    }
  }

  /// Refreshes the list by reloading from page 1.
  Future<void> refresh() async {
    await loadAnnouncements();
  }

  /// Loads the next page of announcements (pagination).
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final response = await _repository.listAnnouncements(
        page: nextPage,
        limit: _pageLimit,
      );

      state = state.copyWith(
        announcements: [...state.announcements, ...response.items],
        isLoadingMore: false,
        currentPage: response.meta.currentPage,
        totalPages: response.meta.totalPages,
        totalItems: response.meta.totalItems,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Failed to load more announcements.',
      );
    }
  }
}

/// Provider for the announcements list state.
final announcementsListProvider =
    StateNotifierProvider<AnnouncementsListNotifier, AnnouncementsListState>(
  (ref) {
    final repository = ref.watch(announcementsRepositoryProvider);
    return AnnouncementsListNotifier(repository);
  },
);

/// Provider for fetching a single announcement by ID.
final announcementDetailProvider =
    FutureProvider.family<Announcement, String>((ref, id) async {
  final repository = ref.watch(announcementsRepositoryProvider);
  return repository.getAnnouncement(id);
});
