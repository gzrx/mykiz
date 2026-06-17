import 'package:freezed_annotation/freezed_annotation.dart';

part 'accommodation_application.freezed.dart';
part 'accommodation_application.g.dart';

@freezed
class AccommodationApplication with _$AccommodationApplication {
  const factory AccommodationApplication({
    required String id,
    required String studentId,
    required String applicationType, // 'semester' | 'out_of_semester'
    required String status,
    String? roomTypePreference,
    String? preferredBlockId,
    @Default([]) List<String> lifestyleTags,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    double? nightlyRate,
    double? totalCost,
    String? assignedBlockId,
    String? assignedRoomId,
    String? assignedBedId,
    String? rejectionReason,
    String? windowId,
    required DateTime createdAt,
    required DateTime updatedAt,
    // Joined fields (nullable, populated in responses)
    String? assignedBlockName,
    String? assignedRoomNumber,
    String? assignedBedLabel,
    String? studentName,
  }) = _AccommodationApplication;

  factory AccommodationApplication.fromJson(Map<String, dynamic> json) =>
      _$AccommodationApplicationFromJson(json);
}
