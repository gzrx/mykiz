import 'package:freezed_annotation/freezed_annotation.dart';

import 'room.dart';

part 'block.freezed.dart';
part 'block.g.dart';

@freezed
class Block with _$Block {
  const factory Block({
    required String id,
    required String name,
    @Default([]) List<Room> rooms,
  }) = _Block;

  factory Block.fromJson(Map<String, dynamic> json) => _$BlockFromJson(json);
}
