import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/calendar/domain/models/calendar_event_model.dart';
import 'package:campus_management/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:campus_management/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:campus_management/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:campus_management/features/dashboard/domain/models/home_dashboard_models.dart';
import 'package:campus_management/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:campus_management/features/dashboard/presentation/screens/hod_dashboard.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/presentation/screens/academic_structure_home_screen.dart';
import 'package:campus_management/core/providers/pagination_provider.dart';
import 'package:campus_management/features/institution_config/domain/models/institution_config_models.dart';
import 'package:campus_management/features/institution_config/presentation/providers/institution_config_providers.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingCalendarRepository implements CalendarRepository {
  int callCount = 0;
  bool shouldFail = true;

  @override
  Future<List<CalendarEventModel>> getCalendar({
    String? startDate,
    String? endDate,
    String? eventType,
  }) async {
    callCount++;
    if (shouldFail) {
      throw Exception('DioException [receive timeout]: Connection timed out after 30000ms');
    }
    return [
      const CalendarEventModel(
        id: 'recovered_event_1',
        title: 'Recovered Seminar',
        startDate: '2026-09-24',
        endDate: '2026-09-24',
        sourceType: CalendarSourceType.manual,
        eventType: CalendarEventType.event,
        scope: CalendarEventScope.college,
        status: CalendarEventStatus.published,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

HomeDashboardModel _createMockHodDashboard() {
  return const HomeDashboardModel(
    role: 'HOD',
    greeting: DashboardGreetingModel(
      displayName: 'Dr. Grace Hopper',
      role: 'HOD',
      greetingText: 'Good morning',
    ),
    context: DashboardContextModel(
      departmentName: 'Computer Science and Engineering',
      departmentCode: 'CSE',
      collegeName: 'Apex Institute of Technology',
    ),
    summary: DashboardSummaryModel(
      attendancePercentage: 88.0,
      facultyCount: 14,
      activeFacultyCount: 14,
      studentsCount: 240,
      activeStudentsCount: 240,
      pendingRequestsCount: 1,
      pendingAttendanceCount: 0,
      systemStatus: 'OPERATIONAL',
    ),
    alerts: [],
    quickActions: [
      DashboardQuickActionModel(
        id: 'qa_alloc',
        label: 'Allocate Faculty',
        route: '/academic/faculty-assignments',
        icon: 'userCheck',
        isPrimary: true,
      ),
      DashboardQuickActionModel(
        id: 'qa_tt',
        label: 'Timetable',
        route: '/timetable',
        icon: 'calendar',
      ),
    ],
    pendingActions: [],
    upcoming: [],
    recent: [],
  );
}

class _TestFacultyAssignmentsNotifier extends AutoDisposeAsyncNotifier<List<FacultyAssignment>> implements FacultyAssignmentsNotifier {
  final List<FacultyAssignment> items;
  _TestFacultyAssignmentsNotifier(this.items);

  @override
  Future<List<FacultyAssignment>> build() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestDepartmentNotifier extends AutoDisposeAsyncNotifier<List<Department>> implements DepartmentNotifier {
  final List<Department> items;
  _TestDepartmentNotifier(this.items);

  @override
  Future<List<Department>> build() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestCourseNotifier extends AutoDisposeAsyncNotifier<List<Course>> implements CourseNotifier {
  final List<Course> items;
  _TestCourseNotifier(this.items);

  @override
  Future<List<Course>> build() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestSemesterNotifier extends AutoDisposeAsyncNotifier<List<Semester>> implements SemesterNotifier {
  final List<Semester> items;
  _TestSemesterNotifier(this.items);

  @override
  Future<List<Semester>> build() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestSectionNotifier extends AutoDisposeAsyncNotifier<List<Section>> implements SectionNotifier {
  final List<Section> items;
  _TestSectionNotifier(this.items);

  @override
  Future<List<Section>> build() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestSubjectNotifier extends AutoDisposeAsyncNotifier<List<Subject>> implements SubjectNotifier {
  final List<Subject> items;
  _TestSubjectNotifier(this.items);

  @override
  Future<List<Subject>> build() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestFacultyNotifier extends StateNotifier<PaginatedState<Faculty>> implements FacultyNotifier {
  _TestFacultyNotifier(List<Faculty> items)
      : super(PaginatedState<Faculty>(items: items, isLoading: false, hasReachedMax: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testHodUser = UserModel(
    id: 'hod_user_1',
    email: 'hod@coea.edu',
    name: 'Dr. Grace Hopper',
    role: AppRole.hod,
    collegeId: 'college_01',
    departmentId: 'dept_cme',
  );

  group('PROMPT 5.1 — Academic Calendar Forensic Recovery & State Decoupling', () {
    testWidgets('A & B. Main calendar date grid stays rendered when event loading times out / fails', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final failingRepo = _FailingCalendarRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(const AuthAuthenticated(user: testHodUser, token: 'jwt')),
            ),
            calendarRepositoryProvider.overrideWithValue(failingRepo),
            selectedCalendarDateProvider.overrideWith((ref) => DateTime(2026, 9, 24)),
            currentMonthProvider.overrideWith((ref) => DateTime(2026, 9, 1)),
          ],
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Title and month header remain rendered
      expect(find.text('Academic Calendar'), findsOneWidget);
      expect(find.text('September 2026'), findsOneWidget);

      // 2. Weekday row labels remain rendered
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);

      // 3. Complete month date grid remains visible (September 1-30)
      expect(find.text('1'), findsWidgets);
      expect(find.text('15'), findsWidgets);
      expect(find.text('24'), findsWidgets);
      expect(find.text('30'), findsWidgets);

      // 4. Clean error message in event region; no technical DioException or stack trace
      expect(find.textContaining('Unable to load events'), findsOneWidget);
      expect(find.textContaining('DioException'), findsNothing);
      expect(find.textContaining('receive timeout'), findsNothing);
      expect(find.textContaining('30000ms'), findsNothing);

      // 5. Try Again button is present
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('D. Month navigation changes month and updates date grid while remaining visible', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final failingRepo = _FailingCalendarRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(const AuthAuthenticated(user: testHodUser, token: 'jwt')),
            ),
            calendarRepositoryProvider.overrideWithValue(failingRepo),
            selectedCalendarDateProvider.overrideWith((ref) => DateTime(2026, 9, 24)),
            currentMonthProvider.overrideWith((ref) => DateTime(2026, 9, 1)),
          ],
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);

      // Tap Next Month chevron (lucide chevronRight)
      final nextBtn = find.byTooltip('Next Month');
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Month header updates to October 2026
      expect(find.text('October 2026'), findsOneWidget);
      // October has 31 days
      expect(find.text('31'), findsWidgets);

      // Tap Previous Month twice to go back to August 2026
      final prevBtn = find.byTooltip('Previous Month');
      expect(prevBtn, findsOneWidget);
      await tester.tap(prevBtn);
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);

      await tester.tap(prevBtn);
      await tester.pumpAndSettle();
      expect(find.text('August 2026'), findsOneWidget);
    });

    testWidgets('E & F. Date selection updates selected date in state and detail header', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final failingRepo = _FailingCalendarRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(const AuthAuthenticated(user: testHodUser, token: 'jwt')),
            ),
            calendarRepositoryProvider.overrideWithValue(failingRepo),
            selectedCalendarDateProvider.overrideWith((ref) => DateTime(2026, 9, 24)),
            currentMonthProvider.overrideWith((ref) => DateTime(2026, 9, 1)),
          ],
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('24 September 2026'), findsOneWidget);

      // Tap on day '10'
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('10 September 2026'), findsOneWidget);
    });

    testWidgets('H. Event retry reloads events and preserves calendar grid', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _FailingCalendarRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(const AuthAuthenticated(user: testHodUser, token: 'jwt')),
            ),
            calendarRepositoryProvider.overrideWithValue(repo),
            selectedCalendarDateProvider.overrideWith((ref) => DateTime(2026, 9, 24)),
            currentMonthProvider.overrideWith((ref) => DateTime(2026, 9, 1)),
          ],
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('Unable to load events'), findsOneWidget);

      // Now set repo to succeed on retry
      repo.shouldFail = false;
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      // Recovered event appears
      expect(find.text('Recovered Seminar'), findsWidgets);
      // Calendar date grid is still intact
      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('24'), findsWidgets);
    });
  });

  group('PROMPT 5.1 — HOD Dashboard & Content-Driven Teaching Allocations', () {
    testWidgets('I & J. Allocation cards render compactly with content-driven height', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockDashboard = _createMockHodDashboard();

      final mockSubject1 = Subject(
        id: 'sub_1',
        collegeId: 'college_01',
        departmentId: 'dept_cme',
        courseId: 'course_1',
        semesterId: 'sem_1',
        name: 'Maths',
        code: 'CM-101',
      );

      final mockSubject2 = Subject(
        id: 'sub_2',
        collegeId: 'college_01',
        departmentId: 'dept_cme',
        courseId: 'course_1',
        semesterId: 'sem_3',
        name: 'Data Structures',
        code: 'CS-201',
      );

      final mockSectionA = Section(
        id: 'sec_1',
        collegeId: 'college_01',
        departmentId: 'dept_cme',
        courseId: 'course_1',
        academicYearId: 'ay_1',
        semesterId: 'sem_1',
        name: 'Sec A',
      );

      final mockSectionB = Section(
        id: 'sec_2',
        collegeId: 'college_01',
        departmentId: 'dept_cme',
        courseId: 'course_1',
        academicYearId: 'ay_1',
        semesterId: 'sem_3',
        name: 'Sec B',
      );

      final List<FacultyAssignment> mockAssignments = [
        FacultyAssignment(
          id: 'fa_1',
          collegeId: 'college_01',
          facultyId: 'fac_1',
          facultyName: 'S Kalyan',
          subjectId: 'sub_1',
          sectionId: 'sec_1',
          semesterId: 'sem_1',
          academicYearId: 'ay_1',
          courseId: 'course_1',
          departmentId: 'dept_cme',
          isActive: true,
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 1),
        ),
        FacultyAssignment(
          id: 'fa_2',
          collegeId: 'college_01',
          facultyId: 'fac_2',
          facultyName: 'Dr. Alan Turing',
          subjectId: 'sub_2',
          sectionId: 'sec_2',
          semesterId: 'sem_3',
          academicYearId: 'ay_1',
          courseId: 'course_1',
          departmentId: 'dept_cme',
          isActive: true,
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 1),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(const AuthAuthenticated(user: testHodUser, token: 'jwt')),
            ),
            homeDashboardProvider.overrideWith((ref) async => mockDashboard),
            facultyAssignmentsProvider.overrideWith(
              () => _TestFacultyAssignmentsNotifier(mockAssignments),
            ),
            subjectsProvider.overrideWith(
              () => _TestSubjectNotifier([mockSubject1, mockSubject2]),
            ),
            sectionsProvider.overrideWith(
              () => _TestSectionNotifier([mockSectionA, mockSectionB]),
            ),
          ],
          child: const MaterialApp(
            home: HodDashboard(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify allocation section rendered
      expect(find.text('Faculty Teaching Allocations'), findsOneWidget);
      expect(find.text('S Kalyan'), findsOneWidget);
      expect(find.text('Sec A'), findsOneWidget);
      expect(find.text('Maths'), findsOneWidget);
      expect(find.text('CM-101'), findsOneWidget);

      expect(find.text('Dr. Alan Turing'), findsOneWidget);
      expect(find.text('Sec B'), findsOneWidget);
      expect(find.text('Data Structures'), findsOneWidget);
      expect(find.text('CS-201'), findsOneWidget);

      // Verify Quick Operations is rendered directly below allocations without giant gap
      expect(find.text('Quick Operations'), findsOneWidget);
      expect(find.text('Allocate Faculty'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });

  group('PROMPT 5.1 — Academic Structure Layout & Compact Header/Stats', () {
    testWidgets('K & L. Department Setup and Create Branch render side-by-side without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640); // narrow mobile
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testDept = Department(
        id: 'dept_cme',
        collegeId: 'college_01',
        hodId: 'hod_user_1',
        name: 'Computer Engineering',
        code: 'CME',
        description: 'Computer Engineering Department',
      );

      final testCourse = Course(
        id: 'course_1',
        collegeId: 'college_01',
        departmentId: 'dept_cme',
        name: 'B.Tech CSE',
        code: 'BTCSE',
        duration: 4,
      );

      final testSemester = Semester(
        id: 'sem_1',
        collegeId: 'college_01',
        departmentId: 'dept_cme',
        courseId: 'course_1',
        academicYearId: 'ay_1',
        number: 1,
        name: 'Semester 1',
      );

      final testSection = Section(
        id: 'sec_1',
        collegeId: 'college_01',
        departmentId: 'dept_cme',
        courseId: 'course_1',
        academicYearId: 'ay_1',
        semesterId: 'sem_1',
        name: 'A',
      );

      final testSubject = Subject(
        id: 'sub_1',
        collegeId: 'college_01',
        departmentId: 'dept_cme',
        courseId: 'course_1',
        semesterId: 'sem_1',
        name: 'Mathematics I',
        code: 'MATH101',
      );

      final testFaculty = Faculty(
        id: 'fac_1',
        collegeId: 'college_01',
        departmentId: 'dept_cme',
        employeeId: 'EMP-01',
        name: 'Dr. Alan Turing',
        email: 'turing@coea.edu',
        phone: '1234567890',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(const AuthAuthenticated(user: testHodUser, token: 'jwt')),
            ),
            terminologyProvider.overrideWithValue(
              const TerminologyHelper(
                InstitutionConfigModel(
                  collegeId: 'college_01',
                  terminology: TerminologyConfig(
                    program: ConceptTerm(singular: 'Branch', plural: 'Branches'),
                    section: ConceptTerm(singular: 'Class', plural: 'Classes'),
                  ),
                ),
              ),
            ),
            departmentsProvider.overrideWith(() => _TestDepartmentNotifier([testDept])),
            coursesProvider.overrideWith(() => _TestCourseNotifier([testCourse])),
            semestersProvider.overrideWith(() => _TestSemesterNotifier([testSemester])),
            sectionsProvider.overrideWith(() => _TestSectionNotifier([testSection])),
            subjectsProvider.overrideWith(() => _TestSubjectNotifier([testSubject])),
            facultyProvider(null).overrideWith((ref) => _TestFacultyNotifier([testFaculty])),
          ],
          child: const MaterialApp(
            home: AcademicStructureHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and both actions rendered
      expect(find.text('Academic Structure'), findsOneWidget);
      expect(find.text('Department Setup'), findsOneWidget);
      expect(find.text('+ Create Branch'), findsOneWidget);

      // Check compact stats deck
      expect(find.text('Faculty'), findsWidgets);
      expect(find.text('Branches'), findsWidgets);
      expect(find.text('Semesters'), findsWidgets);
      expect(find.text('Classes'), findsWidgets);
      expect(find.text('Subjects'), findsWidgets);

      // Verify no exceptions or overflow occurred
      expect(tester.takeException(), isNull);
    });
  });

  group('PROMPT 5.1 — Section 9 HOD Dashboard Hierarchy & 2x2 Metrics Parity', () {
    testWidgets('M. HOD Dashboard renders complete Section 9 hierarchy with 4 operations and 2x2 Department Overview', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const defaultHodDashboard = HomeDashboardModel(
        role: 'HOD',
        greeting: DashboardGreetingModel(
          displayName: 'Dr. Bosu',
          role: 'HOD',
          greetingText: 'Welcome',
        ),
        context: DashboardContextModel(
          departmentName: 'Department of Computer Science & Engineering',
          departmentCode: 'CSE',
          collegeName: 'Apex Institute of Technology',
        ),
        summary: DashboardSummaryModel(
          attendancePercentage: 100.0,
          activeFacultyCount: 14,
          activeStudentsCount: 240,
          systemStatus: 'OPERATIONAL',
        ),
        alerts: [],
        quickActions: [], // Empty defaults to Section 9 4 operations
        pendingActions: [],
        upcoming: [],
        recent: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(const AuthAuthenticated(user: testHodUser, token: 'jwt')),
            ),
            homeDashboardProvider.overrideWith((ref) async => defaultHodDashboard),
            facultyAssignmentsProvider.overrideWith(
              () => _TestFacultyAssignmentsNotifier([]),
            ),
          ],
          child: const MaterialApp(
            home: HodDashboard(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. DashboardGreetingHeader
      expect(find.text('Dr. Bosu'), findsOneWidget);

      // 2. AcadexHeroCard
      expect(find.text('DEPARTMENT HEALTH & OPERATIONS'), findsOneWidget);
      expect(find.text('DEPT: CSE'), findsOneWidget);
      expect(find.text('Department Analytics'), findsOneWidget);
      expect(find.text('Faculty Workload'), findsOneWidget);

      // 3. Quick Operations with Continue Setup and 4 action buttons
      expect(find.text('Quick Operations'), findsOneWidget);
      expect(find.text('Continue Setup'), findsOneWidget);
      expect(find.text('+ Add Course'), findsOneWidget);
      expect(find.text('+ Add Subject'), findsOneWidget);
      expect(find.text('+ Add Student'), findsOneWidget);
      expect(find.text('Assign Faculty'), findsWidgets);

      // 4. Department Overview with 4 distinct metrics in 2x2 grid
      expect(find.text('Department Overview'), findsOneWidget);
      expect(find.text('Department Faculty'), findsOneWidget);
      expect(find.text('Department Students'), findsOneWidget);
      expect(find.text('Department Subjects'), findsOneWidget);
      expect(find.text('Department Attendance'), findsOneWidget);

      // 5. Today's Department Timetable
      expect(find.text("Today's Department Timetable"), findsOneWidget);
      expect(find.text('View Timetable'), findsOneWidget);

      // 6. Faculty Teaching Allocations with Manage All
      expect(find.text('Faculty Teaching Allocations'), findsOneWidget);
      expect(find.text('Manage All'), findsOneWidget);

      // No overflows or exceptions
      expect(tester.takeException(), isNull);
    });
  });
}

