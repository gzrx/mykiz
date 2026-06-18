import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/services/booking_exception.dart';
import 'package:backend/services/booking_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// GET /api/v1/admin/bookings/export — CSV export of bookings.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {
        'error': {
          'code': 'METHOD_NOT_ALLOWED',
          'message': 'Only GET method is allowed.',
        },
      },
    );
  }

  try {
    final params = context.request.uri.queryParameters;

    final facilityId = params['facilityId'];
    final status = params['status'];
    final fromDate =
        params['fromDate'] != null ? DateTime.tryParse(params['fromDate']!) : null;
    final toDate =
        params['toDate'] != null ? DateTime.tryParse(params['toDate']!) : null;

    final service = BookingService();
    // ponytail: high limit instead of removing pagination — same effect, no API change needed
    final bookings = await service.listAllBookings(
      facilityId: facilityId,
      status: status,
      fromDate: fromDate,
      toDate: toDate,
      page: 1,
      limit: 10000,
    );

    final csv = StringBuffer()
      ..writeln('Booking Reference,Student ID,Facility ID,Date,Status,Created At');

    for (final b in bookings) {
      csv.writeln([
        _csvEscape(b.bookingReference),
        _csvEscape(b.studentId),
        _csvEscape(b.facilityId),
        _csvEscape(b.bookingDate.toIso8601String().split('T').first),
        _csvEscape(b.status),
        _csvEscape(b.createdAt.toIso8601String()),
      ].join(','));
    }

    return Response(
      statusCode: HttpStatus.ok,
      body: csv.toString(),
      headers: {
        HttpHeaders.contentTypeHeader: 'text/csv; charset=utf-8',
        'Content-Disposition': 'attachment; filename="bookings_export.csv"',
      },
    );
  } on InvalidRequestException catch (e) {
    return ApiResponse.error(
      statusCode: e.statusCode,
      code: e.code,
      message: e.message,
    );
  } on BookingException catch (e) {
    return ApiResponse.error(
      statusCode: e.statusCode,
      code: e.code,
      message: e.message,
    );
  } catch (_) {
    return ApiResponse.error(
      statusCode: HttpStatus.internalServerError,
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred.',
    );
  }
}

String _csvEscape(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
