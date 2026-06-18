import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking.freezed.dart';
part 'booking.g.dart';

@freezed
class Booking with _$Booking {
  const factory Booking({
    required String id,
    required String bookingReference,
    required String studentId,
    required String facilityId,
    required String slotConfigId,
    required DateTime bookingDate,
    required String status,
    String? rejectionReason,
    String? createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Booking;

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);
}
