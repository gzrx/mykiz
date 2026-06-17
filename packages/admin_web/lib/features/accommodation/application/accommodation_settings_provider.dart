import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/accommodation_repository.dart';

/// State for the accommodation settings (application window toggle).
class AccommodationSettingsState {
  const AccommodationSettingsState({
    this.isOpen = false,
    this.isLoading = true,
    this.errorMessage,
  });

  final bool isOpen;
  final bool isLoading;
  final String? errorMessage;

  AccommodationSettingsState copyWith({
    bool? isOpen,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AccommodationSettingsState(
      isOpen: isOpen ?? this.isOpen,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier managing the application window toggle with optimistic updates.
class AccommodationSettingsNotifier
    extends StateNotifier<AccommodationSettingsState> {
  AccommodationSettingsNotifier(this._repository)
      : super(const AccommodationSettingsState());

  final AccommodationRepository _repository;

  /// Fetches the current window setting from the server.
  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final isOpen = await _repository.getWindowOpen();
      state = AccommodationSettingsState(isOpen: isOpen, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load settings.',
      );
    }
  }

  /// Toggles the window setting with optimistic update and revert on failure.
  Future<void> toggle() async {
    final previous = state.isOpen;
    // Optimistic update
    state = state.copyWith(isOpen: !previous, errorMessage: null);

    try {
      final persisted = await _repository.updateWindowOpen(open: !previous);
      state = state.copyWith(isOpen: persisted);
    } on ApiException catch (e) {
      // Revert on failure
      state = state.copyWith(isOpen: previous, errorMessage: e.message);
    } catch (_) {
      // Revert on failure
      state = state.copyWith(
        isOpen: previous,
        errorMessage: 'Could not save setting. Please try again.',
      );
    }
  }
}

/// Provider for the accommodation settings notifier.
final accommodationSettingsProvider = StateNotifierProvider<
    AccommodationSettingsNotifier, AccommodationSettingsState>((ref) {
  final repository = ref.watch(accommodationRepositoryProvider);
  return AccommodationSettingsNotifier(repository);
});
