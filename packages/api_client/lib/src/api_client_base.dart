import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shared_core/shared_core.dart';

import 'exceptions.dart';

/// Login response containing the JWT token and user data.
class LoginResponse {
  const LoginResponse({required this.token, required this.user});

  final String token;
  final User user;
}

/// Paginated list response containing items and pagination metadata.
class PaginatedResponse<T> {
  const PaginatedResponse({required this.items, required this.meta});

  final List<T> items;
  final PaginationMeta meta;
}

/// Response for the student's own applications endpoint.
class MyApplicationsResponse {
  const MyApplicationsResponse({required this.active, required this.history});

  final List<AccommodationApplication> active;
  final List<AccommodationApplication> history;
}

/// Typed HTTP client for the MyKIZ Backend API.
///
/// Wraps [Dio] with typed methods for all backend endpoints, automatic
/// response deserialization into shared_core models, and HTTP error mapping
/// to typed [ApiException] subclasses.
class MyKizApiClient {
  /// Creates an API client configured with the given [baseUrl].
  ///
  /// Optionally accepts a pre-configured [Dio] instance for testing.
  ///
  /// [onUnauthorized], if provided, is invoked whenever a request maps to
  /// a 401 [UnauthorizedException], before the exception propagates.
  MyKizApiClient({
    required String baseUrl,
    Dio? dio,
    void Function()? onUnauthorized,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 30),
                contentType: 'application/json',
              ),
            ),
        _onUnauthorized = onUnauthorized;

  final Dio _dio;
  final void Function()? _onUnauthorized;

  /// Sets the Bearer token for authenticated requests.
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clears the authentication token.
  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  /// Authenticates a user and returns a [LoginResponse] with JWT and user data.
  ///
  /// POST /api/v1/auth/login
  Future<LoginResponse> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/login',
        data: {'identifier': identifier, 'password': password},
      ),
    );

    final data = response['data'] as Map<String, dynamic>;
    return LoginResponse(
      token: data['token'] as String,
      user: User.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  // ---------------------------------------------------------------------------
  // Announcements
  // ---------------------------------------------------------------------------

  /// Returns a paginated list of announcements.
  ///
  /// GET /api/v1/announcements
  Future<PaginatedResponse<Announcement>> listAnnouncements({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>(
        '/api/v1/announcements',
        queryParameters: {'page': page, 'limit': limit},
      ),
    );

    final items = (response['data'] as List<dynamic>)
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta =
        PaginationMeta.fromJson(response['meta'] as Map<String, dynamic>);

    return PaginatedResponse(items: items, meta: meta);
  }

  /// Returns a single announcement by [id].
  ///
  /// GET /api/v1/announcements/:id
  Future<Announcement> getAnnouncement(String id) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>('/api/v1/announcements/$id'),
    );

    return Announcement.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Creates a new announcement. Requires admin role.
  ///
  /// POST /api/v1/announcements
  Future<Announcement> createAnnouncement({
    required String title,
    required String body,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/announcements',
        data: {'title': title, 'body': body},
      ),
    );

    return Announcement.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Updates an existing announcement. Requires admin role.
  ///
  /// PATCH /api/v1/announcements/:id
  Future<Announcement> updateAnnouncement(
    String id, {
    String? title,
    String? body,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (body != null) data['body'] = body;

    final response = await _request<Map<String, dynamic>>(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/v1/announcements/$id',
        data: data,
      ),
    );

    return Announcement.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Soft-deletes an announcement. Requires admin role.
  ///
  /// DELETE /api/v1/announcements/:id
  Future<void> deleteAnnouncement(String id) async {
    await _request<Map<String, dynamic>>(
      () => _dio.delete<Map<String, dynamic>>('/api/v1/announcements/$id'),
    );
  }

  // ---------------------------------------------------------------------------
  // Complaints
  // ---------------------------------------------------------------------------

  /// Returns a paginated list of complaints (scoped by role).
  ///
  /// GET /api/v1/complaints
  Future<PaginatedResponse<Complaint>> listComplaints({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>(
        '/api/v1/complaints',
        queryParameters: {'page': page, 'limit': limit},
      ),
    );

    final items = (response['data'] as List<dynamic>)
        .map((e) => Complaint.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta =
        PaginationMeta.fromJson(response['meta'] as Map<String, dynamic>);

    return PaginatedResponse(items: items, meta: meta);
  }

  /// Returns a single complaint by [id] (scoped by role).
  ///
  /// GET /api/v1/complaints/:id
  Future<Complaint> getComplaint(String id) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>('/api/v1/complaints/$id'),
    );

    return Complaint.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Submits a new complaint. Requires student role.
  ///
  /// POST /api/v1/complaints (multipart/form-data)
  Future<Complaint> submitComplaint({
    required String description,
    required String location,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final formData = FormData.fromMap({
      'description': description,
      'location': location,
      if (imageBytes != null)
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: imageName ?? 'image.jpg',
        ),
    });

    final response = await _request<Map<String, dynamic>>(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/complaints',
        data: formData,
      ),
    );

    return Complaint.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Advances a complaint's status. Requires admin role.
  ///
  /// PATCH /api/v1/complaints/:id/status
  Future<Complaint> advanceComplaintStatus(
    String id, {
    required String status,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/v1/complaints/$id/status',
        data: {'status': status},
      ),
    );

    return Complaint.fromJson(response['data'] as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // Accommodation
  // ---------------------------------------------------------------------------

  /// Returns the current accommodation settings (application window status).
  ///
  /// GET /api/v1/accommodation/settings
  Future<Map<String, dynamic>> getAccommodationSettings() async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>('/api/v1/accommodation/settings'),
    );
    return response['data'] as Map<String, dynamic>;
  }

  /// Updates the accommodation application window setting. Admin only.
  ///
  /// PUT /api/v1/accommodation/settings
  Future<Map<String, dynamic>> updateAccommodationSettings({
    required bool open,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.put<Map<String, dynamic>>(
        '/api/v1/accommodation/settings',
        data: {'open': open},
      ),
    );
    return response['data'] as Map<String, dynamic>;
  }

  /// Returns all accommodation blocks.
  ///
  /// GET /api/v1/accommodation/blocks
  Future<List<Block>> listBlocks() async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>('/api/v1/accommodation/blocks'),
    );

    return (response['data'] as List<dynamic>)
        .map((e) => Block.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns a paginated, filterable list of accommodation applications.
  ///
  /// GET /api/v1/accommodation/applications?status=&type=&tags=&page=&limit=
  Future<Map<String, dynamic>> listApplications({
    String? status,
    String? type,
    List<String>? tags,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (tags != null && tags.isNotEmpty) queryParams['tags'] = tags.join(',');

    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>(
        '/api/v1/accommodation/applications',
        queryParameters: queryParams,
      ),
    );
    return response;
  }

  /// Returns the student's own applications split into active and history.
  ///
  /// GET /api/v1/accommodation/my-applications
  Future<MyApplicationsResponse> getMyApplications() async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>(
        '/api/v1/accommodation/my-applications',
      ),
    );

    final data = response['data'] as Map<String, dynamic>;
    final active = (data['active'] as List<dynamic>)
        .map((e) => AccommodationApplication.fromJson(e as Map<String, dynamic>))
        .toList();
    final history = (data['history'] as List<dynamic>)
        .map((e) => AccommodationApplication.fromJson(e as Map<String, dynamic>))
        .toList();

    return MyApplicationsResponse(active: active, history: history);
  }

  /// Submits a new accommodation application.
  ///
  /// POST /api/v1/accommodation/applications
  Future<AccommodationApplication> submitAccommodationApplication({
    required String applicationType,
    String? roomTypePreference,
    String? preferredBlockId,
    List<String>? lifestyleTags,
    DateTime? checkInDate,
    DateTime? checkOutDate,
  }) async {
    final body = <String, dynamic>{
      'applicationType': applicationType,
      if (roomTypePreference != null) 'roomTypePreference': roomTypePreference,
      if (preferredBlockId != null) 'preferredBlockId': preferredBlockId,
      if (lifestyleTags != null) 'lifestyleTags': lifestyleTags,
      if (checkInDate != null)
        'checkInDate': checkInDate.toIso8601String().split('T').first,
      if (checkOutDate != null)
        'checkOutDate': checkOutDate.toIso8601String().split('T').first,
    };

    final response = await _request<Map<String, dynamic>>(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/accommodation/applications',
        data: body,
      ),
    );

    return AccommodationApplication.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  /// Checks in an application by UUID.
  ///
  /// POST /api/v1/accommodation/check-in
  Future<AccommodationApplication> checkIn({
    required String applicationId,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/accommodation/check-in',
        data: {'applicationId': applicationId},
      ),
    );
    return AccommodationApplication.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  /// Checks out an application by UUID.
  ///
  /// POST /api/v1/accommodation/check-out
  Future<AccommodationApplication> checkOut({
    required String applicationId,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/accommodation/check-out',
        data: {'applicationId': applicationId},
      ),
    );
    return AccommodationApplication.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  /// Rejects an accommodation application with a reason. Admin only.
  ///
  /// POST /api/v1/accommodation/applications/:id/reject
  Future<AccommodationApplication> rejectApplication(
    String id, {
    required String reason,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/accommodation/applications/$id/reject',
        data: {'reason': reason},
      ),
    );
    return AccommodationApplication.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  /// Returns per-room occupancy counts for a block.
  ///
  /// GET /api/v1/accommodation/occupancy?blockId=...
  Future<List<RoomOccupancy>> getOccupancy(String blockId) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>(
        '/api/v1/accommodation/occupancy',
        queryParameters: {'blockId': blockId},
      ),
    );

    return (response['data'] as List<dynamic>)
        .map((e) => RoomOccupancy.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns rooms filtered by block (and optionally by room type).
  ///
  /// GET /api/v1/accommodation/rooms?blockId=...&roomType=...
  Future<List<Room>> listRooms({
    required String blockId,
    String? roomType,
  }) async {
    final queryParams = <String, dynamic>{'blockId': blockId};
    if (roomType != null) queryParams['roomType'] = roomType;

    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>(
        '/api/v1/accommodation/rooms',
        queryParameters: queryParams,
      ),
    );

    return (response['data'] as List<dynamic>)
        .map((e) => Room.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns beds filtered by room.
  ///
  /// GET /api/v1/accommodation/beds?roomId=...
  Future<List<Bed>> listBeds({required String roomId}) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>(
        '/api/v1/accommodation/beds',
        queryParameters: {'roomId': roomId},
      ),
    );

    return (response['data'] as List<dynamic>)
        .map((e) => Bed.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Approves an application with a specific bed assignment.
  ///
  /// POST /api/v1/accommodation/applications/:id/approve
  Future<AccommodationApplication> approveApplication(
    String id, {
    required String bedId,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/accommodation/applications/$id/approve',
        data: {'bedId': bedId},
      ),
    );

    return AccommodationApplication.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // Bookings
  // ---------------------------------------------------------------------------

  /// Returns a list of active facilities.
  ///
  /// GET /api/v1/facilities
  Future<List<Facility>> listFacilities() async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>('/api/v1/facilities'),
    );
    return (response['data'] as List<dynamic>)
        .map((e) => Facility.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns slot configs for a facility.
  ///
  /// GET /api/v1/facilities/:id/slots
  Future<List<FacilitySlotConfig>> getFacilitySlots(String facilityId) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>(
        '/api/v1/facilities/$facilityId/slots',
      ),
    );
    return (response['data'] as List<dynamic>)
        .map((e) => FacilitySlotConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns slot availability for a facility on a specific date.
  ///
  /// GET /api/v1/facilities/:id/availability?date=YYYY-MM-DD
  Future<List<Map<String, dynamic>>> getSlotAvailability(
    String facilityId, {
    required String date,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>(
        '/api/v1/facilities/$facilityId/availability',
        queryParameters: {'date': date},
      ),
    );
    return (response['data'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// Returns a paginated list of the student's bookings.
  ///
  /// GET /api/v1/bookings?type=active|history&page=&limit=
  Future<PaginatedResponse<Booking>> listBookings({
    String type = 'active',
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>(
        '/api/v1/bookings',
        queryParameters: {'type': type, 'page': page, 'limit': limit},
      ),
    );
    final items = (response['data'] as List<dynamic>)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = _metaOf(response, items.length);
    return PaginatedResponse(items: items, meta: meta);
  }

  /// Submits a new booking.
  ///
  /// POST /api/v1/bookings
  Future<Booking> submitBooking({
    required String facilityId,
    required String slotConfigId,
    required String date,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/bookings',
        data: {
          'facilityId': facilityId,
          'slotConfigId': slotConfigId,
          'date': date,
        },
      ),
    );
    return Booking.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Cancels a booking.
  ///
  /// DELETE /api/v1/bookings/:id
  Future<void> cancelBooking(String id) async {
    await _request<Map<String, dynamic>>(
      () => _dio.delete<Map<String, dynamic>>('/api/v1/bookings/$id'),
    );
  }

  /// QR check-in for a booking.
  ///
  /// POST /api/v1/bookings/check-in
  Future<Booking> checkInBooking({
    required String facilityId,
    required String slotConfigId,
    required String date,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/bookings/check-in',
        data: {
          'facilityId': facilityId,
          'slotConfigId': slotConfigId,
          'date': date,
        },
      ),
    );
    return Booking.fromJson(response['data'] as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // Bookings (Admin)
  // ---------------------------------------------------------------------------

  /// Returns all bookings (admin), filterable.
  ///
  /// GET /api/v1/admin/bookings
  Future<PaginatedResponse<Booking>> listAllBookings({
    String? facility,
    String? status,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (facility != null) queryParams['facility'] = facility;
    if (status != null) queryParams['status'] = status;
    if (from != null) queryParams['from'] = from;
    if (to != null) queryParams['to'] = to;

    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>(
        '/api/v1/admin/bookings',
        queryParameters: queryParams,
      ),
    );
    final items = (response['data'] as List<dynamic>)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = _metaOf(response, items.length);
    return PaginatedResponse(items: items, meta: meta);
  }

  /// Approves a pending booking.
  ///
  /// PUT /api/v1/admin/bookings/:id/approve
  Future<Booking> approveBooking(String id) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.put<Map<String, dynamic>>(
        '/api/v1/admin/bookings/$id/approve',
      ),
    );
    return Booking.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Rejects a pending booking with a reason.
  ///
  /// PUT /api/v1/admin/bookings/:id/reject
  Future<Booking> rejectBooking(String id, {required String reason}) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.put<Map<String, dynamic>>(
        '/api/v1/admin/bookings/$id/reject',
        data: {'reason': reason},
      ),
    );
    return Booking.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Creates a booking on behalf of a student (admin).
  ///
  /// POST /api/v1/admin/bookings
  Future<Booking> createManualBooking({
    required String facilityId,
    required String slotConfigId,
    required String date,
    required String studentId,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/admin/bookings',
        data: {
          'facilityId': facilityId,
          'slotConfigId': slotConfigId,
          'date': date,
          'studentId': studentId,
        },
      ),
    );
    return Booking.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Updates facility settings.
  ///
  /// PUT /api/v1/facilities/:id
  Future<Facility> updateFacility(
    String id, {
    bool? isActive,
    String? approvalMode,
    int? graceBeforeMinutes,
    int? graceAfterMinutes,
  }) async {
    final data = <String, dynamic>{};
    if (isActive != null) data['isActive'] = isActive;
    if (approvalMode != null) data['approvalMode'] = approvalMode;
    if (graceBeforeMinutes != null) {
      data['graceBeforeMinutes'] = graceBeforeMinutes;
    }
    if (graceAfterMinutes != null) {
      data['graceAfterMinutes'] = graceAfterMinutes;
    }

    final response = await _request<Map<String, dynamic>>(
      () => _dio.put<Map<String, dynamic>>(
        '/api/v1/facilities/$id',
        data: data,
      ),
    );
    return Facility.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Adds a slot config to a facility.
  ///
  /// POST /api/v1/facilities/:id/slots
  Future<FacilitySlotConfig> addSlotConfig(
    String facilityId, {
    required String startTime,
    required String endTime,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/facilities/$facilityId/slots',
        data: {'startTime': startTime, 'endTime': endTime},
      ),
    );
    return FacilitySlotConfig.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  /// Deactivates/deletes a slot config.
  ///
  /// DELETE /api/v1/facilities/:id/slots/:slotId
  Future<void> deleteSlotConfig(String facilityId, String slotId) async {
    await _request<Map<String, dynamic>>(
      () => _dio.delete<Map<String, dynamic>>(
        '/api/v1/facilities/$facilityId/slots/$slotId',
      ),
    );
  }

  /// Blocks a date-slot combination.
  ///
  /// POST /api/v1/facilities/:id/slots/:slotId/block
  Future<BlockedSlot> blockSlot(
    String facilityId,
    String slotId, {
    required String date,
    String? reason,
  }) async {
    final data = <String, dynamic>{'date': date};
    if (reason != null) data['reason'] = reason;

    final response = await _request<Map<String, dynamic>>(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/facilities/$facilityId/slots/$slotId/block',
        data: data,
      ),
    );
    return BlockedSlot.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Unblocks a blocked slot.
  ///
  /// DELETE /api/v1/facilities/:id/blocked-slots/:blockId
  Future<void> unblockSlot(String facilityId, String blockId) async {
    await _request<Map<String, dynamic>>(
      () => _dio.delete<Map<String, dynamic>>(
        '/api/v1/facilities/$facilityId/blocked-slots/$blockId',
      ),
    );
  }

  /// Returns booking summary for a date range.
  ///
  /// GET /api/v1/admin/bookings/summary
  Future<Map<String, dynamic>> getBookingSummary({
    required String from,
    required String to,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>(
        '/api/v1/admin/bookings/summary',
        queryParameters: {'from': from, 'to': to},
      ),
    );
    return response['data'] as Map<String, dynamic>;
  }

  /// Returns daily utilization data.
  ///
  /// GET /api/v1/admin/bookings/utilization
  Future<List<Map<String, dynamic>>> getDailyUtilization({
    required String date,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>(
        '/api/v1/admin/bookings/utilization',
        queryParameters: {'date': date},
      ),
    );
    return (response['data'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// Returns the export URL for bookings CSV.
  ///
  /// GET /api/v1/admin/bookings/export
  Future<Uint8List> exportBookingsCsv({
    String? facility,
    String? status,
    String? from,
    String? to,
  }) async {
    final queryParams = <String, dynamic>{};
    if (facility != null) queryParams['facility'] = facility;
    if (status != null) queryParams['status'] = status;
    if (from != null) queryParams['from'] = from;
    if (to != null) queryParams['to'] = to;

    try {
      final response = await _dio.get<List<int>>(
        '/api/v1/admin/bookings/export',
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data!);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Images
  // ---------------------------------------------------------------------------

  /// Retrieves an image by its storage key as raw bytes.
  ///
  /// GET /api/v1/images/:key
  Future<Uint8List> getImage(String key) async {
    try {
      final response = await _dio.get<List<int>>(
        '/api/v1/images/$key',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data!);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Builds a [PaginationMeta] from a response, synthesizing a sensible
  /// default when the server omits or nulls the `meta` field.
  PaginationMeta _metaOf(Map<String, dynamic> response, int itemCount) {
    final meta = response['meta'];
    if (meta is Map<String, dynamic>) {
      return PaginationMeta.fromJson(meta);
    }
    return PaginationMeta(
      currentPage: 1,
      limit: itemCount == 0 ? 20 : itemCount,
      totalItems: itemCount,
      totalPages: 1,
    );
  }

  /// Executes a request and extracts the response data, mapping errors to
  /// typed exceptions.
  Future<T> _request<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Maps a [DioException] to the appropriate [ApiException] subclass.
  ApiException _mapDioException(DioException e) {
    // Handle timeout errors
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const ApiTimeoutException();
    }

    // Handle HTTP error responses
    final response = e.response;
    if (response != null) {
      final data = response.data;
      String code = 'UNKNOWN';
      String message = 'An unexpected error occurred';

      if (data is Map<String, dynamic> && data.containsKey('error')) {
        final error = data['error'] as Map<String, dynamic>;
        code = error['code'] as String? ?? code;
        message = error['message'] as String? ?? message;
      }

      return switch (response.statusCode) {
        401 => () {
            _onUnauthorized?.call();
            return UnauthorizedException(code: code, message: message);
          }(),
        403 => ForbiddenException(code: code, message: message),
        404 => NotFoundException(code: code, message: message),
        400 => ValidationException(code: code, message: message),
        409 => ConflictException(code: code, message: message),
        500 => ServerException(code: code, message: message),
        _ => ServerException(code: code, message: message),
      };
    }

    // Handle connection errors and other failures
    return ServerException(
      code: 'CONNECTION_ERROR',
      message: e.message ?? 'Failed to connect to server',
    );
  }
}
