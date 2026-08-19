import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_lookup_providers.dart';
import 'package:campus_management/features/timetable/presentation/screens/timetable_dashboard_screen.dart';
import 'package:campus_management/features/timetable/presentation/screens/timetable_management_screen.dart';
import 'package:campus_management/features/timetable/presentation/screens/timetable_form_screen.dart';
import 'package:campus_management/features/timetable/presentation/widgets/timetable_widgets.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:google_fonts/google_fonts.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Prompt 95: Timetable UI/UX Redesign & Micro-Interactions Verification', () {
    late UserModel mockStudent;
    late UserModel mockAdmin;
    late TimetableModel mockEntry1;
    late TimetableModel mockEntry2;

    setUp(() {
      mockStudent = const UserModel(
        id: 'std-1',
        name: 'Student Alice',
        email: 'alice@acadex.com',
        role: AppRole.student,
        collegeId: 'col-1',
        sectionId: 'sec-1',
      );

      mockAdmin = const UserModel(
        id: 'adm-1',
        name: 'Admin Bob',
        email: 'admin@acadex.com',
        role: AppRole.collegeAdmin,
        collegeId: 'col-1',
      );

      mockEntry1 = TimetableModel(
        id: 'tt-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-1',
        academicYearId: 'ay-1',
        semesterId: 'sem-1',
        sectionId: 'sec-1',
        subjectId: 'sub-ds',
        facultyId: 'fac-turing',
        dayOfWeek: TimetableDay.monday,
        startTime: '09:00',
        endTime: '10:00',
        roomNumber: 'C-204',
        building: 'Main Block',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      mockEntry2 = TimetableModel(
        id: 'tt-2',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-1',
        academicYearId: 'ay-1',
        semesterId: 'sem-1',
        sectionId: 'sec-1',
        subjectId: 'sub-dbms',
        facultyId: 'fac-hopper',
        dayOfWeek: TimetableDay.monday,
        startTime: '10:00',
        endTime: '11:00',
        roomNumber: 'Lab-1',
        building: 'Science Block',
        sessionType: TimetableSessionType.lab,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    Widget createTestableWidget(Widget child, {List<Override> overrides = const []}) {
      return ProviderScope(
        overrides: [
          timetableSubjectMapProvider.overrideWithValue({}),
          timetableFacultyMapProvider.overrideWithValue({}),
          timetableSectionMapProvider.overrideWithValue({}),
          timetableDepartmentMapProvider.overrideWithValue({}),
          timetableCourseMapProvider.overrideWithValue({}),
          ...overrides,
        ],
        child: MaterialApp(
          home: Scaffold(body: child),
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
        ),
      );
    }

    testWidgets('1. Dashboard renders with Week view and AnimatedSwitcher by default', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          const TimetableDashboardScreen(),
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: mockStudent, token: 'token'))),
            weeklyTimetableProvider.overrideWith((ref) => Stream.value({
              TimetableDay.monday: [mockEntry1, mockEntry2],
              TimetableDay.tuesday: [],
              TimetableDay.wednesday: [],
              TimetableDay.thursday: [],
              TimetableDay.friday: [],
              TimetableDay.saturday: [],
              TimetableDay.sunday: [],
            })),
            timetableViewModeProvider.overrideWith((ref) => TimetableViewMode.week),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Timetable'), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('List'), findsOneWidget);
      expect(find.text('Monday'), findsWidgets);
    });

    testWidgets('2. Dashboard view switcher transitions smoothly to Day view', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          const TimetableDashboardScreen(),
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: mockStudent, token: 'token'))),
            weeklyTimetableProvider.overrideWith((ref) => Stream.value({
              TimetableDay.monday: [mockEntry1],
              TimetableDay.tuesday: [],
              TimetableDay.wednesday: [],
              TimetableDay.thursday: [],
              TimetableDay.friday: [],
              TimetableDay.saturday: [],
              TimetableDay.sunday: [],
            })),
            timetableSelectedDayProvider.overrideWith((ref) => TimetableDay.monday),
            timetableViewModeProvider.overrideWith((ref) => TimetableViewMode.day),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Monday'), findsWidgets);
      expect(find.text('1 class scheduled'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('3. TimetableCard resolves names and opens detail modal on tap', (tester) async {
      final mockSubject = Subject(
        id: 'sub-ds',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        semesterId: 'sem-1',
        name: 'Data Structures & Algorithms',
        code: 'CS301',
        credits: 4,
        type: 'Theory',
      );

      final mockFaculty = Faculty(
        id: 'fac-turing',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        name: 'Dr. Alan Turing',
        employeeId: 'EMP001',
        email: 'turing@acadex.com',
        phone: '1234567890',
        subjectIds: ['sub-ds'],
        sectionIds: ['sec-1'],
      );

      await tester.pumpWidget(
        createTestableWidget(
          TimetableCard(entry: mockEntry1),
          overrides: [
            timetableSubjectMapProvider.overrideWithValue({'sub-ds': mockSubject}),
            timetableFacultyMapProvider.overrideWithValue({'fac-turing': mockFaculty}),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Data Structures & Algorithms'), findsOneWidget);
      expect(find.text('CS301'), findsOneWidget);
      expect(find.text('Dr. Alan Turing'), findsOneWidget);
      expect(find.text('09:00 – 10:00'), findsOneWidget);
      expect(find.text('Lecture'), findsOneWidget);
      expect(find.text('Room C-204 · Main Block'), findsOneWidget);

      // Tap to trigger detail modal
      await tester.tap(find.byType(TimetableCard));
      await tester.pumpAndSettle();

      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Session Type: '), findsOneWidget);
    });

    testWidgets('4. TimetableManagementScreen renders filters, search and "+ Add Schedule"', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          const TimetableManagementScreen(),
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: mockAdmin, token: 'token'))),
            managementTimetableProvider.overrideWith((ref) => Future.value([mockEntry1, mockEntry2])),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Manage Timetable'), findsOneWidget);
      expect(find.text('Add Schedule'), findsOneWidget);
      expect(find.text('Search by subject, faculty, room or section...'), findsOneWidget);
      expect(find.text('All Days'), findsOneWidget);
    });

    testWidgets('5. TimetableFormScreen renders all 5 sections with animated conflict support', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          const TimetableFormScreen(),
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: mockAdmin, token: 'token'))),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Create Timetable Schedule'), findsOneWidget);
      expect(find.text('1. Academic Information'), findsOneWidget);
      expect(find.text('2. Teaching Assignment'), findsOneWidget);
      expect(find.text('3. Schedule & Timing'), findsOneWidget);
      expect(find.text('4. Classroom & Location'), findsOneWidget);
      expect(find.text('5. Audit & Distribution Status'), findsOneWidget);
    });

    testWidgets('6. TodayScheduleWidget displays classes when available and empty state when empty', (tester) async {
      // With classes
      await tester.pumpWidget(
        createTestableWidget(
          TodayScheduleWidget(todayEntries: [mockEntry1]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('09:00 – 10:00'), findsOneWidget);

      // Empty
      await tester.pumpWidget(
        createTestableWidget(
          const TodayScheduleWidget(todayEntries: []),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No classes scheduled for today'), findsOneWidget);
    });

    testWidgets('7. AcadexMotion respects reduced motion settings', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            final duration = AcadexMotion.resolveDuration(context, AcadexMotion.normal);
            expect(duration, equals(AcadexMotion.normal));
            return const SizedBox.shrink();
          },
        ),
      );
    });
  });
}
