import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_request_model.dart';
import 'package:campus_management/features/certificates/data/repositories/mock_certificate_request_repository.dart';
import 'package:campus_management/features/notes/domain/models/note_model.dart';
import 'package:campus_management/features/notes/data/repositories/mock_notes_repository.dart';
import 'package:campus_management/features/notifications/domain/models/notification_models.dart';
import 'package:campus_management/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:campus_management/features/settings/domain/models/settings_models.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/data/repositories/mock_timetable_repository.dart';

void main() {
  group('Realtime Sync Module Tests', () {
    late UserModel mockStudent;
    late UserModel mockFaculty;

    setUp(() {
      mockStudent = UserModel(
        id: 'user_stu_1',
        name: 'Student 1',
        email: 'stu1@example.com',
        role: AppRole.student,
        collegeId: 'col-1',
        departmentId: 'dept-cse',
      );
      
      mockFaculty = UserModel(
        id: 'user_fac_1',
        name: 'Faculty 1',
        email: 'fac1@example.com',
        role: AppRole.faculty,
        collegeId: 'col-1',
        departmentId: 'dept-cse',
      );
    });

    test('Notes Publication Stream filters drafts and emits updates', () async {
      final repo = MockNotesRepository();
      
      // We will listen to the stream and expect multiple states over time
      final stream = repo.watchNotes(
        role: AppRole.student,
        userId: mockStudent.id,
        collegeId: mockStudent.collegeId,
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        semesterId: 'sem-3',
        sectionId: 'sec-a',
      );

      final List<List<NoteModel>> states = [];
      final sub = stream.listen((notes) {
        states.add(notes);
      });

      // Allow initial data to emit
      await Future.delayed(const Duration(milliseconds: 500));

      // There should be some initial published notes from mock data
      expect(states.isNotEmpty, isTrue);
      int initialCount = states.last.length;

      // Add a draft note
      await repo.createNote(
        NoteModel(
          id: 'draft-1',
          title: 'Draft Note',
          description: 'A draft',
          resourceType: ResourceType.textNote,
          collegeId: 'col-1',
          departmentId: 'dept-cse',
          courseId: 'crs-cse',
          semesterId: 'sem-3',
          sectionId: 'sec-a',
          subjectId: 'sub-1',
          facultyId: mockFaculty.id,
          authorUserId: mockFaculty.id,
          status: NoteStatus.draft,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
      );

      await Future.delayed(const Duration(milliseconds: 500));
      // Student stream should NOT include draft note
      expect(states.last.length, equals(initialCount));

      // Update draft to published
      final draftDoc = (await repo.getNotes(collegeId: 'col-1')).firstWhere((n) => n.title == 'Draft Note');
      await repo.updateNote(draftDoc.copyWith(status: NoteStatus.published));

      await Future.delayed(const Duration(milliseconds: 500));
      // Student stream SHOULD now include the newly published note
      expect(states.last.length, equals(initialCount + 1));
      expect(states.last.any((n) => n.id == draftDoc.id && n.status == NoteStatus.published), isTrue);

      await sub.cancel();
    });

    test('Certificate Status Stream emits updates upon admin approval', () async {
      final repo = MockCertificateRequestRepository();
      
      final stream = repo.watchStudentRequests('student-user-id');
      final List<List<CertificateRequest>> states = [];
      final sub = stream.listen((reqs) => states.add(reqs));

      await Future.delayed(const Duration(milliseconds: 500));
      
      // The mock repo has a pending request "req-1" for this student
      final req1Initial = states.last.firstWhere((r) => r.id == 'req-1');
      expect(req1Initial.status, equals(CertificateRequestStatus.pending));

      // Admin approves the certificate
      await repo.updateRequestStatus(
        requestId: 'req-1',
        status: CertificateRequestStatus.approved,
        reviewedBy: 'admin-user-id'
      );

      await Future.delayed(const Duration(milliseconds: 500));
      
      final req1Updated = states.last.firstWhere((r) => r.id == 'req-1');
      expect(req1Updated.status, equals(CertificateRequestStatus.approved));

      await sub.cancel();
    });

    test('Timetable Stream receives updates for the college', () async {
      final repo = MockTimetableRepository();
      
      final stream = repo.watchTimetable(role: AppRole.collegeAdmin, userId: 'admin', collegeId: 'col-1');
      final List<List<TimetableModel>> states = [];
      final sub = stream.listen((tt) => states.add(tt));

      await Future.delayed(const Duration(milliseconds: 500));
      final initialCount = states.last.length;

      // Add a new timetable entry
      final newEntry = TimetableModel(
        id: 'tt-new',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        academicYearId: 'ay-2023',
        semesterId: 'sem-3',
        sectionId: 'sec-a',
        subjectId: 'sub-new',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.monday,
        startTime: '11:00',
        endTime: '12:00',
        roomNumber: '101',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.createEntry(newEntry);

      await Future.delayed(const Duration(milliseconds: 500));
      expect(states.last.length, equals(initialCount + 1));
      
      await sub.cancel();
    });

    test('Notification Stream filters preferences and tracks unread count', () async {
      final repo = MockNotificationRepository();
      
      final stream = repo.watchNotifications(mockStudent, NotificationPreferences.defaults());
      final List<List<NotificationModel>> states = [];
      final sub = stream.listen((n) => states.add(n));

      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mark all as read initially to test unread count
      for (final n in states.last) {
        if (!n.isRead) await repo.markAsRead(n.id, mockStudent.id);
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      expect(states.last.where((n) => !n.isRead).length, equals(0));

      // Create new notification
      await repo.createPersonalNotification(
        NotificationModel(
          id: '',
          title: 'New Grade',
          message: 'Your grade is updated',
          category: NotificationCategory.academic,
          priority: NotificationPriority.high,
          audienceType: NotificationAudienceType.personal,
          recipientUserId: mockStudent.id,
          timestamp: DateTime.now(),
        )
      );

      await Future.delayed(const Duration(milliseconds: 500));
      expect(states.last.where((n) => !n.isRead).length, equals(1));
      
      await sub.cancel();
    });
  });
}
