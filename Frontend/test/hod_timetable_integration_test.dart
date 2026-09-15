import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/presentation/widgets/fresh_department_setup_card.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_lookup_providers.dart';
import 'package:campus_management/features/timetable/presentation/screens/timetable_management_screen.dart';
import 'package:campus_management/features/timetable/presentation/widgets/timetable_class_editor_dialog.dart';
import 'package:campus_management/features/timetable/data/repositories/mock_timetable_repository.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testHod = UserModel(
    id: 'usr-hod-01',
    name: 'Dr. Alan Turing',
    email: 'hod.cse@alpha.edu',
    role: AppRole.hod,
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
  );

  final testDept = Department(
    id: 'dept-cse',
    collegeId: 'col-alpha',
    name: 'Computer Science and Engineering',
    code: 'CSE',
    hodId: 'usr-hod-01',
    description: 'CSE Department',
    isActive: true,
  );

  final testCourse = Course(
    id: 'course-btech',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    name: 'B.Tech CSE',
    code: 'BT-CSE',
    duration: 4,
    isActive: true,
  );

  final testYear = AcademicYear(
    id: 'ay-2026',
    collegeId: 'col-alpha',
    name: '2026–27',
    startDate: DateTime(2026, 6, 1),
    endDate: DateTime(2027, 5, 31),
    isCurrent: true,
    isActive: true,
  );

  final testSemester = Semester(
    id: 'sem-5',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    courseId: 'course-btech',
    academicYearId: 'ay-2026',
    name: 'Semester 5',
    number: 5,
    status: 'active',
    isCurrent: true,
    isActive: true,
  );

  final testSectionA = Section(
    id: 'sec-5a',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    courseId: 'course-btech',
    academicYearId: 'ay-2026',
    semesterId: 'sem-5',
    name: 'A',
    capacity: 60,
    status: 'active',
    isActive: true,
  );

  final testSubject1 = Subject(
    id: 'sub-dbms',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    courseId: 'course-btech',
    semesterId: 'sem-5',
    name: 'Database Management Systems',
    code: 'CS501',
    credits: 4,
    type: 'Theory',
    isActive: true,
  );

  final testSubject2 = Subject(
    id: 'sub-os',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    courseId: 'course-btech',
    semesterId: 'sem-5',
    name: 'Operating Systems',
    code: 'CS502',
    credits: 4,
    type: 'Theory',
    isActive: true,
  );

  final testFaculty1 = Faculty(
    id: 'fac-turing',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    name: 'Dr. Alan Turing',
    employeeId: 'EMP-001',
    email: 'turing@alpha.edu',
    phone: '555-0101',
    designation: 'Professor & HOD',
    isActive: true,
  );

  final testFaculty2 = Faculty(
    id: 'fac-hopper',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    name: 'Prof. Grace Hopper',
    employeeId: 'EMP-002',
    email: 'hopper@alpha.edu',
    phone: '555-0102',
    designation: 'Associate Professor',
    isActive: true,
  );

  final testAssignment1 = FacultyAssignment(
    id: 'asgn-dbms',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    courseId: 'course-btech',
    academicYearId: 'ay-2026',
    semesterId: 'sem-5',
    sectionId: 'sec-5a',
    subjectId: 'sub-dbms',
    facultyId: 'fac-turing',
    facultyName: 'Dr. Alan Turing',
    assignmentType: 'Theory',
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testAssignment2 = FacultyAssignment(
    id: 'asgn-os',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    courseId: 'course-btech',
    academicYearId: 'ay-2026',
    semesterId: 'sem-5',
    sectionId: 'sec-5a',
    subjectId: 'sub-os',
    facultyId: 'fac-hopper',
    facultyName: 'Prof. Grace Hopper',
    assignmentType: 'Theory',
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testContainerDraft = TimetableContainerModel(
    id: 'tt-cnt-5a',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    courseId: 'course-btech',
    academicYearId: 'ay-2026',
    semesterId: 'sem-5',
    sectionId: 'sec-5a',
    name: 'B.Tech CSE Sem 5 Sec A Timetable',
    status: TimetableStatus.draft,
    version: 1,
    activeDays: [
      TimetableDay.monday,
      TimetableDay.tuesday,
      TimetableDay.wednesday,
      TimetableDay.thursday,
      TimetableDay.friday,
    ],
    timingMode: TimetableTimingMode.sameEveryDay,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testContainerPublished = testContainerDraft.copyWith(
    status: TimetableStatus.published,
  );

  final testPeriods = [
    TimetablePeriodModel(
      id: 'p-1',
      index: 1,
      name: 'Period 1',
      startTime: '09:00',
      endTime: '10:00',
    ),
    TimetablePeriodModel(
      id: 'p-2',
      index: 2,
      name: 'Period 2',
      startTime: '10:00',
      endTime: '11:00',
    ),
  ];

  final testGridEntry = TimetableGridEntryModel(
    id: 'entry-dbms-1',
    dayOfWeek: TimetableDay.monday,
    startPeriodIndex: 1,
    periodSpan: 1,
    startTime: '09:00',
    endTime: '10:00',
    facultyAssignmentId: 'asgn-dbms',
    subjectId: 'sub-dbms',
    facultyId: 'fac-turing',
    roomNumber: 'LH-101',
    building: 'Main Block',
    sessionType: TimetableSessionType.lecture,
  );

  final testModelEntry = TimetableModel(
    id: 'tt-entry-1',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    courseId: 'course-btech',
    academicYearId: 'ay-2026',
    semesterId: 'sem-5',
    sectionId: 'sec-5a',
    dayOfWeek: TimetableDay.monday,
    startTime: '09:00',
    endTime: '10:00',
    facultyAssignmentId: 'asgn-dbms',
    subjectId: 'sub-dbms',
    facultyId: 'fac-turing',
    roomNumber: 'LH-101',
    building: 'Main Block',
    sessionType: TimetableSessionType.lecture,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final List<Override> commonOverrides = [
    authProvider.overrideWith((ref) => MockAuthNotifier(
          const AuthAuthenticated(user: testHod, token: 'jwt-token-xyz'),
        )),
    departmentMapProvider.overrideWithValue({'dept-cse': testDept}),
    courseMapProvider.overrideWithValue({'course-btech': testCourse}),
    academicYearMapProvider.overrideWithValue({'ay-2026': testYear}),
    semesterMapProvider.overrideWithValue({'sem-5': testSemester}),
    sectionMapProvider.overrideWithValue({'sec-5a': testSectionA}),
    subjectMapProvider.overrideWithValue({
      'sub-dbms': testSubject1,
      'sub-os': testSubject2,
    }),
    timetableSubjectMapProvider.overrideWithValue({
      'sub-dbms': testSubject1,
      'sub-os': testSubject2,
    }),
    timetableFacultyMapProvider.overrideWithValue({
      'fac-turing': testFaculty1,
      'fac-hopper': testFaculty2,
    }),
    timetableDepartmentMapProvider.overrideWithValue({'dept-cse': testDept}),
    timetableCourseMapProvider.overrideWithValue({'course-btech': testCourse}),
    timetableSectionMapProvider.overrideWithValue({'sec-5a': testSectionA}),
    timetableAcademicYearMapProvider.overrideWithValue({'ay-2026': testYear}),
    timetableSemesterMapProvider.overrideWithValue({'sem-5': testSemester}),
    coursesProvider.overrideWith(() => TestPopulatedCourseNotifier([testCourse])),
    academicYearsProvider.overrideWith(() => TestPopulatedAcademicYearNotifier([testYear])),
    semestersProvider.overrideWith(() => TestPopulatedSemesterNotifier([testSemester])),
    sectionsProvider.overrideWith(() => TestPopulatedSectionNotifier([testSectionA])),
    subjectsForSemesterProvider('sem-5').overrideWithValue([testSubject1, testSubject2]),
    facultyAssignmentsBySectionProvider('sec-5a').overrideWithValue([testAssignment1, testAssignment2]),
    unassignedSubjectsForSectionProvider((semesterId: 'sem-5', sectionId: 'sec-5a')).overrideWithValue([]),
    sectionActiveEnrollmentCountProvider('sec-5a').overrideWithValue(45),
  ];

  group('ACADEX — HOD Timetable Integration Tests (Prompt 4 of 6)', () {
    testWidgets('1. HodTimetableReadinessCard renders READY FOR TIMETABLE when fully assigned', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonOverrides,
          child: const MaterialApp(
            home: Scaffold(
              body: HodTimetableReadinessCard(
                courseId: 'course-btech',
                academicYearId: 'ay-2026',
                semesterId: 'sem-5',
                sectionId: 'sec-5a',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Academic Readiness Status'), findsOneWidget);
      expect(find.text('READY FOR TIMETABLE'), findsOneWidget);
      expect(find.text('2 Subjects'), findsOneWidget);
      expect(find.text('2 Assigned'), findsOneWidget);
      expect(find.text('0 Unassigned'), findsOneWidget);
      expect(find.text('45 Enrolled'), findsOneWidget);
    });

    testWidgets('2. HodTimetableReadinessCard renders UNASSIGNED badge when subjects lack faculty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonOverrides,
            facultyAssignmentsBySectionProvider('sec-5a').overrideWithValue([testAssignment1]),
            unassignedSubjectsForSectionProvider((semesterId: 'sem-5', sectionId: 'sec-5a')).overrideWithValue([testSubject2]),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: HodTimetableReadinessCard(
                courseId: 'course-btech',
                academicYearId: 'ay-2026',
                semesterId: 'sem-5',
                sectionId: 'sec-5a',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Academic Readiness Status'), findsOneWidget);
      expect(find.text('1 UNASSIGNED'), findsOneWidget);
      expect(find.text('1 Assigned'), findsOneWidget);
      expect(find.text('1 Unassigned'), findsOneWidget);
    });

    testWidgets('3. TimetableClassEditorDialog enforces authoritative FacultyAssignment selection & details', (tester) async {
      final mockRepo = MockTimetableRepository();
      final authoringState = TimetableAuthoringState(
        container: testContainerDraft,
        periods: testPeriods,
        breaks: [],
        entries: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonOverrides,
            timetableAuthoringProvider.overrideWith((ref, id) {
              final notifier = TimetableAuthoringNotifier(repository: mockRepo, currentUser: testHod);
              notifier.state = authoringState;
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TimetableClassEditorDialog(
                timetableId: 'tt-cnt-5a',
                day: TimetableDay.monday,
                startPeriodIndex: 1,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Add Class'), findsWidgets);
      expect(find.text('Faculty Assignment *'), findsOneWidget);
      expect(find.text('Select Faculty Assignment'), findsOneWidget);

      // Select assignment
      await tester.tap(find.text('Select Faculty Assignment'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.textContaining('Database Management Systems (CS501) — Dr. Alan Turing'), findsWidgets);
      await tester.tap(find.textContaining('Database Management Systems (CS501) — Dr. Alan Turing').last);
      await tester.pumpAndSettle();

      // Verify Authoritative Summary is displayed
      expect(find.text('Authoritative Assignment Summary'), findsOneWidget);
      expect(find.textContaining('Database Management Systems'), findsWidgets);
      expect(find.textContaining('Dr. Alan Turing'), findsWidgets);
      expect(find.text('Section:'), findsOneWidget);
      expect(find.text('Course:'), findsOneWidget);
    });

    testWidgets('4. FreshDepartmentSetupCard renders Step 8 (Create) and Step 9 (Publish Timetable)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FreshDepartmentSetupCard(
              currentStep: AcademicSetupStep.timetable,
              onAction: () {},
              actionLabel: 'Create Master Timetable',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Timetable'), findsWidgets);
      expect(find.text('Publish Timetable'), findsWidgets);
      expect(find.text('Create Master Timetable'), findsOneWidget);
    });

    testWidgets('5. TimetableManagementScreen renders filters and section timetable with draft badge', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockTimetableRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonOverrides,
            timetableFilterProvider.overrideWith((ref) => TimetableFilterState(
                  courseId: 'course-btech',
                  academicYearId: 'ay-2026',
                  semesterId: 'sem-5',
                  sectionId: 'sec-5a',
                )),
            managementContainersProvider.overrideWith((ref) async => [testContainerDraft]),
            managementTimetableProvider.overrideWith((ref) async => [testModelEntry]),
            timetableAuthoringProvider.overrideWith((ref, id) {
              final notifier = TimetableAuthoringNotifier(repository: mockRepo, currentUser: testHod);
              notifier.state = TimetableAuthoringState(
                container: testContainerDraft,
                periods: testPeriods,
                breaks: [],
                entries: [testGridEntry],
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: TimetableManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Filters and Readiness card
      expect(find.text('Academic Readiness Status'), findsOneWidget);
      expect(find.text('READY FOR TIMETABLE'), findsOneWidget);

      // Section Container details
      expect(find.text('B.Tech CSE Sem 5 Sec A Timetable'), findsOneWidget);
      expect(find.text('DRAFT'), findsWidgets);
      expect(find.text('Publish'), findsOneWidget);

      // Scheduled slot
      expect(find.textContaining('Database Management Systems'), findsWidgets);
      expect(find.textContaining('Dr. Alan Turing'), findsWidgets);
      expect(find.textContaining('LH-101'), findsWidgets);
    });

    testWidgets('6. TimetableManagementScreen handles published state with unpublish action', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockTimetableRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonOverrides,
            timetableFilterProvider.overrideWith((ref) => TimetableFilterState(
                  courseId: 'course-btech',
                  academicYearId: 'ay-2026',
                  semesterId: 'sem-5',
                  sectionId: 'sec-5a',
                )),
            managementContainersProvider.overrideWith((ref) async => [testContainerPublished]),
            managementTimetableProvider.overrideWith((ref) async => []),
            timetableAuthoringProvider.overrideWith((ref, id) {
              final notifier = TimetableAuthoringNotifier(repository: mockRepo, currentUser: testHod);
              notifier.state = TimetableAuthoringState(
                container: testContainerPublished,
                periods: testPeriods,
                breaks: [],
                entries: [testGridEntry],
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: TimetableManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('PUBLISHED'), findsWidgets);
      expect(find.text('Unpublish'), findsOneWidget);
    });

    testWidgets('7. Responsive viewports & text scale factors on TimetableManagementScreen (360dp, 390dp, 412dp)', (tester) async {
      final mockRepo = MockTimetableRepository();
      final viewports = [
        const Size(360, 640),
        const Size(390, 844),
        const Size(412, 915),
      ];
      final textScales = [1.0, 1.15, 1.25];

      for (final size in viewports) {
        for (final scale in textScales) {
          tester.view.physicalSize = Size(size.width * 2.0, size.height * 2.0);
          tester.view.devicePixelRatio = 2.0;

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                ...commonOverrides,
                timetableFilterProvider.overrideWith((ref) => TimetableFilterState(
                      courseId: 'course-btech',
                      academicYearId: 'ay-2026',
                      semesterId: 'sem-5',
                      sectionId: 'sec-5a',
                    )),
                managementContainersProvider.overrideWith((ref) async => [testContainerDraft]),
                managementTimetableProvider.overrideWith((ref) async => [testModelEntry]),
                timetableAuthoringProvider.overrideWith((ref, id) {
                  final notifier = TimetableAuthoringNotifier(repository: mockRepo, currentUser: testHod);
                  notifier.state = TimetableAuthoringState(
                    container: testContainerDraft,
                    periods: testPeriods,
                    breaks: [],
                    entries: [testGridEntry],
                  );
                  return notifier;
                }),
              ],
              child: MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: const TimetableManagementScreen(),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Academic Readiness Status'), findsOneWidget);
          expect(find.text('Publish'), findsOneWidget);
        }
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}

// ── Test Notifiers ──────────────────────────────────────────────────────────

class TestPopulatedCourseNotifier extends AutoDisposeAsyncNotifier<List<Course>> implements CourseNotifier {
  final List<Course> items;
  TestPopulatedCourseNotifier(this.items);

  @override
  Future<List<Course>> build() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestPopulatedAcademicYearNotifier extends AutoDisposeAsyncNotifier<List<AcademicYear>> implements AcademicYearNotifier {
  final List<AcademicYear> items;
  TestPopulatedAcademicYearNotifier(this.items);

  @override
  Future<List<AcademicYear>> build() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestPopulatedSemesterNotifier extends AutoDisposeAsyncNotifier<List<Semester>> implements SemesterNotifier {
  final List<Semester> items;
  TestPopulatedSemesterNotifier(this.items);

  @override
  Future<List<Semester>> build() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestPopulatedSectionNotifier extends AutoDisposeAsyncNotifier<List<Section>> implements SectionNotifier {
  final List<Section> items;
  TestPopulatedSectionNotifier(this.items);

  @override
  Future<List<Section>> build() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
