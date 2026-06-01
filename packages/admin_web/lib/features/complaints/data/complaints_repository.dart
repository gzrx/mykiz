import 'dart:typed_data';

import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../../auth/data/auth_repository.dart';

/// Repository that handles complaints API calls.
class ComplaintsRepository {
  const ComplaintsRepository(this._client);

  final MyKizApiClient _client;

  /// Returns a paginated list of all complaints (admin sees all).
  Future<PaginatedResponse<Complaint>> listComplaints({
    int page = 1,
    int limit = 20,
  }) {
    return _client.listComplaints(page: page, limit: limit);
  }

  /// Returns a single complaint by [id].
  Future<Complaint> getComplaint(String id) {
    return _client.getComplaint(id);
  }

  /// Advances a complaint's status to [newStatus].
  Future<Complaint> advanceStatus(String id, {required String newStatus}) {
    return _client.advanceComplaintStatus(id, status: newStatus);
  }

  /// Retrieves an image by its storage [key] as raw bytes.
  Future<Uint8List> getImage(String key) {
    return _client.getImage(key);
  }
}

/// Provider for the [ComplaintsRepository].
final complaintsRepositoryProvider = Provider<ComplaintsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ComplaintsRepository(client);
});
