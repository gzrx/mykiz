import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../../auth/application/auth_provider.dart';

/// Combined state for the bookings feature.
class BookingsState {
  const BookingsState({
    this.facilities = const [],
    this.selectedFacility,
    this.slots = const [],
    this.availability = const [],
    this.activeBookings = const [],
    this.history = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Facility> facilities;
  final Facility? selectedFacility;
  final List<FacilitySlotConfig> slots;
  final List<Map<String, dynamic>> availability;
  final List<Booking> activeBookings;
  final List<Booking> history;
  final bool isLoading;
  final String? errorMessage;

  BookingsState copyWith({
    List<Facility>? facilities,
    Facility? selectedFacility,
    List<FacilitySlotConfig>? slots,
    List<Map<String, dynamic>>? availability,
    List<Booking>? activeBookings,
    List<Booking>? history,
    bool? isLoading,
    String? errorMessage,
    bool clearSelectedFacility = false,
    bool clearError = false,
  }) {
    return BookingsState(
      facilities: facilities ?? this.facilities,
      selectedFacility: clearSelectedFacility
          ? null
          : (selectedFacility ?? this.selectedFacility),
      slots: slots ?? this.slots,
      availability: availability ?? this.availability,
      activeBookings: activeBookings ?? this.activeBookings,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier that manages the bookings feature state.
class BookingsNotifier extends StateNotifier<BookingsState> {
  BookingsNotifier(this._apiClient) : super(const BookingsState());

  final MyKizApiClient _apiClient;

  Future<void> fetchFacilities() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final facilities = await _apiClient.listFacilities();
      state = state.copyWith(facilities: facilities, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load facilities.',
      );
    }
  }

  Future<void> selectFacility(String id) async {
    final facility = state.facilities.firstWhere((f) => f.id == id);
    state = state.copyWith(selectedFacility: facility);
    try {
      final slots = await _apiClient.getFacilitySlots(id);
      state = state.copyWith(slots: slots);
    } catch (_) {
      // ponytail: slots fetch failure is non-critical, availability screen handles it
    }
  }

  Future<void> fetchAvailability(String facilityId, DateTime date) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final availability =
          await _apiClient.getSlotAvailability(facilityId, date: dateStr);
      state = state.copyWith(availability: availability, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load availability.',
      );
    }
  }

  Future<bool> submitBooking({
    required String facilityId,
    required String slotConfigId,
    required String date,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _apiClient.submitBooking(
        facilityId: facilityId,
        slotConfigId: slotConfigId,
        date: date,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to submit booking.',
      );
      return false;
    }
  }

  Future<void> cancelBooking(String id) async {
    try {
      await _apiClient.cancelBooking(id);
      await fetchActiveBookings();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(errorMessage: 'Failed to cancel booking.');
    }
  }

  Future<void> fetchActiveBookings() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiClient.listBookings(type: 'active');
      state = state.copyWith(activeBookings: response.items, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load bookings.',
      );
    }
  }

  Future<void> fetchHistory() async {
    try {
      final response = await _apiClient.listBookings(type: 'history');
      state = state.copyWith(history: response.items);
    } catch (_) {
      // ponytail: history load failure is non-critical
    }
  }
}

/// Main bookings state provider.
final bookingsProvider =
    StateNotifierProvider<BookingsNotifier, BookingsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BookingsNotifier(apiClient);
});

/// FutureProvider for facility list (used standalone in some views).
final facilitiesProvider = FutureProvider<List<Facility>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.listFacilities();
});

/// Badge provider for the Bookings dashboard tile.
/// Returns the count of active bookings, or null if none.
Future<String?> bookingsBadgeProvider(WidgetRef ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.listBookings(type: 'active', limit: 1);
    final count = response.meta.totalItems;
    return count > 0 ? count.toString() : null;
  } catch (_) {
    return null;
  }
}
