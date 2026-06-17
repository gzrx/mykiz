import 'package:freezed_annotation/freezed_annotation.dart';

import 'bed.dart';

part 'room.freezed.dart';
part 'room.g.dart';

@freezed
class Room with _$Room {
  const factory Room({
    required String id,
    required String blockId,
    required String roomNumber,
    required String roomType, // 'single' | 'twin_sharing'
    @Default([]) List<Bed> beds,
  }) = _Room;

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
}
