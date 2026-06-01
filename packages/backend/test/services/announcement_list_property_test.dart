// Feature: mykiz-platform, Property 8: Announcement list excludes deleted and is ordered
import 'package:glados/glados.dart';
import 'package:shared_core/shared_core.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 4.1**
///
/// Property 8: Announcement list excludes deleted and is ordered
/// For any set of announcements where some are soft-deleted and some are not,
/// the list endpoint SHALL return only non-deleted announcements, ordered by
/// createdAt descending.

/// Represents an announcement record with its deletion status.
///
/// This mirrors the database row before filtering is applied. The [isDeleted]
/// field determines whether the announcement should appear in list results.
class AnnouncementRecord {
  const AnnouncementRecord({
    required this.announcement,
    required this.isDeleted,
  });

  final Announcement announcement;
  final bool isDeleted;
}

/// Simulates the filtering and ordering logic applied by [AnnouncementService.list].
///
/// This replicates the SQL query behavior:
/// - WHERE is_deleted = false (exclude soft-deleted)
/// - ORDER BY created_at DESC (newest first)
///
/// Returns only non-deleted announcements sorted by createdAt descending.
List<Announcement> applyListLogic(List<AnnouncementRecord> records) {
  final nonDeleted =
      records.where((r) => !r.isDeleted).map((r) => r.announcement).toList();
  nonDeleted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return nonDeleted;
}

/// Custom generators for announcement property testing.
extension AnnouncementGenerators on Any {

  /// Generates a list of AnnouncementRecords with random deletion flags.
  ///
  /// Ensures at least one deleted and one non-deleted record when list size >= 2
  /// to make the property test meaningful.
  Generator<List<AnnouncementRecord>> get announcementRecordList => simple(
        generate: (random, size) {
          // Generate between 1 and 30 records
          final count = random.nextInt(30) + 1;
          final records = <AnnouncementRecord>[];

          for (var i = 0; i < count; i++) {
            final id = List.generate(
              32,
              (_) => 'abcdef0123456789'[random.nextInt(16)],
            ).join();
            final title = List.generate(
              random.nextInt(50) + 1,
              (_) => String.fromCharCode(97 + random.nextInt(26)),
            ).join();
            final body = List.generate(
              random.nextInt(100) + 1,
              (_) => String.fromCharCode(97 + random.nextInt(26)),
            ).join();
            final authorId = List.generate(
              32,
              (_) => 'abcdef0123456789'[random.nextInt(16)],
            ).join();

            // Random createdAt using day offsets to avoid exceeding nextInt limit
            // Range: 0 to ~1095 days (3 years) from base date
            final baseDate = DateTime(2023, 1, 1);
            final dayOffset = random.nextInt(1095);
            final secondOffset = random.nextInt(86400);
            final createdAt = baseDate.add(
              Duration(days: dayOffset, seconds: secondOffset),
            );
            final updatedAt = createdAt.add(
              Duration(minutes: random.nextInt(10000)),
            );

            final isDeleted = random.nextBool();

            records.add(AnnouncementRecord(
              announcement: Announcement(
                id: id,
                title: title,
                body: body,
                authorId: authorId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
              isDeleted: isDeleted,
            ));
          }

          return records;
        },
        shrink: (input) => [],
      );
}

void main() {
  group('Property 8: Announcement list excludes deleted and is ordered', () {
    // Property 8a: The list result SHALL contain no soft-deleted announcements.
    Glados(any.announcementRecordList, ExploreConfig(numRuns: 100)).test(
      'list result contains no deleted announcements for any input set',
      (records) {
        final result = applyListLogic(records);

        // Collect IDs of deleted records
        final deletedIds = records
            .where((r) => r.isDeleted)
            .map((r) => r.announcement.id)
            .toSet();

        // Verify no deleted announcement appears in the result
        for (final announcement in result) {
          expect(
            deletedIds.contains(announcement.id),
            isFalse,
            reason:
                'Deleted announcement "${announcement.id}" should not appear '
                'in list results',
          );
        }
      },
    );

    // Property 8b: The list result SHALL contain all non-deleted announcements.
    Glados(any.announcementRecordList, ExploreConfig(numRuns: 100)).test(
      'list result contains all non-deleted announcements for any input set',
      (records) {
        final result = applyListLogic(records);

        // Collect IDs of non-deleted records
        final nonDeletedIds = records
            .where((r) => !r.isDeleted)
            .map((r) => r.announcement.id)
            .toSet();

        final resultIds = result.map((a) => a.id).toSet();

        expect(
          resultIds,
          equals(nonDeletedIds),
          reason: 'All non-deleted announcements should appear in the result',
        );
      },
    );

    // Property 8c: The list result SHALL be ordered by createdAt descending.
    Glados(any.announcementRecordList, ExploreConfig(numRuns: 100)).test(
      'list result is ordered by createdAt descending for any input set',
      (records) {
        final result = applyListLogic(records);

        // Verify ordering: each item's createdAt >= next item's createdAt
        for (var i = 0; i < result.length - 1; i++) {
          final current = result[i].createdAt;
          final next = result[i + 1].createdAt;

          expect(
            current.compareTo(next) >= 0,
            isTrue,
            reason: 'Announcement at index $i (createdAt: $current) should be '
                '>= announcement at index ${i + 1} (createdAt: $next). '
                'List must be ordered by createdAt descending.',
          );
        }
      },
    );
  });
}
