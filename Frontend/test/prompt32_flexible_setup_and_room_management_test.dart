import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/utils/academic_prerequisite_guard.dart';

void main() {
  group('Prompt 32 — Flexible Academic Setup & Room Management Tests', () {
    final mockCourse = Course(
      id: 'c1',
      collegeId: 'col1',
      departmentId: 'd1',
      name: 'Computer Science & Engineering',
      code: 'CSE',
      duration: 4,
      isActive: true,
    );

    final mockAcademicYear = AcademicYear(
      id: 'ay1',
      collegeId: 'col1',
      name: '2026-2027',
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2027, 5, 31),
      isActive: true,
    );

    final mockSemester = Semester(
      id: 'sem1',
      collegeId: 'col1',
      departmentId: 'd1',
      courseId: 'c1',
      academicYearId: 'ay1',
      name: 'Semester 1',
      number: 1,
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 11, 30),
      isActive: true,
    );

    final mockSection = Section(
      id: 'sec1',
      collegeId: 'col1',
      departmentId: 'd1',
      courseId: 'c1',
      semesterId: 'sem1',
      academicYearId: 'ay1',
      name: 'Section A',
      capacity: 60,
      isActive: true,
    );

    final mockSubject = Subject(
      id: 'sub1',
      collegeId: 'col1',
      departmentId: 'd1',
      courseId: 'c1',
      semesterId: 'sem1',
      name: 'Operating Systems',
      code: 'CS301',
      credits: 4,
      type: 'Theory',
      isActive: true,
    );

    final mockFaculty = Faculty(
      id: 'f1',
      collegeId: 'col1',
      departmentId: 'd1',
      name: 'Prof. Ada Lovelace',
      employeeId: 'EMP002',
      email: 'ada@acadex.edu',
      phone: '9876543210',
      isActive: true,
      accountStatus: AccountStatus.active,
    );

    final mockFacultyAssignment = FacultyAssignment(
      id: 'fa1',
      collegeId: 'col1',
      departmentId: 'd1',
      courseId: 'c1',
      semesterId: 'sem1',
      sectionId: 'sec1',
      subjectId: 'sub1',
      facultyId: 'f1',
      facultyName: 'Prof. Ada Lovelace',
      academicYearId: 'ay1',
      isActive: true,
    );

    test('1. Room model serialization handles empty/null departmentId cleanly', () {
      final campusSharedRoom = Room(
        id: 'room_shared_1',
        collegeId: 'col1',
        departmentId: '', // Empty means campus-shared
        name: 'Main Auditorium',
        code: 'AUD-01',
        capacity: 300,
        type: 'AUDITORIUM',
        isActive: true,
      );

      final json = campusSharedRoom.toJson();
      expect(json.containsKey('departmentId'), isFalse,
          reason: 'Backend Zod rejects empty string departmentId, it should be omitted');
      expect(json['code'], 'AUD-01');
      expect(json['capacity'], 300);

      final deptRoom = Room(
        id: 'room_dept_1',
        collegeId: 'col1',
        departmentId: 'd1',
        name: 'CS Lab 1',
        code: 'CS-L1',
        capacity: 40,
        type: 'LAB',
        isActive: true,
      );

      final deptJson = deptRoom.toJson();
      expect(deptJson['departmentId'], 'd1');
    });

    test('2. Independent Room Creation: Room does NOT require courses, faculty, or timetable', () {
      final room = Room(
        id: 'room_stand_alone',
        collegeId: 'col1',
        departmentId: 'd1',
        name: 'Seminar Hall B',
        code: 'SH-B',
        capacity: 120,
        type: 'SEMINAR_HALL',
        isActive: true,
      );

      expect(room.id, isNotEmpty);
      expect(room.code, 'SH-B');
      expect(room.isActive, isTrue);
    });

    test('3. Subject creation does NOT require Rooms or Faculty', () {
      final prereqResult = AcademicPrerequisiteGuard.checkSubjectPrerequisites(
        courses: [mockCourse],
        semesters: [mockSemester],
      );

      expect(prereqResult.isAllowed, isTrue);
      expect(prereqResult.isSatisfied, isTrue);
    });

    test('4. Timetable is NOT blocked when rooms are absent by default (Flexible Philosophy)', () {
      final prereqResult = AcademicPrerequisiteGuard.checkTimetablePrerequisites(
        courses: [mockCourse],
        academicYears: [mockAcademicYear],
        semesters: [mockSemester],
        sections: [mockSection],
        subjects: [mockSubject],
        facultyAssignments: [mockFacultyAssignment],
        rooms: [], // Zero rooms configured
        isSectionEnabled: true,
        isRoomRequired: false, // Default: rooms optional
      );

      expect(prereqResult.isAllowed, isTrue,
          reason: 'Institutions can schedule classes without pre-configuring physical rooms');
      expect(prereqResult.isSatisfied, isTrue);
    });

    test('5. When rooms ARE explicitly required and missing, smart prerequisite dialog gives clean guidance', () {
      final prereqResult = AcademicPrerequisiteGuard.checkTimetablePrerequisites(
        courses: [mockCourse],
        academicYears: [mockAcademicYear],
        semesters: [mockSemester],
        sections: [mockSection],
        subjects: [mockSubject],
        facultyAssignments: [mockFacultyAssignment],
        rooms: [],
        isSectionEnabled: true,
        isRoomRequired: true, // Institution mandates room booking
      );

      expect(prereqResult.isAllowed, isFalse);
      expect(prereqResult.title, 'Timetable needs a little setup');
      expect(prereqResult.missingType, AcademicPrerequisiteType.room);
      expect(prereqResult.priorityLevel, PrerequisitePriorityLevel.optional);
      expect(prereqResult.actionRoute, '/academics/rooms/new');
      expect(prereqResult.actionLabel, 'Add Room');
      expect(prereqResult.message, contains('No rooms are set up yet'));
    });

    test('6. When faculty assignments are missing, route points directly to /faculty-assignments', () {
      final prereqResult = AcademicPrerequisiteGuard.checkTimetablePrerequisites(
        courses: [mockCourse],
        academicYears: [mockAcademicYear],
        semesters: [mockSemester],
        sections: [mockSection],
        subjects: [mockSubject],
        facultyAssignments: [], // Missing assignments
        rooms: [],
        isSectionEnabled: true,
      );

      expect(prereqResult.isAllowed, isFalse);
      expect(prereqResult.missingType, AcademicPrerequisiteType.facultyAssignment);
      expect(prereqResult.actionRoute, '/faculty-assignments');
      expect(prereqResult.actionLabel, 'Assign Faculty');
    });

    test('7. Sections are optional when institution disables sections', () {
      final facultyAssignmentPrereq = AcademicPrerequisiteGuard.checkFacultyAssignmentPrerequisites(
        courses: [mockCourse],
        semesters: [mockSemester],
        sections: [], // No sections created
        subjects: [mockSubject],
        faculties: [mockFaculty],
        isSectionEnabled: false, // Disabled by institution config
      );

      expect(facultyAssignmentPrereq.isAllowed, isTrue,
          reason: 'Institutions without sections must not be blocked from assigning faculty');

      final timetablePrereq = AcademicPrerequisiteGuard.checkTimetablePrerequisites(
        courses: [mockCourse],
        academicYears: [mockAcademicYear],
        semesters: [mockSemester],
        sections: [], // No sections
        subjects: [mockSubject],
        facultyAssignments: [mockFacultyAssignment],
        rooms: [],
        isSectionEnabled: false,
      );

      expect(timetablePrereq.isAllowed, isTrue,
          reason: 'Institutions without sections must not be blocked from creating timetables');
    });

    testWidgets('8. Smart Prerequisite Dialog displays human-readable explanation with direct action',
        (tester) async {
      final prereqResult = AcademicPrerequisiteGuard.checkTimetablePrerequisites(
        courses: [mockCourse],
        academicYears: [mockAcademicYear],
        semesters: [mockSemester],
        sections: [mockSection],
        subjects: [mockSubject],
        facultyAssignments: [mockFacultyAssignment],
        rooms: [],
        isSectionEnabled: true,
        isRoomRequired: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AcademicPrerequisiteGuard.showSmartPrerequisiteDialog(
                  context,
                  prereqResult,
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text('Timetable needs a little setup'), findsOneWidget);

      // Verify Human Explanation
      expect(find.textContaining('No rooms are set up yet'), findsOneWidget);

      // Verify Action Button
      expect(find.text('Add Room'), findsOneWidget);

      // Verify Cancel Button
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
