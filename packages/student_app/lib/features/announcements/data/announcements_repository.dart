import 'package:api_client/api_client.dart';
import 'package:shared_core/shared_core.dart';

/// Repository that wraps [MyKizApiClient] announcement methods.
///
/// Provides a clean interface for the application layer to fetch
/// announcements without depending directly on the API client.
class AnnouncementsRepository {
  const AnnouncementsRepository(this._apiClient);

  final MyKizApiClient _apiClient;

  /// Fetches a paginated list of announcements.
  ///
  /// [page] defaults to 1, [limit] defaults to 20.
  Future<PaginatedResponse<Announcement>> listAnnouncements({
    int page = 1,
    int limit = 20,
  }) {
    return _apiClient.listAnnouncements(page: page, limit: limit);
  }

  /// Fetches a single announcement by its [id].
  Future<Announcement> getAnnouncement(String id) {
    return _apiClient.getAnnouncement(id);
  }
}
