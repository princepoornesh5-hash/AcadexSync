import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/attendance/domain/models/assigned_class.dart';
import 'package:campus_management/core/presentation/navigation/acadex_nav_item.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Prompt 24: Core Workflow Consolidation & Pilot Readiness Tests', () {
    test('1. CurrentAcademicContext parses and separates stage and period correctly', () {
      final json = {
        'collegeId': 'col_123',
        'isCurrentAuthoritative': true,
        'academicYear': {
          'id': 'ay_1',
          'name': '2026–27',
          'isCurrent': true,
          'status': 'ACTIVE',
        },
        'totalActiveCohorts': 1,
        'activeCohorts': [
          {
            'cohort': '2024–27',
            'courseId': 'course_1',
            'courseName': 'Diploma in Computer Engineering',
            'courseCode': 'DCSE',
            'departmentId': 'dept_1',
            'academicStage': '3rd Year',
            'stageNumber': 3,
            'entryYear': 2024,
            'expectedGraduationYear': 2027,
            'progressionType': 'YEAR_SEMESTER',
            'periods': [
              {
                'semesterId': 'sem_5',
                'name': 'Semester 5',
                'number': 5,
                'isCurrent': true,
                'status': 'ACTIVE',
                'sections': [
                  {
                    'sectionId': 'sec_A',
                    'name': 'A',
                    'capacity': 60,
                  }
                ],
              }
            ],
          }
        ],
      };

      final context = CurrentAcademicContext.fromJson(json);

      expect(context.collegeId, 'col_123');
      expect(context.isCurrentAuthoritative, isTrue);
      expect(context.academicYear?.name, '2026–27');
      expect(context.activeCohorts.length, 1);

      final cohort = context.activeCohorts.first;
      expect(cohort.cohort, '2024–27');
      expect(cohort.academicStage, '3rd Year');
      expect(cohort.progressionType, 'YEAR_SEMESTER');
      expect(cohort.periods.first.name, 'Semester 5');
      // Verify stage and period are distinct
      expect(cohort.academicStage, isNot(cohort.periods.first.name));
    });

    test('2. AssignedClass generates rich contextualDescription with cohort and stage', () {
      final assignedClass = AssignedClass(
        id: 'cls_1',
        subjectId: 'sub_1',
        subjectName: 'Database Management Systems',
        sectionId: 'sec_A',
        sectionName: 'A',
        semester: 'Semester 5',
        timeSlot: '10:00 - 11:00 AM',
        date: DateTime.now(),
        cohort: '2024–27',
        academicStage: '3rd Year',
      );

      final desc = assignedClass.contextualDescription;

      expect(desc, contains('2024–27'));
      expect(desc, contains('3rd Year'));
      expect(desc, contains('Semester 5'));
      expect(desc, contains('Class A'));
      expect(desc, '2024–27 · 3rd Year · Semester 5 · Class A');
    });

    test('3. Navigation Registry contains assignments accessible by faculty and student', () {
      final facultyGrouped = AcadexNavigationService.getGroupedNavItems(AppRole.faculty);
      final studentGrouped = AcadexNavigationService.getGroupedNavItems(AppRole.student);
      final hodGrouped = AcadexNavigationService.getGroupedNavItems(AppRole.hod);

      final facultyItems = facultyGrouped.values.expand((list) => list).toList();
      final studentItems = studentGrouped.values.expand((list) => list).toList();
      final hodItems = hodGrouped.values.expand((list) => list).toList();

      final facultyHasAssignments = facultyItems.any((item) => item.route == '/assignments');
      final studentHasAssignments = studentItems.any((item) => item.route == '/assignments');
      final hodHasAssignments = hodItems.any((item) => item.route == '/assignments');

      expect(facultyHasAssignments, isTrue);
      expect(studentHasAssignments, isTrue);
      expect(hodHasAssignments, isTrue);
    });

    test('4. Faculty dashboard quick actions expose Assignments shortcut', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final quickActions = container.read(facultyQuickActionsProvider);
      final hasAssignments = quickActions.any((action) => action.route == '/assignments');

      expect(hasAssignments, isTrue);
    });

    test('5. College Admin dashboard quick actions focus on institution setup', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final quickActions = container.read(collegeAdminQuickActionsProvider);
      final routes = quickActions.map((a) => a.route).toList();

      expect(routes, contains('/academics/academic-years'));
      expect(routes, contains('/academics/departments'));
      expect(routes, contains('/academics/hods'));
    });
  });
}
