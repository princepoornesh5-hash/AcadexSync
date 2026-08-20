import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/data/repositories/mock_timetable_repository.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_authoring_providers.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_lookup_providers.dart';
import 'package:campus_management/features/timetable/presentation/widgets/timetable_structure_editor_dialog.dart';
import 'package:campus_management/features/timetable/presentation/screens/timetable_designer_screen.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ACADEX Phase 5C: Flexible Period & Break Designer Tests', () {
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

    final initialPeriods = [
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
    ];

    final initialBreaks = [
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
      String id = 'tt-structure-1',
      TimetableTimingMode timingMode = TimetableTimingMode.sameEveryDay,
    }) {
      return TimetableContainerModel(
        id: id,
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-btech',
        academicYearId: 'ay-2026',
        semesterId: 'sem-4',
        sectionId: 'sec-4a',
        name: 'CSE Sem 4 Sec A Schedule',
        status: TimetableStatus.draft,
        version: 1,
        activeDays: const [
          TimetableDay.monday,
          TimetableDay.tuesday,
          TimetableDay.wednesday,
          TimetableDay.thursday,
          TimetableDay.friday,
        ],
        timingMode: timingMode,
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
          timetableSubjectMapProvider.overrideWithValue(const {}),
          timetableFacultyMapProvider.overrideWithValue(const {}),
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
    // 1. ADD PERIOD WORKFLOW & RECALCULATION
    // =========================================================================
    testWidgets('1. Add Period dialog creates new period with contiguous index', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createSampleContainer();
      final authoringState = TimetableAuthoringState(
        container: container,
        periods: List.from(initialPeriods),
        breaks: [],
        entries: [],
      );

      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          child: const TimetableStructureEditorDialog(timetableId: 'tt-structure-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Periods & Timing (3)'), findsOneWidget);
      expect(find.text('P1'), findsOneWidget);
      expect(find.text('P2'), findsOneWidget);
      expect(find.text('P3'), findsOneWidget);

      // Tap Add Period button in tab
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Period'));
      await tester.pumpAndSettle();

      // Form dialog is shown with default 'Period 4' and start '12:00'
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, '10:00'), '13:00'); // End time
      await tester.pumpAndSettle();

      // Tap Add in subdialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      // Period 4 added
      expect(find.text('P4'), findsOneWidget);
    });

    // =========================================================================
    // 2. EDIT PERIOD & REORDERING
    // =========================================================================
    testWidgets('2. Edit Period and Reorder up/down recalculates indices', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createSampleContainer();
      final authoringState = TimetableAuthoringState(
        container: container,
        periods: List.from(initialPeriods),
        breaks: [],
        entries: [],
      );

      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          child: const TimetableStructureEditorDialog(timetableId: 'tt-structure-1'),
        ),
      );
      await tester.pumpAndSettle();

      // Edit P1
      await tester.tap(find.byIcon(LucideIcons.pencil).first);
      await tester.pumpAndSettle();

      expect(find.text('Edit Period'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Period 1'), 'Morning Starter');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Morning Starter'), findsOneWidget);

      // Reorder P2 down
      await tester.tap(find.byIcon(LucideIcons.arrowDown).first);
      await tester.pumpAndSettle();

      // Verify indices maintained
      expect(find.text('P1'), findsOneWidget);
      expect(find.text('P2'), findsOneWidget);
    });

    // =========================================================================
    // 3. PREVENT DELETING OCCUPIED PERIOD
    // =========================================================================
    testWidgets('3. Occupied period shows disabled state or tooltip preventing delete', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createSampleContainer();
      final classEntryInP1 = TimetableGridEntryModel(
        id: 'entry-1',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 1,
        periodSpan: 1,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: 'sub-1',
        facultyId: 'fac-1',
        roomNumber: 'LH-1',
        sessionType: TimetableSessionType.lecture,
      );

      final authoringState = TimetableAuthoringState(
        container: container,
        periods: List.from(initialPeriods),
        breaks: [],
        entries: [classEntryInP1],
      );

      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          child: const TimetableStructureEditorDialog(timetableId: 'tt-structure-1'),
        ),
      );
      await tester.pumpAndSettle();

      // Occupied period has disabled tooltip
      expect(find.byTooltip('Occupied by class'), findsOneWidget);

      // P1 remains in the list
      expect(find.text('Period 1'), findsOneWidget);
    });

    // =========================================================================
    // 4. TIMING MODES (SAME EVERY DAY VS DIFFERENT PER DAY)
    // =========================================================================
    testWidgets('4. Timing mode switch enables day-specific tabs', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createSampleContainer();
      final authoringState = TimetableAuthoringState(
        container: container,
        periods: List.from(initialPeriods),
        breaks: [],
        entries: [],
      );

      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          child: const TimetableStructureEditorDialog(timetableId: 'tt-structure-1'),
        ),
      );
      await tester.pumpAndSettle();

      // Click Different Per Day chip
      await tester.tap(find.text('Different Per Day'));
      await tester.pumpAndSettle();

      // Active days chips are displayed (Monday, Tuesday, Wednesday, Thursday, Friday)
      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Tuesday'), findsOneWidget);
      expect(find.text('Wednesday'), findsOneWidget);
    });

    // =========================================================================
    // 5. BREAK DESIGNER (ADD/EDIT/DELETE COMMON & DAY-SPECIFIC BREAKS)
    // =========================================================================
    testWidgets('5. Break Designer allows adding, editing, and deleting common & day-specific breaks', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createSampleContainer();
      final authoringState = TimetableAuthoringState(
        container: container,
        periods: List.from(initialPeriods),
        breaks: List.from(initialBreaks),
        entries: [],
      );

      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          child: const TimetableStructureEditorDialog(timetableId: 'tt-structure-1'),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Breaks Tab
      await tester.tap(find.text('Breaks (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Lunch Break'), findsOneWidget);
      expect(find.text('Common Break'), findsOneWidget);
      expect(find.text('Vertical Span'), findsOneWidget);

      // Add a Tea Break
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Break'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Lunch Break'), 'Afternoon Tea');
      await tester.enterText(find.widgetWithText(TextField, '13:00'), '16:00');
      await tester.enterText(find.widgetWithText(TextField, '14:00'), '16:30');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.text('Afternoon Tea'), findsOneWidget);

      // Delete the Lunch Break
      await tester.tap(find.byIcon(LucideIcons.trash2).first);
      await tester.pumpAndSettle();

      expect(find.text('Lunch Break'), findsNothing);
    });

    // =========================================================================
    // 6. ROLE RESTRICTIONS
    // =========================================================================
    testWidgets('6. Student has read-only structure access without modification buttons', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createSampleContainer();
      final authoringState = TimetableAuthoringState(
        container: container,
        periods: List.from(initialPeriods),
        breaks: List.from(initialBreaks),
        entries: [],
      );

      // Test as Student
      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          currentUser: studentUser,
          child: const TimetableStructureEditorDialog(timetableId: 'tt-structure-1'),
        ),
      );
      await tester.pumpAndSettle();

      // Add Period and action buttons are not shown for read-only user
      expect(find.widgetWithText(ElevatedButton, 'Add Period'), findsNothing);
      expect(find.byIcon(LucideIcons.pencil), findsNothing);
      expect(find.byIcon(LucideIcons.trash2), findsNothing);
    });

    testWidgets('7. Structure & Timing button is accessible from TimetableDesignerScreen for HOD', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createSampleContainer();
      final authoringState = TimetableAuthoringState(
        container: container,
        periods: List.from(initialPeriods),
        breaks: List.from(initialBreaks),
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

      // Tap Structure & Timing in toolbar
      final structureBtn = find.widgetWithText(OutlinedButton, 'Structure & Timing');
      expect(structureBtn, findsOneWidget);
      await tester.tap(structureBtn);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.byType(TimetableStructureEditorDialog), findsOneWidget);
    });

    // =========================================================================
    // 8. DARK MODE & RESPONSIVE LAYOUT
    // =========================================================================
    testWidgets('8. Dark mode renders structure editor cleanly', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createSampleContainer();
      final authoringState = TimetableAuthoringState(
        container: container,
        periods: List.from(initialPeriods),
        breaks: List.from(initialBreaks),
        entries: [],
      );

      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          isDark: true,
          child: const TimetableStructureEditorDialog(timetableId: 'tt-structure-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TimetableStructureEditorDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('9. Mobile layout (360x700) renders structure editor without overflow', (tester) async {
      final container = createSampleContainer();
      final authoringState = TimetableAuthoringState(
        container: container,
        periods: List.from(initialPeriods),
        breaks: List.from(initialBreaks),
        entries: [],
      );

      await tester.pumpWidget(
        createTestWidget(
          authoringState: authoringState,
          size: const Size(360, 700),
          child: const TimetableStructureEditorDialog(timetableId: 'tt-structure-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TimetableStructureEditorDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
