import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/widgets/progressive_enrollment_dialog.dart';
import 'package:campus_management/features/institution_config/presentation/providers/institution_config_providers.dart';
import 'package:campus_management/features/institution_config/domain/models/institution_config_models.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';

void main() {
  group('PROMPT 35 — People & Student Enrollment Domain Models', () {
    test('StudentEnrollment supports section optionality and configuration-driven fields', () {
      final jsonWithSection = {
        'id': 'enr_001',
        'collegeId': 'col_alpha',
        'departmentId': 'dept_cse',
        'studentId': 'stu_001',
        'courseId': 'crs_btech',
        'academicYearId': 'ay_2026',
        'semesterId': 'sem_1',
        'sectionId': 'sec_a',
        'cohort': '2026–30',
        'academicStage': 'Year 1',
        'status': 'active',
        'enrollmentDate': '2026-06-01T00:00:00.000Z',
      };

      final enrollmentWithSection = StudentEnrollment.fromJson(jsonWithSection);
      expect(enrollmentWithSection.id, 'enr_001');
      expect(enrollmentWithSection.sectionId, 'sec_a');
      expect(enrollmentWithSection.cohort, '2026–30');
      expect(enrollmentWithSection.academicStage, 'Year 1');
      expect(enrollmentWithSection.isActive, true);

      // Section-disabled enrollment (sectionId is null)
      final jsonWithoutSection = {
        'id': 'enr_002',
        'collegeId': 'col_alpha',
        'departmentId': 'dept_cse',
        'studentId': 'stu_002',
        'courseId': 'crs_btech',
        'academicYearId': 'ay_2026',
        'semesterId': 'sem_1',
        'sectionId': null,
        'cohort': '2026–30',
        'status': 'active',
      };

      final enrollmentWithoutSection = StudentEnrollment.fromJson(jsonWithoutSection);
      expect(enrollmentWithoutSection.id, 'enr_002');
      expect(enrollmentWithoutSection.sectionId, isNull);
      expect(enrollmentWithoutSection.isActive, true);

      // Serialization preserves null sectionId without crash
      final serialized = enrollmentWithoutSection.toJson();
      expect(serialized.containsKey('sectionId'), false);

      // Empty factory test
      final empty = StudentEnrollment.empty();
      expect(empty.id, '');
      expect(empty.sectionId, isNull);
    });

    test('Student model separates profile from canonical placement while supporting lifecycle states', () {
      final json = {
        'id': 'stu_100',
        'collegeId': 'col_alpha',
        'departmentId': 'dept_cse',
        'courseId': 'crs_btech',
        'academicYearId': 'ay_2026',
        'semesterId': 'sem_1',
        'sectionId': 'sec_a',
        'name': 'Ada Lovelace',
        'rollNumber': '26CSE001',
        'email': 'ada@collegea.edu',
        'phone': '+919876543210',
        'cohort': '2026–30',
        'academicStage': 'Year 1',
        'isActive': true,
      };

      final student = Student.fromJson(json);
      expect(student.name, 'Ada Lovelace');
      expect(student.rollNumber, '26CSE001');
      expect(student.status, 'active');
      expect(student.cohort, '2026–30');
      expect(student.academicStage, 'Year 1');
    });
  });

  group('PROMPT 35 — Progressive Enrollment Dialog & Terminology UI', () {
    testWidgets('Renders progressive enrollment dialog and adapts to section optionality', (tester) async {
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
            terminologyProvider.overrideWithValue(const TerminologyHelper(sectionDisabledConfig)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ProgressiveEnrollmentDialog(
                initialDepartmentId: 'dept_cse',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify progressive dialog header and title rendered
      expect(find.text('Enroll Student'), findsOneWidget);
      expect(find.text('Step 1: Select Student'), findsOneWidget);

      // Verify that when section is disabled, steps are 6 instead of 7
      expect(find.text('Step 1 of 6'), findsOneWidget);
    });

    testWidgets('Renders properly on mobile screen width 360px without horizontal overflow', (tester) async {
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
              body: ProgressiveEnrollmentDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Enroll Student'), findsOneWidget);
    });
  });
}
