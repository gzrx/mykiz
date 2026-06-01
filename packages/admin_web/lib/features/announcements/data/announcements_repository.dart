import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../../auth/data/auth_repository.dart';

/// Repository that handles announcement API calls.
class AnnouncementsRepository {
  const AnnouncementsRepository(this._client);

  final MyKizApiClient _client;

  /// Returns a paginated list of announcements.
  Future<PaginatedResponse<Announcement>> listAnnouncements({
    int page = 1,
    int limit = 20,
  }) {
    return _client.listAnnouncements(page: page, limit: limit);
  }

  /// Returns a single announcement by [id].
  Future<Announcement> getAnnouncement(String id) {
    return _client.getAnnouncement(id);
  }

  /// Creates a new announcement with the given [title] and [body].
  Future<Announcement> createAnnouncement({
    required String title,
    required String body,
  }) {
    return _client.createAnnouncement(title: title, body: body);
  }

  /// Updates an existing announcement by [id].
  /// At least one of [title] or [body] must be provided.
  Future<Announcement> updateAnnouncement(
    String id, {
    String? title,
    String? body,
  }) {
    return _client.updateAnnouncement(id, title: title, body: body);
  }

  /// Soft-deletes an announcement by [id].
  Future<void> deleteAnnouncement(String id) {
    return _client.deleteAnnouncement(id);
  }
}

/// Provider for the [AnnouncementsRepository].
final announcementsRepositoryProvider =
    Provider<AnnouncementsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AnnouncementsRepository(client);
});
