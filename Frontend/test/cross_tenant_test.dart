import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/notes/domain/models/note_model.dart';
import 'package:campus_management/features/notes/data/repositories/mock_notes_repository.dart';

void main() {
  group('Cross-Tenant Data Security Boundaries', () {
    test('Student A cannot access Notes from Section B', () async {
      final repo = MockNotesRepository();
      
      // Request stream for Section 3A
      final stream3A = repo.watchNotes(
        role: AppRole.student,
        userId: 'student-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        semesterId: 'sem-3',
        sectionId: 'sec-3a', // Valid section
      );

      final notes3A = await stream3A.first;
      
      // Should find at least the mocked public note for 3A
      expect(notes3A.where((n) => n.title.contains('Introduction to Operating Systems')).isNotEmpty, isTrue);
      // Ensure no draft notes are leaked to students
      expect(notes3A.where((n) => n.status != NoteStatus.published).isEmpty, isTrue);

      // Request stream for Section 3B (Another section)
      final stream3B = repo.watchNotes(
        role: AppRole.student,
        userId: 'student-2',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        semesterId: 'sem-3',
        sectionId: 'sec-3b', // Different section
      );

      final notes3B = await stream3B.first;
      
      // Should NOT find 3A's notes
      expect(notes3B.where((n) => n.sectionId == 'sec-3a').isEmpty, isTrue);
    });

    test('HOD A cannot access Notes from Department B', () async {
      final repo = MockNotesRepository();
      
      // HOD in CSE
      final cseStream = repo.watchNotes(
        role: AppRole.hod,
        userId: 'hod-1',
        departmentId: 'dept-cse',
      );

      final cseNotes = await cseStream.first;
      expect(cseNotes.isNotEmpty, isTrue);
      expect(cseNotes.every((n) => n.departmentId == 'dept-cse'), isTrue);

      // HOD in Mechanical
      final mechStream = repo.watchNotes(
        role: AppRole.hod,
        userId: 'hod-2',
        departmentId: 'dept-mech',
      );

      final mechNotes = await mechStream.first;
      // Should NOT find CSE notes
      expect(mechNotes.where((n) => n.departmentId == 'dept-cse').isEmpty, isTrue);
    });

    test('Notes Publishing Flow: Drafts are hidden from Students', () async {
      final repo = MockNotesRepository();
      
      // Request stream for Faculty (Author)
      final facultyStream = repo.watchNotes(
        role: AppRole.faculty,
        userId: 'user-fac-1',
      );

      final facultyNotes = await facultyStream.first;
      
      // Faculty should see the draft note
      expect(facultyNotes.where((n) => n.title.contains('DBMS Normalization') && n.status == NoteStatus.draft).isNotEmpty, isTrue);

      // Request stream for Student
      final studentStream = repo.watchNotes(
        role: AppRole.student,
        userId: 'student-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        semesterId: 'sem-3',
        sectionId: 'sec-3a',
      );

      final studentNotes = await studentStream.first;
      
      // Student must NOT see the draft note
      expect(studentNotes.where((n) => n.title.contains('DBMS Normalization')).isEmpty, isTrue);
    });
  });
}
