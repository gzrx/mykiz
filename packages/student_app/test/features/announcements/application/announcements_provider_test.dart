import 'package:api_client/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_core/shared_core.dart';
import 'package:student_app/features/announcements/application/announcements_provider.dart';
import 'package:student_app/features/announcements/data/announcements_repository.dart';

class MockMyKizApiClient extends Mock implements MyKizApiClient {}

void main() {
  late MockMyKizApiClient mockApiClient;
  late AnnouncementsRepository repository;

  final sampleAnnouncements = [
    Announcement(
      id: 'ann-1',
      title: 'First Announcement',
      body: 'Body of the first announcement',
      authorId: 'admin-1',
      createdAt: DateTime(2024, 6, 15),
      updatedAt: DateTime(2024, 6, 15),
    ),
    Announcement(
      id: 'ann-2',
      title: 'Second Announcement',
      body: 'Body of the second announcement',
      authorId: 'admin-1',
      createdAt: DateTime(2024, 6, 14),
      updatedAt: DateTime(2024, 6, 14),
    ),
  ];

  final sampleMeta = PaginationMeta(
    currentPage: 1,
    limit: 20,
    totalItems: 2,
    totalPages: 1,
  );

  setUp(() {
    mockApiClient = MockMyKizApiClient();
    repository = AnnouncementsRepository(mockApiClient);
  });

  group('AnnouncementsRepository', () {
    test('listAnnouncements delegates to api client', () async {
      when(() => mockApiClient.listAnnouncements(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => PaginatedResponse(
            items: sampleAnnouncements,
            meta: sampleMeta,
          ));

      final result = await repository.listAnnouncements(page: 1, limit: 20);

      expect(result.items, sampleAnnouncements);
      expect(result.meta.totalItems, 2);
      verify(() => mockApiClient.listAnnouncements(page: 1, limit: 20))
          .called(1);
    });

    test('getAnnouncement delegates to api client', () async {
      when(() => mockApiClient.getAnnouncement(any()))
          .thenAnswer((_) async => sampleAnnouncements[0]);

      final result = await repository.getAnnouncement('ann-1');

      expect(result.id, 'ann-1');
      expect(result.title, 'First Announcement');
      verify(() => mockApiClient.getAnnouncement('ann-1')).called(1);
    });
  });

  group('AnnouncementsListNotifier', () {
    test('does not fetch on creation (screen triggers load)', () async {
      final notifier = AnnouncementsListNotifier(repository);
      await Future<void>.delayed(Duration.zero);

      // No load fires from the constructor — the screen calls
      // loadAnnouncements() post-auth (mirrors complaints).
      expect(notifier.state.announcements, isEmpty);
      expect(notifier.state.isLoading, false);
      verifyNever(() => mockApiClient.listAnnouncements(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ));
    });

    test('loadAnnouncements populates state', () async {
      when(() => mockApiClient.listAnnouncements(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => PaginatedResponse(
            items: sampleAnnouncements,
            meta: sampleMeta,
          ));

      final notifier = AnnouncementsListNotifier(repository);
      await notifier.loadAnnouncements();

      expect(notifier.state.announcements, sampleAnnouncements);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.currentPage, 1);
      expect(notifier.state.totalPages, 1);
      expect(notifier.state.totalItems, 2);
      expect(notifier.state.error, isNull);
    });

    test('sets error state when load fails', () async {
      when(() => mockApiClient.listAnnouncements(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenThrow(const ServerException(
        code: 'INTERNAL_ERROR',
        message: 'Server error',
      ));

      final notifier = AnnouncementsListNotifier(repository);
      await notifier.loadAnnouncements();

      expect(notifier.state.announcements, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Server error');
    });

    test('refresh reloads from page 1', () async {
      when(() => mockApiClient.listAnnouncements(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => PaginatedResponse(
            items: sampleAnnouncements,
            meta: sampleMeta,
          ));

      final notifier = AnnouncementsListNotifier(repository);
      await notifier.loadAnnouncements();

      // Refresh
      await notifier.refresh();

      expect(notifier.state.announcements, sampleAnnouncements);
      expect(notifier.state.currentPage, 1);
      // Called twice: initial load + refresh
      verify(() => mockApiClient.listAnnouncements(page: 1, limit: 20))
          .called(2);
    });

    test('loadMore appends next page items', () async {
      final page1Meta = PaginationMeta(
        currentPage: 1,
        limit: 20,
        totalItems: 3,
        totalPages: 2,
      );
      final page2Announcements = [
        Announcement(
          id: 'ann-3',
          title: 'Third Announcement',
          body: 'Body of the third announcement',
          authorId: 'admin-2',
          createdAt: DateTime(2024, 6, 13),
          updatedAt: DateTime(2024, 6, 13),
        ),
      ];
      final page2Meta = PaginationMeta(
        currentPage: 2,
        limit: 20,
        totalItems: 3,
        totalPages: 2,
      );

      var callCount = 0;
      when(() => mockApiClient.listAnnouncements(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return PaginatedResponse(
            items: sampleAnnouncements,
            meta: page1Meta,
          );
        }
        return PaginatedResponse(
          items: page2Announcements,
          meta: page2Meta,
        );
      });

      final notifier = AnnouncementsListNotifier(repository);
      await notifier.loadAnnouncements();

      expect(notifier.state.hasMore, true);

      await notifier.loadMore();

      expect(notifier.state.announcements.length, 3);
      expect(notifier.state.announcements.last.id, 'ann-3');
      expect(notifier.state.currentPage, 2);
      expect(notifier.state.isLoadingMore, false);
    });

    test('loadMore does nothing when no more pages', () async {
      when(() => mockApiClient.listAnnouncements(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => PaginatedResponse(
            items: sampleAnnouncements,
            meta: sampleMeta,
          ));

      final notifier = AnnouncementsListNotifier(repository);
      await notifier.loadAnnouncements();

      expect(notifier.state.hasMore, false);

      await notifier.loadMore();

      // Should not have made another API call
      verify(() => mockApiClient.listAnnouncements(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).called(1); // Only the initial load
    });
  });

  group('AnnouncementsListState', () {
    test('hasMore is true when currentPage < totalPages', () {
      const state = AnnouncementsListState(currentPage: 1, totalPages: 3);
      expect(state.hasMore, true);
    });

    test('hasMore is false when currentPage >= totalPages', () {
      const state = AnnouncementsListState(currentPage: 3, totalPages: 3);
      expect(state.hasMore, false);
    });
  });
}
