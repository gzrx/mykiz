import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../data/accommodation_repository.dart';

/// State for the check-in/out tab.
class CheckInOutState {
  const CheckInOutState({
    this.isLoading = false,
    this.result,
    this.errorMessage,
  });

  final bool isLoading;
  final AccommodationApplication? result;
  final String? errorMessage;

  CheckInOutState copyWith({
    bool? isLoading,
    AccommodationApplication? result,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return CheckInOutState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier that handles check-in and check-out operations.
class CheckInOutNotifier extends StateNotifier<CheckInOutState> {
  CheckInOutNotifier(this._repo) : super(const CheckInOutState());

  final AccommodationRepository _repo;

  /// Performs check-in for the given application UUID.
  Future<void> checkIn(String applicationId) async {
    state = const CheckInOutState(isLoading: true);
    try {
      final app = await _repo.checkIn(applicationId);
      state = CheckInOutState(result: app);
    } on NotFoundException {
      state = const CheckInOutState(errorMessage: 'Application not found');
    } on ValidationException catch (e) {
      state = CheckInOutState(
        errorMessage: e.code == 'INVALID_TRANSITION'
            ? 'Application is not eligible for check-in'
            : 'Invalid application ID',
      );
    } on ApiException catch (e) {
      state = CheckInOutState(
        errorMessage: e.code == 'INVALID_TRANSITION'
            ? 'Application is not eligible for check-in'
            : e.message,
      );
    } on Exception {
      state = const CheckInOutState(
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  /// Performs check-out for the given application UUID.
  Future<void> checkOut(String applicationId) async {
    state = const CheckInOutState(isLoading: true);
    try {
      final app = await _repo.checkOut(applicationId);
      state = CheckInOutState(result: app);
    } on NotFoundException {
      state = const CheckInOutState(errorMessage: 'Application not found');
    } on ValidationException catch (e) {
      state = CheckInOutState(
        errorMessage: e.code == 'INVALID_TRANSITION'
            ? 'Application is not eligible for check-out'
            : 'Invalid application ID',
      );
    } on ApiException catch (e) {
      state = CheckInOutState(
        errorMessage: e.code == 'INVALID_TRANSITION'
            ? 'Application is not eligible for check-out'
            : e.message,
      );
    } on Exception {
      state = const CheckInOutState(
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  /// Clears the current result/error.
  void clear() {
    state = const CheckInOutState();
  }
}

/// Provider for check-in/out state.
final checkInOutProvider =
    StateNotifierProvider<CheckInOutNotifier, CheckInOutState>((ref) {
  final repo = ref.watch(accommodationRepositoryProvider);
  return CheckInOutNotifier(repo);
});
