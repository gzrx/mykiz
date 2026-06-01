import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../data/announcements_repository.dart';

// ---------------------------------------------------------------------------
// Announcements List State
// ---------------------------------------------------------------------------

/// State for the announcements list screen.
class AnnouncementsListState {
  const AnnouncementsListState({
    this.announcements = const [],
    this.meta,
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.limit = 20,
  });

  final List<Announcement> announcements;
  final PaginationMeta? meta;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final int limit;

  int get totalPages => meta?.totalPages ?? 1;
  int get totalItems => meta?.totalItems ?? 0;

  AnnouncementsListState copyWith({
    List<Announcement>? announcements,
    PaginationMeta? meta,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    int? limit,
  }) {
    return AnnouncementsListState(
      announcements: announcements ?? this.announcements,
      meta: meta ?? this.meta,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentPage: currentPage ?? this.currentPage,
      limit: limit ?? this.limit,
    );
  }
}

/// Notifier that manages the announcements list state.
class AnnouncementsListNotifier extends StateNotifier<AnnouncementsListState> {
  AnnouncementsListNotifier(this._repository)
      : super(const AnnouncementsListState());

  final AnnouncementsRepository _repository;

  /// Fetches announcements for the given [page].
  Future<void> fetchAnnouncements({int? page, int? limit}) async {
    final targetPage = page ?? state.currentPage;
    final targetLimit = limit ?? state.limit;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      currentPage: targetPage,
      limit: targetLimit,
    );

    try {
      final response = await _repository.listAnnouncements(
        page: targetPage,
        limit: targetLimit,
      );

      state = state.copyWith(
        announcements: response.items,
        meta: response.meta,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  /// Navigates to the next page.
  Future<void> nextPage() async {
    if (state.currentPage < state.totalPages) {
      await fetchAnnouncements(page: state.currentPage + 1);
    }
  }

  /// Navigates to the previous page.
  Future<void> previousPage() async {
    if (state.currentPage > 1) {
      await fetchAnnouncements(page: state.currentPage - 1);
    }
  }

  /// Navigates to a specific [page].
  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= state.totalPages) {
      await fetchAnnouncements(page: page);
    }
  }

  /// Soft-deletes an announcement and refreshes the list.
  Future<bool> deleteAnnouncement(String id) async {
    try {
      await _repository.deleteAnnouncement(id);
      await fetchAnnouncements();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Failed to delete announcement.',
      );
      return false;
    }
  }
}

/// Provider for the announcements list state.
final announcementsListProvider =
    StateNotifierProvider<AnnouncementsListNotifier, AnnouncementsListState>(
        (ref) {
  final repository = ref.watch(announcementsRepositoryProvider);
  return AnnouncementsListNotifier(repository);
});

// ---------------------------------------------------------------------------
// Single Announcement State
// ---------------------------------------------------------------------------

/// State for viewing/editing a single announcement.
class AnnouncementDetailState {
  const AnnouncementDetailState({
    this.announcement,
    this.isLoading = false,
    this.errorMessage,
    this.isSaving = false,
    this.saveSuccess = false,
  });

  final Announcement? announcement;
  final bool isLoading;
  final String? errorMessage;
  final bool isSaving;
  final bool saveSuccess;

  AnnouncementDetailState copyWith({
    Announcement? announcement,
    bool? isLoading,
    String? errorMessage,
    bool? isSaving,
    bool? saveSuccess,
  }) {
    return AnnouncementDetailState(
      announcement: announcement ?? this.announcement,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSaving: isSaving ?? this.isSaving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
    );
  }
}

/// Notifier that manages a single announcement's state.
class AnnouncementDetailNotifier
    extends StateNotifier<AnnouncementDetailState> {
  AnnouncementDetailNotifier(this._repository)
      : super(const AnnouncementDetailState());

  final AnnouncementsRepository _repository;

  /// Fetches a single announcement by [id].
  Future<void> fetchAnnouncement(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final announcement = await _repository.getAnnouncement(id);
      state = state.copyWith(
        announcement: announcement,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load announcement.',
      );
    }
  }

  /// Updates an existing announcement.
  Future<bool> updateAnnouncement(
    String id, {
    String? title,
    String? body,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null, saveSuccess: false);

    try {
      final updated = await _repository.updateAnnouncement(
        id,
        title: title,
        body: body,
      );
      state = state.copyWith(
        announcement: updated,
        isSaving: false,
        saveSuccess: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to update announcement.',
      );
      return false;
    }
  }

  /// Creates a new announcement.
  Future<bool> createAnnouncement({
    required String title,
    required String body,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null, saveSuccess: false);

    try {
      final created = await _repository.createAnnouncement(
        title: title,
        body: body,
      );
      state = state.copyWith(
        announcement: created,
        isSaving: false,
        saveSuccess: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to create announcement.',
      );
      return false;
    }
  }

  /// Resets the state.
  void reset() {
    state = const AnnouncementDetailState();
  }
}

/// Provider for the announcement detail state.
final announcementDetailProvider = StateNotifierProvider<
    AnnouncementDetailNotifier, AnnouncementDetailState>((ref) {
  final repository = ref.watch(announcementsRepositoryProvider);
  return AnnouncementDetailNotifier(repository);
});
