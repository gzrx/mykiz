import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:minio_new/minio.dart';

/// /api/v1/images/:key route handler.
///
/// - GET: Proxy image from MinIO object storage.
Future<Response> onRequest(RequestContext context, String key) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _getImage(context, key);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {
          'error': {
            'code': 'METHOD_NOT_ALLOWED',
            'message': 'Only GET method is allowed for this endpoint.',
          },
        },
      );
  }
}

/// GET /api/v1/images/:key
///
/// Proxies an image from MinIO. The key corresponds to the object key
/// stored in the complaints table (e.g., "complaints/{uuid}.{ext}").
/// Returns the image bytes with the correct content-type header.
/// Returns 404 if the image is not found in MinIO.
Future<Response> _getImage(RequestContext context, String key) async {
  try {
    final minio = Minio(
      endPoint: Platform.environment['MINIO_ENDPOINT'] ?? 'localhost',
      port: int.parse(Platform.environment['MINIO_PORT'] ?? '9000'),
      useSSL: false,
      accessKey: Platform.environment['MINIO_ACCESS_KEY'] ?? 'mykiz_minio',
      secretKey:
          Platform.environment['MINIO_SECRET_KEY'] ?? 'mykiz_minio_secret',
    );

    final bucket = Platform.environment['MINIO_BUCKET'] ?? 'mykiz-uploads';

    // Reconstruct the full object key (the route param may be URL-decoded)
    final objectKey = key;

    // Get object metadata to determine content type
    final stat = await minio.statObject(bucket, objectKey);

    // Determine content type from the object key extension
    String contentType;
    if (objectKey.endsWith('.png')) {
      contentType = 'image/png';
    } else if (objectKey.endsWith('.jpg') || objectKey.endsWith('.jpeg')) {
      contentType = 'image/jpeg';
    } else {
      // Fallback to metadata or octet-stream
      contentType = stat.metaData?['content-type'] ??
          stat.metaData?['Content-Type'] ??
          'application/octet-stream';
    }

    // Stream the object from MinIO
    final stream = await minio.getObject(bucket, objectKey);

    // Collect all bytes from the stream
    final chunks = <List<int>>[];
    await for (final chunk in stream) {
      chunks.add(chunk);
    }
    final bytes =
        chunks.fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));

    return Response.bytes(
      body: bytes,
      headers: {
        'Content-Type': contentType,
        'Cache-Control': 'public, max-age=86400',
      },
    );
  } on MinioError {
    return ApiResponse.error(
      statusCode: HttpStatus.notFound,
      code: 'NOT_FOUND',
      message: 'Image not found.',
    );
  } catch (e) {
    // Any other error (network, etc.) — treat as not found for images
    return ApiResponse.error(
      statusCode: HttpStatus.notFound,
      code: 'NOT_FOUND',
      message: 'Image not found.',
    );
  }
}
