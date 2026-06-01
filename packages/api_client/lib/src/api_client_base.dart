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

/// Typed HTTP client for the MyKIZ Backend API.
///
/// Wraps [Dio] with typed methods for all backend endpoints, automatic
/// response deserialization into shared_core models, and HTTP error mapping
/// to typed [ApiException] subclasses.
class MyKizApiClient {
  /// Creates an API client configured with the given [baseUrl].
  ///
  /// Optionally accepts a pre-configured [Dio] instance for testing.
  MyKizApiClient({required String baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 30),
                contentType: 'application/json',
              ),
            );

  final Dio _dio;

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
        401 => UnauthorizedException(code: code, message: message),
        403 => ForbiddenException(code: code, message: message),
        404 => NotFoundException(code: code, message: message),
        400 => ValidationException(code: code, message: message),
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
