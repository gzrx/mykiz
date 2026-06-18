import 'dart:typed_data';

import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../../auth/data/auth_repository.dart';

/// Repository that handles bookings API calls for admin.
class BookingsRepository {
  const BookingsRepository(this._client);

  final MyKizApiClient _client;

  Future<List<Facility>> listFacilities() => _client.listFacilities();

  Future<Facility> updateFacility(
    String id, {
    bool? isActive,
    String? approvalMode,
    int? graceBeforeMinutes,
    int? graceAfterMinutes,
  }) =>
      _client.updateFacility(
        id,
        isActive: isActive,
        approvalMode: approvalMode,
        graceBeforeMinutes: graceBeforeMinutes,
        graceAfterMinutes: graceAfterMinutes,
      );

  Future<List<FacilitySlotConfig>> getFacilitySlots(String facilityId) =>
      _client.getFacilitySlots(facilityId);

  Future<FacilitySlotConfig> addSlotConfig(
    String facilityId, {
    required String startTime,
    required String endTime,
  }) =>
      _client.addSlotConfig(facilityId, startTime: startTime, endTime: endTime);

  Future<void> deleteSlotConfig(String facilityId, String slotId) =>
      _client.deleteSlotConfig(facilityId, slotId);

  Future<BlockedSlot> blockSlot(
    String facilityId,
    String slotId, {
    required String date,
    String? reason,
  }) =>
      _client.blockSlot(facilityId, slotId, date: date, reason: reason);

  Future<void> unblockSlot(String facilityId, String blockId) =>
      _client.unblockSlot(facilityId, blockId);

  Future<PaginatedResponse<Booking>> listAllBookings({
    String? facility,
    String? status,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  }) =>
      _client.listAllBookings(
        facility: facility,
        status: status,
        from: from,
        to: to,
        page: page,
        limit: limit,
      );

  Future<Booking> approveBooking(String id) => _client.approveBooking(id);

  Future<Booking> rejectBooking(String id, {required String reason}) =>
      _client.rejectBooking(id, reason: reason);

  Future<Booking> createManualBooking({
    required String facilityId,
    required String slotConfigId,
    required String date,
    required String studentId,
  }) =>
      _client.createManualBooking(
        facilityId: facilityId,
        slotConfigId: slotConfigId,
        date: date,
        studentId: studentId,
      );

  Future<Map<String, dynamic>> getBookingSummary({
    required String from,
    required String to,
  }) =>
      _client.getBookingSummary(from: from, to: to);

  Future<List<Map<String, dynamic>>> getDailyUtilization({
    required String date,
  }) =>
      _client.getDailyUtilization(date: date);

  Future<Uint8List> exportBookingsCsv({
    String? facility,
    String? status,
    String? from,
    String? to,
  }) =>
      _client.exportBookingsCsv(
        facility: facility,
        status: status,
        from: from,
        to: to,
      );
}

/// Provider for the [BookingsRepository].
final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return BookingsRepository(client);
});
