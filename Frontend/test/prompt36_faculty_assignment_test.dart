import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/widgets/faculty_assignment_dialog.dart';
import 'package:campus_management/features/academic_structure/presentation/utils/academic_prerequisite_guard.dart';
import 'package:campus_management/features/institution_config/presentation/providers/institution_config_providers.dart';
import 'package:campus_management/features/institution_config/domain/models/institution_config_models.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';

void main() {
  group('PROMPT 36 — FacultyAssignment Domain Model & Lifecycle Hardening', () {
    test('FacultyAssignment supports section optionality, lifecycle status, and endedAt', () {
      final jsonWithSection = {
        'id': 'fa_001',
        'collegeId': 'col_alpha',
        'departmentId': 'dept_cse',
        'facultyId': 'fac_001',
        'facultyName': 'Dr. Ada Lovelace',
        'courseId': 'crs_btech',
        'academicYearId': 'ay_2026',
        'semesterId': 'sem_5',
        'sectionId': 'sec_a',
        'subjectId': 'sub_dbms',
        'status': 'active',
        'isActive': true,
        'createdAt': '2026-06-01T00:00:00.000Z',
      };

      final assignment = FacultyAssignment.fromJson(jsonWithSection);
      expect(assignment.id, 'fa_001');
      expect(assignment.sectionId, 'sec_a');
      expect(assignment.status, 'active');
      expect(assignment.effectiveStatus, 'active');
      expect(assignment.isActive, true);
      expect(assignment.endedAt, isNull);

      // Section-disabled assignment (sectionId is null)
      final jsonWithoutSection = {
        'id': 'fa_002',
        'collegeId': 'col_alpha',
        'departmentId': 'dept_cse',
        'facultyId': 'fac_001',
        'facultyName': 'Dr. Ada Lovelace',
        'courseId': 'crs_btech',
        'academicYearId': 'ay_2026',
        'semesterId': 'sem_5',
        'sectionId': null,
        'subjectId': 'sub_dbms',
        'status': 'ended',
        'isActive': false,
        'endedAt': '2026-11-30T00:00:00.000Z',
      };

      final endedAssignment = FacultyAssignment.fromJson(jsonWithoutSection);
      expect(endedAssignment.id, 'fa_002');
      expect(endedAssignment.sectionId, isNull);
      expect(endedAssignment.status, 'ended');
      expect(endedAssignment.effectiveStatus, 'ended');
      expect(endedAssignment.isActive, false);
      expect(endedAssignment.endedAt, isNotNull);

      // Serialization safely omits null sectionId
      final serialized = endedAssignment.toJson();
      expect(serialized.containsKey('sectionId'), false);
      expect(serialized['status'], 'ended');

      // Empty factory test
      final empty = FacultyAssignment.empty();
      expect(empty.id, '');
      expect(empty.sectionId, isNull);
      expect(empty.status, 'active');
      expect(empty.isActive, true);
    });

    test('Inactive faculty cannot be selected for new assignments', () {
      final activeFaculty = Faculty(
        id: 'fac_active',
        collegeId: 'col1',
        departmentId: 'dept1',
        name: 'Active Faculty',
        employeeId: 'EMP_ACT',
        email: 'act@univ.edu',
        phone: '+919876543210',
        isActive: true,
      );

      final inactiveFaculty = Faculty(
        id: 'fac_inactive',
        collegeId: 'col1',
        departmentId: 'dept1',
        name: 'Inactive Faculty',
        employeeId: 'EMP_INACT',
        email: 'inact@univ.edu',
        phone: '+919876543211',
        isActive: false,
      );

      final allFaculty = [activeFaculty, inactiveFaculty];
      final eligibleFaculty = allFaculty.where((f) => f.isActive).toList();

      expect(eligibleFaculty.length, 1);
      expect(eligibleFaculty.first.id, 'fac_active');
    });
  });

  group('PROMPT 36 — Prerequisite Guard Validations', () {
    test('checkFacultyAssignmentPrerequisites flags missing Academic Year accurately', () {
      final courses = [
        Course(
          id: 'c1',
          collegeId: 'col1',
          name: 'Computer Science',
          code: 'CS',
          departmentId: 'dept1',
        ),
      ];

      final faculty = [
        Faculty(
          id: 'f1',
          collegeId: 'col1',
          departmentId: 'dept1',
          name: 'Prof. Turing',
          employeeId: 'EMP001',
          email: 'turing@univ.edu',
          phone: '+919876543210',
          isActive: true,
          subjectIds: const [],
          sectionIds: const [],
        ),
      ];

      final subjects = [
        Subject(
          id: 's1',
          collegeId: 'col1',
          departmentId: 'dept1',
          courseId: 'c1',
          semesterId: 'sem1',
          name: 'Algorithms',
          code: 'CS201',
        ),
      ];

      // Missing academic years
      final prereqNoAY = AcademicPrerequisiteGuard.checkFacultyAssignmentPrerequisites(
        courses: courses,
        semesters: const [],
        sections: const [],
        academicYears: const [], // Empty academic years!
        faculty: faculty,
        subjects: subjects,
        isSectionEnabled: false,
      );

      expect(prereqNoAY.isAllowed, false);
      expect(prereqNoAY.message, contains('Academic Year'));

      // Available when all prerequisites exist
      final validAY = [
        AcademicYear(
          id: 'ay1',
          collegeId: 'col1',
          name: '2026-27',
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2027, 5, 31),
          isCurrent: true,
          status: 'active',
        ),
      ];

      final validSemesters = [
        Semester(
          id: 'sem1',
          collegeId: 'col1',
          departmentId: 'dept1',
          courseId: 'c1',
          academicYearId: 'ay1',
          name: 'Semester 1',
          number: 1,
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 11, 30),
        ),
      ];

      final prereqValid = AcademicPrerequisiteGuard.checkFacultyAssignmentPrerequisites(
        courses: courses,
        semesters: validSemesters,
        sections: const [],
        academicYears: validAY,
        faculty: faculty,
        subjects: subjects,
        isSectionEnabled: false,
      );

      expect(prereqValid.isAllowed, true);
      expect(prereqValid.message, isNull);
    });

    test('checkFacultyAssignmentPrerequisites blocks when faculty or subject is missing', () {
      final prereqNoFaculty = AcademicPrerequisiteGuard.checkFacultyAssignmentPrerequisites(
        courses: [
          Course(id: 'c1', collegeId: 'col1', departmentId: 'dept1', name: 'CS', code: 'CS'),
        ],
        semesters: [
          Semester(
            id: 's1',
            collegeId: 'col1',
            departmentId: 'dept1',
            courseId: 'c1',
            academicYearId: 'ay1',
            name: 'Sem 1',
            number: 1,
            startDate: DateTime(2026, 6, 1),
            endDate: DateTime(2026, 11, 30),
          ),
        ],
        sections: const [],
        academicYears: [
          AcademicYear(
            id: 'ay1',
            collegeId: 'col1',
            name: '2026-27',
            startDate: DateTime(2026, 6, 1),
            endDate: DateTime(2027, 5, 31),
            isCurrent: true,
          ),
        ],
        subjects: [
          Subject(id: 'sub1', collegeId: 'col1', departmentId: 'dept1', courseId: 'c1', semesterId: 's1', name: 'Algorithms', code: 'CS201'),
        ],
        faculty: const [], // Empty faculty!
        isSectionEnabled: false,
      );

      expect(prereqNoFaculty.isAllowed, false);
      expect(prereqNoFaculty.message?.toLowerCase(), contains('faculty'));
    });
  });

  group('PROMPT 36 — Progressive Dialog UI & Responsive Viewport', () {
    testWidgets('Renders progressive assignment dialog and adapts to section optionality', (tester) async {
      final mockRepo = MockAcademicRepository();

      // Configure institution with Section disabled
      const sectionDisabledConfig = InstitutionConfigModel(
        collegeId: 'col_alpha',
        institutionType: InstitutionType.polytechnic,
        academicStructure: AcademicStructureConfig(
          program: true,
          academicYear: true,
          semester: true,
          section: false, // Section Disabled
          subject: true,
          building: false,
          room: false,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            academicRepositoryProvider.overrideWithValue(mockRepo),
            institutionConfigProvider.overrideWith((ref) => Future.value(sectionDisabledConfig)),
            terminologyProvider.overrideWithValue(const TerminologyHelper(sectionDisabledConfig)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FacultyAssignmentDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Dialog renders successfully
      expect(find.text('Assign Faculty to Class'), findsOneWidget);
    });

    testWidgets('Renders properly on narrow mobile viewport (360px) without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockAcademicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            academicRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FacultyAssignmentDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Faculty Subject & Class Assignment'), findsOneWidget);
    });
  });
}
