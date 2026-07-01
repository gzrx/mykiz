import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_occupancy.freezed.dart';
part 'room_occupancy.g.dart';

/// Occupancy summary for a single room, as returned by
/// GET /api/v1/accommodation/occupancy. Distinct from [Room]: it carries
/// aggregate bed counts, not the full bed list or block linkage.
@freezed
class RoomOccupancy with _$RoomOccupancy {
  const factory RoomOccupancy({
    required String roomId,
    required String roomNumber,
    required String roomType, // 'single' | 'twin_sharing'
    required int total,
    required int occupied,
  }) = _RoomOccupancy;

  factory RoomOccupancy.fromJson(Map<String, dynamic> json) =>
      _$RoomOccupancyFromJson(json);
}
