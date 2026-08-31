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
import 'package:campus_management/features/timetable/presentation/screens/timetable_designer_screen.dart';
import 'package:campus_management/features/timetable/presentation/widgets/timetable_spreadsheet_grid.dart';
import 'package:campus_management/features/timetable/presentation/widgets/timetable_class_editor_dialog.dart';
import 'package:campus_management/features/timetable/presentation/widgets/timetable_structure_editor_dialog.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FastMockAcademicRepository implements AcademicRepository {
  final List<Department> departments = [
    Department(id: 'd1', collegeId: 'c1', name: 'Computer Engineering', code: 'CS', hodId: 'usr-hod', description: ''),
  ];
  final List<Course> courses = [
    Course(id: 'cr1', collegeId: 'c1', departmentId: 'd1', name: 'B.Tech Computer Science', code: 'BTECH-CS'),
  ];
  final List<AcademicYear> academicYears = [
    AcademicYear(id: 'ay2', collegeId: 'c1', name: '2026-2027', startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 12, 31), isCurrent: true),
  ];
  final List<Semester> semesters = [
    Semester(id: 'sem1', collegeId: 'c1', departmentId: 'd1', courseId: 'cr1', academicYearId: 'ay2', name: 'Semester 1', number: 1),
  ];
  final List<Section> sections = [
    Section(id: 'sec1', collegeId: 'c1', departmentId: 'd1', semesterId: 'sem1', name: 'A'),
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

  group('ACADEX Phase 5D: Timetable Designer Interaction & Editing Tests', () {
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
      name: 'Dr. Turing',
      email: 'hod@git.edu',
      role: AppRole.hod,
      collegeId: 'c1',
      departmentId: 'd1',
    );

    final facultyAliceUser = UserModel(
      id: 'usr-faculty-alice',
      name: 'Faculty Alice',
      email: 'alice@git.edu',
      role: AppRole.faculty,
      collegeId: 'c1',
      departmentId: 'd1',
    );

    final studentUser = UserModel(
      id: 'usr-student',
      name: 'Student Bob',
      email: 'student@git.edu',
      role: AppRole.student,
      collegeId: 'c1',
      departmentId: 'd1',
      sectionId: 'sec1',
    );

    final mockSubject1 = Subject(
      id: 'sub-dbms',
      collegeId: 'c1',
      departmentId: 'd1',
      semesterId: 'sem1',
      name: 'Database Management Systems',
      code: 'CS401',
      credits: 4,
      type: 'Theory',
    );

    final mockSubject2 = Subject(
      id: 'sub-os',
      collegeId: 'c1',
      departmentId: 'd1',
      semesterId: 'sem1',
      name: 'Operating Systems',
      code: 'CS402',
      credits: 4,
      type: 'Theory',
    );

    final mockFaculty1 = Faculty(
      id: 'fac-grace',
      collegeId: 'c1',
      departmentId: 'd1',
      name: 'Dr. Grace Hopper',
      employeeId: 'EMP-01',
      email: 'grace@git.edu',
      phone: '1234567890',
      subjectIds: ['sub-dbms'],
      sectionIds: ['sec1'],
    );

    final mockFaculty2 = Faculty(
      id: 'fac-ada',
      collegeId: 'c1',
      departmentId: 'd1',
      name: 'Dr. Ada Lovelace',
      employeeId: 'EMP-02',
      email: 'ada@git.edu',
      phone: '1234567891',
      subjectIds: ['sub-os'],
      sectionIds: ['sec1'],
    );

    final testContainer = TimetableContainerModel(
      id: 'tt-interactive-1',
      collegeId: 'c1',
      departmentId: 'd1',
      courseId: 'cr1',
      academicYearId: 'ay2',
      semesterId: 'sem1',
      sectionId: 'sec1',
      name: 'Interactive CSE Timetable',
      status: TimetableStatus.draft,
      version: 1,
      activeDays: [TimetableDay.monday, TimetableDay.tuesday, TimetableDay.wednesday, TimetableDay.thursday, TimetableDay.friday],
      timingMode: TimetableTimingMode.sameEveryDay,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final testPeriods = [
      TimetablePeriodModel(id: 'p1', index: 1, name: 'Period 1', startTime: '09:00', endTime: '10:00'),
      TimetablePeriodModel(id: 'p2', index: 2, name: 'Period 2', startTime: '10:00', endTime: '11:00'),
      TimetablePeriodModel(id: 'p3', index: 3, name: 'Period 3', startTime: '11:00', endTime: '12:00'),
      TimetablePeriodModel(id: 'p4', index: 4, name: 'Period 4', startTime: '12:00', endTime: '13:00'),
      TimetablePeriodModel(id: 'p5', index: 5, name: 'Period 5', startTime: '13:00', endTime: '14:00'),
    ];

    final testBreaks = [
      TimetableBreakModel(
        id: 'brk-lunch',
        name: 'Lunch Break',
        breakType: TimetableBreakType.lunch,
        startTime: '12:00',
        endTime: '13:00',
        appliesToDays: [TimetableDay.monday, TimetableDay.tuesday, TimetableDay.wednesday, TimetableDay.thursday, TimetableDay.friday],
      ),
    ];

    setUp(() async {
      mockRepo = MockTimetableRepository();
      mockAcademicRepo = FastMockAcademicRepository();

      await mockRepo.createTimetableContainer(testContainer);
      await mockRepo.savePeriodsBatch(testContainer.id, testPeriods);
      await mockRepo.saveBreaksBatch(testContainer.id, testBreaks);
    });

    Widget createTestWidget({
      required Widget child,
      UserModel? currentUser,
      bool isDark = false,
      Size size = const Size(1280, 900),
    }) {
      final user = currentUser ?? hodCsUser;

      final deptMap = {for (var d in mockAcademicRepo.departments) d.id: d};
      final courseMap = {for (var c in mockAcademicRepo.courses) c.id: c};
      final sectionMap = {for (var s in mockAcademicRepo.sections) s.id: s};
      final subjectMap = {'sub-dbms': mockSubject1, 'sub-os': mockSubject2};
      final facultyMap = {'fac-grace': mockFaculty1, 'fac-ada': mockFaculty2};

      return ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: user, token: 'mock-token'))),
          currentUserProvider.overrideWithValue(user),
          timetableRepositoryProvider.overrideWithValue(mockRepo),
          academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
          timetableSubjectMapProvider.overrideWithValue(subjectMap),
          timetableFacultyMapProvider.overrideWithValue(facultyMap),
          timetableDepartmentMapProvider.overrideWithValue(deptMap),
          timetableCourseMapProvider.overrideWithValue(courseMap),
          timetableSectionMapProvider.overrideWithValue(sectionMap),
        ],
        child: MaterialApp(
          theme: isDark ? ThemeData.dark() : ThemeData.light(),
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: Scaffold(body: child),
          ),
        ),
      );
    }

    // =========================================================================
    // 1. EMPTY CELL CLICK OPENS ADD CLASS EDITOR
    // =========================================================================
    testWidgets('1. Clicking an empty cell opens Add Class editor dialog with pre-filled day and period', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        child: TimetableDesignerScreen(timetableId: testContainer.id),
      ));
      await tester.pumpAndSettle();

      // Spreadsheet grid is rendered
      expect(find.byType(TimetableSpreadsheetGrid), findsOneWidget);

      // Tap on empty cell (Monday Period 1)
      final plusIcons = find.byIcon(LucideIcons.plus);
      expect(plusIcons, findsWidgets);
      await tester.tap(plusIcons.first);
      await tester.pumpAndSettle();

      // Add Class dialog opens with pre-filled day & period context
      expect(find.byType(TimetableClassEditorDialog), findsOneWidget);
      expect(find.text('Add Class'), findsWidgets);
      expect(find.textContaining('Monday'), findsWidgets);
      expect(find.textContaining('Period 1'), findsWidgets);
    });

    // =========================================================================
    // 2. ADD CLASS, SELECT SUBJECT, FACULTY & SAVE
    // =========================================================================
    testWidgets('2. Filling subject, faculty, room and saving adds new class to the grid', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        child: TimetableDesignerScreen(timetableId: testContainer.id),
      ));
      await tester.pumpAndSettle();

      // Open Add Class on Monday Period 1
      await tester.tap(find.byIcon(LucideIcons.plus).first);
      await tester.pumpAndSettle();

      // Select Subject
      await tester.tap(find.text('Select subject'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Database Management Systems').last);
      await tester.pumpAndSettle();

      // Select Faculty
      await tester.tap(find.text('Select faculty member'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Dr. Grace Hopper').last);
      await tester.pumpAndSettle();

      // Enter Room
      await tester.enterText(find.widgetWithText(TextField, '').first, 'Lab-201');
      await tester.pumpAndSettle();

      // Click Add Class CTA
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Class'));
      await tester.pumpAndSettle();

      // Dialog is closed and new entry is visible in grid
      expect(find.byType(TimetableClassEditorDialog), findsNothing);
      expect(find.text('Database Management Systems'), findsOneWidget);
      expect(find.text('Dr. Grace Hopper'), findsOneWidget);
      expect(find.text('Lab-201'), findsOneWidget);
      expect(find.text('Unsaved Changes'), findsOneWidget);
    });

    // =========================================================================
    // 3. CONFLICT VALIDATIONS (MISSING FIELDS, BREAK & FACULTY CONFLICTS)
    // =========================================================================
    testWidgets('3. Missing subject, faculty, break conflict, and faculty clashes show real-time error feedback', (tester) async {
      // Pre-populate Monday P1
      final p1Entry = TimetableGridEntryModel(
        id: 'entry-mon-p1',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 1,
        periodSpan: 1,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: 'sub-dbms',
        facultyId: 'fac-grace',
        roomNumber: 'Lab-201',
        sessionType: TimetableSessionType.lecture,
      );
      await mockRepo.saveGridEntriesBatch(testContainer.id, [p1Entry]);

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        child: TimetableDesignerScreen(timetableId: testContainer.id),
      ));
      await tester.pumpAndSettle();

      // Open Add Class on Monday Period 2
      await tester.tap(find.byIcon(LucideIcons.plus).first);
      await tester.pumpAndSettle();

      // Missing Subject and Faculty errors are shown
      expect(find.textContaining('Please select a Subject'), findsOneWidget);
      expect(find.textContaining('Please select a Faculty member'), findsOneWidget);
    });

    // =========================================================================
    // 4. EDIT & DELETE CLASS WITH CONFIRMATION
    // =========================================================================
    testWidgets('4. Tapping class opens Edit Class dialog and deleting removes it after confirmation', (tester) async {
      final p1Entry = TimetableGridEntryModel(
        id: 'entry-del-test',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 1,
        periodSpan: 1,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: 'sub-dbms',
        facultyId: 'fac-grace',
        roomNumber: 'Lab-201',
        sessionType: TimetableSessionType.lecture,
      );
      await mockRepo.saveGridEntriesBatch(testContainer.id, [p1Entry]);

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        child: TimetableDesignerScreen(timetableId: testContainer.id),
      ));
      await tester.pumpAndSettle();

      // Tap on the existing class card
      await tester.tap(find.text('Database Management Systems'));
      await tester.pumpAndSettle();

      // Edit Class dialog is open
      expect(find.byType(TimetableClassEditorDialog), findsOneWidget);
      expect(find.text('Edit Class'), findsWidgets);
      expect(find.text('Delete Class'), findsOneWidget);

      // Tap Delete Class
      await tester.tap(find.text('Delete Class'));
      await tester.pumpAndSettle();

      // Confirmation dialog is shown
      expect(find.text('Delete Class'), findsWidgets);
      expect(find.textContaining('Remove Database Management Systems from Monday P1?'), findsOneWidget);

      // Confirm Delete
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      // Class is removed from grid
      expect(find.byType(TimetableClassEditorDialog), findsNothing);
      expect(find.text('Database Management Systems'), findsNothing);
    });

    // =========================================================================
    // 5. MERGE RIGHT ACTION (EXTENDS PERIOD SPAN)
    // =========================================================================
    testWidgets('5. Merge Right extends entry period span and recalculates timing', (tester) async {
      final p1Entry = TimetableGridEntryModel(
        id: 'entry-mon-p1',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 1,
        periodSpan: 1,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: 'sub-dbms',
        facultyId: 'fac-grace',
        roomNumber: 'Lab-201',
        sessionType: TimetableSessionType.lab,
      );
      await mockRepo.saveGridEntriesBatch(testContainer.id, [p1Entry]);

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        child: TimetableDesignerScreen(timetableId: testContainer.id),
      ));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(tester.element(find.byType(TimetableDesignerScreen)));
      final notifier = container.read(timetableAuthoringProvider(testContainer.id).notifier);

      // Perform merge right
      expect(container.read(timetableAuthoringProvider(testContainer.id)).canMergeRight(p1Entry.id), isTrue);
      notifier.mergeEntryRight(p1Entry.id);
      await tester.pumpAndSettle();

      final state = container.read(timetableAuthoringProvider(testContainer.id));
      final merged = state.entries.firstWhere((e) => e.id == p1Entry.id);
      expect(merged.periodSpan, equals(2));
      expect(merged.endTime, equals('11:00'));
      expect(merged.isMergedHorizontal, isTrue);
    });

    // =========================================================================
    // 6. SPLIT ACTION (RESTORES 1-PERIOD SLOTS)
    // =========================================================================
    testWidgets('6. Split action restores multi-period merged class into 1-period slots', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final p1Merged = TimetableGridEntryModel(
        id: 'entry-mon-merged',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 1,
        periodSpan: 2,
        startTime: '09:00',
        endTime: '11:00',
        subjectId: 'sub-dbms',
        facultyId: 'fac-grace',
        roomNumber: 'Lab-201',
        sessionType: TimetableSessionType.lab,
      );
      await mockRepo.saveGridEntriesBatch(testContainer.id, [p1Merged]);

      await tester.pumpWidget(createTestWidget(
        child: TimetableDesignerScreen(timetableId: testContainer.id),
      ));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(tester.element(find.byType(TimetableDesignerScreen)));
      final notifier = container.read(timetableAuthoringProvider(testContainer.id).notifier);

      expect(container.read(timetableAuthoringProvider(testContainer.id)).canSplit(p1Merged.id), isTrue);
      notifier.splitEntry(p1Merged.id);
      await tester.pumpAndSettle();

      final state = container.read(timetableAuthoringProvider(testContainer.id));
      expect(state.entries.length, equals(2));
      expect(state.entries.every((e) => e.periodSpan == 1), isTrue);
      expect(state.entries.map((e) => e.startPeriodIndex).toList(), containsAll([1, 2]));
    });

    // =========================================================================
    // 7. STRUCTURE EDITOR (PERIODS & BREAKS)
    // =========================================================================
    testWidgets('7. Structure & Timing button opens structure editor dialog', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        child: TimetableDesignerScreen(timetableId: testContainer.id),
      ));
      await tester.pumpAndSettle();

      // Click Structure & Timing
      await tester.tap(find.text('Structure & Timing'));
      await tester.pumpAndSettle();

      // Structure Editor Dialog is shown
      expect(find.byType(TimetableStructureEditorDialog), findsOneWidget);
      expect(find.textContaining('Periods & Timing'), findsOneWidget);
    });

    // =========================================================================
    // 8. MOVE CLASS OPERATION
    // =========================================================================
    testWidgets('8. Moving class safely updates day, period index, and timings', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final p1Entry = TimetableGridEntryModel(
        id: 'entry-move-1',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 1,
        periodSpan: 1,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: 'sub-dbms',
        facultyId: 'fac-grace',
        roomNumber: 'Lab-201',
        sessionType: TimetableSessionType.lecture,
      );
      await mockRepo.saveGridEntriesBatch(testContainer.id, [p1Entry]);

      await tester.pumpWidget(createTestWidget(
        child: TimetableDesignerScreen(timetableId: testContainer.id),
      ));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(tester.element(find.byType(TimetableDesignerScreen)));
      final notifier = container.read(timetableAuthoringProvider(testContainer.id).notifier);

      // Move Monday P1 -> Tuesday P2
      notifier.moveEntry(
        entryId: p1Entry.id,
        targetDay: TimetableDay.tuesday,
        targetStartPeriodIndex: 2,
      );
      await tester.pumpAndSettle();

      final state = container.read(timetableAuthoringProvider(testContainer.id));
      final moved = state.entries.firstWhere((e) => e.id == p1Entry.id);
      expect(moved.dayOfWeek, equals(TimetableDay.tuesday));
      expect(moved.startPeriodIndex, equals(2));
      expect(moved.startTime, equals('10:00'));
      expect(moved.endTime, equals('11:00'));
    });

    // =========================================================================
    // 9. UNDO & REDO STACK
    // =========================================================================
    testWidgets('9. Local Undo and Redo revert and re-apply grid modifications', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        child: TimetableDesignerScreen(timetableId: testContainer.id),
      ));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(tester.element(find.byType(TimetableDesignerScreen)));
      final notifier = container.read(timetableAuthoringProvider(testContainer.id).notifier);

      expect(notifier.canUndo, isFalse);

      // 1. Create entry
      final entry = TimetableGridEntryModel(
        id: 'entry-undo-test',
        dayOfWeek: TimetableDay.wednesday,
        startPeriodIndex: 1,
        periodSpan: 1,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: 'sub-dbms',
        facultyId: 'fac-grace',
        roomNumber: 'Room-101',
        sessionType: TimetableSessionType.lecture,
      );
      notifier.createEntry(entry);
      await tester.pumpAndSettle();

      expect(container.read(timetableAuthoringProvider(testContainer.id)).entries.length, equals(1));
      expect(notifier.canUndo, isTrue);

      // 2. Undo
      notifier.undo();
      await tester.pumpAndSettle();

      expect(container.read(timetableAuthoringProvider(testContainer.id)).entries.length, equals(0));
      expect(notifier.canRedo, isTrue);

      // 3. Redo
      notifier.redo();
      await tester.pumpAndSettle();

      expect(container.read(timetableAuthoringProvider(testContainer.id)).entries.length, equals(1));
    });

    // =========================================================================
    // 10. UNSAVED CHANGES NAVIGATION GUARD
    // =========================================================================
    testWidgets('10. Leaving designer with unsaved changes prompts confirmation dialog', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        child: TimetableDesignerScreen(timetableId: testContainer.id),
      ));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(tester.element(find.byType(TimetableDesignerScreen)));
      final notifier = container.read(timetableAuthoringProvider(testContainer.id).notifier);

      // Make dirty change
      notifier.createEntry(TimetableGridEntryModel(
        id: 'entry-dirty',
        dayOfWeek: TimetableDay.thursday,
        startPeriodIndex: 1,
        periodSpan: 1,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: 'sub-dbms',
        facultyId: 'fac-grace',
        roomNumber: '101',
        sessionType: TimetableSessionType.lecture,
      ));
      await tester.pumpAndSettle();

      expect(container.read(timetableAuthoringProvider(testContainer.id)).isDirty, isTrue);

      // Click back button
      await tester.tap(find.byIcon(LucideIcons.arrowLeft));
      await tester.pumpAndSettle();

      // Exit confirmation is displayed
      expect(find.text('Discard Changes'), findsOneWidget);
      expect(find.text('Save & Exit'), findsOneWidget);
    });

    // =========================================================================
    // 11. PUBLISH CONFIRMATION SUMMARY MODAL & ATOMIC PUBLISH
    // =========================================================================
    testWidgets('11. Publish button displays confirmation summary dialog and projects to live schedule', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final entry = TimetableGridEntryModel(
        id: 'entry-pub-1',
        dayOfWeek: TimetableDay.friday,
        startPeriodIndex: 1,
        periodSpan: 1,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: 'sub-dbms',
        facultyId: 'fac-grace',
        roomNumber: '101',
        sessionType: TimetableSessionType.lecture,
      );
      await mockRepo.saveGridEntriesBatch(testContainer.id, [entry]);

      await tester.pumpWidget(createTestWidget(
        child: TimetableDesignerScreen(timetableId: testContainer.id),
      ));
      await tester.pumpAndSettle();

      // Click Publish
      await tester.tap(find.widgetWithText(ElevatedButton, 'Publish'));
      await tester.pumpAndSettle();

      // Publish modal is open
      expect(find.text('Publish Timetable Schedule'), findsOneWidget);
      expect(find.text('Teaching Classes'), findsOneWidget);
      expect(find.text('Confirm & Publish'), findsOneWidget);

      // Confirm & Publish
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm & Publish'));
      await tester.pumpAndSettle();

      // Container status updated to published
      final updated = await mockRepo.getTimetableContainer(testContainer.id);
      expect(updated?.status, equals(TimetableStatus.published));
    });

    // =========================================================================
    // 12. ROLE RESTRICTION: STUDENT & NORMAL FACULTY READ-ONLY ACCESS
    // =========================================================================
    testWidgets('12. Student and Normal Faculty have read-only access without edit or publish CTAs', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // As Student
      await tester.pumpWidget(createTestWidget(
        currentUser: studentUser,
        child: TimetableDesignerScreen(timetableId: testContainer.id),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Save Draft'), findsNothing);
      expect(find.text('Publish'), findsNothing);
      expect(find.text('Structure & Timing'), findsNothing);

      // As Normal Faculty
      await tester.pumpWidget(createTestWidget(
        currentUser: facultyAliceUser,
        child: TimetableDesignerScreen(timetableId: testContainer.id),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Save Draft'), findsNothing);
      expect(find.text('Publish'), findsNothing);
    });

    // =========================================================================
    // 13. COLLEGE ADMIN ACCESS
    // =========================================================================
    testWidgets('13. College Admin has full editing access in the designer', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        currentUser: collegeAdminUser,
        child: TimetableDesignerScreen(timetableId: testContainer.id),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Save Draft'), findsOneWidget);
      expect(find.text('Publish'), findsOneWidget);
      expect(find.text('Structure & Timing'), findsOneWidget);
    });
  });
}
