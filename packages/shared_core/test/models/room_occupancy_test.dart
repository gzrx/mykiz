import 'package:shared_core/shared_core.dart';
import 'package:test/test.dart';

void main() {
  test('RoomOccupancy.fromJson maps occupancy endpoint shape', () {
    final json = {
      'roomId': '00000000-0000-4000-d100-000000000001',
      'roomNumber': 'A-101',
      'roomType': 'single',
      'total': 1,
      'occupied': 0,
    };
    final room = RoomOccupancy.fromJson(json);
    expect(room.roomId, json['roomId']);
    expect(room.roomNumber, 'A-101');
    expect(room.roomType, 'single');
    expect(room.total, 1);
    expect(room.occupied, 0);
  });
}
