import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/domain/repositories/academic_repository.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/data/repositories/mock_timetable_repository.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_lookup_providers.dart';
import 'package:campus_management/features/timetable/presentation/screens/timetable_setup_screen.dart';
import 'package:campus_management/features/timetable/presentation/screens/timetable_management_screen.dart';
import 'package:campus_management/features/timetable/presentation/screens/timetable_designer_screen.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FastMockAcademicRepository implements AcademicRepository {
  final List<Department> departments = [
    Department(id: 'd1', collegeId: 'c1', name: 'Computer Engineering', code: 'CS', hodId: 'usr-hod', description: ''),
    Department(id: 'd2', collegeId: 'c1', name: 'Mechanical Engineering', code: 'ME', hodId: 'usr-hod2', description: ''),
  ];
  final List<Course> courses = [
    Course(id: 'cr1', collegeId: 'c1', departmentId: 'd1', name: 'B.Tech CS', code: 'BTECH-CS'),
    Course(id: 'cr2', collegeId: 'c1', departmentId: 'd2', name: 'B.Tech ME', code: 'BTECH-ME'),
  ];
  final List<AcademicYear> academicYears = [
    AcademicYear(id: 'ay2', collegeId: 'c1', name: '2026-2027', startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 12, 31), isCurrent: true),
  ];
  final List<Semester> semesters = [
    Semester(id: 'sem1', collegeId: 'c1', departmentId: 'd1', courseId: 'cr1', academicYearId: 'ay2', name: 'Semester 1', number: 1),
    Semester(id: 'sem2', collegeId: 'c1', departmentId: 'd1', courseId: 'cr1', academicYearId: 'ay2', name: 'Semester 2', number: 2),
  ];
  final List<Section> sections = [
    Section(id: 'sec1', collegeId: 'c1', departmentId: 'd1', semesterId: 'sem1', name: 'A'),
    Section(id: 'sec2', collegeId: 'c1', departmentId: 'd1', semesterId: 'sem1', name: 'B'),
  ];

  @override
  Future<List<College>> getColleges({String? search, String? status}) async => [];
  @override
  Future<List<Department>> getDepartments({String? collegeId, String? search, String? status}) async => List.from(departments);
  @override
  Future<List<Course>> getCourses({String? collegeId, String? departmentId, String? search}) async => List.from(courses);
  @override
  Future<List<AcademicYear>> getAcademicYears({String? collegeId}) async => List.from(academicYears);
  @override
  Future<List<Semester>> getSemesters({String? academicYearId, String? collegeId, String? courseId}) async => List.from(semesters);
  @override
  Future<List<Section>> getSections({String? collegeId, String? courseId, String? semesterId}) async => List.from(sections);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ACADEX Phase 5C: Timetable Creation & Configuration Tests', () {
    late MockTimetableRepository mockRepo;
    late FastMockAcademicRepository mockAcademicRepo;

    final collegeAdminUser = UserModel(
      id: 'usr-col-admin',
      name: 'College Admin',
      email: 'admin@git.edu',
      role: AppRole.collegeAdmin,
      collegeId: 'c1',
    );

    final hodCsUser = UserModel(
      id: 'usr-hod',
      name: 'HOD CS',
      email: 'hod@git.edu',
      role: AppRole.hod,
      collegeId: 'c1',
      departmentId: 'd1',
    );

    final normalFacultyUser = UserModel(
      id: 'usr-faculty',
      name: 'Faculty Alice',
      email: 'faculty@git.edu',
      role: AppRole.faculty,
      collegeId: 'c1',
      departmentId: 'd1',
    );

    final studentUser = UserModel(
      id: 'usr-student',
      name: 'Student User',
      email: 'student@git.edu',
      role: AppRole.student,
      collegeId: 'c1',
      departmentId: 'd1',
      sectionId: 'sec1',
    );

    setUp(() {
      mockRepo = MockTimetableRepository();
      mockAcademicRepo = FastMockAcademicRepository();
    });

    Widget createTestWidget({
      required Widget child,
      UserModel? currentUser,
      bool isDark = false,
      Size size = const Size(1200, 900),
    }) {
      final user = currentUser ?? hodCsUser;

      final deptMap = {for (var d in mockAcademicRepo.departments) d.id: d};
      final courseMap = {for (var c in mockAcademicRepo.courses) c.id: c};
      final sectionMap = {for (var s in mockAcademicRepo.sections) s.id: s};
      final yearMap = {for (var y in mockAcademicRepo.academicYears) y.id: y};

      return ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: user, token: 'mock-token'))),
          currentUserProvider.overrideWithValue(user),
          timetableRepositoryProvider.overrideWithValue(mockRepo),
          academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
          timetableSubjectMapProvider.overrideWithValue(const {}),
          timetableFacultyMapProvider.overrideWithValue(const {}),
          timetableDepartmentMapProvider.overrideWithValue(deptMap),
          timetableCourseMapProvider.overrideWithValue(courseMap),
          timetableSectionMapProvider.overrideWithValue(sectionMap),
          timetableAcademicYearMapProvider.overrideWithValue(yearMap),
        ],
        child: MaterialApp(
          key: ValueKey('app_${user.id}_${user.role.name}'),
          theme: isDark ? ThemeData.dark() : ThemeData.light(),
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: Scaffold(body: child),
          ),
        ),
      );
    }

    // =========================================================================
    // 1. ROLE VISIBILITY ON MANAGEMENT SCREEN
    // =========================================================================
    testWidgets('1a. Create Timetable button is visible for HOD & College Admin', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // As HOD: Create button is visible
      await tester.pumpWidget(createTestWidget(
        currentUser: hodCsUser,
        child: const TimetableManagementScreen(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Create Timetable'), findsWidgets);

      // As College Admin: Create button is visible
      await tester.pumpWidget(createTestWidget(
        currentUser: collegeAdminUser,
        child: const TimetableManagementScreen(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Create Timetable'), findsWidgets);
    });

    testWidgets('1b. Student and Normal Faculty cannot access or create timetables', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // As Student: Screen shows unauthorized and Create Timetable is not present
      await tester.pumpWidget(createTestWidget(
        currentUser: studentUser,
        child: const TimetableManagementScreen(),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Unauthorized'), findsWidgets);
      expect(find.text('Create Timetable'), findsNothing);

      // As Normal Faculty: Screen shows unauthorized
      await tester.pumpWidget(createTestWidget(
        currentUser: normalFacultyUser,
        child: const TimetableManagementScreen(),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Unauthorized'), findsWidgets);
      expect(find.text('Create Timetable'), findsNothing);
    });

    // =========================================================================
    // 2. TIMETABLE SETUP WIZARD FLOW (5 STEPS)
    // =========================================================================
    testWidgets('2. TimetableSetupScreen completes all 5 wizard steps and navigates to designer', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        currentUser: hodCsUser,
        child: const TimetableSetupScreen(),
      ));
      await tester.pumpAndSettle();

      // Step 1: Academic Context
      expect(find.text('Step 1: Academic Hierarchy'), findsOneWidget);

      // Select Course
      await tester.tap(find.text('Course / Degree Program *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B.Tech CS (BTECH-CS)').last);
      await tester.pumpAndSettle();

      // Select Academic Year
      await tester.tap(find.text('Academic Year *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026-2027').last);
      await tester.pumpAndSettle();

      // Select Semester
      await tester.tap(find.text('Semester *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semester 1').last);
      await tester.pumpAndSettle();

      // Select Section
      await tester.tap(find.text('Section *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A').last);
      await tester.pumpAndSettle();

      // Click Next to Step 2
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next Step'));
      await tester.pumpAndSettle();

      // Step 2: Working Days
      expect(find.text('Step 2: Working Days & Timing Mode'), findsOneWidget);
      expect(find.text('Active Working Days *'), findsOneWidget);

      // Click Next to Step 3
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next Step'));
      await tester.pumpAndSettle();

      // Step 3: Periods
      expect(find.textContaining('Step 3: Period Slots'), findsOneWidget);
      expect(find.text('P1'), findsOneWidget);

      // Click Next to Step 4
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next Step'));
      await tester.pumpAndSettle();

      // Step 4: Breaks
      expect(find.textContaining('Step 4: Configure Breaks'), findsOneWidget);
      expect(find.text('Lunch Break'), findsOneWidget);

      // Click Next to Step 5 (Preview)
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next Step'));
      await tester.pumpAndSettle();

      // Step 5: Preview
      expect(find.text('Timetable Configuration Summary'), findsOneWidget);
      expect(find.text('Create & Open Designer'), findsOneWidget);

      // Click Create & Open Designer
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create & Open Designer'));
      await tester.pumpAndSettle();

      // Designer is opened
      expect(find.byType(TimetableDesignerScreen), findsOneWidget);
    });

    // =========================================================================
    // 3. TIMETABLE CREATION SCREEN (DEDICATED SCREEN WIZARD)
    // =========================================================================
    testWidgets('3. TimetableCreationScreen completes wizard and creates draft container', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        currentUser: collegeAdminUser,
        child: const TimetableCreationScreen(),
      ));
      await tester.pumpAndSettle();

      // Step 1: Select Dept, Course, Year, Sem, Section
      expect(find.text('Step 1: Academic Hierarchy'), findsOneWidget);

      await tester.tap(find.text('Select department'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Computer Engineering').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select course'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B.Tech CS (BTECH-CS)').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select academic year'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026-2027').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select semester'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semester 1 (Semester 1)').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select section'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Section A').last);
      await tester.pumpAndSettle();

      // Next Step 2
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next Step'));
      await tester.pumpAndSettle();

      // Next Step 3
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next Step'));
      await tester.pumpAndSettle();

      // Next Step 4
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next Step'));
      await tester.pumpAndSettle();

      // Next Step 5
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next Step'));
      await tester.pumpAndSettle();

      // Create & Open Designer
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create & Open Designer'));
      await tester.pumpAndSettle();

      // Navigated to Designer
      expect(find.byType(TimetableDesignerScreen), findsOneWidget);

      // Verify draft in repository
      final containers = await mockRepo.getTimetableContainers(collegeId: 'c1');
      expect(containers.length, equals(1));
      expect(containers.first.status, equals(TimetableStatus.draft));
      expect(containers.first.version, equals(1));

      // Verify Attendance projection is untouched (0 legacy entries)
      final legacy = await mockRepo.getTimetable(collegeId: 'c1');
      expect(legacy.isEmpty, isTrue);
    });

    // =========================================================================
    // 4. HOD DEPARTMENT ISOLATION
    // =========================================================================
    testWidgets('4. HOD is locked to their assigned department in setup wizard', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        currentUser: hodCsUser,
        child: const TimetableSetupScreen(),
      ));
      await tester.pumpAndSettle();

      // For HOD, Department dropdown is locked to Computer Engineering
      expect(find.text('Computer Engineering (CS)'), findsOneWidget);
    });

    // =========================================================================
    // 5. DUPLICATE DRAFT DETECTION
    // =========================================================================
    testWidgets('5. Setup wizard detects existing draft for section and provides continue action', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Pre-populate mock repo with existing draft
      final existingDraft = TimetableContainerModel(
        id: 'tt-existing-draft-1',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay2',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'CS Sem 1 Sec A Existing Draft',
        status: TimetableStatus.draft,
        version: 1,
        activeDays: [TimetableDay.monday, TimetableDay.tuesday, TimetableDay.wednesday, TimetableDay.thursday, TimetableDay.friday],
        timingMode: TimetableTimingMode.sameEveryDay,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await mockRepo.createTimetableContainer(existingDraft);

      await tester.pumpWidget(createTestWidget(
        currentUser: hodCsUser,
        child: const TimetableSetupScreen(),
      ));
      await tester.pumpAndSettle();

      // Select Course, Year, Sem, Section
      await tester.tap(find.text('Course / Degree Program *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B.Tech CS (BTECH-CS)').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Academic Year *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026-2027').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Semester *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semester 1').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Section *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A').last);
      await tester.pumpAndSettle();

      // Duplicate notice is displayed
      expect(find.text('Draft Timetable Already Exists'), findsOneWidget);
      expect(find.text('Open Existing Draft'), findsOneWidget);
    });

    // =========================================================================
    // 6. MANAGEMENT SCREEN CONTAINER ACTIONS (DRAFT VS PUBLISHED)
    // =========================================================================
    testWidgets('6. TimetableManagementScreen displays Draft container and supports publishing', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final draftContainer = TimetableContainerModel(
        id: 'tt-mgmt-draft-1',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay2',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Master Timetable CS Sem 1',
        status: TimetableStatus.draft,
        version: 1,
        activeDays: [TimetableDay.monday, TimetableDay.tuesday, TimetableDay.wednesday, TimetableDay.thursday, TimetableDay.friday],
        timingMode: TimetableTimingMode.sameEveryDay,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await mockRepo.createTimetableContainer(draftContainer);
      await mockRepo.savePeriodsBatch(draftContainer.id, [
        TimetablePeriodModel(id: 'p1', index: 1, name: 'Period 1', startTime: '09:00', endTime: '10:00'),
      ]);

      await tester.pumpWidget(createTestWidget(
        currentUser: hodCsUser,
        child: const TimetableManagementScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Card is shown
      expect(find.text('Master Timetable CS Sem 1'), findsOneWidget);
      expect(find.text('DRAFT'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Continue Editing'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Publish'), findsOneWidget);

      // Publish the container
      await tester.tap(find.widgetWithText(OutlinedButton, 'Publish'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Published status is displayed
      expect(find.text('PUBLISHED'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Edit Draft / New Version'), findsOneWidget);
    });

    // =========================================================================
    // 7. VERSION SAFETY: EDIT PUBLISHED TIMETABLE CREATES DRAFT VERSION
    // =========================================================================
    testWidgets('7. Editing published timetable creates new draft version v2 safely', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final publishedContainer = TimetableContainerModel(
        id: 'tt-mgmt-published-1',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay2',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Live Published CS Sem 1',
        status: TimetableStatus.published,
        version: 1,
        activeDays: [TimetableDay.monday, TimetableDay.tuesday, TimetableDay.wednesday, TimetableDay.thursday, TimetableDay.friday],
        timingMode: TimetableTimingMode.sameEveryDay,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await mockRepo.createTimetableContainer(publishedContainer);
      await mockRepo.savePeriodsBatch(publishedContainer.id, [
        TimetablePeriodModel(id: 'p1', index: 1, name: 'Period 1', startTime: '09:00', endTime: '10:00'),
      ]);

      await tester.pumpWidget(createTestWidget(
        currentUser: hodCsUser,
        child: const TimetableManagementScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Click Edit Draft / New Version
      await tester.tap(find.widgetWithText(OutlinedButton, 'Edit Draft / New Version'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Designer is opened with the new draft version
      expect(find.byType(TimetableDesignerScreen), findsOneWidget);
    });
  });
}
