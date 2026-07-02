import 'package:admin_web/features/accommodation/application/occupancy_provider.dart';
import 'package:admin_web/features/accommodation/data/accommodation_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

import 'fake_accommodation_repository.dart';

class _OccupancyFakeRepository extends FakeAccommodationRepository {
  @override
  Future<List<RoomOccupancy>> getOccupancy(String blockId) async => const [
        RoomOccupancy(
            roomId: 'r1',
            roomNumber: 'A-101',
            roomType: 'single',
            total: 1,
            occupied: 1),
      ];
}

void main() {
  test('selectBlock loads RoomOccupancy rows', () async {
    final container = ProviderContainer(overrides: [
      accommodationRepositoryProvider
          .overrideWithValue(_OccupancyFakeRepository()),
    ]);
    addTearDown(container.dispose);

    await container.read(occupancyProvider.notifier).selectBlock('b1');
    final rooms = container.read(occupancyProvider).rooms;
    expect(rooms, hasLength(1));
    expect(rooms.first.occupied, 1);
  });
}
