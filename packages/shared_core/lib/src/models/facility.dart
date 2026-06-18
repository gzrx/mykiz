import 'package:freezed_annotation/freezed_annotation.dart';

part 'facility.freezed.dart';
part 'facility.g.dart';

@freezed
class Facility with _$Facility {
  const factory Facility({
    required String id,
    required String name,
    String? description,
    required String approvalMode,
    required bool isActive,
    required int capacity,
    required int graceBeforeMinutes,
    required int graceAfterMinutes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Facility;

  factory Facility.fromJson(Map<String, dynamic> json) =>
      _$FacilityFromJson(json);
}
