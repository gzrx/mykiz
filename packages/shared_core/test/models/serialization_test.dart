import 'package:shared_core/shared_core.dart';
import 'package:test/test.dart';

void main() {
  group('User JSON serialization', () {
    test('round-trip produces equivalent object', () {
      final user = User(
        id: '550e8400-e29b-41d4-a716-446655440000',
        identifier: 'A123456',
        name: 'Ahmad Bin Ali',
        role: 'student',
        createdAt: DateTime.utc(2024, 1, 15, 10, 30, 0),
      );

      final json = user.toJson();
      final restored = User.fromJson(json);

      expect(restored, equals(user));
    });

    test('toJson produces correct keys and values', () {
      final user = User(
        id: 'abc-123',
        identifier: 'S98765',
        name: 'Dr. Siti',
        role: 'admin',
        createdAt: DateTime.utc(2024, 6, 1, 8, 0, 0),
      );

      final json = user.toJson();

      expect(json['id'], 'abc-123');
      expect(json['identifier'], 'S98765');
      expect(json['name'], 'Dr. Siti');
      expect(json['role'], 'admin');
      expect(json['createdAt'], '2024-06-01T08:00:00.000Z');
    });
  });

  group('Announcement JSON serialization', () {
    test('round-trip produces equivalent object', () {
      final announcement = Announcement(
        id: '660e8400-e29b-41d4-a716-446655440001',
        title: 'Water Disruption Notice',
        body: 'Water supply will be disrupted on 20 Jan 2024 from 9am to 5pm.',
        authorId: 'admin-uuid-001',
        createdAt: DateTime.utc(2024, 1, 18, 14, 0, 0),
        updatedAt: DateTime.utc(2024, 1, 18, 14, 0, 0),
      );

      final json = announcement.toJson();
      final restored = Announcement.fromJson(json);

      expect(restored, equals(announcement));
    });

    test('toJson produces correct keys and values', () {
      final announcement = Announcement(
        id: 'ann-id',
        title: 'Test Title',
        body: 'Test Body',
        authorId: 'author-1',
        createdAt: DateTime.utc(2024, 3, 10, 12, 0, 0),
        updatedAt: DateTime.utc(2024, 3, 11, 9, 30, 0),
      );

      final json = announcement.toJson();

      expect(json['id'], 'ann-id');
      expect(json['title'], 'Test Title');
      expect(json['body'], 'Test Body');
      expect(json['authorId'], 'author-1');
      expect(json['createdAt'], '2024-03-10T12:00:00.000Z');
      expect(json['updatedAt'], '2024-03-11T09:30:00.000Z');
    });
  });

  group('Complaint JSON serialization', () {
    test('round-trip produces equivalent object with imageKey', () {
      final complaint = Complaint(
        id: '770e8400-e29b-41d4-a716-446655440002',
        studentId: 'student-uuid-001',
        description: 'Leaking pipe in bathroom',
        location: 'Block A, Room 301',
        imageKey: 'complaints/img-001.jpg',
        status: 'submitted',
        createdAt: DateTime.utc(2024, 2, 5, 16, 45, 0),
        updatedAt: DateTime.utc(2024, 2, 5, 16, 45, 0),
      );

      final json = complaint.toJson();
      final restored = Complaint.fromJson(json);

      expect(restored, equals(complaint));
    });

    test('round-trip produces equivalent object without imageKey', () {
      final complaint = Complaint(
        id: '880e8400-e29b-41d4-a716-446655440003',
        studentId: 'student-uuid-002',
        description: 'Broken window latch',
        location: 'Block B, Room 105',
        imageKey: null,
        status: 'in_progress',
        createdAt: DateTime.utc(2024, 2, 10, 9, 0, 0),
        updatedAt: DateTime.utc(2024, 2, 12, 11, 30, 0),
      );

      final json = complaint.toJson();
      final restored = Complaint.fromJson(json);

      expect(restored, equals(complaint));
    });

    test('toJson produces correct keys and values', () {
      final complaint = Complaint(
        id: 'cmp-id',
        studentId: 'stu-1',
        description: 'Broken light',
        location: 'Lobby',
        imageKey: 'img/key.png',
        status: 'resolved',
        createdAt: DateTime.utc(2024, 4, 1, 8, 0, 0),
        updatedAt: DateTime.utc(2024, 4, 3, 10, 0, 0),
      );

      final json = complaint.toJson();

      expect(json['id'], 'cmp-id');
      expect(json['studentId'], 'stu-1');
      expect(json['description'], 'Broken light');
      expect(json['location'], 'Lobby');
      expect(json['imageKey'], 'img/key.png');
      expect(json['status'], 'resolved');
      expect(json['createdAt'], '2024-04-01T08:00:00.000Z');
      expect(json['updatedAt'], '2024-04-03T10:00:00.000Z');
    });

    test('null imageKey is excluded or null in JSON', () {
      final complaint = Complaint(
        id: 'cmp-null',
        studentId: 'stu-2',
        description: 'No image complaint',
        location: 'Block C',
        imageKey: null,
        status: 'submitted',
        createdAt: DateTime.utc(2024, 5, 1),
        updatedAt: DateTime.utc(2024, 5, 1),
      );

      final json = complaint.toJson();

      // imageKey should either be absent or null in the JSON map
      expect(json['imageKey'], isNull);
    });
  });

  group('ComplaintStatus enum serialization', () {
    test('submitted serializes to "submitted"', () {
      expect(ComplaintStatus.submitted.name, 'submitted');
    });

    test('inProgress serializes to "inProgress"', () {
      expect(ComplaintStatus.inProgress.name, 'inProgress');
    });

    test('resolved serializes to "resolved"', () {
      expect(ComplaintStatus.resolved.name, 'resolved');
    });

    test('all enum values are accounted for', () {
      expect(ComplaintStatus.values.length, 3);
      expect(
        ComplaintStatus.values.map((e) => e.name).toList(),
        ['submitted', 'inProgress', 'resolved'],
      );
    });
  });
}
