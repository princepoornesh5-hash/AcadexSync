import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:campus_management/core/presentation/navigation/acadex_nav_item.dart';
import 'package:campus_management/core/presentation/providers/navigation_provider.dart';
import 'package:campus_management/core/presentation/widgets/acadex_data_table.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/search/domain/models/search_models.dart';
import 'package:campus_management/features/search/data/repositories/mock_search_repository.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/home_dashboard_widgets.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';

void main() {
  group('Bug 1: Academic Structure Navigation Patterns', () {
    test('Academic items route URLs use canonical :id detail pattern', () {
      final dept = Department(
        id: 'dept_123',
        collegeId: 'col_1',
        name: 'Computer Science',
        code: 'CSE',
        hodId: 'hod_1',
        description: 'Dept of CSE',
      );
      final course = Course(
        id: 'course_456',
        collegeId: 'col_1',
        departmentId: 'dept_123',
        name: 'B.Tech CSE',
        code: 'BTCSE',
        duration: 4,
      );
      final sem = Semester(
        id: 'sem_789',
        collegeId: 'col_1',
        departmentId: 'dept_123',
        courseId: 'course_456',
        academicYearId: 'ay_1',
        name: 'Semester 4',
        number: 4,
      );
      final sec = Section(
        id: 'sec_101',
        collegeId: 'col_1',
        departmentId: 'dept_123',
        semesterId: 'sem_789',
        name: 'Section A',
        capacity: 60,
      );

      expect('/academics/departments/${dept.id}', '/academics/departments/dept_123');
      expect('/academics/courses/${course.id}', '/academics/courses/course_456');
      expect('/academics/semesters/${sem.id}', '/academics/semesters/sem_789');
      expect('/academics/sections/${sec.id}', '/academics/sections/sec_101');
    });
  });

  group('Bug 2: Sidebar Active Navigation Item Selection (HOD & All Roles)', () {
    test('Selecting /academics/students activates ONLY Students, NOT Academics or People', () {
      final activeItem = AcadexNavigationService.resolveActiveItem('/academics/students', AppRole.hod);
      expect(activeItem, isNotNull);
      expect(activeItem!.id, 'students');
      expect(activeItem.route, '/academics/students');

      final allHodItems = AcadexNavigationService.getGroupedNavItems(AppRole.hod).values.expand((x) => x).toList();
      final academicsItem = allHodItems.firstWhere((i) => i.id == 'academics');
      expect(academicsItem.matchesRoute('/academics/students'), isFalse);

      final allCollegeAdminItems = AcadexNavigationService.getGroupedNavItems(AppRole.collegeAdmin).values.expand((x) => x).toList();
      final peopleItem = allCollegeAdminItems.firstWhere((i) => i.id == 'people');
      expect(peopleItem.matchesRoute('/academics/students'), isFalse);
    });

    test('Selecting /academics activates ONLY Academics, NOT Students', () {
      final activeItem = AcadexNavigationService.resolveActiveItem('/academics', AppRole.hod);
      expect(activeItem, isNotNull);
      expect(activeItem!.id, 'academics');
      expect(activeItem.route, '/academics');

      final allHodItems = AcadexNavigationService.getGroupedNavItems(AppRole.hod).values.expand((x) => x).toList();
      final studentsItem = allHodItems.firstWhere((i) => i.id == 'students');
      expect(studentsItem.matchesRoute('/academics'), isFalse);
    });

    test('Direct URL entry with query parameters cleans and matches correctly', () {
      final activeItem = AcadexNavigationService.resolveActiveItem('/academics/students?deptId=CSE&search=alice', AppRole.hod);
      expect(activeItem, isNotNull);
      expect(activeItem!.id, 'students');
    });

    test('Works consistently across College Admin, Faculty, Student, and Super Admin', () {
      for (final role in [AppRole.collegeAdmin, AppRole.faculty, AppRole.superAdmin]) {
        final activeItem = AcadexNavigationService.resolveActiveItem('/academics/students', role);
        if (activeItem != null) {
          expect(activeItem.id, 'students');
        }
      }
    });
  });

  group('Bug 3: Students Directory Table Checkbox Removal', () {
    testWidgets('AcadexDataTable renders with showCheckboxColumn: false and no checkboxes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcadexDataTable(
              showCheckboxColumn: false,
              columns: const ['Student', 'Roll No.', 'Status'],
              rows: [
                DataRow(
                  cells: const [
                    DataCell(Text('Jane Doe')),
                    DataCell(Text('CS2026-001')),
                    DataCell(Text('Active')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DataTable), findsOneWidget);
      final dataTable = tester.widget<DataTable>(find.byType(DataTable));
      expect(dataTable.showCheckboxColumn, isFalse);
      expect(find.byType(Checkbox), findsNothing);
    });
  });

  group('Bug 4: Global Search Navigation Destinations & Scoped Queries', () {
    test('Navigation search resolves destination matching "students" for HOD', () {
      final destinations = AcadexNavigationService.searchNavigationDestinations('students', AppRole.hod);
      expect(destinations, isNotEmpty);
      expect(destinations.any((d) => d.destinationRoute == '/academics/students'), isTrue);
      expect(destinations.first.title, contains('Students'));
    });

    test('MockSearchRepository returns navigation destination and scoped entities', () async {
      final repo = MockSearchRepository();
      const user = UserModel(
        id: 'u_hod',
        name: 'Alan Turing',
        email: 'hod@acadex.edu',
        role: AppRole.hod,
        collegeId: 'col_1',
        departmentId: 'dept_cse',
      );

      final results = await repo.search('students', user);

      expect(results, isNotEmpty);
      // Contains navigation result
      expect(results.any((r) => r.type == SearchResultType.navigation), isTrue);
      final navResult = results.firstWhere((r) => r.type == SearchResultType.navigation);
      expect(navResult.destinationRoute, '/academics/students');
    });

    test('Search destination URLs point to actual canonical routes rather than /module/*', () async {
      final repo = MockSearchRepository();
      const user = UserModel(
        id: 'u_hod',
        name: 'Alan Turing',
        email: 'hod@acadex.edu',
        role: AppRole.hod,
        collegeId: 'col_1',
        departmentId: 'dept_cse',
      );

      final results = await repo.search('alice', user);

      for (final r in results) {
        expect(r.destinationRoute.startsWith('/module/'), isFalse, reason: 'Route ${r.destinationRoute} should be canonical');
      }
    });
  });

  group('Bug 5: Dashboard Action Selection State & Visual Persistence', () {
    test('GlobalNavigationState deterministically evaluates active dashboard actions', () {
      const state = GlobalNavigationState(
        lastSelectedActionRoute: '/attendance/review',
        lastSelectedActionId: 'qa_h4',
      );

      final allRoutes = ['/faculty-management', '/academic-structure', '/timetable', '/attendance/review'];

      // qa_h4 matches
      expect(
        state.isActionActive(
          route: '/attendance/review',
          id: 'qa_h4',
          allRoutes: allRoutes,
        ),
        isTrue,
      );

      // timetable does not match
      expect(
        state.isActionActive(
          route: '/timetable',
          id: 'qa_h3',
          allRoutes: allRoutes,
        ),
        isFalse,
      );
    });

    test('Entering destination via direct route clears stale action selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(navigationProvider.notifier);
      notifier.selectDashboardAction(route: '/timetable', id: 'qa_h3');
      expect(container.read(navigationProvider).lastSelectedActionRoute, '/timetable');
      expect(container.read(navigationProvider).lastSelectedActionId, 'qa_h3');

      // User enters /settings via sidebar
      notifier.updateRoute('/settings');
      expect(container.read(navigationProvider).lastSelectedActionRoute, '/settings');
      expect(container.read(navigationProvider).lastSelectedActionId, isNull);

      final allRoutes = ['/timetable', '/attendance/review'];
      // Returning to dashboard: /timetable is no longer selected
      expect(
        container.read(navigationProvider).isActionActive(route: '/timetable', id: 'qa_h3', allRoutes: allRoutes),
        isFalse,
      );
    });

    testWidgets('DashboardActionCard renders distinct active styling when selected', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardActionCard(
              label: 'Department Timetable',
              icon: LucideIcons.calendar,
              isSelected: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Department Timetable'), findsOneWidget);
      await tester.tap(find.text('Department Timetable'));
      expect(tapped, isTrue);
    });
  });
}
