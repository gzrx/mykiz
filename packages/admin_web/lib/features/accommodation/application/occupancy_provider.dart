import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../data/accommodation_repository.dart';

/// State for the occupancy tab.
class OccupancyState {
  const OccupancyState({
    this.blocks = const [],
    this.selectedBlockId,
    this.rooms = const [],
    this.isLoadingBlocks = false,
    this.isLoadingRooms = false,
    this.errorMessage,
  });

  final List<Block> blocks;
  final String? selectedBlockId;
  final List<RoomOccupancy> rooms;
  final bool isLoadingBlocks;
  final bool isLoadingRooms;
  final String? errorMessage;

  OccupancyState copyWith({
    List<Block>? blocks,
    String? selectedBlockId,
    List<RoomOccupancy>? rooms,
    bool? isLoadingBlocks,
    bool? isLoadingRooms,
    String? errorMessage,
  }) {
    return OccupancyState(
      blocks: blocks ?? this.blocks,
      selectedBlockId: selectedBlockId ?? this.selectedBlockId,
      rooms: rooms ?? this.rooms,
      isLoadingBlocks: isLoadingBlocks ?? this.isLoadingBlocks,
      isLoadingRooms: isLoadingRooms ?? this.isLoadingRooms,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier that manages occupancy tab state.
class OccupancyNotifier extends StateNotifier<OccupancyState> {
  OccupancyNotifier(this._repository) : super(const OccupancyState());

  final AccommodationRepository _repository;

  /// Fetches all blocks.
  Future<void> fetchBlocks() async {
    state = state.copyWith(isLoadingBlocks: true, errorMessage: null);
    try {
      final blocks = await _repository.listBlocks();
      state = state.copyWith(blocks: blocks, isLoadingBlocks: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoadingBlocks: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoadingBlocks: false,
        errorMessage: 'Failed to load blocks.',
      );
    }
  }

  /// Selects a block and fetches its occupancy data.
  Future<void> selectBlock(String blockId) async {
    state = state.copyWith(
      selectedBlockId: blockId,
      isLoadingRooms: true,
      rooms: [],
      errorMessage: null,
    );
    try {
      final rooms = await _repository.getOccupancy(blockId);
      state = state.copyWith(rooms: rooms, isLoadingRooms: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoadingRooms: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoadingRooms: false,
        errorMessage: 'Failed to load occupancy data.',
      );
    }
  }
}

/// Provider for the occupancy notifier.
final occupancyProvider =
    StateNotifierProvider<OccupancyNotifier, OccupancyState>((ref) {
  final repository = ref.watch(accommodationRepositoryProvider);
  return OccupancyNotifier(repository);
});
