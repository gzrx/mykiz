import 'package:freezed_annotation/freezed_annotation.dart';

part 'facility_slot_config.freezed.dart';
part 'facility_slot_config.g.dart';

@freezed
class FacilitySlotConfig with _$FacilitySlotConfig {
  const factory FacilitySlotConfig({
    required String id,
    required String facilityId,
    required String startTime,
    required String endTime,
    required bool isActive,
    required DateTime createdAt,
  }) = _FacilitySlotConfig;

  factory FacilitySlotConfig.fromJson(Map<String, dynamic> json) =>
      _$FacilitySlotConfigFromJson(json);
}
