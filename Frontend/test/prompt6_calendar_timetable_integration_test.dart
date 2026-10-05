import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/core/presentation/utils/acadex_entity_formatters.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/attendance/domain/models/assigned_class.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:campus_management/features/calendar/domain/models/calendar_event_model.dart';
import 'package:campus_management/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_lookup_providers.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/timetable/presentation/screens/timetable_dashboard_screen.dart';
import 'package:campus_management/features/timetable/presentation/widgets/acadex_timetable_calendar.dart';
import 'package:campus_management/features/timetable/presentation/widgets/daily_timeline_view.dart';
import 'package:campus_management/features/timetable/presentation/widgets/dashboard_timetable_live_card.dart';
import 'package:campus_management/features/timetable/presentation/widgets/timetable_entry_detail_sheet.dart';
import 'package:campus_management/features/timetable/presentation/widgets/timetable_widgets.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.initial);

  @override
  Future<void> login(String identifier, String password) async {}
  @override
  Future<void> loginAsDevelopmentRole(AppRole role) async {}
  @override
  Future<void> logout() async { state = const AuthUnauthenticated(); }
  @override
  Future<void> logoutAll() async { state = const AuthUnauthenticated(); }
  @override
  Future<void> resetPassword(String email) async {}
  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {}
  @override
  void updateCurrentUser(UserModel updatedUser) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Test Entities
  final mockUserFaculty = UserModel(
    id: 'user_fac_01',
    collegeId: 'col_123',
    departmentId: 'dept_cs',
    name: 'Prof. Alan Turing',
    email: 'alan@acadex.edu',
    role: AppRole.faculty,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final mockUserStudent = UserModel(
    id: 'user_stu_01',
    collegeId: 'col_123',
    departmentId: 'dept_cs',
    name: 'John Student',
    email: 'john@acadex.edu',
    role: AppRole.student,
    sectionId: 'sec_cs_a',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final mockEntry1 = TimetableModel(
    id: 'entry_01',
    timetableId: 'tt_published_01',
    collegeId: 'col_123',
    departmentId: 'dept_cs',
    courseId: 'crs_btech',
    academicYearId: 'ay_2026',
    semesterId: 'sem_05',
    sectionId: 'sec_cs_a',
    subjectId: 'sub_dbms_01',
    facultyId: 'fac_turing_01',
    facultyAssignmentId: 'fa_dbms_turing',
    roomId: 'room_204',
    dayOfWeek: TimetableDay.thursday,
    startTime: '10:00',
    endTime: '11:00',
    roomNumber: '204',
    building: 'CS Block',
    sessionType: TimetableSessionType.lecture,
    subjectName: 'Database Systems',
    subjectCode: 'CS501',
    sectionName: 'A',
    facultyName: 'Prof. Alan Turing',
    courseName: 'B.Tech CSE',
    semesterName: 'Semester 5',
    cohort: '2024-2028',
    academicStage: 'Year 3',
    contextualDescription: '2024-2028 · Year 3 · Semester 5 · Class A',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final mockEntry2 = TimetableModel(
    id: 'entry_02',
    timetableId: 'tt_published_01',
    collegeId: 'col_123',
    departmentId: 'dept_cs',
    courseId: 'crs_btech',
    academicYearId: 'ay_2026',
    semesterId: 'sem_05',
    sectionId: 'sec_cs_a',
    subjectId: 'sub_algo_02',
    facultyId: 'fac_knuth_02',
    facultyAssignmentId: 'fa_algo_knuth',
    roomId: 'room_205',
    dayOfWeek: TimetableDay.thursday,
    startTime: '11:15',
    endTime: '12:15',
    roomNumber: '205',
    building: 'CS Block',
    sessionType: TimetableSessionType.lecture,
    subjectName: 'Advanced Algorithms',
    subjectCode: 'CS502',
    sectionName: 'A',
    facultyName: 'Prof. Donald Knuth',
    courseName: 'B.Tech CSE',
    semesterName: 'Semester 5',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  group('PROMPT 6: Academic Calendar & Working Day / Holiday Integration', () {
    testWidgets('1. DailyTimelineView renders Holiday state and suppresses classes when date is configured holiday', (tester) async {
      final holidayDate = DateTime(2026, 10, 2); // Gandhi Jayanti

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: mockUserFaculty, token: 'mock-token'))),
            currentUserProvider.overrideWith((ref) => mockUserFaculty),
            workingDayResolutionProvider('2026-10-02').overrideWith(
              (ref) async => const WorkingDayResolution(
                date: '2026-10-02',
                isWorkingDay: false,
                isHoliday: true,
                reason: 'Gandhi Jayanti',
                overrideType: 'HOLIDAY',
              ),
            ),
            selectedDayEventsProvider.overrideWithValue([]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: DailyTimelineView(
                entries: const [],
                selectedDate: holidayDate,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verified Holiday state elements
      expect(find.text('HOLIDAY'), findsWidgets);
      expect(find.text('Gandhi Jayanti'), findsOneWidget);
      expect(find.text('No regular classes scheduled.'), findsOneWidget);
      // Generic misleading message must NOT appear
      expect(find.text('No classes scheduled for this day'), findsNothing);
    });

    testWidgets('2. DailyTimelineView renders campus events distinctly when no classes are scheduled', (tester) async {
      final eventDate = DateTime(2026, 10, 15);

      final mockExamEvent = CalendarEventModel(
        id: 'ev_exam_01',
        title: 'Mid-Term DBMS Examination',
        description: 'Semester 5 Computer Science Mid-Semester Examination',
        eventType: CalendarEventType.examination,
        startDate: '2026-10-15',
        endDate: '2026-10-15',
        location: 'Auditorium Hall A',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: mockUserStudent, token: 'mock-token'))),
            currentUserProvider.overrideWith((ref) => mockUserStudent),
            workingDayResolutionProvider('2026-10-15').overrideWith(
              (ref) async => const WorkingDayResolution(
                date: '2026-10-15',
                isWorkingDay: true,
                isHoliday: false,
              ),
            ),
            selectedDayEventsProvider.overrideWithValue([mockExamEvent]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: DailyTimelineView(
                entries: const [],
                selectedDate: eventDate,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EXAMINATION'), findsOneWidget);
      expect(find.text('Mid-Term DBMS Examination'), findsOneWidget);
      expect(find.text('Auditorium Hall A'), findsOneWidget);
      expect(find.text('No regular timetable classes scheduled on this day.'), findsOneWidget);
    });

    testWidgets('3. AcadexTimetableCalendar supports date navigation and month switching', (tester) async {
      DateTime selected = DateTime(2026, 10, 1);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            timetableSelectedDateProvider.overrideWith((ref) => selected),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: AcadexTimetableCalendar(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifies Month Title
      expect(find.text("October '26"), findsOneWidget);
      // Verifies weekday labels
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);

      // Tap Next Month Chevron
      final nextMonthBtn = find.byTooltip('Next Month');
      expect(nextMonthBtn, findsOneWidget);
      await tester.tap(nextMonthBtn);
      await tester.pumpAndSettle();

      // Month Title transitions to November '26
      expect(find.text("November '26"), findsOneWidget);
    });
  });

  group('PROMPT 6: Timetable Modes & Multi-View Behavior', () {
    testWidgets('4. TimetableDashboardScreen properly respects ViewMode on mobile (Day, Week, List)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final weeklyMap = {
        TimetableDay.thursday: [mockEntry1, mockEntry2],
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: mockUserFaculty, token: 'mock-token'))),
            currentUserProvider.overrideWith((ref) => mockUserFaculty),
            weeklyTimetableProvider.overrideWith((ref) => Stream.value(weeklyMap)),
            timetableSelectedDayProvider.overrideWith((ref) => TimetableDay.thursday),
            timetableSelectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 1)),
            timetableViewModeProvider.overrideWith((ref) => TimetableViewMode.day),
            workingDayResolutionProvider('2026-10-01').overrideWith(
              (ref) async => const WorkingDayResolution(
                date: '2026-10-01',
                isWorkingDay: true,
                isHoliday: false,
              ),
            ),
            selectedDayEventsProvider.overrideWithValue([]),
          ],
          child: const MaterialApp(
            home: TimetableDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In Day mode, DailyTimelineView renders entries
      expect(find.text('Database Systems'), findsOneWidget);
      expect(find.text('Advanced Algorithms'), findsOneWidget);

      // Switch to List mode by tapping the List segment
      // (Verifies that isMobile does NOT lock mobile users into Day view)
      await tester.tap(find.text('List'));
      await tester.pumpAndSettle();

      // In List mode, TimetableListView renders day group headers
      expect(find.byType(TimetableListView), findsOneWidget);
      expect(find.text('Thursday'), findsOneWidget);
      expect(find.text('2 classes'), findsOneWidget);
    });
  });

  group('PROMPT 6: Timetable → FacultyAssignment & Timetable → Attendance Integration', () {
    testWidgets('5. Marking Attendance from Timetable preserves authoritative IDs and canonical context', (tester) async {
      AssignedClass? activeClassCaptured;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: mockUserFaculty, token: 'mock-token'))),
            currentUserProvider.overrideWith((ref) => mockUserFaculty),
            workingDayResolutionProvider('2026-10-01').overrideWith(
              (ref) async => const WorkingDayResolution(
                date: '2026-10-01',
                isWorkingDay: true,
                isHoliday: false,
              ),
            ),
            selectedDayEventsProvider.overrideWithValue([]),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              return MaterialApp(
                theme: AppTheme.lightTheme,
                home: Scaffold(
                  body: DailyTimelineView(
                    entries: [mockEntry1],
                    selectedDate: DateTime(2026, 10, 1),
                  ),
                  floatingActionButton: Builder(
                    builder: (ctx) => ElevatedButton(
                      onPressed: () {
                        activeClassCaptured = ref.read(activeClassProvider);
                      },
                      child: const Text('Check Active Class'),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify human-readable titles and zero raw IDs
      expect(find.text('Database Systems'), findsOneWidget);
      expect(find.text('Section A'), findsOneWidget);
      expect(find.text('10:00 – 11:00'), findsOneWidget);
      expect(find.text('CS Block • 204'), findsOneWidget);

      // Verify no raw IDs in UI
      expect(find.text('sub_dbms_01'), findsNothing);
      expect(find.text('sec_cs_a'), findsNothing);
      expect(find.text('fa_dbms_turing'), findsNothing);

      // Tap "Mark Attendance"
      final markAttendanceBtn = find.text('Mark Attendance');
      expect(markAttendanceBtn, findsOneWidget);
      await tester.tap(markAttendanceBtn);
      await tester.pumpAndSettle();

      // Check captured active class from provider
      await tester.tap(find.text('Check Active Class'));
      await tester.pumpAndSettle();

      expect(activeClassCaptured, isNotNull);
      expect(activeClassCaptured!.timetableId, equals('tt_published_01'));
      expect(activeClassCaptured!.timetableEntryId, equals('entry_01'));
      expect(activeClassCaptured!.facultyAssignmentId, equals('fa_dbms_turing'));
      expect(activeClassCaptured!.subjectId, equals('sub_dbms_01'));
      expect(activeClassCaptured!.subjectName, equals('Database Systems'));
      expect(activeClassCaptured!.sectionId, equals('sec_cs_a'));
      expect(activeClassCaptured!.sectionName, equals('A'));
      expect(activeClassCaptured!.timeSlot, equals('10:00 – 11:00'));
      expect(activeClassCaptured!.date, equals(DateTime(2026, 10, 1)));
    });

    testWidgets('6. TimetableEntryDetailSheet displays rich context and role-specific actions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: mockUserFaculty, token: 'mock-token'))),
            currentUserProvider.overrideWith((ref) => mockUserFaculty),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: TimetableEntryDetailSheet(
                entry: mockEntry1,
                selectedDate: DateTime(2026, 10, 1),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifies all canonical context fields
      expect(find.text('Database Systems'), findsOneWidget);
      expect(find.text('CS501'), findsOneWidget);
      expect(find.text('Thursday · 10:00 – 11:00'), findsOneWidget);
      expect(find.text('Section A'), findsOneWidget);
      expect(find.text('Prof. Alan Turing'), findsOneWidget);
      expect(find.text('CS Block · Room 204'), findsOneWidget);
      expect(find.text('2024-2028 · Year 3 · Semester 5 · Class A'), findsOneWidget);

      // Verifies Faculty actions are present
      expect(find.text('Mark Attendance'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Assignments'), findsOneWidget);

      // Student/HOD only actions must not show for Faculty
      expect(find.text('My Attendance'), findsNothing);
      expect(find.text('Faculty Assignment'), findsNothing);
    });

    testWidgets('7. TimetableEntryDetailSheet presents student actions for student role', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: mockUserStudent, token: 'mock-token'))),
            currentUserProvider.overrideWith((ref) => mockUserStudent),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: TimetableEntryDetailSheet(
                entry: mockEntry1,
                selectedDate: DateTime(2026, 10, 1),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Student actions
      expect(find.text('My Attendance'), findsOneWidget);
      expect(find.text('Subject Notes'), findsOneWidget);

      // Faculty action must NOT appear for students
      expect(find.text('Mark Attendance'), findsNothing);
    });
  });

  group('PROMPT 6: Dashboard Live Context Card', () {
    testWidgets('8. DashboardTimetableLiveCard renders active current class with direct Mark Attendance', (tester) async {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: mockUserFaculty, token: 'mock-token'))),
            currentUserProvider.overrideWith((ref) => mockUserFaculty),
            workingDayResolutionProvider(dateStr).overrideWith(
              (ref) async => WorkingDayResolution(
                date: dateStr,
                isWorkingDay: true,
                isHoliday: false,
              ),
            ),
            currentClassProvider.overrideWithValue(AsyncValue.data(mockEntry1)),
            nextClassProvider.overrideWithValue(const AsyncValue.data(null)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardTimetableLiveCard(role: AppRole.faculty),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CURRENT CLASS'), findsOneWidget);
      expect(find.text('Database Systems'), findsOneWidget);
      expect(find.text('10:00 – 11:00'), findsOneWidget);
      expect(find.text('Section A'), findsOneWidget);
      expect(find.text('Mark Attendance'), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);
    });
  });

  group('PROMPT 6: Responsive Multi-Viewport Suite (360, 390, 412, 768, 1280dp)', () {
    final viewports = [
      const Size(360, 640),
      const Size(390, 844),
      const Size(412, 915),
      const Size(768, 1024),
      const Size(1280, 800),
    ];

    for (final size in viewports) {
      testWidgets('9. Timetable renders without overflow or clipping at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: mockUserFaculty, token: 'mock-token'))),
              currentUserProvider.overrideWith((ref) => mockUserFaculty),
              workingDayResolutionProvider('2026-10-01').overrideWith(
                (ref) async => const WorkingDayResolution(
                  date: '2026-10-01',
                  isWorkingDay: true,
                  isHoliday: false,
                ),
              ),
              selectedDayEventsProvider.overrideWithValue([]),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: DailyTimelineView(
                  entries: [mockEntry1, mockEntry2],
                  selectedDate: DateTime(2026, 10, 1),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Database Systems'), findsOneWidget);
        expect(find.text('Advanced Algorithms'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('PROMPT 6: Entity Sanitization & Zero Internal ID Leakage', () {
    testWidgets('10. AcadexEntityFormatters sanitize missing or raw object IDs with graceful fallbacks', (tester) async {
      // Raw 24-character hexadecimal MongoDB ObjectIds
      const rawSubjectId = '67389a0b12c34d5e6f7a8b9c';
      const rawFacultyId = '67389a0b12c34d5e6f7a8b9d';
      const rawSectionId = '67389a0b12c34d5e6f7a8b9e';

      final cleanSubject = AcadexEntityFormatters.formatSubjectLabel(null, rawId: rawSubjectId);
      final cleanFaculty = AcadexEntityFormatters.formatFacultyLabel(null, rawId: rawFacultyId);
      final cleanSection = AcadexEntityFormatters.formatSectionLabel(null, rawId: rawSectionId);

      expect(cleanSubject, equals('Assigned Subject'));
      expect(cleanFaculty, equals('Faculty Member'));
      expect(cleanSection, equals('Assigned Section'));

      // Clean human-readable values pass through uncorrupted
      expect(AcadexEntityFormatters.formatSubjectLabel('Compiler Design'), equals('Compiler Design'));
      expect(AcadexEntityFormatters.formatFacultyLabel('Dr. Grace Hopper'), equals('Dr. Grace Hopper'));
      expect(AcadexEntityFormatters.formatSectionLabel('B', prefix: true), equals('Section B'));
      expect(AcadexEntityFormatters.formatSectionLabel('B', prefix: false), equals('B'));
    });
  });
}
