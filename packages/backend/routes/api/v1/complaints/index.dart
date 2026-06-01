import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/complaint_service.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:http_parser/http_parser.dart';

/// /api/v1/complaints route handler.
///
/// - GET: List complaints with role-based scoping (any authenticated user)
/// - POST: Submit a new complaint with optional image (multipart)
Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _listComplaints(context);
    case HttpMethod.post:
      return _submitComplaint(context);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {
          'error': {
            'code': 'METHOD_NOT_ALLOWED',
            'message': 'Only GET and POST methods are allowed.',
          },
        },
      );
  }
}

/// GET /api/v1/complaints
///
/// Lists complaints with pagination and role-based scoping.
/// Students see only their own complaints; Admins see all.
Future<Response> _listComplaints(RequestContext context) async {
  try {
    final user = context.read<UserPayload>();
    final pagination = parsePagination(context);

    final service = ComplaintService();
    final result = await service.list(
      page: pagination.page,
      limit: pagination.limit,
      requesterId: user.id,
      requesterRole: user.role,
    );

    final complaintsJson =
        result.complaints.map((c) => c.toJson()).toList();

    return ApiResponse.success(
      data: complaintsJson,
      meta: result.meta.toJson(),
    );
  } on InvalidRequestException catch (e) {
    return ApiResponse.error(
      statusCode: e.statusCode,
      code: e.code,
      message: e.message,
    );
  } on ComplaintException catch (e) {
    return ApiResponse.error(
      statusCode: e.statusCode,
      code: e.code,
      message: e.message,
    );
  } catch (e) {
    return ApiResponse.error(
      statusCode: HttpStatus.internalServerError,
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred.',
    );
  }
}

/// POST /api/v1/complaints
///
/// Submits a new complaint. Student only — returns 403 for admins.
/// Accepts multipart form data with fields: description, location
/// and optional file part: image (JPEG/PNG, max 5 MB).
Future<Response> _submitComplaint(RequestContext context) async {
  try {
    final user = context.read<UserPayload>();

    // Only students can submit complaints
    if (user.role != 'student') {
      return ApiResponse.error(
        statusCode: HttpStatus.forbidden,
        code: 'FORBIDDEN',
        message: 'Only students can submit complaints.',
      );
    }

    // Parse multipart form data
    final contentType =
        context.request.headers['content-type'] ?? '';

    String description = '';
    String location = '';
    Uint8List? imageBytes;
    String? imageMimeType;

    if (contentType.contains('multipart/form-data')) {
      // Parse multipart boundary
      final mediaType = MediaType.parse(contentType);
      final boundary = mediaType.parameters['boundary'];

      if (boundary == null) {
        return ApiResponse.error(
          statusCode: HttpStatus.badRequest,
          code: 'INVALID_REQUEST',
          message: 'Missing multipart boundary.',
        );
      }

      // Read raw body bytes by collecting the stream
      final bodyStream = context.request.bytes();
      final chunks = <List<int>>[];
      await for (final chunk in bodyStream) {
        chunks.add(chunk);
      }
      final bodyBytes =
          chunks.fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));

      // Parse multipart parts
      final parts = _parseMultipart(bodyBytes, boundary);

      for (final part in parts) {
        final disposition = part.headers['content-disposition'] ?? '';
        final name = _extractFieldName(disposition);

        if (name == 'description') {
          description = utf8.decode(part.body);
        } else if (name == 'location') {
          location = utf8.decode(part.body);
        } else if (name == 'image') {
          imageBytes = Uint8List.fromList(part.body);
          imageMimeType =
              part.headers['content-type'] ?? 'application/octet-stream';
        }
      }
    } else {
      // Fallback: try to parse as JSON for non-multipart requests
      try {
        final body = await context.request.json() as Map<String, dynamic>;
        description = (body['description'] as String?) ?? '';
        location = (body['location'] as String?) ?? '';
      } catch (_) {
        return ApiResponse.error(
          statusCode: HttpStatus.badRequest,
          code: 'INVALID_REQUEST',
          message:
              'Request must be multipart/form-data or valid JSON.',
        );
      }
    }

    final service = ComplaintService();
    final complaint = await service.submit(
      description: description,
      location: location,
      studentId: user.id,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
    );

    return ApiResponse.created(data: complaint.toJson());
  } on ComplaintException catch (e) {
    return ApiResponse.error(
      statusCode: e.statusCode,
      code: e.code,
      message: e.message,
    );
  } catch (e) {
    return ApiResponse.error(
      statusCode: HttpStatus.internalServerError,
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred.',
    );
  }
}

/// Represents a single part in a multipart request.
class _MultipartPart {
  _MultipartPart({required this.headers, required this.body});
  final Map<String, String> headers;
  final List<int> body;
}

/// Parses multipart form data from raw bytes.
List<_MultipartPart> _parseMultipart(List<int> bodyBytes, String boundary) {
  final parts = <_MultipartPart>[];
  final boundaryBytes = utf8.encode('--$boundary');
  final endBoundaryBytes = utf8.encode('--$boundary--');

  // Find all boundary positions
  final positions = <int>[];
  for (var i = 0; i <= bodyBytes.length - boundaryBytes.length; i++) {
    var match = true;
    for (var j = 0; j < boundaryBytes.length; j++) {
      if (bodyBytes[i + j] != boundaryBytes[j]) {
        match = false;
        break;
      }
    }
    if (match) {
      positions.add(i);
    }
  }

  // Parse each part between boundaries
  for (var i = 0; i < positions.length - 1; i++) {
    final start = positions[i] + boundaryBytes.length;
    final end = positions[i + 1];

    // Skip the CRLF after boundary
    var partStart = start;
    if (partStart < bodyBytes.length && bodyBytes[partStart] == 13) {
      partStart++; // CR
    }
    if (partStart < bodyBytes.length && bodyBytes[partStart] == 10) {
      partStart++; // LF
    }

    // Check if this is the end boundary
    final partBytes = bodyBytes.sublist(partStart, end);
    if (_startsWith(bodyBytes, start, endBoundaryBytes)) continue;

    // Split headers from body (separated by double CRLF)
    final headerEnd = _findDoubleCrlf(partBytes);
    if (headerEnd == -1) continue;

    final headerBytes = partBytes.sublist(0, headerEnd);
    final bodyStart = headerEnd + 4; // Skip \r\n\r\n
    var bodyEnd = partBytes.length;

    // Remove trailing CRLF before next boundary
    if (bodyEnd >= 2 &&
        partBytes[bodyEnd - 2] == 13 &&
        partBytes[bodyEnd - 1] == 10) {
      bodyEnd -= 2;
    }

    final bodyData = partBytes.sublist(bodyStart, bodyEnd);

    // Parse headers
    final headerStr = utf8.decode(headerBytes);
    final headers = <String, String>{};
    for (final line in headerStr.split('\r\n')) {
      final colonIndex = line.indexOf(':');
      if (colonIndex > 0) {
        final key = line.substring(0, colonIndex).trim().toLowerCase();
        final value = line.substring(colonIndex + 1).trim();
        headers[key] = value;
      }
    }

    parts.add(_MultipartPart(headers: headers, body: bodyData));
  }

  return parts;
}

/// Checks if bytes at position start with the given prefix.
bool _startsWith(List<int> bytes, int position, List<int> prefix) {
  if (position + prefix.length > bytes.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (bytes[position + i] != prefix[i]) return false;
  }
  return true;
}

/// Finds the position of \r\n\r\n in the byte list.
int _findDoubleCrlf(List<int> bytes) {
  for (var i = 0; i < bytes.length - 3; i++) {
    if (bytes[i] == 13 &&
        bytes[i + 1] == 10 &&
        bytes[i + 2] == 13 &&
        bytes[i + 3] == 10) {
      return i;
    }
  }
  return -1;
}

/// Extracts the field name from a Content-Disposition header value.
String? _extractFieldName(String disposition) {
  final nameMatch = RegExp(r'name="([^"]*)"').firstMatch(disposition);
  return nameMatch?.group(1);
}
