import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/data/repositories/mock_timetable_repository.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_authoring_providers.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_lookup_providers.dart';
import 'package:campus_management/features/timetable/presentation/widgets/timetable_class_editor_dialog.dart';
import 'package:campus_management/features/timetable/presentation/screens/timetable_designer_screen.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ACADEX Phase 5B: Class Cell Editor & Assignment Tests', () {
    late MockTimetableRepository mockRepo;
    late MockAcademicRepository mockAcademicRepo;

    final hodCseUser = UserModel(
      id: 'usr-hod',
      name: 'HOD CSE',
      email: 'hod@col1.edu',
      role: AppRole.hod,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
    );

    final studentUser = UserModel(
      id: 'usr-student',
      name: 'Student User',
      email: 'student@col1.edu',
      role: AppRole.student,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
      sectionId: 'sec-4a',
    );

    final testSubjects = [
      Subject(
        id: 'sub-ds',
        name: 'Data Structures',
        code: 'CS201',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        semesterId: 'sem-4',
        credits: 4,
        type: 'Theory',
      ),
      Subject(
        id: 'sub-algo',
        name: 'Algorithms Lab',
        code: 'CS202L',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        semesterId: 'sem-4',
        credits: 2,
        type: 'Practical',
      ),
      Subject(
        id: 'sub-os',
        name: 'Operating Systems',
        code: 'CS203',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        semesterId: 'sem-4',
        credits: 3,
        type: 'Theory',
      ),
    ];

    final testFaculty = [
      Faculty(
        id: 'fac-1',
        name: 'Dr. Alan Turing',
        employeeId: 'EMP001',
        email: 'turing@col1.edu',
        phone: '1234567890',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
      ),
      Faculty(
        id: 'fac-2',
        name: 'Prof. Grace Hopper',
        employeeId: 'EMP002',
        email: 'hopper@col1.edu',
        phone: '1234567891',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
      ),
    ];

    final testAssignments = [
      FacultyAssignment(
        id: 'asgn-ds',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-btech',
        academicYearId: 'ay-2026',
        semesterId: 'sem-4',
        sectionId: 'sec-4a',
        subjectId: 'sub-ds',
        facultyId: 'fac-1',
        facultyName: 'Dr. Alan Turing',
        assignmentType: 'Theory',
        isActive: true,
      ),
      FacultyAssignment(
        id: 'asgn-algo',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-btech',
        academicYearId: 'ay-2026',
        semesterId: 'sem-4',
        sectionId: 'sec-4a',
        subjectId: 'sub-algo',
        facultyId: 'fac-2',
        facultyName: 'Prof. Grace Hopper',
        assignmentType: 'Practical',
        isActive: true,
      ),
    ];

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
      TimetablePeriodModel(
        id: 'p-3',
        index: 3,
        name: 'Period 3',
        startTime: '11:00',
        endTime: '12:00',
      ),
      TimetablePeriodModel(
        id: 'p-4',
        index: 4,
        name: 'Period 4',
        startTime: '12:00',
        endTime: '13:00',
      ),
      TimetablePeriodModel(
        id: 'p-5',
        index: 5,
        name: 'Period 5',
        startTime: '14:00',
        endTime: '15:00',
      ),
    ];

    final testBreaks = [
      TimetableBreakModel(
        id: 'brk-lunch',
        name: 'Lunch Break',
        startTime: '13:00',
        endTime: '14:00',
        appliesToDays: [
          TimetableDay.monday,
          TimetableDay.tuesday,
          TimetableDay.wednesday,
          TimetableDay.thursday,
          TimetableDay.friday,
        ],
        isVerticalSpan: true,
        breakType: TimetableBreakType.lunch,
      ),
    ];

    TimetableContainerModel createSampleContainer({
      String id = 'tt-editor-1',
      List<TimetableDay>? activeDays,
    }) {
      return TimetableContainerModel(
        id: id,
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-btech',
        academicYearId: 'ay-2026',
        semesterId: 'sem-4',
        sectionId: 'sec-4a',
        name: 'CSE Sem 4 Sec A Master Timetable',
        status: TimetableStatus.draft,
        version: 1,
        activeDays: activeDays ?? [
          TimetableDay.monday,
          TimetableDay.tuesday,
          TimetableDay.wednesday,
          TimetableDay.thursday,
          TimetableDay.friday,
        ],
        timingMode: TimetableTimingMode.sameEveryDay,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
    }

    setUp(() {
      mockRepo = MockTimetableRepository();
      mockAcademicRepo = MockAcademicRepository();
    });

    Widget createTestWidget({
      required Widget child,
      required TimetableAuthoringState authoringState,
      UserModel? currentUser,
      bool isDark = false,
      Size size = const Size(1200, 900),
    }) {
      final user = currentUser ?? hodCseUser;
      final subjectMap = {for (var s in testSubjects) s.id: s};
      final facultyMap = {for (var f in testFaculty) f.id: f};
      final deptMap = <String, Department>{'dept-cse': Department(id: 'dept-cse', collegeId: 'col-1', name: 'Computer Science', code: 'CSE', hodId: 'usr-hod', description: '')};
      final courseMap = <String, Course>{'crs-btech': Course(id: 'crs-btech', collegeId: 'col-1', departmentId: 'dept-cse', name: 'B.Tech CSE', code: 'BT-CSE')};
      final sectionMap = <String, Section>{'sec-4a': Section(id: 'sec-4a', collegeId: 'col-1', departmentId: 'dept-cse', semesterId: 'sem-4', name: 'Section A')};

      return ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: user, token: 'mock-token'))),
          academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
          timetableAuthoringProvider.overrideWith((ref, id) {
            final notifier = TimetableAuthoringNotifier(repository: mockRepo, currentUser: user);
            notifier.state = authoringState;
            return notifier;
          }),
          timetableSubjectMapProvider.overrideWithValue(subjectMap),
          timetableFacultyMapProvider.overrideWithValue(facultyMap),
          timetableDepartmentMapProvider.overrideWithValue(deptMap),
          timetableCourseMapProvider.overrideWithValue(courseMap),
          timetableSectionMapProvider.overrideWithValue(sectionMap),
          facultyAssignmentsBySectionProvider('sec-4a').overrideWithValue(testAssignments),
        ],
        child: MaterialApp(
          theme: isDark ? ThemeData.dark() : ThemeData.light(),
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: Material(child: child),
          ),
        ),
      );
    }

    // =========================================================================
    // 1. ADD CLASS WORKFLOW & INITIAL CONTEXT
    // =========================================================================
    testWidgets('1. Add Class Dialog opens with fixed known context and allows adding a class', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createSampleContainer();
      final authoringState = TimetableAuthoringState(
        container: container,
        periods: testPeriods,
        breaks: testBreaks,
        entries: [],
      );

      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          child: const TimetableClassEditorDialog(
            timetableId: 'tt-editor-1',
            day: TimetableDay.monday,
            startPeriodIndex: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Context
      expect(find.byType(TimetableClassEditorDialog), findsOneWidget);
      expect(find.textContaining('Monday • Period 1 (09:00)'), findsOneWidget);
      expect(find.textContaining('Computer Science • B.Tech CSE • Sem sem-4 • Sec Section A'), findsOneWidget);

      // Verify Form fields are present
      expect(find.text('Faculty Assignment *'), findsOneWidget);
      expect(find.text('Session Type'), findsOneWidget);
      expect(find.text('Duration (Consecutive Periods)'), findsOneWidget);
      expect(find.text('Room Number'), findsOneWidget);

      // Select Faculty Assignment
      await tester.tap(find.text('Select Faculty Assignment'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Data Structures (CS201) — Dr. Alan Turing').last);
      await tester.pumpAndSettle();

      // Enter Room Number
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. LH-101, Lab-2'), 'LH-101');
      await tester.pumpAndSettle();

      // Save Class
      final addButton = find.widgetWithText(ElevatedButton, 'Add Class');
      expect(addButton, findsOneWidget);
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.byType(TimetableClassEditorDialog), findsNothing);
    });

    // =========================================================================
    // 2. EDIT CLASS WORKFLOW & PRE-FILLED FIELDS
    // =========================================================================
    testWidgets('2. Edit Class Dialog pre-fills existing entry and updates in place', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createSampleContainer();
      final existingEntry = TimetableGridEntryModel(
        id: 'entry-ds-1',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 1,
        periodSpan: 1,
        startTime: '09:00',
        endTime: '10:00',
        facultyAssignmentId: 'asgn-ds',
        subjectId: 'sub-ds',
        facultyId: 'fac-1',
        roomNumber: 'LH-101',
        building: 'Main Block',
        sessionType: TimetableSessionType.lecture,
      );

      final authoringState = TimetableAuthoringState(
        container: container,
        periods: testPeriods,
        breaks: testBreaks,
        entries: [existingEntry],
      );

      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          child: TimetableClassEditorDialog(
            timetableId: 'tt-editor-1',
            day: TimetableDay.monday,
            startPeriodIndex: 1,
            existingEntry: existingEntry,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Mode
      expect(find.text('Edit Class'), findsOneWidget);
      expect(find.textContaining('Data Structures'), findsWidgets);
      expect(find.textContaining('Dr. Alan Turing'), findsWidgets);
      expect(find.text('LH-101'), findsOneWidget);
      expect(find.text('Main Block'), findsOneWidget);
      expect(find.text('Delete Class'), findsOneWidget);

      // Edit Room Number
      await tester.enterText(find.widgetWithText(TextFormField, 'LH-101'), 'LH-202');
      await tester.pumpAndSettle();

      // Save update
      final updateButton = find.widgetWithText(ElevatedButton, 'Update Class');
      expect(updateButton, findsOneWidget);
      await tester.ensureVisible(updateButton);
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      expect(find.byType(TimetableClassEditorDialog), findsNothing);
    });

    // =========================================================================
    // 3. DELETE CLASS WITH CONFIRMATION
    // =========================================================================
    testWidgets('3. Delete Class opens confirmation dialog and removes entry', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createSampleContainer();
      final existingEntry = TimetableGridEntryModel(
        id: 'entry-to-del',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 1,
        periodSpan: 1,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: 'sub-ds',
        facultyId: 'fac-1',
        roomNumber: 'LH-101',
        sessionType: TimetableSessionType.lecture,
      );

      final authoringState = TimetableAuthoringState(
        container: container,
        periods: testPeriods,
        breaks: testBreaks,
        entries: [existingEntry],
      );

      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          child: TimetableClassEditorDialog(
            timetableId: 'tt-editor-1',
            day: TimetableDay.monday,
            startPeriodIndex: 1,
            existingEntry: existingEntry,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Click Delete Class
      final deleteBtn = find.widgetWithText(OutlinedButton, 'Delete Class');
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog is shown
      expect(find.textContaining('This change will take effect locally in your draft.'), findsOneWidget);

      // Confirm Delete
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.byType(TimetableClassEditorDialog), findsNothing);
    });

    // =========================================================================
    // 4. DURATION & MULTI-PERIOD MERGE CALCULATION
    // =========================================================================
    testWidgets('4. Multi-period duration calculates merged time and shows span preview', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createSampleContainer();
      final authoringState = TimetableAuthoringState(
        container: container,
        periods: testPeriods,
        breaks: testBreaks,
        entries: [],
      );

      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          child: const TimetableClassEditorDialog(
            timetableId: 'tt-editor-1',
            day: TimetableDay.monday,
            startPeriodIndex: 2, // 10:00
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Duration selector is present
      expect(find.text('1 Period (10:00 - 11:00)'), findsOneWidget);

      // Change Duration to 2 Periods (10:00 - 12:00)
      await tester.tap(find.text('1 Period (10:00 - 11:00)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 Periods (10:00 - 12:00) [Merged]').last);
      await tester.pumpAndSettle();

      // Merged preview banner is displayed
      expect(find.textContaining('Merged Entry: Spans Period 2 to 3 (10:00 – 12:00)'), findsOneWidget);
    });

    // =========================================================================
    // 5. BREAK CONFLICT VALIDATION
    // =========================================================================
    testWidgets('5. Overlap with Break shows inline conflict and disables Save', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createSampleContainer();
      final authoringState = TimetableAuthoringState(
        container: container,
        periods: testPeriods,
        breaks: testBreaks,
        entries: [],
      );

      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          child: const TimetableClassEditorDialog(
            timetableId: 'tt-editor-1',
            day: TimetableDay.monday,
            startPeriodIndex: 4, // 12:00 - 13:00
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select Faculty Assignment
      await tester.tap(find.text('Select Faculty Assignment'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Data Structures (CS201) — Dr. Alan Turing').last);
      await tester.pumpAndSettle();

      // Expand to 2 periods (12:00 - 15:00) -> overlaps with 13:00-14:00 Lunch break
      await tester.tap(find.text('1 Period (12:00 - 13:00)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 Periods (12:00 - 15:00) [Merged]').last);
      await tester.pumpAndSettle();

      // Break conflict is shown
      expect(find.textContaining('Break Conflict: Timeslot (12:00 - 15:00) overlaps with Lunch Break'), findsOneWidget);

      // Save button is disabled
      final addButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Add Class'));
      expect(addButton.onPressed, isNull);
    });

    // =========================================================================
    // 6. SECTION & FACULTY CONFLICT VALIDATION
    // =========================================================================
    testWidgets('6. Section and Faculty conflicts are detected and reported inline', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createSampleContainer();
      final existingMondayP2 = TimetableGridEntryModel(
        id: 'entry-monday-p2',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 2,
        periodSpan: 1,
        startTime: '10:00',
        endTime: '11:00',
        subjectId: 'sub-algo',
        facultyId: 'fac-1', // Dr. Turing
        roomNumber: 'LH-101',
        sessionType: TimetableSessionType.practical,
      );

      final authoringState = TimetableAuthoringState(
        container: container,
        periods: testPeriods,
        breaks: testBreaks,
        entries: [existingMondayP2],
      );

      // Attempt to add a 2-period class starting at P1 (09:00 - 11:00) on Monday
      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          child: const TimetableClassEditorDialog(
            timetableId: 'tt-editor-1',
            day: TimetableDay.monday,
            startPeriodIndex: 1, // 09:00 - 10:00
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select Faculty Assignment
      await tester.tap(find.text('Select Faculty Assignment'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Data Structures (CS201) — Dr. Alan Turing').last);
      await tester.pumpAndSettle();

      // Set Span to 2 Periods (09:00 - 11:00) which collides with existingMondayP2 (10:00-11:00)
      await tester.tap(find.text('1 Period (09:00 - 10:00)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 Periods (09:00 - 11:00) [Merged]').last);
      await tester.pumpAndSettle();

      // Section Conflict is reported
      expect(find.textContaining('Section Conflict: Timeslot overlaps with existing class (Algorithms Lab, 10:00 - 11:00).'), findsOneWidget);

      // Faculty Conflict is reported (Dr. Turing already teaching P2)
      expect(find.textContaining('Faculty Conflict: Dr. Alan Turing is already scheduled on Monday (10:00 - 11:00).'), findsOneWidget);

      // Save button is disabled
      final addButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Add Class'));
      expect(addButton.onPressed, isNull);
    });

    // =========================================================================
    // 7. ROOM CONFLICT VALIDATION
    // =========================================================================
    testWidgets('7. Room conflict is detected when same room is booked simultaneously', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createSampleContainer();
      final existingMondayP1 = TimetableGridEntryModel(
        id: 'entry-monday-p1',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 1,
        periodSpan: 1,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: 'sub-algo',
        facultyId: 'fac-2', // Prof. Hopper
        roomNumber: 'LH-101',
        sessionType: TimetableSessionType.practical,
      );

      final authoringState = TimetableAuthoringState(
        container: container,
        periods: testPeriods,
        breaks: testBreaks,
        entries: [existingMondayP1],
      );

      // Open on Monday P1 with different faculty, same room LH-101
      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          child: const TimetableClassEditorDialog(
            timetableId: 'tt-editor-1',
            day: TimetableDay.monday,
            startPeriodIndex: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select Faculty Assignment'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Data Structures (CS201) — Dr. Alan Turing').last, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Enter Room LH-101
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. LH-101, Lab-2'), 'LH-101');
      await tester.pumpAndSettle();

      // Room Conflict is detected
      expect(find.textContaining('Room Conflict: Room LH-101 is already booked on Monday (09:00 - 10:00).'), findsOneWidget);

      final addButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Add Class'));
      expect(addButton.onPressed, isNull);
    });

    // =========================================================================
    // 8. ROLE RESTRICTIONS ON DESIGNER GRID
    // =========================================================================
    testWidgets('8. Student and Normal Faculty cannot open class editor from grid', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createSampleContainer();
      final authoringState = TimetableAuthoringState(
        container: container,
        periods: testPeriods,
        breaks: testBreaks,
        entries: [],
      );

      // Test as Student
      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          currentUser: studentUser,
          child: TimetableDesignerScreen(timetableId: container.id),
        ),
      );
      await tester.pumpAndSettle();

      // For student, '+' add affordance is not shown
      expect(find.byIcon(LucideIcons.plus), findsNothing);
      expect(find.byType(TimetableClassEditorDialog), findsNothing);
    });

    testWidgets('9. HOD and College Admin can open class editor from grid', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createSampleContainer();
      final authoringState = TimetableAuthoringState(
        container: container,
        periods: testPeriods,
        breaks: testBreaks,
        entries: [],
      );

      // Test as HOD
      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          currentUser: hodCseUser,
          child: TimetableDesignerScreen(timetableId: container.id),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on '+' empty cell affordance
      await tester.tap(find.byIcon(LucideIcons.plus).first);
      await tester.pumpAndSettle();

      // Dialog opens for HOD
      expect(find.byType(TimetableClassEditorDialog), findsOneWidget);
    });

    // =========================================================================
    // 10. RESPONSIVE MOBILE VIEWPORT (NO OVERFLOW)
    // =========================================================================
    testWidgets('10. Mobile viewport (360x700) renders class editor dialog without overflow', (tester) async {
      final container = createSampleContainer();
      final authoringState = TimetableAuthoringState(
        container: container,
        periods: testPeriods,
        breaks: testBreaks,
        entries: [],
      );

      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          size: const Size(360, 700),
          child: const TimetableClassEditorDialog(
            timetableId: 'tt-editor-1',
            day: TimetableDay.monday,
            startPeriodIndex: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TimetableClassEditorDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // =========================================================================
    // 11. DARK MODE THEME RENDERING
    // =========================================================================
    testWidgets('11. Dark mode renders class editor cleanly with dark surface tokens', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createSampleContainer();
      final authoringState = TimetableAuthoringState(
        container: container,
        periods: testPeriods,
        breaks: testBreaks,
        entries: [],
      );

      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          isDark: true,
          child: const TimetableClassEditorDialog(
            timetableId: 'tt-editor-1',
            day: TimetableDay.monday,
            startPeriodIndex: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TimetableClassEditorDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
