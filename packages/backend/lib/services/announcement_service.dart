import 'package:shared_core/shared_core.dart';

import 'database.dart';

/// Exception thrown when an announcement is not found or has been soft-deleted.
class NotFoundException implements Exception {
  const NotFoundException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

/// Exception thrown when input validation fails.
class ValidationException implements Exception {
  const ValidationException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

/// Service responsible for creating, reading, updating, and soft-deleting
/// announcements.
///
/// All body content is stored as plain text with no markup interpretation.
class AnnouncementService {
  /// Creates a new announcement.
  ///
  /// Validates that [title] is between 1 and 200 characters and [body] is
  /// between 1 and 5000 characters. Throws [ValidationException] if validation
  /// fails.
  ///
  /// Returns the created [Announcement] with a generated UUID and server-set
  /// timestamps.
  Future<Announcement> create({
    required String title,
    required String body,
    required String authorId,
  }) async {
    _validateTitle(title);
    _validateBody(body);

    final result = await Database.query(
      'INSERT INTO announcements (title, body, author_id) '
      'VALUES (@title, @body, @authorId) '
      'RETURNING id, title, body, author_id, is_deleted, created_at, updated_at',
      parameters: {
        'title': title,
        'body': body,
        'authorId': authorId,
      },
    );

    return _rowToAnnouncement(result.first);
  }

  /// Retrieves an announcement by its UUID.
  ///
  /// Throws [NotFoundException] if the announcement does not exist or has been
  /// soft-deleted.
  Future<Announcement> getById(String id) async {
    final result = await Database.query(
      'SELECT id, title, body, author_id, is_deleted, created_at, updated_at '
      'FROM announcements '
      'WHERE id = @id AND is_deleted = false',
      parameters: {'id': id},
    );

    if (result.isEmpty) {
      throw const NotFoundException(
        code: 'NOT_FOUND',
        message: 'Announcement not found.',
      );
    }

    return _rowToAnnouncement(result.first);
  }

  /// Lists announcements with pagination, excluding soft-deleted records.
  ///
  /// Returns announcements ordered by createdAt descending.
  /// Defaults to page 1 and limit 20. Maximum limit is 100.
  ///
  /// Returns a record containing the list of announcements and pagination
  /// metadata.
  Future<({List<Announcement> items, PaginationMeta meta})> list({
    int page = 1,
    int limit = 20,
  }) async {
    // Clamp limit to max 100
    if (limit > 100) {
      limit = 100;
    }

    final offset = (page - 1) * limit;

    // Get total count of non-deleted announcements
    final countResult = await Database.query(
      'SELECT COUNT(*) FROM announcements WHERE is_deleted = false',
    );
    final totalItems = countResult.first[0] as int;

    // Get paginated results
    final result = await Database.query(
      'SELECT id, title, body, author_id, is_deleted, created_at, updated_at '
      'FROM announcements '
      'WHERE is_deleted = false '
      'ORDER BY created_at DESC '
      'LIMIT @limit OFFSET @offset',
      parameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final items = result.map(_rowToAnnouncement).toList();

    final totalPages = totalItems == 0 ? 1 : (totalItems / limit).ceil();

    final meta = PaginationMeta(
      currentPage: page,
      limit: limit,
      totalItems: totalItems,
      totalPages: totalPages,
    );

    return (items: items, meta: meta);
  }

  /// Updates an existing announcement with partial update support.
  ///
  /// At least one of [title] or [body] must be provided. The same validation
  /// rules apply as for creation. Only provided fields are updated; the other
  /// field remains unchanged. The updatedAt timestamp is always refreshed.
  ///
  /// Throws [NotFoundException] if the announcement does not exist or has been
  /// soft-deleted.
  /// Throws [ValidationException] if validation fails.
  Future<Announcement> update(
    String id, {
    String? title,
    String? body,
  }) async {
    if (title == null && body == null) {
      throw const ValidationException(
        code: 'VALIDATION_ERROR',
        message: 'At least one field (title or body) must be provided.',
      );
    }

    if (title != null) {
      _validateTitle(title);
    }
    if (body != null) {
      _validateBody(body);
    }

    // Check if announcement exists and is not soft-deleted
    final existing = await Database.query(
      'SELECT id FROM announcements WHERE id = @id AND is_deleted = false',
      parameters: {'id': id},
    );

    if (existing.isEmpty) {
      throw const NotFoundException(
        code: 'NOT_FOUND',
        message: 'Announcement not found.',
      );
    }

    // Build dynamic update query
    final setClauses = <String>[];
    final parameters = <String, dynamic>{'id': id};

    if (title != null) {
      setClauses.add('title = @title');
      parameters['title'] = title;
    }
    if (body != null) {
      setClauses.add('body = @body');
      parameters['body'] = body;
    }
    setClauses.add('updated_at = NOW()');

    final result = await Database.query(
      'UPDATE announcements SET ${setClauses.join(', ')} '
      'WHERE id = @id AND is_deleted = false '
      'RETURNING id, title, body, author_id, is_deleted, created_at, updated_at',
      parameters: parameters,
    );

    return _rowToAnnouncement(result.first);
  }

  /// Soft-deletes an announcement by setting is_deleted to true.
  ///
  /// Throws [NotFoundException] if the announcement does not exist or has
  /// already been soft-deleted.
  Future<void> softDelete(String id) async {
    final result = await Database.query(
      'UPDATE announcements SET is_deleted = true, updated_at = NOW() '
      'WHERE id = @id AND is_deleted = false '
      'RETURNING id',
      parameters: {'id': id},
    );

    if (result.isEmpty) {
      throw const NotFoundException(
        code: 'NOT_FOUND',
        message: 'Announcement not found.',
      );
    }
  }

  /// Validates the title field.
  void _validateTitle(String title) {
    if (title.isEmpty || title.length > 200) {
      throw const ValidationException(
        code: 'VALIDATION_ERROR',
        message: 'Title must be between 1 and 200 characters.',
      );
    }
  }

  /// Validates the body field.
  void _validateBody(String body) {
    if (body.isEmpty || body.length > 5000) {
      throw const ValidationException(
        code: 'VALIDATION_ERROR',
        message: 'Body must be between 1 and 5000 characters.',
      );
    }
  }

  /// Converts a database row to an [Announcement] model.
  Announcement _rowToAnnouncement(dynamic row) {
    return Announcement(
      id: row[0] as String,
      title: row[1] as String,
      body: row[2] as String,
      authorId: row[3] as String,
      createdAt: row[5] as DateTime,
      updatedAt: row[6] as DateTime,
    );
  }
}
