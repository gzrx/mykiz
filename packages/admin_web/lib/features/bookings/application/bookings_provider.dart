import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../data/bookings_repository.dart';

// ---------------------------------------------------------------------------
// Bookings List
// ---------------------------------------------------------------------------

class BookingsListState {
  const BookingsListState({
    this.bookings = const [],
    this.totalItems = 0,
    this.page = 1,
    this.limit = 20,
    this.facilityFilter,
    this.statusFilter,
    this.fromDate,
    this.toDate,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Booking> bookings;
  final int totalItems;
  final int page;
  final int limit;
  final String? facilityFilter;
  final String? statusFilter;
  final String? fromDate;
  final String? toDate;
  final bool isLoading;
  final String? errorMessage;

  int get totalPages => (totalItems / limit).ceil().clamp(1, 9999);

  BookingsListState copyWith({
    List<Booking>? bookings,
    int? totalItems,
    int? page,
    int? limit,
    String? facilityFilter,
    String? statusFilter,
    String? fromDate,
    String? toDate,
    bool? isLoading,
    String? errorMessage,
    bool clearFacility = false,
    bool clearStatus = false,
    bool clearFrom = false,
    bool clearTo = false,
  }) {
    return BookingsListState(
      bookings: bookings ?? this.bookings,
      totalItems: totalItems ?? this.totalItems,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      facilityFilter:
          clearFacility ? null : (facilityFilter ?? this.facilityFilter),
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
      fromDate: clearFrom ? null : (fromDate ?? this.fromDate),
      toDate: clearTo ? null : (toDate ?? this.toDate),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class BookingsListNotifier extends StateNotifier<BookingsListState> {
  BookingsListNotifier(this._repository) : super(const BookingsListState());

  final BookingsRepository _repository;

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.listAllBookings(
        facility: state.facilityFilter,
        status: state.statusFilter,
        from: state.fromDate,
        to: state.toDate,
        page: state.page,
        limit: state.limit,
      );
      state = state.copyWith(
        bookings: result.items,
        totalItems: result.meta.totalItems,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load bookings.',
      );
    }
  }

  void setFacilityFilter(String? facility) {
    state = state.copyWith(
      facilityFilter: facility,
      clearFacility: facility == null,
      page: 1,
    );
    fetch();
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatus: status == null,
      page: 1,
    );
    fetch();
  }

  void setDateRange(String? from, String? to) {
    state = state.copyWith(
      fromDate: from,
      toDate: to,
      clearFrom: from == null,
      clearTo: to == null,
      page: 1,
    );
    fetch();
  }

  void goToPage(int page) {
    state = state.copyWith(page: page);
    fetch();
  }

  Future<void> approveBooking(String id) async {
    try {
      await _repository.approveBooking(id);
      await fetch();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  Future<void> rejectBooking(String id, {required String reason}) async {
    try {
      await _repository.rejectBooking(id, reason: reason);
      await fetch();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }
}

// ---------------------------------------------------------------------------
// Facilities
// ---------------------------------------------------------------------------

class FacilitiesState {
  const FacilitiesState({
    this.facilities = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Facility> facilities;
  final bool isLoading;
  final String? errorMessage;

  FacilitiesState copyWith({
    List<Facility>? facilities,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FacilitiesState(
      facilities: facilities ?? this.facilities,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class FacilitiesNotifier extends StateNotifier<FacilitiesState> {
  FacilitiesNotifier(this._repository) : super(const FacilitiesState());

  final BookingsRepository _repository;

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final facilities = await _repository.listFacilities();
      state = FacilitiesState(facilities: facilities);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load facilities.',
      );
    }
  }

  Future<void> toggleActive(String id, {required bool isActive}) async {
    try {
      await _repository.updateFacility(id, isActive: isActive);
      await fetch();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  Future<void> updateApprovalMode(String id, String mode) async {
    try {
      await _repository.updateFacility(id, approvalMode: mode);
      await fetch();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final bookingsListProvider =
    StateNotifierProvider<BookingsListNotifier, BookingsListState>((ref) {
  final repository = ref.watch(bookingsRepositoryProvider);
  return BookingsListNotifier(repository);
});

final facilitiesProvider =
    StateNotifierProvider<FacilitiesNotifier, FacilitiesState>((ref) {
  final repository = ref.watch(bookingsRepositoryProvider);
  return FacilitiesNotifier(repository);
});
