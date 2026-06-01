import 'dart:typed_data';

import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../data/complaints_repository.dart';

/// State for the complaints list screen.
class ComplaintsListState {
  const ComplaintsListState({
    this.complaints = const [],
    this.meta,
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
  });

  final List<Complaint> complaints;
  final PaginationMeta? meta;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;

  ComplaintsListState copyWith({
    List<Complaint>? complaints,
    PaginationMeta? meta,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
  }) {
    return ComplaintsListState(
      complaints: complaints ?? this.complaints,
      meta: meta ?? this.meta,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Notifier that manages the complaints list state.
class ComplaintsListNotifier extends StateNotifier<ComplaintsListState> {
  ComplaintsListNotifier(this._repository) : super(const ComplaintsListState());

  final ComplaintsRepository _repository;

  /// Fetches complaints for the given [page].
  Future<void> fetchComplaints({int page = 1}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _repository.listComplaints(page: page);
      state = ComplaintsListState(
        complaints: response.items,
        meta: response.meta,
        currentPage: page,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  /// Navigates to the next page if available.
  Future<void> nextPage() async {
    final meta = state.meta;
    if (meta != null && state.currentPage < meta.totalPages) {
      await fetchComplaints(page: state.currentPage + 1);
    }
  }

  /// Navigates to the previous page if available.
  Future<void> previousPage() async {
    if (state.currentPage > 1) {
      await fetchComplaints(page: state.currentPage - 1);
    }
  }
}

/// Provider for the complaints list notifier.
final complaintsListProvider =
    StateNotifierProvider<ComplaintsListNotifier, ComplaintsListState>((ref) {
  final repository = ref.watch(complaintsRepositoryProvider);
  return ComplaintsListNotifier(repository);
});

/// State for the complaint detail screen.
class ComplaintDetailState {
  const ComplaintDetailState({
    this.complaint,
    this.isLoading = false,
    this.isAdvancing = false,
    this.errorMessage,
  });

  final Complaint? complaint;
  final bool isLoading;
  final bool isAdvancing;
  final String? errorMessage;

  ComplaintDetailState copyWith({
    Complaint? complaint,
    bool? isLoading,
    bool? isAdvancing,
    String? errorMessage,
  }) {
    return ComplaintDetailState(
      complaint: complaint ?? this.complaint,
      isLoading: isLoading ?? this.isLoading,
      isAdvancing: isAdvancing ?? this.isAdvancing,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier that manages a single complaint's detail state.
class ComplaintDetailNotifier extends StateNotifier<ComplaintDetailState> {
  ComplaintDetailNotifier(this._repository)
      : super(const ComplaintDetailState());

  final ComplaintsRepository _repository;

  /// Fetches a single complaint by [id].
  Future<void> fetchComplaint(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final complaint = await _repository.getComplaint(id);
      state = ComplaintDetailState(complaint: complaint);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  /// Advances the complaint status to [newStatus].
  Future<void> advanceStatus(String newStatus) async {
    final complaint = state.complaint;
    if (complaint == null) return;

    state = state.copyWith(isAdvancing: true, errorMessage: null);

    try {
      final updated =
          await _repository.advanceStatus(complaint.id, newStatus: newStatus);
      state = ComplaintDetailState(complaint: updated);
    } on ApiException catch (e) {
      state = state.copyWith(isAdvancing: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isAdvancing: false,
        errorMessage: 'Failed to advance status.',
      );
    }
  }
}

/// Provider for the complaint detail notifier.
final complaintDetailProvider =
    StateNotifierProvider<ComplaintDetailNotifier, ComplaintDetailState>((ref) {
  final repository = ref.watch(complaintsRepositoryProvider);
  return ComplaintDetailNotifier(repository);
});

/// Provider that fetches a complaint image by its storage key.
///
/// Returns the image bytes or null if the image cannot be loaded.
final complaintImageProvider =
    FutureProvider.family<Uint8List?, String>((ref, imageKey) async {
  final repository = ref.watch(complaintsRepositoryProvider);
  try {
    return await repository.getImage(imageKey);
  } catch (_) {
    return null;
  }
});
