import 'package:api_client/api_client.dart';
import 'package:shared_core/shared_core.dart';

import 'package:admin_web/features/accommodation/data/accommodation_repository.dart';

/// Fake repository for testing the accommodation settings provider.
class FakeAccommodationRepository implements AccommodationRepository {
  bool windowOpen = false;
  bool shouldFail = false;

  @override
  Future<bool> getWindowOpen() async {
    if (shouldFail) {
      throw const ServerException(
        code: 'INTERNAL',
        message: 'Server error',
      );
    }
    return windowOpen;
  }

  @override
  Future<bool> updateWindowOpen({required bool open}) async {
    if (shouldFail) {
      throw const ServerException(
        code: 'INTERNAL',
        message: 'Could not save setting.',
      );
    }
    windowOpen = open;
    return windowOpen;
  }

  @override
  Future<List<Block>> listBlocks() async => [];

  @override
  Future<List<Room>> getOccupancy(String blockId) async => [];

  @override
  Future<List<Room>> listRooms({required String blockId, String? roomType}) async => [];

  @override
  Future<List<Bed>> listAvailableBeds({required String roomId}) async => [];

  @override
  Future<AccommodationApplication> approveApplication(String id, {required String bedId}) =>
      throw UnimplementedError();

  @override
  Future<AccommodationApplication> checkIn(String applicationId) =>
      throw UnimplementedError();

  @override
  Future<AccommodationApplication> checkOut(String applicationId) =>
      throw UnimplementedError();

  @override
  Future<AccommodationApplication> rejectApplication(String id, {required String reason}) =>
      throw UnimplementedError();

  @override
  Future<({List<AccommodationApplication> items, int total})> listApplications({
    String? status,
    String? type,
    List<String>? tags,
    int page = 1,
    int limit = 20,
  }) async => (items: <AccommodationApplication>[], total: 0);
}
