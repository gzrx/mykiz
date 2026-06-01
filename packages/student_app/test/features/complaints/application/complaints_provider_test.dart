import 'dart:typed_data';

import 'package:api_client/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_core/shared_core.dart';
import 'package:student_app/features/complaints/application/complaints_provider.dart';

class MockMyKizApiClient extends Mock implements MyKizApiClient {}

void main() {
  late MockMyKizApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockMyKizApiClient();
  });

  final sampleComplaint = Complaint(
    id: 'complaint-1',
    studentId: 'student-1',
    description: 'Broken window in room',
    location: 'Block A, Level 2, Room 201',
    status: 'submitted',
    createdAt: DateTime(2024, 3, 1),
    updatedAt: DateTime(2024, 3, 1),
  );

  final sampleComplaintWithImage = Complaint(
    id: 'complaint-2',
    studentId: 'student-1',
    description: 'Leaking pipe',
    location: 'Block B, Level 1, Bathroom',
    imageKey: 'images/complaint-2.jpg',
    status: 'in_progress',
    createdAt: DateTime(2024, 3, 2),
    updatedAt: DateTime(2024, 3, 3),
  );

  group('ComplaintsListNotifier', () {
    late ComplaintsListNotifier notifier;

    setUp(() {
      notifier = ComplaintsListNotifier(mockApiClient);
    });

    test('initial state has empty complaints and is not loading', () {
      expect(notifier.state.complaints, isEmpty);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.meta, isNull);
    });

    test('fetchComplaints sets loading then populates complaints on success',
        () async {
      final meta = PaginationMeta(
        currentPage: 1,
        limit: 20,
        totalItems: 2,
        totalPages: 1,
      );

      when(() => mockApiClient.listComplaints(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => PaginatedResponse(
            items: [sampleComplaint, sampleComplaintWithImage],
            meta: meta,
          ));

      final states = <ComplaintsListState>[];
      notifier.addListener((state) => states.add(state));

      await notifier.fetchComplaints();

      // Should have gone through loading state
      expect(states.any((s) => s.isLoading), isTrue);
      expect(notifier.state.complaints.length, 2);
      expect(notifier.state.complaints[0].id, 'complaint-1');
      expect(notifier.state.complaints[1].id, 'complaint-2');
      expect(notifier.state.meta, meta);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, isNull);
    });

    test('fetchComplaints sets error message on API exception', () async {
      when(() => mockApiClient.listComplaints(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenThrow(const ServerException(
        code: 'INTERNAL_ERROR',
        message: 'Server error',
      ));

      await notifier.fetchComplaints();

      expect(notifier.state.complaints, isEmpty);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, 'Server error');
    });

    test('fetchComplaints sets generic error on unexpected exception',
        () async {
      when(() => mockApiClient.listComplaints(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenThrow(Exception('network failure'));

      await notifier.fetchComplaints();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, 'An unexpected error occurred.');
    });

    test('refresh calls fetchComplaints with default params', () async {
      when(() => mockApiClient.listComplaints(
            page: 1,
            limit: 20,
          )).thenAnswer((_) async => PaginatedResponse(
            items: [sampleComplaint],
            meta: const PaginationMeta(
              currentPage: 1,
              limit: 20,
              totalItems: 1,
              totalPages: 1,
            ),
          ));

      await notifier.refresh();

      verify(() => mockApiClient.listComplaints(page: 1, limit: 20)).called(1);
      expect(notifier.state.complaints.length, 1);
    });
  });

  group('ComplaintSubmissionNotifier', () {
    late ComplaintSubmissionNotifier notifier;

    setUp(() {
      notifier = ComplaintSubmissionNotifier(mockApiClient);
    });

    test('initial state is not submitting and not success', () {
      expect(notifier.state.isSubmitting, isFalse);
      expect(notifier.state.isSuccess, isFalse);
      expect(notifier.state.errorMessage, isNull);
    });

    test('submit sets isSubmitting then isSuccess on success', () async {
      when(() => mockApiClient.submitComplaint(
            description: any(named: 'description'),
            location: any(named: 'location'),
            imageBytes: any(named: 'imageBytes'),
            imageName: any(named: 'imageName'),
          )).thenAnswer((_) async => sampleComplaint);

      final states = <ComplaintSubmissionState>[];
      notifier.addListener((state) => states.add(state));

      await notifier.submit(
        description: 'Broken window',
        location: 'Block A, Room 201',
      );

      expect(states.any((s) => s.isSubmitting), isTrue);
      expect(notifier.state.isSuccess, isTrue);
      expect(notifier.state.isSubmitting, isFalse);
      expect(notifier.state.errorMessage, isNull);
    });

    test('submit with image passes bytes and name to API', () async {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);

      when(() => mockApiClient.submitComplaint(
            description: any(named: 'description'),
            location: any(named: 'location'),
            imageBytes: any(named: 'imageBytes'),
            imageName: any(named: 'imageName'),
          )).thenAnswer((_) async => sampleComplaintWithImage);

      await notifier.submit(
        description: 'Leaking pipe',
        location: 'Block B, Bathroom',
        imageBytes: imageBytes,
        imageName: 'photo.jpg',
      );

      verify(() => mockApiClient.submitComplaint(
            description: 'Leaking pipe',
            location: 'Block B, Bathroom',
            imageBytes: imageBytes,
            imageName: 'photo.jpg',
          )).called(1);
      expect(notifier.state.isSuccess, isTrue);
    });

    test('submit sets error message on API exception', () async {
      when(() => mockApiClient.submitComplaint(
            description: any(named: 'description'),
            location: any(named: 'location'),
            imageBytes: any(named: 'imageBytes'),
            imageName: any(named: 'imageName'),
          )).thenThrow(const ValidationException(
        code: 'VALIDATION_ERROR',
        message: 'Description is required',
      ));

      await notifier.submit(
        description: '',
        location: 'Block A',
      );

      expect(notifier.state.isSubmitting, isFalse);
      expect(notifier.state.isSuccess, isFalse);
      expect(notifier.state.errorMessage, 'Description is required');
    });

    test('reset clears state', () async {
      when(() => mockApiClient.submitComplaint(
            description: any(named: 'description'),
            location: any(named: 'location'),
            imageBytes: any(named: 'imageBytes'),
            imageName: any(named: 'imageName'),
          )).thenAnswer((_) async => sampleComplaint);

      await notifier.submit(
        description: 'Test',
        location: 'Test',
      );
      expect(notifier.state.isSuccess, isTrue);

      notifier.reset();

      expect(notifier.state.isSubmitting, isFalse);
      expect(notifier.state.isSuccess, isFalse);
      expect(notifier.state.errorMessage, isNull);
    });
  });

  group('ComplaintDetailNotifier', () {
    late ComplaintDetailNotifier notifier;

    setUp(() {
      notifier = ComplaintDetailNotifier(mockApiClient);
    });

    test('initial state has no complaint and is not loading', () {
      expect(notifier.state.complaint, isNull);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, isNull);
    });

    test('fetchComplaint sets loading then populates complaint on success',
        () async {
      when(() => mockApiClient.getComplaint(any()))
          .thenAnswer((_) async => sampleComplaintWithImage);

      final states = <ComplaintDetailState>[];
      notifier.addListener((state) => states.add(state));

      await notifier.fetchComplaint('complaint-2');

      expect(states.any((s) => s.isLoading), isTrue);
      expect(notifier.state.complaint, sampleComplaintWithImage);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, isNull);

      verify(() => mockApiClient.getComplaint('complaint-2')).called(1);
    });

    test('fetchComplaint sets error on not found', () async {
      when(() => mockApiClient.getComplaint(any())).thenThrow(
        const NotFoundException(
          code: 'NOT_FOUND',
          message: 'Complaint not found',
        ),
      );

      await notifier.fetchComplaint('nonexistent');

      expect(notifier.state.complaint, isNull);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, 'Complaint not found');
    });

    test('fetchComplaint sets generic error on unexpected exception', () async {
      when(() => mockApiClient.getComplaint(any()))
          .thenThrow(Exception('network error'));

      await notifier.fetchComplaint('complaint-1');

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, 'An unexpected error occurred.');
    });
  });
}
