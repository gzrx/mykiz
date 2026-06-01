import 'dart:typed_data';

import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../../auth/application/auth_provider.dart';

/// State for the complaints list.
class ComplaintsListState {
  const ComplaintsListState({
    this.complaints = const [],
    this.meta,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Complaint> complaints;
  final PaginationMeta? meta;
  final bool isLoading;
  final String? errorMessage;

  ComplaintsListState copyWith({
    List<Complaint>? complaints,
    PaginationMeta? meta,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ComplaintsListState(
      complaints: complaints ?? this.complaints,
      meta: meta ?? this.meta,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// State for complaint submission.
class ComplaintSubmissionState {
  const ComplaintSubmissionState({
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;

  ComplaintSubmissionState copyWith({
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return ComplaintSubmissionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }
}

/// State for a single complaint detail.
class ComplaintDetailState {
  const ComplaintDetailState({
    this.complaint,
    this.isLoading = false,
    this.errorMessage,
  });

  final Complaint? complaint;
  final bool isLoading;
  final String? errorMessage;

  ComplaintDetailState copyWith({
    Complaint? complaint,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ComplaintDetailState(
      complaint: complaint ?? this.complaint,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier that manages the complaints list state.
class ComplaintsListNotifier extends StateNotifier<ComplaintsListState> {
  ComplaintsListNotifier(this._apiClient) : super(const ComplaintsListState());

  final MyKizApiClient _apiClient;

  /// Fetches the student's complaints (backend scopes to current user).
  Future<void> fetchComplaints({int page = 1, int limit = 20}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiClient.listComplaints(
        page: page,
        limit: limit,
      );

      state = ComplaintsListState(
        complaints: response.items,
        meta: response.meta,
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

  /// Refreshes the list from page 1.
  Future<void> refresh() => fetchComplaints();
}

/// Notifier that manages complaint submission state.
class ComplaintSubmissionNotifier
    extends StateNotifier<ComplaintSubmissionState> {
  ComplaintSubmissionNotifier(this._apiClient)
      : super(const ComplaintSubmissionState());

  final MyKizApiClient _apiClient;

  /// Submits a new complaint with description, location, and optional image.
  Future<void> submit({
    required String description,
    required String location,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    state = const ComplaintSubmissionState(isSubmitting: true);

    try {
      await _apiClient.submitComplaint(
        description: description,
        location: location,
        imageBytes: imageBytes,
        imageName: imageName,
      );

      state = const ComplaintSubmissionState(isSuccess: true);
    } on ApiException catch (e) {
      state = ComplaintSubmissionState(errorMessage: e.message);
    } catch (e) {
      state = const ComplaintSubmissionState(
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Resets the submission state for a new submission.
  void reset() {
    state = const ComplaintSubmissionState();
  }
}

/// Notifier that manages a single complaint detail state.
class ComplaintDetailNotifier extends StateNotifier<ComplaintDetailState> {
  ComplaintDetailNotifier(this._apiClient)
      : super(const ComplaintDetailState());

  final MyKizApiClient _apiClient;

  /// Fetches a single complaint by ID.
  Future<void> fetchComplaint(String id) async {
    state = const ComplaintDetailState(isLoading: true);

    try {
      final complaint = await _apiClient.getComplaint(id);
      state = ComplaintDetailState(complaint: complaint);
    } on ApiException catch (e) {
      state = ComplaintDetailState(errorMessage: e.message);
    } catch (e) {
      state = const ComplaintDetailState(
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }
}

/// Provider for the complaints list notifier.
final complaintsListProvider =
    StateNotifierProvider<ComplaintsListNotifier, ComplaintsListState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ComplaintsListNotifier(apiClient);
});

/// Provider for complaint submission notifier.
final complaintSubmissionProvider = StateNotifierProvider<
    ComplaintSubmissionNotifier, ComplaintSubmissionState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ComplaintSubmissionNotifier(apiClient);
});

/// Provider for complaint detail notifier.
final complaintDetailProvider =
    StateNotifierProvider<ComplaintDetailNotifier, ComplaintDetailState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ComplaintDetailNotifier(apiClient);
});

/// Provider that fetches a complaint image by its key.
final complaintImageProvider =
    FutureProvider.family<Uint8List, String>((ref, imageKey) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getImage(imageKey);
});
