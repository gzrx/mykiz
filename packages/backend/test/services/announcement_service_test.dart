import 'package:backend/services/announcement_service.dart';
import 'package:test/test.dart';

void main() {
  group('AnnouncementService validation', () {
    final service = AnnouncementService();

    group('title validation', () {
      test('rejects empty title', () async {
        expect(
          () => service.create(
            title: '',
            body: 'Valid body content',
            authorId: 'author-uuid',
          ),
          throwsA(
            isA<ValidationException>()
                .having((e) => e.code, 'code', 'VALIDATION_ERROR')
                .having(
                  (e) => e.message,
                  'message',
                  contains('Title'),
                ),
          ),
        );
      });

      test('rejects title exceeding 200 characters', () async {
        final longTitle = 'a' * 201;
        expect(
          () => service.create(
            title: longTitle,
            body: 'Valid body content',
            authorId: 'author-uuid',
          ),
          throwsA(
            isA<ValidationException>()
                .having((e) => e.code, 'code', 'VALIDATION_ERROR'),
          ),
        );
      });

      test('accepts title at exactly 200 characters', () async {
        // This will throw NotFoundException because there's no DB,
        // but it should NOT throw ValidationException
        final title200 = 'a' * 200;
        try {
          await service.create(
            title: title200,
            body: 'Valid body',
            authorId: 'author-uuid',
          );
        } on ValidationException {
          fail('Should not throw ValidationException for 200-char title');
        } catch (_) {
          // Expected: DB connection error since no database is running
        }
      });

      test('accepts title at exactly 1 character', () async {
        try {
          await service.create(
            title: 'A',
            body: 'Valid body',
            authorId: 'author-uuid',
          );
        } on ValidationException {
          fail('Should not throw ValidationException for 1-char title');
        } catch (_) {
          // Expected: DB connection error
        }
      });
    });

    group('body validation', () {
      test('rejects empty body', () async {
        expect(
          () => service.create(
            title: 'Valid title',
            body: '',
            authorId: 'author-uuid',
          ),
          throwsA(
            isA<ValidationException>()
                .having((e) => e.code, 'code', 'VALIDATION_ERROR')
                .having(
                  (e) => e.message,
                  'message',
                  contains('Body'),
                ),
          ),
        );
      });

      test('rejects body exceeding 5000 characters', () async {
        final longBody = 'b' * 5001;
        expect(
          () => service.create(
            title: 'Valid title',
            body: longBody,
            authorId: 'author-uuid',
          ),
          throwsA(
            isA<ValidationException>()
                .having((e) => e.code, 'code', 'VALIDATION_ERROR'),
          ),
        );
      });

      test('accepts body at exactly 5000 characters', () async {
        final body5000 = 'b' * 5000;
        try {
          await service.create(
            title: 'Valid title',
            body: body5000,
            authorId: 'author-uuid',
          );
        } on ValidationException {
          fail('Should not throw ValidationException for 5000-char body');
        } catch (_) {
          // Expected: DB connection error
        }
      });
    });

    group('update validation', () {
      test('rejects update with no fields provided', () async {
        expect(
          () => service.update('some-id'),
          throwsA(
            isA<ValidationException>()
                .having((e) => e.code, 'code', 'VALIDATION_ERROR')
                .having(
                  (e) => e.message,
                  'message',
                  contains('At least one field'),
                ),
          ),
        );
      });

      test('rejects update with empty title', () async {
        expect(
          () => service.update('some-id', title: ''),
          throwsA(
            isA<ValidationException>()
                .having((e) => e.code, 'code', 'VALIDATION_ERROR'),
          ),
        );
      });

      test('rejects update with title exceeding 200 characters', () async {
        expect(
          () => service.update('some-id', title: 'a' * 201),
          throwsA(
            isA<ValidationException>()
                .having((e) => e.code, 'code', 'VALIDATION_ERROR'),
          ),
        );
      });

      test('rejects update with empty body', () async {
        expect(
          () => service.update('some-id', body: ''),
          throwsA(
            isA<ValidationException>()
                .having((e) => e.code, 'code', 'VALIDATION_ERROR'),
          ),
        );
      });

      test('rejects update with body exceeding 5000 characters', () async {
        expect(
          () => service.update('some-id', body: 'b' * 5001),
          throwsA(
            isA<ValidationException>()
                .having((e) => e.code, 'code', 'VALIDATION_ERROR'),
          ),
        );
      });

      test('accepts update with only title provided', () async {
        try {
          await service.update('some-id', title: 'New title');
        } on ValidationException {
          fail('Should not throw ValidationException for valid title-only update');
        } catch (_) {
          // Expected: DB connection error or NotFoundException
        }
      });

      test('accepts update with only body provided', () async {
        try {
          await service.update('some-id', body: 'New body');
        } on ValidationException {
          fail('Should not throw ValidationException for valid body-only update');
        } catch (_) {
          // Expected: DB connection error or NotFoundException
        }
      });
    });
  });
}
