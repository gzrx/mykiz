import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../../auth/application/auth_provider.dart';

// ---------------------------------------------------------------------------
// Application window provider
// ---------------------------------------------------------------------------

/// Fetches whether the application window is currently open.
final accommodationWindowProvider = FutureProvider<bool>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.getAccommodationSettings();
  return data['applications_open'] == true ||
      data['applications_open'] == 'true';
});

// ---------------------------------------------------------------------------
// Blocks provider (for form dropdowns)
// ---------------------------------------------------------------------------

/// Fetches available blocks for the preferred block dropdown.
final accommodationBlocksProvider = FutureProvider<List<Block>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.listBlocks();
});

// ---------------------------------------------------------------------------
// My applications (active + history)
// ---------------------------------------------------------------------------

/// Fetches the student's own applications: active list + history.
/// Used by status cards, history list, and duplicate-submission prevention.
final myAccommodationAppsProvider =
    FutureProvider<MyApplicationsResponse>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.getMyApplications();
});

// ---------------------------------------------------------------------------
// Submission state + notifier
// ---------------------------------------------------------------------------

/// State for application submission.
class AccommodationSubmissionState {
  const AccommodationSubmissionState({
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
}

/// Notifier that handles semester and out-of-semester application submission.
class AccommodationSubmissionNotifier
    extends StateNotifier<AccommodationSubmissionState> {
  AccommodationSubmissionNotifier(this._api)
      : super(const AccommodationSubmissionState());

  final MyKizApiClient _api;

  /// Submits a semester application.
  Future<void> submitSemester({
    required String roomTypePreference,
    required String preferredBlockId,
    required List<String> lifestyleTags,
  }) async {
    state = const AccommodationSubmissionState(isSubmitting: true);
    try {
      await _api.submitAccommodationApplication(
        applicationType: 'semester',
        roomTypePreference: roomTypePreference,
        preferredBlockId: preferredBlockId,
        lifestyleTags: lifestyleTags,
      );
      state = const AccommodationSubmissionState(isSuccess: true);
    } on ApiException catch (e) {
      state = AccommodationSubmissionState(errorMessage: e.message);
    } catch (_) {
      state = const AccommodationSubmissionState(
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  /// Submits an out-of-semester application.
  Future<void> submitOutOfSemester({
    required DateTime checkInDate,
    required DateTime checkOutDate,
  }) async {
    state = const AccommodationSubmissionState(isSubmitting: true);
    try {
      await _api.submitAccommodationApplication(
        applicationType: 'out_of_semester',
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
      );
      state = const AccommodationSubmissionState(isSuccess: true);
    } on ApiException catch (e) {
      state = AccommodationSubmissionState(errorMessage: e.message);
    } catch (_) {
      state = const AccommodationSubmissionState(
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  /// Resets state for a new submission.
  void reset() => state = const AccommodationSubmissionState();
}

/// Provider for accommodation submission.
final accommodationSubmissionProvider = StateNotifierProvider<
    AccommodationSubmissionNotifier, AccommodationSubmissionState>((ref) {
  final api = ref.watch(apiClientProvider);
  return AccommodationSubmissionNotifier(api);
});
