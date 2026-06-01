import 'dart:io';
import 'dart:typed_data';

import 'package:minio_new/minio.dart';
import 'package:shared_core/shared_core.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';

/// Exception thrown by [ComplaintService] for domain-specific errors.
class ComplaintException implements Exception {
  const ComplaintException({
    required this.code,
    required this.message,
    this.statusCode = 400,
  });

  final String code;
  final String message;
  final int statusCode;
}

/// Result of a paginated complaint list query.
class PaginatedComplaints {
  const PaginatedComplaints({
    required this.complaints,
    required this.meta,
  });

  final List<Complaint> complaints;
  final PaginationMeta meta;
}

/// Service responsible for complaint submission, retrieval, status transitions,
/// and enforcement of immutability rules.
class ComplaintService {
  ComplaintService({Minio? minioClient}) : _minio = minioClient;

  final Minio? _minio;
  static final _uuid = Uuid();

  /// Returns the MinIO client, creating one from environment if not injected.
  Minio get _minioClient {
    if (_minio != null) return _minio!;
    return Minio(
      endPoint: Platform.environment['MINIO_ENDPOINT'] ?? 'localhost',
      port: int.parse(Platform.environment['MINIO_PORT'] ?? '9000'),
      useSSL: false,
      accessKey: Platform.environment['MINIO_ACCESS_KEY'] ?? 'mykiz_minio',
      secretKey: Platform.environment['MINIO_SECRET_KEY'] ?? 'mykiz_minio_secret',
    );
  }

  String get _bucket =>
      Platform.environment['MINIO_BUCKET'] ?? 'mykiz-uploads';

  /// Submits a new complaint.
  ///
  /// Validates [description] (1-1000 chars) and [location] (1-200 chars).
  /// Optionally handles image upload with JPEG/PNG validation and 5 MB limit.
  /// Sets initial status to "submitted", generates UUID, and sets server
  /// createdAt.
  ///
  /// Throws [ComplaintException] for validation failures or file errors.
  Future<Complaint> submit({
    required String description,
    required String location,
    required String studentId,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    // Validate description
    if (description.isEmpty || description.length > 1000) {
      throw const ComplaintException(
        code: 'VALIDATION_ERROR',
        message:
            'Description must be between 1 and 1000 characters.',
        statusCode: 400,
      );
    }

    // Validate location
    if (location.isEmpty || location.length > 200) {
      throw const ComplaintException(
        code: 'VALIDATION_ERROR',
        message: 'Location must be between 1 and 200 characters.',
        statusCode: 400,
      );
    }

    // Handle image upload if provided
    String? imageKey;
    if (imageBytes != null) {
      // Validate file size (max 5 MB)
      if (imageBytes.length > 5 * 1024 * 1024) {
        throw const ComplaintException(
          code: 'FILE_TOO_LARGE',
          message: 'Image must not exceed 5 MB.',
          statusCode: 400,
        );
      }

      // Validate MIME type
      final validMimeTypes = ['image/jpeg', 'image/png'];
      if (imageMimeType == null ||
          !validMimeTypes.contains(imageMimeType.toLowerCase())) {
        throw const ComplaintException(
          code: 'INVALID_FILE_TYPE',
          message: 'Image must be JPEG or PNG format.',
          statusCode: 400,
        );
      }

      // Determine file extension
      final extension =
          imageMimeType.toLowerCase() == 'image/png' ? 'png' : 'jpg';

      // Generate unique key for MinIO storage
      imageKey = 'complaints/${_uuid.v4()}.$extension';

      // Upload to MinIO
      await _minioClient.putObject(
        _bucket,
        imageKey,
        Stream.value(imageBytes),
        size: imageBytes.length,
        metadata: {'Content-Type': imageMimeType},
      );
    }

    // Generate complaint ID and timestamps
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();

    // Insert into database
    await Database.query(
      'INSERT INTO complaints (id, student_id, description, location, image_key, status, created_at, updated_at) '
      'VALUES (@id, @studentId, @description, @location, @imageKey, @status, @createdAt, @updatedAt)',
      parameters: {
        'id': id,
        'studentId': studentId,
        'description': description,
        'location': location,
        'imageKey': imageKey,
        'status': 'submitted',
        'createdAt': now,
        'updatedAt': now,
      },
    );

    return Complaint(
      id: id,
      studentId: studentId,
      description: description,
      location: location,
      imageKey: imageKey,
      status: 'submitted',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Retrieves a complaint by ID with ownership scoping.
  ///
  /// - Students can only see their own complaints (returns 404 for others).
  /// - Admins can see all complaints.
  ///
  /// Throws [ComplaintException] with NOT_FOUND if complaint doesn't exist
  /// or if a student tries to access another student's complaint.
  Future<Complaint> getById(
    String id, {
    required String requesterId,
    required String requesterRole,
  }) async {
    final result = await Database.query(
      'SELECT id, student_id, description, location, image_key, status, created_at, updated_at '
      'FROM complaints WHERE id = @id',
      parameters: {'id': id},
    );

    if (result.isEmpty) {
      throw const ComplaintException(
        code: 'NOT_FOUND',
        message: 'Complaint not found.',
        statusCode: 404,
      );
    }

    final row = result.first;
    final complaint = _rowToComplaint(row);

    // Ownership scoping: students can only see their own complaints
    if (requesterRole == 'student' && complaint.studentId != requesterId) {
      throw const ComplaintException(
        code: 'NOT_FOUND',
        message: 'Complaint not found.',
        statusCode: 404,
      );
    }

    return complaint;
  }

  /// Lists complaints with pagination and role-based scoping.
  ///
  /// - Students see only their own complaints.
  /// - Admins see all complaints.
  /// - Results are ordered by createdAt descending.
  Future<PaginatedComplaints> list({
    int page = 1,
    int limit = 20,
    required String requesterId,
    required String requesterRole,
  }) async {
    // Build WHERE clause based on role
    final whereClause =
        requesterRole == 'student' ? 'WHERE student_id = @requesterId' : '';

    final parameters = <String, dynamic>{};
    if (requesterRole == 'student') {
      parameters['requesterId'] = requesterId;
    }

    // Get total count
    final countResult = await Database.query(
      'SELECT COUNT(*) FROM complaints $whereClause',
      parameters: parameters,
    );
    final totalItems = countResult.first[0] as int;

    // Calculate pagination
    final totalPages = (totalItems / limit).ceil();
    final offset = (page - 1) * limit;

    // Fetch paginated results
    final queryParams = Map<String, dynamic>.from(parameters);
    queryParams['limit'] = limit;
    queryParams['offset'] = offset;

    final result = await Database.query(
      'SELECT id, student_id, description, location, image_key, status, created_at, updated_at '
      'FROM complaints $whereClause '
      'ORDER BY created_at DESC '
      'LIMIT @limit OFFSET @offset',
      parameters: queryParams,
    );

    final complaints = result.map(_rowToComplaint).toList();

    return PaginatedComplaints(
      complaints: complaints,
      meta: PaginationMeta(
        currentPage: page,
        limit: limit,
        totalItems: totalItems,
        totalPages: totalPages == 0 ? 1 : totalPages,
      ),
    );
  }

  /// Advances the status of a complaint using the linear state machine.
  ///
  /// Validates the transition using [ComplaintStatus.canTransitionTo].
  /// Only forward transitions are allowed: submitted → in_progress → resolved.
  ///
  /// Throws [ComplaintException] with:
  /// - NOT_FOUND if complaint doesn't exist
  /// - INVALID_TRANSITION if the transition is not valid
  Future<Complaint> advanceStatus(
    String id, {
    required String newStatus,
  }) async {
    // Fetch current complaint
    final result = await Database.query(
      'SELECT id, student_id, description, location, image_key, status, created_at, updated_at '
      'FROM complaints WHERE id = @id',
      parameters: {'id': id},
    );

    if (result.isEmpty) {
      throw const ComplaintException(
        code: 'NOT_FOUND',
        message: 'Complaint not found.',
        statusCode: 404,
      );
    }

    final row = result.first;
    final currentStatusStr = row[5] as String;

    // Parse current status
    final currentStatus = _parseStatus(currentStatusStr);
    if (currentStatus == null) {
      throw const ComplaintException(
        code: 'INVALID_TRANSITION',
        message: 'Current complaint status is invalid.',
        statusCode: 400,
      );
    }

    // Parse target status
    final targetStatus = _parseStatus(newStatus);
    if (targetStatus == null) {
      throw const ComplaintException(
        code: 'INVALID_TRANSITION',
        message:
            'Invalid target status. Must be one of: submitted, in_progress, resolved.',
        statusCode: 400,
      );
    }

    // Validate transition
    if (!currentStatus.canTransitionTo(targetStatus)) {
      throw ComplaintException(
        code: 'INVALID_TRANSITION',
        message:
            'Cannot transition from "$currentStatusStr" to "$newStatus".',
        statusCode: 400,
      );
    }

    // Update status
    final now = DateTime.now().toUtc();
    await Database.query(
      'UPDATE complaints SET status = @newStatus, updated_at = @updatedAt '
      'WHERE id = @id',
      parameters: {
        'id': id,
        'newStatus': newStatus,
        'updatedAt': now,
      },
    );

    return Complaint(
      id: row[0] as String,
      studentId: row[1] as String,
      description: row[2] as String,
      location: row[3] as String,
      imageKey: row[4] as String?,
      status: newStatus,
      createdAt: row[6] as DateTime,
      updatedAt: now,
    );
  }

  /// Rejects any attempt to modify complaint fields (description, location,
  /// image).
  ///
  /// Always throws [ComplaintException] with FORBIDDEN (403).
  Never rejectModification() {
    throw const ComplaintException(
      code: 'FORBIDDEN',
      message:
          'Complaints cannot be modified after submission. Only status advancement by an Admin is permitted.',
      statusCode: 403,
    );
  }

  /// Rejects any attempt to delete a complaint.
  ///
  /// Always throws [ComplaintException] with FORBIDDEN (403).
  Never rejectDeletion() {
    throw const ComplaintException(
      code: 'FORBIDDEN',
      message: 'Complaints cannot be deleted.',
      statusCode: 403,
    );
  }

  /// Converts a database row to a [Complaint] model.
  Complaint _rowToComplaint(dynamic row) {
    return Complaint(
      id: row[0] as String,
      studentId: row[1] as String,
      description: row[2] as String,
      location: row[3] as String,
      imageKey: row[4] as String?,
      status: row[5] as String,
      createdAt: row[6] as DateTime,
      updatedAt: row[7] as DateTime,
    );
  }

  /// Parses a status string to [ComplaintStatus] enum.
  ///
  /// Handles both snake_case (from DB) and camelCase formats.
  ComplaintStatus? _parseStatus(String status) {
    switch (status) {
      case 'submitted':
        return ComplaintStatus.submitted;
      case 'in_progress':
        return ComplaintStatus.inProgress;
      case 'resolved':
        return ComplaintStatus.resolved;
      default:
        return null;
    }
  }
}
