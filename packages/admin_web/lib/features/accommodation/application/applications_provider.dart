import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../data/accommodation_repository.dart';

/// State for the applications tab.
class ApplicationsState {
  const ApplicationsState({
    this.applications = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 20,
    this.statusFilter,
    this.typeFilter,
    this.tagFilters = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<AccommodationApplication> applications;
  final int total;
  final int page;
  final int limit;
  final String? statusFilter;
  final String? typeFilter;
  final List<String> tagFilters;
  final bool isLoading;
  final String? errorMessage;

  int get totalPages => (total / limit).ceil().clamp(1, 9999);

  ApplicationsState copyWith({
    List<AccommodationApplication>? applications,
    int? total,
    int? page,
    int? limit,
    String? statusFilter,
    String? typeFilter,
    List<String>? tagFilters,
    bool? isLoading,
    String? errorMessage,
    bool clearStatusFilter = false,
    bool clearTypeFilter = false,
  }) {
    return ApplicationsState(
      applications: applications ?? this.applications,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      tagFilters: tagFilters ?? this.tagFilters,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier that manages the applications list with filtering and pagination.
class ApplicationsNotifier extends StateNotifier<ApplicationsState> {
  ApplicationsNotifier(this._repository) : super(const ApplicationsState());

  final AccommodationRepository _repository;

  /// Fetches applications with current filters.
  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.listApplications(
        status: state.statusFilter,
        type: state.typeFilter,
        tags: state.tagFilters.isEmpty ? null : state.tagFilters,
        page: state.page,
        limit: state.limit,
      );
      state = state.copyWith(
        applications: result.items,
        total: result.total,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load applications.',
      );
    }
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
      page: 1,
    );
    fetch();
  }

  void setTypeFilter(String? type) {
    state = state.copyWith(
      typeFilter: type,
      clearTypeFilter: type == null,
      page: 1,
    );
    fetch();
  }

  void setTagFilters(List<String> tags) {
    state = state.copyWith(tagFilters: tags, page: 1);
    fetch();
  }

  void goToPage(int page) {
    state = state.copyWith(page: page);
    fetch();
  }
}

/// Provider for the applications notifier.
final applicationsProvider =
    StateNotifierProvider<ApplicationsNotifier, ApplicationsState>((ref) {
  final repository = ref.watch(accommodationRepositoryProvider);
  return ApplicationsNotifier(repository);
});
