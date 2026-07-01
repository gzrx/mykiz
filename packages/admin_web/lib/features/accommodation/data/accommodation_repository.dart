import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../../auth/data/auth_repository.dart';

/// Repository that handles accommodation API calls.
class AccommodationRepository {
  const AccommodationRepository(this._client);

  final MyKizApiClient _client;

  /// Returns the current application window status.
  Future<bool> getWindowOpen() async {
    final data = await _client.getAccommodationSettings();
    return data['applications_open'] as bool;
  }

  /// Updates the application window status.
  Future<bool> updateWindowOpen({required bool open}) async {
    final data = await _client.updateAccommodationSettings(open: open);
    return data['applications_open'] as bool;
  }

  /// Returns all blocks.
  Future<List<Block>> listBlocks() => _client.listBlocks();

  /// Returns occupancy data (rooms with beds) for a block.
  Future<List<RoomOccupancy>> getOccupancy(String blockId) =>
      _client.getOccupancy(blockId);

  /// Returns rooms for a block, optionally filtered by room type.
  /// Only includes rooms with at least one unoccupied bed.
  Future<List<Room>> listRooms({
    required String blockId,
    String? roomType,
  }) async {
    final rooms = await _client.listRooms(blockId: blockId, roomType: roomType);
    // Filter to rooms that have at least one available bed
    return rooms
        .where((r) => r.beds.any((b) => !b.isOccupied))
        .toList();
  }

  /// Returns beds for a room (only unoccupied).
  Future<List<Bed>> listAvailableBeds({required String roomId}) async {
    final beds = await _client.listBeds(roomId: roomId);
    return beds.where((b) => !b.isOccupied).toList();
  }

  /// Approves an application with the given bed assignment.
  Future<AccommodationApplication> approveApplication(
    String id, {
    required String bedId,
  }) =>
      _client.approveApplication(id, bedId: bedId);

  /// Checks in an application by UUID. Returns the updated application.
  Future<AccommodationApplication> checkIn(String applicationId) =>
      _client.checkIn(applicationId: applicationId);

  /// Checks out an application by UUID. Returns the updated application.
  Future<AccommodationApplication> checkOut(String applicationId) =>
      _client.checkOut(applicationId: applicationId);

  /// Rejects an application with a mandatory reason.
  Future<AccommodationApplication> rejectApplication(
    String id, {
    required String reason,
  }) =>
      _client.rejectApplication(id, reason: reason);

  /// Returns a paginated, filterable list of accommodation applications.
  Future<({List<AccommodationApplication> items, int total})> listApplications({
    String? status,
    String? type,
    List<String>? tags,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.listApplications(
      status: status,
      type: type,
      tags: tags,
      page: page,
      limit: limit,
    );
    final data = response['data'] as List<dynamic>? ?? [];
    final meta = response['meta'] as Map<String, dynamic>?;
    final total = meta?['totalItems'] as int? ?? data.length;
    final items = data
        .map((e) =>
            AccommodationApplication.fromJson(e as Map<String, dynamic>))
        .toList();
    return (items: items, total: total);
  }
}

/// Provider for the [AccommodationRepository].
final accommodationRepositoryProvider =
    Provider<AccommodationRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AccommodationRepository(client);
});
