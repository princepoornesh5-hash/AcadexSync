import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/notes/domain/models/note_model.dart';
import 'package:campus_management/features/notes/data/repositories/mock_notes_repository.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/data/repositories/mock_timetable_repository.dart';
import 'package:campus_management/features/attendance/data/repositories/mock_attendance_repository.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/core/firebase/firebase_exceptions.dart';

void main() {
  group('ACADEX Faculty Assignment & Academic Relationship Engine', () {
    late MockAcademicRepository academicRepo;
    late MockTimetableRepository timetableRepo;
    late MockAttendanceRepository attendanceRepo;

    setUp(() {
      academicRepo = MockAcademicRepository();
      timetableRepo = MockTimetableRepository();
      attendanceRepo = MockAttendanceRepository();
    });

    test('1. Create FacultyAssignment with canonical attributes', () async {
      final assignment = FacultyAssignment(
        id: 'fa_engine_1',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec3',
        subjectId: 'sub2',
        facultyId: 'f1',
        facultyName: 'Prof. Alan Turing',
        createdBy: 'hod_cs_1',
        assignedBy: 'hod_cs_1',
        roomId: 'Room 301',
        maxStudents: 60,
        assignmentType: 'Theory & Lab',
        isActive: true,
        createdAt: DateTime.now(),
      );

      await academicRepo.createFacultyAssignment(assignment);

      final assignments = await academicRepo.getFacultyAssignments(facultyId: 'f1');
      expect(assignments.any((a) => a.id == 'fa_engine_1'), isTrue);
      final retrieved = assignments.firstWhere((a) => a.id == 'fa_engine_1');
      expect(retrieved.facultyName, equals('Prof. Alan Turing'));
      expect(retrieved.sectionId, equals('sec3'));
      expect(retrieved.subjectId, equals('sub2'));
    });

    test('2. Duplicate assignment is strictly REJECTED with BackendValidationException', () async {
      final assignment1 = FacultyAssignment(
        id: 'fa_dup_1',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec2',
        subjectId: 'sub3',
        facultyId: 'f1',
        facultyName: 'Prof. Alan Turing',
        isActive: true,
        createdAt: DateTime.now(),
      );

      await academicRepo.createFacultyAssignment(assignment1);

      // Attempt exact duplicate with same faculty, subject, and section
      final duplicateAssignment = FacultyAssignment(
        id: 'fa_dup_2',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec2',
        subjectId: 'sub3',
        facultyId: 'f1',
        facultyName: 'Prof. Alan Turing',
        isActive: true,
        createdAt: DateTime.now(),
      );

      expect(
        () async => await academicRepo.createFacultyAssignment(duplicateAssignment),
        throwsA(isA<BackendValidationException>()),
      );
    });

    test('3. Cross-college assignment is strictly REJECTED with BackendPermissionException', () async {
      final crossCollegeAssignment = FacultyAssignment(
        id: 'fa_cross_col',
        collegeId: 'c2', // Invalid college for faculty f1 (belongs to c1)
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        subjectId: 'sub1',
        facultyId: 'f1',
        facultyName: 'Prof. Alan Turing',
        isActive: true,
        createdAt: DateTime.now(),
      );

      expect(
        () async => await academicRepo.createFacultyAssignment(crossCollegeAssignment),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('4. HOD cannot assign faculty from another department', () async {
      final crossDeptAssignment = FacultyAssignment(
        id: 'fa_cross_dept',
        collegeId: 'c1',
        departmentId: 'd1', // CS department
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        subjectId: 'sub1',
        facultyId: 'f2', // Nikola Tesla belongs to d2 (Mechanical)
        facultyName: 'Prof. Nikola Tesla',
        isActive: true,
        createdAt: DateTime.now(),
      );

      expect(
        () async => await academicRepo.createFacultyAssignment(crossDeptAssignment),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('5. College Admin can assign within own college across departments', () async {
      final meAssignment = FacultyAssignment(
        id: 'fa_me_valid',
        collegeId: 'c1',
        departmentId: 'd2', // ME department
        courseId: 'cr3',
        academicYearId: 'ay1',
        semesterId: 'sem_me1',
        sectionId: 'sec_me1',
        subjectId: 'sub_me1',
        facultyId: 'f2', // Nikola Tesla in d2
        facultyName: 'Prof. Nikola Tesla',
        isActive: true,
        createdAt: DateTime.now(),
      );

      await academicRepo.createFacultyAssignment(meAssignment);

      final meAssignments = await academicRepo.getFacultyAssignments(departmentId: 'd2');
      expect(meAssignments.any((a) => a.id == 'fa_me_valid'), isTrue);
    });

    test('6. Faculty sees only own active assignments', () async {
      final f1Assignments = await academicRepo.getFacultyAssignments(facultyId: 'f1');
      expect(f1Assignments.every((a) => a.facultyId == 'f1'), isTrue);

      final f2Assignments = await academicRepo.getFacultyAssignments(facultyId: 'f2');
      expect(f2Assignments.every((a) => a.facultyId == 'f2'), isTrue);
      expect(f2Assignments.any((a) => a.facultyId == 'f1'), isFalse);
    });

    test('7. Subject filtering retrieves correct assigned faculty records', () async {
      final sub1Assignments = await academicRepo.getFacultyAssignments(subjectId: 'sub1');
      expect(sub1Assignments, isNotEmpty);
      expect(sub1Assignments.every((a) => a.subjectId == 'sub1'), isTrue);
    });

    test('8. Section filtering retrieves correct assigned faculty records', () async {
      final sec1Assignments = await academicRepo.getFacultyAssignments(sectionId: 'sec1');
      expect(sec1Assignments, isNotEmpty);
      expect(sec1Assignments.every((a) => a.sectionId == 'sec1'), isTrue);
    });

    test('9. Faculty filtering isolates assignments for specific faculty', () async {
      final f1List = await academicRepo.getFacultyAssignments(facultyId: 'f1');
      expect(f1List, isNotEmpty);
      expect(f1List.every((a) => a.facultyId == 'f1'), isTrue);
    });

    test('10. Notes module allows authoring only for assigned subjects', () async {
      final facultyUser = UserModel(
        id: 'f1',
        name: 'Prof. Alan Turing',
        email: 'alan@git.edu',
        role: AppRole.faculty,
        collegeId: 'c1',
        departmentId: 'd1',
      );

      final activeAssignments = [
        FacultyAssignment(
          id: 'assign_1',
          collegeId: 'c1',
          departmentId: 'd1',
          courseId: 'cr1',
          academicYearId: 'ay1',
          semesterId: 'sem1',
          sectionId: 'sec1',
          subjectId: 'sub1',
          facultyId: 'f1',
          facultyName: 'Prof. Alan Turing',
          isActive: true,
          createdAt: DateTime.now(),
        ),
      ];

      final notesRepo = MockNotesRepository(
        currentUser: facultyUser,
        assignments: activeAssignments,
      );

      // Allowed Note for sub1
      final validNote = NoteModel(
        id: 'note_valid_ds',
        title: 'Binary Search Trees & Red-Black Trees',
        description: 'Self-balancing search tree invariants',
        resourceType: ResourceType.textNote,
        chapter: 'Trees',
        subjectId: 'sub1',
        sectionId: 'sec1',
        courseId: 'cr1',
        departmentId: 'd1',
        collegeId: 'c1',
        semesterId: 'sem1',
        facultyId: 'f1',
        authorUserId: 'f1',
        status: NoteStatus.published,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await notesRepo.createNote(validNote);
      final notes = await notesRepo.getNotes(collegeId: 'c1', subjectId: 'sub1');
      expect(notes.any((n) => n.id == 'note_valid_ds'), isTrue);

      // Disallowed Note for sub_unassigned
      final invalidNote = validNote.copyWith(id: 'note_invalid', subjectId: 'sub_unassigned');
      expect(
        () async => await notesRepo.createNote(invalidNote),
        throwsA(isA<BackendValidationException>()),
      );
    });

    test('11. Attendance module resolves and utilizes assigned classes', () async {
      final assignedClasses = await attendanceRepo.getAssignedClasses('faculty1', DateTime.now());
      expect(assignedClasses, isNotEmpty);
      expect(assignedClasses.first.subjectName, isNotEmpty);
    });

    test('12. Timetable creation only allows assigned faculty for subject and section', () async {
      // Overlapping slot verification
      final slot1 = TimetableModel(
        id: 'tt_slot_valid',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        academicYearId: 'ay-2023',
        semesterId: 'sem-3',
        sectionId: 'sec-3a',
        subjectId: 'sub-ds',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.wednesday,
        startTime: '10:00',
        endTime: '11:00',
        roomNumber: 'Lab 2',
        building: 'CS Block',
        sessionType: TimetableSessionType.practical,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await timetableRepo.createEntry(slot1);
      final entries = await timetableRepo.getTimetable(collegeId: 'col-1', sectionId: 'sec-3a');
      expect(entries.any((e) => e.id == 'tt_slot_valid'), isTrue);
    });

    test('13. Student receives timetable strictly matching their enrolled section', () async {
      final studentEntries = await timetableRepo.getTimetable(collegeId: 'col-1', sectionId: 'sec-3a');
      expect(studentEntries, isNotEmpty);
      expect(studentEntries.every((e) => e.sectionId == 'sec-3a'), isTrue);
    });

    test('14. Student watches notes strictly published to their enrolled section', () async {
      final notesRepo = MockNotesRepository();
      final stream = notesRepo.watchNotes(
        role: AppRole.student,
        userId: 'stu_1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        semesterId: 'sem-3',
        sectionId: 'sec-3a',
      );

      final studentNotes = await stream.first;
      expect(studentNotes, isNotEmpty);
      expect(studentNotes.every((n) => n.sectionId == 'sec-3a'), isTrue);
      expect(studentNotes.every((n) => n.status == NoteStatus.published), isTrue);
    });

    test('15. Assignment deactivation and removal updates teaching allocation', () async {
      final assignment = FacultyAssignment(
        id: 'fa_temp_test',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec3',
        subjectId: 'sub3',
        facultyId: 'f1',
        facultyName: 'Prof. Alan Turing',
        isActive: true,
        createdAt: DateTime.now(),
      );

      await academicRepo.createFacultyAssignment(assignment);
      var list = await academicRepo.getFacultyAssignments(facultyId: 'f1');
      expect(list.any((a) => a.id == 'fa_temp_test'), isTrue);

      // Deactivate / Remove assignment
      await academicRepo.removeFacultyAssignment('fa_temp_test');
      list = await academicRepo.getFacultyAssignments(facultyId: 'f1');
      expect(list.any((a) => a.id == 'fa_temp_test'), isFalse);
    });
  });
}
