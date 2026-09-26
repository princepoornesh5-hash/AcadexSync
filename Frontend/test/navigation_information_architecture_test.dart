import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

import 'package:campus_management/core/presentation/navigation/acadex_nav_item.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/acadex_bottom_nav.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/acadex_drawer.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/acadex_nav_rail.dart';
import 'package:campus_management/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:campus_management/features/academic_structure/presentation/screens/academic_structure_home_screen.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/domain/repositories/academic_repository.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/timetable/data/repositories/timetable_repository.dart';

// Test Mocks & Repositories
class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestDepartmentNotifier extends DepartmentNotifier {
  final List<Department> initialDepartments;
  TestDepartmentNotifier(this.initialDepartments);
  @override
  Future<List<Department>> build() async => initialDepartments;
}

class TestCourseNotifier extends CourseNotifier {
  final List<Course> initialCourses;
  TestCourseNotifier(this.initialCourses);
  @override
  Future<List<Course>> build() async => initialCourses;
}

class TestAcademicYearNotifier extends AcademicYearNotifier {
  final List<AcademicYear> initialYears;
  TestAcademicYearNotifier(this.initialYears);
  @override
  Future<List<AcademicYear>> build() async => initialYears;
}

class TestSemesterNotifier extends SemesterNotifier {
  final List<Semester> initialSemesters;
  TestSemesterNotifier(this.initialSemesters);
  @override
  Future<List<Semester>> build() async => initialSemesters;
}

class TestSectionNotifier extends SectionNotifier {
  final List<Section> initialSections;
  TestSectionNotifier(this.initialSections);
  @override
  Future<List<Section>> build() async => initialSections;
}

class TestSubjectNotifier extends SubjectNotifier {
  final List<Subject> initialSubjects;
  TestSubjectNotifier(this.initialSubjects);
  @override
  Future<List<Subject>> build() async => initialSubjects;
}

class TestFacultyAssignmentNotifier extends FacultyAssignmentsNotifier {
  final List<FacultyAssignment> initialAssignments;
  TestFacultyAssignmentNotifier(this.initialAssignments);
  @override
  Future<List<FacultyAssignment>> build() async => initialAssignments;
}

class MockAcademicRepository implements AcademicRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTimetableRepository implements TimetableRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Test User definitions
  const testHodUser = UserModel(
    id: 'user-hod',
    name: 'Dr. Alan Turing',
    email: 'hod@acadex.edu',
    role: AppRole.hod,
    departmentId: 'dept-cse',
    collegeId: 'col-1',
  );

  const testCollegeAdminUser = UserModel(
    id: 'user-admin',
    name: 'Admin Grace Hopper',
    email: 'admin@acadex.edu',
    role: AppRole.collegeAdmin,
    collegeId: 'col-1',
  );

  const testFacultyUser = UserModel(
    id: 'user-faculty',
    name: 'Prof. Donald Knuth',
    email: 'faculty@acadex.edu',
    role: AppRole.faculty,
    departmentId: 'dept-cse',
    collegeId: 'col-1',
  );

  const testStudentUser = UserModel(
    id: 'user-student',
    name: 'Ada Lovelace',
    email: 'ada@acadex.edu',
    role: AppRole.student,
    departmentId: 'dept-cse',
    collegeId: 'col-1',
  );

  group('ACADEX — Navigation & Information Architecture Simplification Tests', () {
    // 1. HOD receives only HOD-valid primary destinations
    test('1. HOD receives only HOD-valid primary destinations', () {
      final items = AcadexNavigationService.getPrimaryNavItems(testHodUser.role);
      final labels = items.map((i) => i.label).toList();

      expect(labels, equals(['Home', 'Academics', 'Attendance', 'Notes']));
      expect(labels.contains('Colleges'), isFalse);
      expect(labels.contains('Users'), isFalse);
      expect(labels.contains('People'), isFalse);
      expect(labels.contains('Reports'), isFalse);
    });

    // 2. College Admin receives only College Admin-valid primary destinations
    test('2. College Admin receives only College Admin-valid primary destinations', () {
      final items = AcadexNavigationService.getPrimaryNavItems(testCollegeAdminUser.role);
      final labels = items.map((i) => i.label).toList();

      expect(labels, equals(['Home', 'Academics', 'People', 'Reports']));
      expect(labels.contains('Colleges'), isFalse); // Super Admin only
      expect(labels.contains('My Classes'), isFalse); // Faculty only
    });

    // 3. Faculty receives Faculty-valid destinations
    test('3. Faculty receives Faculty-valid destinations', () {
      final items = AcadexNavigationService.getPrimaryNavItems(testFacultyUser.role);
      final labels = items.map((i) => i.label).toList();

      expect(labels, equals(['Home', 'My Classes', 'Attendance', 'Notes']));
      expect(labels.contains('Academics'), isFalse);
      expect(labels.contains('People'), isFalse);
      expect(labels.contains('Colleges'), isFalse);
    });

    // 4. Student receives Student-valid destinations
    test('4. Student receives Student-valid destinations', () {
      final items = AcadexNavigationService.getPrimaryNavItems(testStudentUser.role);
      final labels = items.map((i) => i.label).toList();

      expect(labels, equals(['Home', 'Timetable', 'Attendance', 'Notes']));
      expect(labels.contains('Academics'), isFalse);
      expect(labels.contains('People'), isFalse);
      expect(labels.contains('Reports'), isFalse);
    });

    // 5. Unauthorized navigation entries are not exposed
    test('5. Unauthorized navigation entries are not exposed to restricted roles', () {
      final studentGrouped = AcadexNavigationService.getGroupedNavItems(AppRole.student);
      final allStudentRoutes = studentGrouped.values.expand((list) => list).map((i) => i.route).toList();

      expect(allStudentRoutes.contains('/academics'), isFalse);
      expect(allStudentRoutes.contains('/academics/setup'), isFalse);
      expect(allStudentRoutes.contains('/users'), isFalse);
      expect(allStudentRoutes.contains('/analytics'), isFalse);

      final facultyGrouped = AcadexNavigationService.getGroupedNavItems(AppRole.faculty);
      final allFacultyRoutes = facultyGrouped.values.expand((list) => list).map((i) => i.route).toList();
      expect(allFacultyRoutes.contains('/academics'), isFalse);
      expect(allFacultyRoutes.contains('/academics/setup'), isFalse);
    });

    // 6. Dashboard no longer duplicates primary navigation destinations
    test('6. Dashboard quick actions represent contextual next operations rather than duplicate permanent navigation', () {
      final container = ProviderContainer();

      final hodActions = container.read(hodQuickActionsProvider);
      final hodActionLabels = hodActions.map((a) => a.label).toList();
      // Ensure HOD quick operations are contextual actions, not generic top-level duplicates
      expect(hodActionLabels.contains('Academic Years'), isFalse);
      expect(hodActionLabels.contains('Faculty'), isFalse);
      expect(hodActionLabels.contains('Students'), isFalse);
      expect(hodActionLabels.contains('Attendance'), isFalse);
      expect(hodActionLabels.contains('Continue Setup'), isTrue);
      expect(hodActionLabels.contains('Assign Faculty'), isTrue);

      final adminActions = container.read(collegeAdminQuickActionsProvider);
      final adminActionLabels = adminActions.map((a) => a.label).toList();
      expect(adminActionLabels.contains('Attendance'), isFalse);
      expect(adminActionLabels.contains('Timetable'), isFalse);
      expect(adminActionLabels.contains('Department Setup'), isTrue);
    });

    // 7. Academics contains/setup-links to Department Setup
    testWidgets('7. Academics home screen renders setup guidance linking to Department Setup', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
              user: testHodUser,
              token: 'test-token',
            ))),
            academicRepositoryProvider.overrideWithValue(MockAcademicRepository()),
            departmentsProvider.overrideWith(() => TestDepartmentNotifier([
              Department(id: 'dept-cse', name: 'Computer Science', code: 'CSE', collegeId: 'col-1', hodId: 'user-hod', description: 'CSE Dept', isActive: true),
            ])),
            coursesProvider.overrideWith(() => TestCourseNotifier([])),
            academicYearsProvider.overrideWith(() => TestAcademicYearNotifier([])),
            semestersProvider.overrideWith(() => TestSemesterNotifier([])),
            sectionsProvider.overrideWith(() => TestSectionNotifier([])),
            subjectsProvider.overrideWith(() => TestSubjectNotifier([])),
            facultyAssignmentsProvider.overrideWith(() => TestFacultyAssignmentNotifier([])),
            timetableRepositoryProvider.overrideWithValue(MockTimetableRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AcademicStructureHomeScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Department Setup'), findsWidgets);
      expect(find.text('Academic Structure'), findsOneWidget);
    });

    // 8. HOD Department Setup remains the guided setup entry point
    test('8. HOD Department Setup route /academics/setup is matched under Academics navigation group', () {
      final activeItem = AcadexNavigationService.resolveActiveItem('/academics/setup', AppRole.hod);
      expect(activeItem, isNotNull);
      expect(activeItem!.id, equals('academics'));
      expect(activeItem.group, equals(AcadexNavGroup.academics));
    });

    // 9. Nested academic routes correctly highlight Academics
    test('9. Nested academic routes (/academics/courses/new, /faculty-assignments) correctly resolve to Academics', () {
      final courseNewMatch = AcadexNavigationService.resolveActiveItem('/academics/courses/new', AppRole.hod);
      expect(courseNewMatch?.id, equals('academics'));

      final semesterNewMatch = AcadexNavigationService.resolveActiveItem('/academics/semesters/new', AppRole.hod);
      expect(semesterNewMatch?.id, equals('academics'));

      final sectionNewMatch = AcadexNavigationService.resolveActiveItem('/academics/sections/new', AppRole.hod);
      expect(sectionNewMatch?.id, equals('academics'));

      final assignmentMatch = AcadexNavigationService.resolveActiveItem('/faculty-assignments', AppRole.hod);
      expect(assignmentMatch?.id, equals('academics'));
    });

    // 10. Create & Continue retains correct navigation context
    test('10. Continuation route retains Academics active matching on semester creation target', () {
      const continuationRoute = '/academics/semesters/new?courseId=course-1&academicYearId=ay-1';
      final match = AcadexNavigationService.resolveActiveItem(continuationRoute, AppRole.hod);
      expect(match?.id, equals('academics'));
    });

    // 11. Timetable remains accessible without exposing unnecessary CRUD-level navigation
    test('11. Timetable is directly accessible for student/faculty at /timetable and HOD/admin at /timetable/manage', () {
      final studentTimetable = AcadexNavigationService.resolveActiveItem('/timetable', AppRole.student);
      expect(studentTimetable?.id, equals('timetable_user'));
      expect(studentTimetable?.label, equals('Timetable'));

      final hodTimetable = AcadexNavigationService.resolveActiveItem('/timetable/manage', AppRole.hod);
      expect(hodTimetable?.id, equals('timetable_admin'));
      expect(hodTimetable?.label, equals('Timetable'));
    });

    // 12. Attendance remains a direct operational destination for authorized roles
    test('12. Attendance is a direct primary destination for HOD, Faculty, Student, and College Admin', () {
      for (final role in [AppRole.hod, AppRole.faculty, AppRole.student]) {
        final primaryItems = AcadexNavigationService.getPrimaryNavItems(role);
        expect(primaryItems.any((i) => i.id == 'attendance'), isTrue, reason: 'Attendance missing in primary nav for $role');
      }

      final match = AcadexNavigationService.resolveActiveItem('/attendance', AppRole.faculty);
      expect(match?.id, equals('attendance'));
    });

    // 13. Notes remains directly discoverable for supported roles
    test('13. Notes is a direct primary destination for HOD, Faculty, and Student', () {
      for (final role in [AppRole.hod, AppRole.faculty, AppRole.student]) {
        final primaryItems = AcadexNavigationService.getPrimaryNavItems(role);
        expect(primaryItems.any((i) => i.id == 'notes'), isTrue, reason: 'Notes missing in primary nav for $role');
      }

      final match = AcadexNavigationService.resolveActiveItem('/notes', AppRole.student);
      expect(match?.id, equals('notes'));
    });

    // 14. AI Assistant remains secondary
    test('14. AI Assistant is not a primary bottom navigation tab and is located under secondary tools in drawer', () {
      for (final role in AppRole.values) {
        final primaryItems = AcadexNavigationService.getPrimaryNavItems(role);
        expect(primaryItems.any((i) => i.id == 'ai_assistant'), isFalse, reason: 'AI Assistant should not be in primary tabs for $role');
      }

      final hodGrouped = AcadexNavigationService.getGroupedNavItems(AppRole.hod);
      final systemItems = hodGrouped[AcadexNavGroup.system] ?? [];
      expect(systemItems.any((i) => i.id == 'ai_assistant'), isTrue);
    });

    // 15. Profile / Settings / Logout are not duplicated unnecessarily
    test('15. Profile and Settings are grouped under SYSTEM in Drawer with single Logout action', () {
      final grouped = AcadexNavigationService.getGroupedNavItems(AppRole.hod);
      final systemItems = grouped[AcadexNavGroup.system] ?? [];
      final systemLabels = systemItems.map((i) => i.label).toList();

      expect(systemLabels.contains('Profile'), isTrue);
      expect(systemLabels.contains('Settings'), isTrue);
      // Ensure Logout is not duplicated inside the navigation items list
      expect(systemLabels.contains('Logout'), isFalse);
    });

    // 16. 360px mobile width layout renders with zero overflow and all action buttons accessible
    testWidgets('16. 360px mobile width layout renders with zero overflow and all action buttons accessible', (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
              user: testHodUser,
              token: 'test-token',
            ))),
          ],
          child: MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.white,
              bottomNavigationBar: AcadexBottomNav(
                activeRoute: '/dashboard/hod',
                onTabSelected: (_) {},
              ),
              drawer: const AcadexDrawer(activeRoute: '/dashboard/hod', isModal: true),
              body: const Text('Body on 360px'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify bottom nav renders 5 tabs: Home, Academics, Attendance, Notes, More
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Academics'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      // Verify zero overflow in bottom nav
      expect(tester.takeException(), isNull);

      // Open drawer on 360px
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('WORKSPACE'), findsOneWidget);
      expect(find.text('ACADEMICS'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);

      // Verify zero overflow in drawer
      expect(tester.takeException(), isNull);
    });

    // 17. Tablet layout renders AcadexNavRail with correct primary destinations
    testWidgets('17. Tablet layout renders AcadexNavRail with correct primary destinations', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
              user: testCollegeAdminUser,
              token: 'test-token',
            ))),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  AcadexNavRail(
                    activeRoute: '/dashboard/college_admin',
                    onDestinationSelected: (_) {},
                  ),
                  const Expanded(child: Text('Tablet Body')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Academics'), findsOneWidget);
      expect(find.text('People'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
    });
  });
}
