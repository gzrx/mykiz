import 'package:freezed_annotation/freezed_annotation.dart';

part 'bed.freezed.dart';
part 'bed.g.dart';

@freezed
class Bed with _$Bed {
  const factory Bed({
    required String id,
    required String roomId,
    required String bedLabel,
    required bool isOccupied,
  }) = _Bed;

  factory Bed.fromJson(Map<String, dynamic> json) => _$BedFromJson(json);
}
