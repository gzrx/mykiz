import 'package:freezed_annotation/freezed_annotation.dart';

part 'blocked_slot.freezed.dart';
part 'blocked_slot.g.dart';

@freezed
class BlockedSlot with _$BlockedSlot {
  const factory BlockedSlot({
    required String id,
    required String facilityId,
    required String slotConfigId,
    required DateTime blockedDate,
    String? reason,
    required DateTime createdAt,
  }) = _BlockedSlot;

  factory BlockedSlot.fromJson(Map<String, dynamic> json) =>
      _$BlockedSlotFromJson(json);
}
