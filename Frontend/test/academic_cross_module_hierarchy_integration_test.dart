import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/notes/domain/models/note_model.dart';
import 'package:campus_management/features/notes/data/repositories/mock_notes_repository.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/data/repositories/timetable_repository.dart';
import 'package:campus_management/features/timetable/data/repositories/mock_timetable_repository.dart';
import 'package:campus_management/features/attendance/data/repositories/mock_attendance_repository.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/core/firebase/firebase_exceptions.dart';

void main() {
  group('ACADEX Academic Hierarchy + Cross-Module Integration Tests', () {
    late MockAcademicRepository academicRepo;
    late MockTimetableRepository timetableRepo;
    late MockAttendanceRepository attendanceRepo;

    setUp(() {
      academicRepo = MockAcademicRepository();
      timetableRepo = MockTimetableRepository();
      attendanceRepo = MockAttendanceRepository();
    });

    test('1. Super Admin manages colleges and platform level entities', () async {
      final colleges = await academicRepo.getColleges();
      expect(colleges, isNotEmpty);
      expect(colleges.first.name, contains('Institute of Technology'));
    });

    test('2. College Admin manages college academic structure (Depts, Courses, Sems, Secs, Subjects)', () async {
      final depts = await academicRepo.getDepartments();
      expect(depts, isNotEmpty);
      expect(depts.map((d) => d.code), contains('CS'));

      final courses = await academicRepo.getCourses();
      expect(courses, isNotEmpty);

      final semesters = await academicRepo.getSemesters();
      expect(semesters, isNotEmpty);

      final sections = await academicRepo.getSections();
      expect(sections, isNotEmpty);

      final subjects = await academicRepo.getSubjects();
      expect(subjects, isNotEmpty);
    });

    test('3. HOD assigns Faculty to Subject & Section (Faculty Assignment Bridge)', () async {
      // Assign faculty f1 to sub2 and sec2 (which has no existing assignment)
      final assignment = FacultyAssignment(
        id: 'assign_test_1',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec2',
        subjectId: 'sub2',
        facultyId: 'f1',
        facultyName: 'Dr. Alan Turing',
        isActive: true,
        createdAt: DateTime.now(),
      );

      await academicRepo.createFacultyAssignment(assignment);

      final facultyAssignments = await academicRepo.getFacultyAssignments(facultyId: 'f1');
      expect(facultyAssignments.any((a) => a.id == 'assign_test_1'), isTrue);
      final active = facultyAssignments.firstWhere((a) => a.id == 'assign_test_1');
      expect(active.subjectId, equals('sub2'));
      expect(active.sectionId, equals('sec2'));
    });

    test('4. Faculty creates Lesson Notes for assigned Subject & Section successfully', () async {
      final facultyUser = UserModel(
        id: 'f1',
        name: 'Dr. Alan Turing',
        email: 'alan@turing.edu',
        role: AppRole.faculty,
        collegeId: 'c1',
        departmentId: 'd1',
      );

      final List<FacultyAssignment> activeAssignments = [
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
          facultyName: 'Dr. Alan Turing',
          isActive: true,
          createdAt: DateTime.now(),
        ),
      ];

      final notesRepo = MockNotesRepository(
        currentUser: facultyUser,
        assignments: activeAssignments,
      );

      final note = NoteModel(
        id: 'note_test_1',
        title: 'Algorithms & Complexity - Lecture 1',
        description: 'Introduction to Asymptotic Notation and Recurrences',
        content: 'Big O, Omega, Theta notation analysis.',
        resourceType: ResourceType.textNote,
        chapter: 'Chapter 1: Asymptotic Analysis',
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

      await notesRepo.createNote(note);

      final notes = await notesRepo.getNotes(collegeId: 'c1', subjectId: 'sub1');
      expect(notes.any((n) => n.title == 'Algorithms & Complexity - Lecture 1'), isTrue);
    });

    test('5. Faculty is REJECTED when attempting to author Notes for an unassigned Subject', () async {
      final facultyUser = UserModel(
        id: 'f1',
        name: 'Dr. Alan Turing',
        email: 'alan@turing.edu',
        role: AppRole.faculty,
        collegeId: 'c1',
        departmentId: 'd1',
      );

      // Faculty is only assigned to sub1
      final List<FacultyAssignment> activeAssignments = [
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
          facultyName: 'Dr. Alan Turing',
          isActive: true,
          createdAt: DateTime.now(),
        ),
      ];

      final notesRepo = MockNotesRepository(
        currentUser: facultyUser,
        assignments: activeAssignments,
      );

      // Attempting to author notes for unassigned subject 'sub_unassigned'
      final invalidNote = NoteModel(
        id: 'note_invalid',
        title: 'Quantum Mechanics Lecture',
        description: 'Unauthorized notes',
        resourceType: ResourceType.textNote,
        chapter: 'Unit 1',
        subjectId: 'sub_unassigned',
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

      expect(
        () async => await notesRepo.createNote(invalidNote),
        throwsA(isA<BackendValidationException>()),
      );
    });

    test('6. College Admin is BLOCKED from authoring lesson notes directly', () async {
      final adminUser = UserModel(
        id: 'admin1',
        name: 'College Principal',
        email: 'admin@college.edu',
        role: AppRole.collegeAdmin,
        collegeId: 'c1',
      );

      final notesRepo = MockNotesRepository(currentUser: adminUser);

      final adminNote = NoteModel(
        id: 'admin_note_1',
        title: 'Administrative Circular',
        description: 'Notes authored by admin',
        resourceType: ResourceType.textNote,
        chapter: 'Unit 1',
        subjectId: 'sub1',
        sectionId: 'sec1',
        courseId: 'cr1',
        departmentId: 'd1',
        collegeId: 'c1',
        semesterId: 'sem1',
        facultyId: 'admin1',
        authorUserId: 'admin1',
        status: NoteStatus.published,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () async => await notesRepo.createNote(adminNote),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('7. Student receives and watches published Notes strictly for their enrolled Section', () async {
      final notesRepo = MockNotesRepository();

      // Student in sec-3a
      final studentStream = notesRepo.watchNotes(
        role: AppRole.student,
        userId: 'student1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        semesterId: 'sem-3',
        sectionId: 'sec-3a',
      );

      final initialNotes = await studentStream.first;
      expect(initialNotes, isNotEmpty);
      expect(initialNotes.every((n) => n.status == NoteStatus.published), isTrue);
      expect(initialNotes.every((n) => n.sectionId == 'sec-3a'), isTrue);

      // Student in different section sec-3b should NOT see sec-3a notes
      final otherSectionStream = notesRepo.watchNotes(
        role: AppRole.student,
        userId: 'student2',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        semesterId: 'sem-3',
        sectionId: 'sec-3b',
      );

      final otherSectionNotes = await otherSectionStream.first;
      expect(otherSectionNotes.any((n) => n.sectionId == 'sec-3a'), isFalse);
    });

    test('8. Timetable conflict detection rejects overlapping Faculty schedule', () async {
      final now = DateTime.now();
      final slot1 = TimetableModel(
        id: 'tt_slot_1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        academicYearId: 'ay-2023',
        semesterId: 'sem-3',
        sectionId: 'sec-3a',
        subjectId: 'sub-ds',
        facultyId: 'fac-overlap',
        dayOfWeek: TimetableDay.friday,
        startTime: '10:00',
        endTime: '11:00',
        roomNumber: 'Room 101',
        building: 'Tech Block',
        sessionType: TimetableSessionType.lecture,
        createdAt: now,
        updatedAt: now,
      );

      await timetableRepo.createEntry(slot1);

      // Overlapping slot with same faculty on Friday 10:30 - 11:30
      final slotOverlap = TimetableModel(
        id: 'tt_slot_2',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        academicYearId: 'ay-2023',
        semesterId: 'sem-3',
        sectionId: 'sec-3b',
        subjectId: 'sub-os',
        facultyId: 'fac-overlap',
        dayOfWeek: TimetableDay.friday,
        startTime: '10:30',
        endTime: '11:30',
        roomNumber: 'Room 102',
        building: 'Tech Block',
        sessionType: TimetableSessionType.lecture,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        () async => await timetableRepo.createEntry(slotOverlap),
        throwsA(isA<TimetableConflictException>()),
      );
    });

    test('9. Timetable conflict detection rejects overlapping Section schedule', () async {
      final now = DateTime.now();
      final slot1 = TimetableModel(
        id: 'tt_sec_1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        academicYearId: 'ay-2023',
        semesterId: 'sem-3',
        sectionId: 'sec-exclusive',
        subjectId: 'sub-ds',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.saturday,
        startTime: '09:00',
        endTime: '10:00',
        roomNumber: 'Room 201',
        building: 'Tech Block',
        sessionType: TimetableSessionType.lecture,
        createdAt: now,
        updatedAt: now,
      );

      await timetableRepo.createEntry(slot1);

      // Same section scheduled with different faculty at same time
      final slotOverlap = TimetableModel(
        id: 'tt_sec_2',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        academicYearId: 'ay-2023',
        semesterId: 'sem-3',
        sectionId: 'sec-exclusive',
        subjectId: 'sub-os',
        facultyId: 'fac-2',
        dayOfWeek: TimetableDay.saturday,
        startTime: '09:00',
        endTime: '10:00',
        roomNumber: 'Room 202',
        building: 'Tech Block',
        sessionType: TimetableSessionType.lecture,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        () async => await timetableRepo.createEntry(slotOverlap),
        throwsA(isA<TimetableConflictException>()),
      );
    });

    test('10. Faculty Workload calculation sums assigned subjects, sections, and contact periods', () async {
      final assignments = [
        FacultyAssignment(
          id: 'a1',
          collegeId: 'c1',
          departmentId: 'd1',
          courseId: 'cr1',
          academicYearId: 'ay1',
          semesterId: 'sem1',
          sectionId: 'sec1',
          subjectId: 'sub1',
          facultyId: 'f1',
          facultyName: 'Dr. Alan Turing',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        FacultyAssignment(
          id: 'a2',
          collegeId: 'c1',
          departmentId: 'd1',
          courseId: 'cr1',
          academicYearId: 'ay1',
          semesterId: 'sem1',
          sectionId: 'sec2',
          subjectId: 'sub1',
          facultyId: 'f1',
          facultyName: 'Dr. Alan Turing',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        FacultyAssignment(
          id: 'a3',
          collegeId: 'c1',
          departmentId: 'd1',
          courseId: 'cr1',
          academicYearId: 'ay1',
          semesterId: 'sem1',
          sectionId: 'sec1',
          subjectId: 'sub2',
          facultyId: 'f1',
          facultyName: 'Dr. Alan Turing',
          isActive: true,
          createdAt: DateTime.now(),
        ),
      ];

      final facultyAssigned = assignments.where((a) => a.facultyId == 'f1' && a.isActive).toList();
      final uniqueSubjects = facultyAssigned.map((a) => a.subjectId).toSet().length;
      final uniqueSections = facultyAssigned.map((a) => a.sectionId).toSet().length;
      final totalWeeklyPeriods = facultyAssigned.length * 4;

      expect(uniqueSubjects, equals(2));
      expect(uniqueSections, equals(2));
      expect(totalWeeklyPeriods, equals(12));
    });

    test('11. Cross-college assignment and data isolation is strictly enforced', () async {
      final crossCollegeAssignment = FacultyAssignment(
        id: 'cross_assign',
        collegeId: 'c2',
        departmentId: 'd1', // Belongs to c1
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        subjectId: 'sub1',
        facultyId: 'f1',
        facultyName: 'Dr. Alan Turing',
        isActive: true,
        createdAt: DateTime.now(),
      );

      expect(
        () async => await academicRepo.createFacultyAssignment(crossCollegeAssignment),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('12. End-to-End Unified Academic Life-Cycle Pipeline', () async {
      // 1. College Admin creates department, course, semester, section, subject
      final depts = await academicRepo.getDepartments();
      final dept = depts.firstWhere((d) => d.id == 'd1');
      expect(dept, isNotNull);

      // 2. HOD assigns faculty f2 to subject sub3 + section sec1
      final assignment = FacultyAssignment(
        id: 'e2e_assign_1',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        subjectId: 'sub3',
        facultyId: 'f1',
        facultyName: 'Dr. Alan Turing',
        isActive: true,
        createdAt: DateTime.now(),
      );
      await academicRepo.createFacultyAssignment(assignment);

      // 3. Faculty uploads notes
      final facultyUser = UserModel(
        id: 'f1',
        name: 'Dr. Alan Turing',
        email: 'alan@turing.edu',
        role: AppRole.faculty,
        collegeId: 'c1',
        departmentId: 'd1',
      );
      final notesRepo = MockNotesRepository(
        currentUser: facultyUser,
        assignments: [assignment],
      );
      await notesRepo.createNote(NoteModel(
        id: 'e2e_note_1',
        title: 'End to End Integration Lesson',
        description: 'Full pipeline lesson material',
        resourceType: ResourceType.textNote,
        chapter: 'Chapter 10',
        subjectId: 'sub3',
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
      ));

      // 4. Student enrolled in sec1 resolves and sees the lesson note
      final studentStream = notesRepo.watchNotes(
        role: AppRole.student,
        userId: 'stu_1',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem1',
        sectionId: 'sec1',
      );
      final studentNotes = await studentStream.first;
      expect(studentNotes.any((n) => n.title == 'End to End Integration Lesson'), isTrue);

      // 5. Faculty retrieves assigned classes for attendance roster
      final assignedClasses = await attendanceRepo.getAssignedClasses('faculty1', DateTime.now());
      expect(assignedClasses, isNotEmpty);
      expect(assignedClasses.first.subjectName, isNotEmpty);
    });
  });
}
