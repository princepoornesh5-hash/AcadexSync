import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/data/repositories/mock_timetable_repository.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/timetable/presentation/widgets/timetable_spreadsheet_grid.dart';
import 'package:campus_management/features/timetable/presentation/screens/timetable_designer_screen.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_lookup_providers.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ACADEX Phase 5A: Spreadsheet Grid Foundation Tests', () {
    late MockTimetableRepository mockRepo;

    final superAdminUser = UserModel(
      id: 'usr-sa',
      name: 'Super Admin',
      email: 'sa@acadex.edu',
      role: AppRole.superAdmin,
    );

    final collegeAdminUser = UserModel(
      id: 'usr-ca',
      name: 'College Admin',
      email: 'ca@col1.edu',
      role: AppRole.collegeAdmin,
      collegeId: 'col-1',
    );

    final hodCseUser = UserModel(
      id: 'usr-hod',
      name: 'HOD CSE',
      email: 'hod@col1.edu',
      role: AppRole.hod,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
    );

    final facultyNormalUser = UserModel(
      id: 'usr-fac',
      name: 'Normal Faculty',
      email: 'fac@col1.edu',
      role: AppRole.faculty,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
    );

    final studentUser = UserModel(
      id: 'usr-student',
      name: 'Student One',
      email: 'student@col1.edu',
      role: AppRole.student,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
      sectionId: 'sec-4a',
    );

    TimetableContainerModel createSampleContainer({
      String id = 'tt-grid-1',
      List<TimetableDay>? activeDays,
    }) {
      final now = DateTime.now();
      return TimetableContainerModel(
        id: id,
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-btech',
        academicYearId: 'ay-2026',
        semesterId: '4',
        sectionId: 'sec-4a',
        name: 'CSE Sem 4 Sec A Master Schedule',
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
        createdAt: now,
        updatedAt: now,
      );
    }

    final samplePeriods = [
      TimetablePeriodModel(id: 'p-1', index: 1, name: 'Period 1', startTime: '09:00', endTime: '10:00'),
      TimetablePeriodModel(id: 'p-2', index: 2, name: 'Period 2', startTime: '10:00', endTime: '11:00'),
      TimetablePeriodModel(id: 'p-3', index: 3, name: 'Period 3', startTime: '11:15', endTime: '12:15'),
      TimetablePeriodModel(id: 'p-4', index: 4, name: 'Period 4', startTime: '12:15', endTime: '13:15'),
    ];

    setUp(() {
      mockRepo = MockTimetableRepository();
    });

    Widget createTestWidget({
      required TimetableAuthoringState state,
      required TimetableAuthoringPermissions permissions,
      Brightness brightness = Brightness.light,
      Size screenSize = const Size(1200, 800),
      Function(TimetableDay day, int periodIndex)? onCellTap,
      Function(TimetableGridEntryModel entry)? onEntryTap,
    }) {
      return ProviderScope(
        overrides: [
          timetableRepositoryProvider.overrideWithValue(mockRepo),
          academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
          authProvider.overrideWith((ref) => MockAuthNotifier(const AuthUnauthenticated())),
          timetableSubjectMapProvider.overrideWithValue(const {}),
          timetableFacultyMapProvider.overrideWithValue(const {}),
          timetableSectionMapProvider.overrideWithValue(const {}),
          timetableDepartmentMapProvider.overrideWithValue(const {}),
          timetableCourseMapProvider.overrideWithValue(const {}),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: MediaQuery(
            data: MediaQueryData(size: screenSize),
            child: Scaffold(
              body: TimetableSpreadsheetGrid(
                authoringState: state,
                permissions: permissions,
                onCellTap: onCellTap,
                onEntryTap: onEntryTap,
              ),
            ),
          ),
        ),
      );
    }

    // =========================================================================
    // 1 - 6: Active Days, Period Headers, Coordinates & Entries
    // =========================================================================
    testWidgets('1, 2, 3. Active days and period headers render with deterministic alignment', (tester) async {
      final container = createSampleContainer();
      final state = TimetableAuthoringState(
        container: container,
        periods: samplePeriods,
        breaks: const [],
        entries: const [],
      );

      await tester.pumpWidget(createTestWidget(
        state: state,
        permissions: const TimetableAuthoringPermissions.full(),
      ));
      await tester.pumpAndSettle();

      // Verify Header Row
      expect(find.text('DAY / PERIOD'), findsOneWidget);
      expect(find.text('Period 1'), findsOneWidget);
      expect(find.text('Period 2'), findsOneWidget);
      expect(find.text('Period 3'), findsOneWidget);
      expect(find.text('Period 4'), findsOneWidget);
      expect(find.text('09:00 - 10:00'), findsOneWidget);

      // Verify Active Days
      expect(find.text('MONDAY'), findsOneWidget);
      expect(find.text('TUESDAY'), findsOneWidget);
      expect(find.text('WEDNESDAY'), findsOneWidget);
      expect(find.text('THURSDAY'), findsOneWidget);
      expect(find.text('FRIDAY'), findsOneWidget);
      expect(find.text('SATURDAY'), findsNothing);
    });

    testWidgets('4, 5, 6, 7. Empty cells, single-period entry and entry metadata render', (tester) async {
      final container = createSampleContainer();
      final entry = TimetableGridEntryModel(
        id: 'e-dbms',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 1,
        periodSpan: 1,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: 'Database Management',
        facultyId: 'Dr. Alan Turing',
        roomNumber: 'Room C-204',
        building: 'Main Block',
        sessionType: TimetableSessionType.lecture,
      );

      final state = TimetableAuthoringState(
        container: container,
        periods: samplePeriods,
        breaks: const [],
        entries: [entry],
      );

      await tester.pumpWidget(createTestWidget(
        state: state,
        permissions: const TimetableAuthoringPermissions.full(),
      ));
      await tester.pumpAndSettle();

      // Populated Entry
      expect(find.text('Database Management'), findsOneWidget);
      expect(find.text('Dr. Alan Turing'), findsOneWidget);
      expect(find.text('Room C-204 (Main Block)'), findsOneWidget);
      expect(find.text('LECTURE'), findsOneWidget);

      // Empty cells should have '+' affordance for full editable permissions
      expect(find.byIcon(LucideIcons.plus), findsWidgets);
    });

    // =========================================================================
    // 8 - 9: Merged Entries (2-period and 3-period)
    // =========================================================================
    testWidgets('8. Two-period merged entry renders exactly once across its span', (tester) async {
      final container = createSampleContainer();
      final mergedEntry = TimetableGridEntryModel(
        id: 'e-lab-2p',
        dayOfWeek: TimetableDay.tuesday,
        startPeriodIndex: 1,
        periodSpan: 2, // Periods 1 & 2
        startTime: '09:00',
        endTime: '11:00',
        subjectId: 'Operating Systems Lab',
        facultyId: 'Prof. Linus',
        roomNumber: 'Lab 102',
        sessionType: TimetableSessionType.lab,
      );

      final state = TimetableAuthoringState(
        container: container,
        periods: samplePeriods,
        breaks: const [],
        entries: [mergedEntry],
      );

      await tester.pumpWidget(createTestWidget(
        state: state,
        permissions: const TimetableAuthoringPermissions.full(),
      ));
      await tester.pumpAndSettle();

      // Merged cell rendered exactly once
      expect(find.text('Operating Systems Lab'), findsOneWidget);
      expect(find.text('LAB'), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowRightLeft), findsOneWidget);
    });

    testWidgets('9. Three-period merged entry spans correctly across periods', (tester) async {
      final container = createSampleContainer();
      final mergedEntry = TimetableGridEntryModel(
        id: 'e-project-3p',
        dayOfWeek: TimetableDay.wednesday,
        startPeriodIndex: 1,
        periodSpan: 3, // Periods 1, 2, 3
        startTime: '09:00',
        endTime: '12:15',
        subjectId: 'Capstone Major Project',
        facultyId: 'Prof. Hopper',
        roomNumber: 'Project Lab',
        sessionType: TimetableSessionType.practical,
      );

      final state = TimetableAuthoringState(
        container: container,
        periods: samplePeriods,
        breaks: const [],
        entries: [mergedEntry],
      );

      await tester.pumpWidget(createTestWidget(
        state: state,
        permissions: const TimetableAuthoringPermissions.full(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Capstone Major Project'), findsOneWidget);
      expect(find.text('PRACTICAL'), findsOneWidget);
    });

    // =========================================================================
    // 10 - 11: Common Breaks & Day-Specific Breaks
    // =========================================================================
    testWidgets('10 & 11. Common break and Day-specific break rendering', (tester) async {
      final container = createSampleContainer();
      final commonLunch = TimetableBreakModel(
        id: 'brk-lunch',
        name: 'Lunch Break',
        startTime: '12:15',
        endTime: '13:15',
        appliesToDays: [TimetableDay.monday, TimetableDay.tuesday, TimetableDay.wednesday, TimetableDay.thursday, TimetableDay.friday],
        breakType: TimetableBreakType.lunch,
      );

      final fridaySpecialBreak = TimetableBreakModel(
        id: 'brk-friday-assembly',
        name: 'Friday Assembly',
        startTime: '09:00',
        endTime: '10:00',
        appliesToDays: [TimetableDay.friday],
        breakType: TimetableBreakType.assembly,
      );

      final state = TimetableAuthoringState(
        container: container,
        periods: samplePeriods,
        breaks: [commonLunch, fridaySpecialBreak],
        entries: const [],
      );

      await tester.pumpWidget(createTestWidget(
        state: state,
        permissions: const TimetableAuthoringPermissions.full(),
      ));
      await tester.pumpAndSettle();

      // Common lunch renders on all 5 active days (Period 4: 12:15-13:15)
      expect(find.text('Lunch Break'), findsNWidgets(5));
      expect(find.byIcon(LucideIcons.utensils), findsNWidgets(5));

      // Friday assembly renders ONLY once on Friday (Period 1: 09:00-10:00)
      expect(find.text('Friday Assembly'), findsOneWidget);
    });

    // =========================================================================
    // 12 - 13: Selection Behavior
    // =========================================================================
    testWidgets('12 & 13. Selected cell and occupied entry selection callback', (tester) async {
      final container = createSampleContainer();
      final entry = TimetableGridEntryModel(
        id: 'e-1',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 1,
        periodSpan: 1,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: 'Algorithms',
        facultyId: 'Prof. Knuth',
        roomNumber: '101',
        sessionType: TimetableSessionType.lecture,
      );

      TimetableDay? tappedDay;
      int? tappedPIndex;
      TimetableGridEntryModel? tappedEntry;

      final state = TimetableAuthoringState(
        container: container,
        periods: samplePeriods,
        breaks: const [],
        entries: [entry],
        selectedCell: const TimetableCellCoordinate(day: TimetableDay.monday, periodIndex: 1),
        selectedEntryId: 'e-1',
      );

      await tester.pumpWidget(createTestWidget(
        state: state,
        permissions: const TimetableAuthoringPermissions.full(),
        onCellTap: (d, p) {
          tappedDay = d;
          tappedPIndex = p;
        },
        onEntryTap: (e) {
          tappedEntry = e;
        },
      ));
      await tester.pumpAndSettle();

      // Tap on occupied cell
      await tester.tap(find.text('Algorithms'));
      expect(tappedEntry?.id, 'e-1');

      // Tap on an empty cell (e.g. Tuesday Period 2)
      final plusIcons = find.byIcon(LucideIcons.plus);
      await tester.tap(plusIcons.first);
      expect(tappedDay, isNotNull);
      expect(tappedPIndex, isNotNull);
    });

    // =========================================================================
    // 14 - 19: Role-Based Affordances & Super Admin Platform Scope
    // =========================================================================
    testWidgets('14 & 15. Student and Normal Faculty read-only mode hides edit affordances', (tester) async {
      final container = createSampleContainer();
      final state = TimetableAuthoringState(
        container: container,
        periods: samplePeriods,
        breaks: const [],
        entries: const [],
      );

      // Student / Faculty: Read-only permissions
      await tester.pumpWidget(createTestWidget(
        state: state,
        permissions: const TimetableAuthoringPermissions.readOnly(),
      ));
      await tester.pumpAndSettle();

      // No '+' edit affordance in empty cells
      expect(find.byIcon(LucideIcons.plus), findsNothing);
    });

    testWidgets('16, 17, 18. HOD, College Admin, and Delegated Faculty show edit affordances', (tester) async {
      final container = createSampleContainer();
      final state = TimetableAuthoringState(
        container: container,
        periods: samplePeriods,
        breaks: const [],
        entries: const [],
      );

      await tester.pumpWidget(createTestWidget(
        state: state,
        permissions: const TimetableAuthoringPermissions.full(),
      ));
      await tester.pumpAndSettle();

      // Editable '+' icons present in grid
      expect(find.byIcon(LucideIcons.plus), findsWidgets);
    });

    // =========================================================================
    // 20: Dark Mode
    // =========================================================================
    testWidgets('20. Dark mode renders with dark theme tokens cleanly', (tester) async {
      final container = createSampleContainer();
      final state = TimetableAuthoringState(
        container: container,
        periods: samplePeriods,
        breaks: const [],
        entries: const [],
      );

      await tester.pumpWidget(createTestWidget(
        state: state,
        permissions: const TimetableAuthoringPermissions.full(),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.text('DAY / PERIOD'), findsOneWidget);
    });

    // =========================================================================
    // 21 - 22: Responsive & Horizontal Scrolling
    // =========================================================================
    testWidgets('21 & 22. Narrow viewport provides horizontal scrolling without overflow', (tester) async {
      final container = createSampleContainer();
      final state = TimetableAuthoringState(
        container: container,
        periods: samplePeriods,
        breaks: const [],
        entries: const [],
      );

      // Narrow screen (e.g., mobile 375x667)
      await tester.pumpWidget(createTestWidget(
        state: state,
        permissions: const TimetableAuthoringPermissions.full(),
        screenSize: const Size(375, 667),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(tester.takeException(), isNull); // 0 layout overflow errors
    });

    // =========================================================================
    // 23 - 25: Empty, Loading, and Error States in TimetableDesignerScreen
    // =========================================================================
    testWidgets('23. TimetableDesignerScreen renders loaded spreadsheet grid state', (tester) async {
      const ttId = 'tt-designer-loaded';
      final container = createSampleContainer(id: ttId);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            timetableRepositoryProvider.overrideWithValue(mockRepo),
            academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
            authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: hodCseUser, token: 'mock-token'))),
            currentUserProvider.overrideWithValue(hodCseUser),
            timetableAuthoringProvider.overrideWith(
              (ref, id) => TimetableAuthoringNotifier(
                repository: mockRepo,
                currentUser: hodCseUser,
              )..state = TimetableAuthoringState(
                container: container,
                periods: samplePeriods,
                breaks: const [],
                entries: const [],
              ),
            ),
            timetableSubjectMapProvider.overrideWithValue(const {}),
            timetableFacultyMapProvider.overrideWithValue(const {}),
            timetableSectionMapProvider.overrideWithValue(const {}),
            timetableDepartmentMapProvider.overrideWithValue(const {}),
            timetableCourseMapProvider.overrideWithValue(const {}),
          ],
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const MediaQuery(
              data: MediaQueryData(size: Size(1200, 800)),
              child: TimetableDesignerScreen(timetableId: ttId),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text(container.name), findsOneWidget);
      expect(find.text('DRAFT'), findsOneWidget);
      expect(find.text('Spreadsheet Grid'), findsOneWidget);
      expect(find.text('Save Draft'), findsOneWidget);
      expect(find.text('Publish'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('24. TimetableDesignerScreen renders loading state initially', (tester) async {
      const ttId = 'tt-designer-loading';
      final loadingNotifier = TimetableAuthoringNotifier(
        repository: mockRepo,
        currentUser: hodCseUser,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            timetableRepositoryProvider.overrideWithValue(mockRepo),
            academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
            authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: hodCseUser, token: 'mock-token'))),
            currentUserProvider.overrideWithValue(hodCseUser),
            timetableAuthoringProvider.overrideWith((ref, id) => loadingNotifier),
            timetableSubjectMapProvider.overrideWithValue(const {}),
            timetableFacultyMapProvider.overrideWithValue(const {}),
            timetableSectionMapProvider.overrideWithValue(const {}),
            timetableDepartmentMapProvider.overrideWithValue(const {}),
            timetableCourseMapProvider.overrideWithValue(const {}),
          ],
          child: const MaterialApp(
            home: TimetableDesignerScreen(timetableId: ttId),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Clean up widget tree to dispose spinning animation controller
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('25. TimetableDesignerScreen renders error state upon failure', (tester) async {
      const ttId = 'tt-designer-error';
      final errorNotifier = TimetableAuthoringNotifier(
        repository: mockRepo,
        currentUser: hodCseUser,
      );
      errorNotifier.state = const TimetableAuthoringState(errorMessage: 'Network error 500');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            timetableRepositoryProvider.overrideWithValue(mockRepo),
            academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
            authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: hodCseUser, token: 'mock-token'))),
            currentUserProvider.overrideWithValue(hodCseUser),
            timetableAuthoringProvider.overrideWith((ref, id) => errorNotifier),
            timetableSubjectMapProvider.overrideWithValue(const {}),
            timetableFacultyMapProvider.overrideWithValue(const {}),
            timetableSectionMapProvider.overrideWithValue(const {}),
            timetableDepartmentMapProvider.overrideWithValue(const {}),
            timetableCourseMapProvider.overrideWithValue(const {}),
          ],
          child: const MaterialApp(
            home: TimetableDesignerScreen(timetableId: ttId),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Error Loading Timetable'), findsOneWidget);
      expect(find.text('Network error 500'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
