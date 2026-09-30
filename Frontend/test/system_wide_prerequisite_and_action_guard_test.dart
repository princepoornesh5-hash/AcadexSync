import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/utils/academic_prerequisite_guard.dart';

void main() {
  group('System-Wide Prerequisite & Action Guard Tests', () {
    final mockCourse = Course(
      id: 'c1',
      collegeId: 'col1',
      departmentId: 'd1',
      name: 'Computer Engineering',
      code: 'CSE',
      duration: 3,
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
      name: 'A',
      capacity: 60,
      isActive: true,
    );

    final mockSubject = Subject(
      id: 'sub1',
      collegeId: 'col1',
      departmentId: 'd1',
      courseId: 'c1',
      semesterId: 'sem1',
      name: 'Data Structures',
      code: 'CS101',
      credits: 4,
      type: 'Theory',
      isActive: true,
    );

    final mockFaculty = Faculty(
      id: 'f1',
      collegeId: 'col1',
      departmentId: 'd1',
      name: 'Dr. Alan Turing',
      employeeId: 'EMP001',
      email: 'turing@acadex.edu',
      phone: '1234567890',
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
      facultyName: 'Dr. Alan Turing',
      academicYearId: 'ay1',
      isActive: true,
    );

    final mockRoom = Room(
      id: 'rm1',
      collegeId: 'col1',
      departmentId: 'd1',
      name: 'Lab 101',
      code: 'L101',
      capacity: 60,
      type: 'LAB',
      isActive: true,
    );

    test('1. No Course -> checkSemesterPrerequisites blocks and provides guidance', () {
      final res = AcademicPrerequisiteGuard.checkSemesterPrerequisites(
        courses: [],
        academicYears: [mockAcademicYear],
      );

      expect(res.isAllowed, isFalse);
      expect(res.isSatisfied, isFalse);
      expect(res.missingType, equals(AcademicPrerequisiteType.course));
      expect(res.message, contains('Course is required'));
      expect(res.actionLabel, equals('Create Course'));
    });

    test('2. No Academic Year -> checkSemesterPrerequisites blocks and provides guidance', () {
      final res = AcademicPrerequisiteGuard.checkSemesterPrerequisites(
        courses: [mockCourse],
        academicYears: [],
      );

      expect(res.isAllowed, isFalse);
      expect(res.missingType, equals(AcademicPrerequisiteType.academicYear));
      expect(res.message, contains('Academic Year is required'));
      expect(res.actionLabel, equals('Create Academic Year'));
    });

    test('3. No Semester -> checkSectionPrerequisites blocks and provides guidance', () {
      final res = AcademicPrerequisiteGuard.checkSectionPrerequisites(
        courses: [mockCourse],
        semesters: [],
      );

      expect(res.isAllowed, isFalse);
      expect(res.missingType, equals(AcademicPrerequisiteType.semester));
      expect(res.message, contains('Create a Semester for this Course first'));
      expect(res.actionLabel, equals('Create Semester'));
    });

    test('4. No Subject -> checkFacultyAssignmentPrerequisites blocks and provides guidance', () {
      final res = AcademicPrerequisiteGuard.checkFacultyAssignmentPrerequisites(
        courses: [mockCourse],
        semesters: [mockSemester],
        sections: [mockSection],
        subjects: [],
        faculty: [mockFaculty],
      );

      expect(res.isAllowed, isFalse);
      expect(res.missingType, equals(AcademicPrerequisiteType.subject));
      expect(res.message, contains('Add a Subject for this Semester first'));
      expect(res.actionLabel, equals('Add Subject'));
    });

    test('5. Inactive Faculty -> checkFacultyAssignmentPrerequisites excludes and blocks', () {
      final inactiveFaculty = Faculty(
        id: 'f2',
        collegeId: 'col1',
        departmentId: 'd1',
        name: 'Inactive Prof',
        employeeId: 'EMP002',
        email: 'inactive@acadex.edu',
        phone: '1234567890',
        isActive: false,
      );

      final res = AcademicPrerequisiteGuard.checkFacultyAssignmentPrerequisites(
        courses: [mockCourse],
        semesters: [mockSemester],
        sections: [mockSection],
        subjects: [mockSubject],
        faculty: [inactiveFaculty],
      );

      expect(res.isAllowed, isFalse);
      expect(res.missingType, equals(AcademicPrerequisiteType.faculty));
      expect(res.message, contains('No active faculty available'));
      expect(res.actionLabel, equals('Provision Faculty'));
    });

    test('6. No Faculty Assignment -> checkTimetablePrerequisites blocks and provides guidance', () {
      final res = AcademicPrerequisiteGuard.checkTimetablePrerequisites(
        courses: [mockCourse],
        academicYears: [mockAcademicYear],
        semesters: [mockSemester],
        sections: [mockSection],
        subjects: [mockSubject],
        facultyAssignments: [],
        rooms: [mockRoom],
      );

      expect(res.isAllowed, isFalse);
      expect(res.missingType, equals(AcademicPrerequisiteType.facultyAssignment));
      expect(res.message, contains('At least one teaching assignment is required'));
      expect(res.actionLabel, equals('Assign Faculty'));
    });

    test('7. Room Optionality -> checkTimetablePrerequisites allows by default, blocks when isRoomRequired: true', () {
      // Default: room is optional, timetable allowed
      final resOptional = AcademicPrerequisiteGuard.checkTimetablePrerequisites(
        courses: [mockCourse],
        academicYears: [mockAcademicYear],
        semesters: [mockSemester],
        sections: [mockSection],
        subjects: [mockSubject],
        facultyAssignments: [mockFacultyAssignment],
        rooms: [],
      );
      expect(resOptional.isAllowed, isTrue);

      // When institution requires rooms, check blocks with clear guidance
      final resRequired = AcademicPrerequisiteGuard.checkTimetablePrerequisites(
        courses: [mockCourse],
        academicYears: [mockAcademicYear],
        semesters: [mockSemester],
        sections: [mockSection],
        subjects: [mockSubject],
        facultyAssignments: [mockFacultyAssignment],
        rooms: [],
        isRoomRequired: true,
      );

      expect(resRequired.isAllowed, isFalse);
      expect(resRequired.missingType, equals(AcademicPrerequisiteType.room));
      expect(resRequired.message, contains('requires rooms for timetable scheduling'));
      expect(resRequired.actionLabel, equals('Add Room'));
      expect(resRequired.actionRoute, equals('/academics/rooms/new'));
    });

    test('8. Full Academic Foundation -> checkTimetablePrerequisites allows continuation', () {
      final res = AcademicPrerequisiteGuard.checkTimetablePrerequisites(
        courses: [mockCourse],
        academicYears: [mockAcademicYear],
        semesters: [mockSemester],
        sections: [mockSection],
        subjects: [mockSubject],
        facultyAssignments: [mockFacultyAssignment],
        rooms: [mockRoom],
      );

      expect(res.isAllowed, isTrue);
      expect(res.isSatisfied, isTrue);
      expect(res.missingType, isNull);
    });

    test('9. No Published Timetable -> checkAttendanceEntryPrerequisites blocks attendance', () {
      final res = AcademicPrerequisiteGuard.checkAttendanceEntryPrerequisites(
        isTimetablePublished: false,
        enrolledStudentsCount: 30,
      );

      expect(res.isAllowed, isFalse);
      expect(res.missingType, equals(AcademicPrerequisiteType.publishedTimetable));
      expect(res.message, contains('This class is not published on the timetable'));
      expect(res.actionLabel, equals('View Timetable'));
    });

    test('10. No Enrolled Students -> checkAttendanceEntryPrerequisites blocks attendance', () {
      final res = AcademicPrerequisiteGuard.checkAttendanceEntryPrerequisites(
        isTimetablePublished: true,
        enrolledStudentsCount: 0,
      );

      expect(res.isAllowed, isFalse);
      expect(res.missingType, equals(AcademicPrerequisiteType.enrollment));
      expect(res.message, contains('No students are enrolled in this section yet'));
      expect(res.actionLabel, equals('Manage Sections'));
    });

    testWidgets('11. Blocker Dialog UI renders explanation, why it is required, and action button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  final check = AcademicPrerequisiteGuard.checkTimetablePrerequisites(
                    courses: [],
                    academicYears: [],
                    semesters: [],
                    sections: [],
                    subjects: [],
                    facultyAssignments: [],
                    rooms: [],
                  );
                  AcademicPrerequisiteGuard.showBlockerDialog(context, check);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Timetable needs a little setup'), findsOneWidget);
      expect(find.text('Create a Course first.'), findsOneWidget);
      expect(find.text('Create Course'), findsOneWidget);
    });
  });
}
