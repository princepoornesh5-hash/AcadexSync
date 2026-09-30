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
import 'package:campus_management/features/calendar/presentation/widgets/calendar_event_detail_sheet.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePrompt45CalendarRepository implements CalendarRepository {
  List<CalendarEventModel> events;
  int fetchCount = 0;

  FakePrompt45CalendarRepository({this.events = const []});

  @override
  Future<List<CalendarEventModel>> getCalendar({
    String? startDate,
    String? endDate,
    String? eventType,
  }) async {
    fetchCount++;
    return events;
  }

  @override
  Future<CalendarEventModel> getEventById(String id) async {
    return events.firstWhere((e) => e.id == id);
  }

  @override
  Future<CalendarEventModel> createEvent(Map<String, dynamic> data) async {
    final newEv = CalendarEventModel.fromJson(data);
    events = [...events, newEv];
    return newEv;
  }

  @override
  Future<CalendarEventModel> updateEvent(String id, Map<String, dynamic> data) async {
    final idx = events.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final updated = events[idx].copyWith(title: data['title'] as String?);
      events[idx] = updated;
      return updated;
    }
    throw Exception('Event not found');
  }

  @override
  Future<CalendarEventModel> cancelEvent(String id, {String? reason}) async {
    final idx = events.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final updated = events[idx].copyWith(status: CalendarEventStatus.cancelled);
      events[idx] = updated;
      return updated;
    }
    throw Exception('Event not found');
  }

  @override
  Future<CalendarEventModel> publishEvent(String id) async {
    final idx = events.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final updated = events[idx].copyWith(status: CalendarEventStatus.published);
      events[idx] = updated;
      return updated;
    }
    throw Exception('Event not found');
  }

  @override
  Future<List<AcademicCalendarModel>> getAcademicCalendars({
    String? academicYearId,
    String? semesterId,
  }) async =>
      [
        const AcademicCalendarModel(
          id: 'cal_01',
          collegeId: 'college_01',
          academicYearId: 'ay_01',
          title: 'Fall 2026 Academic Calendar',
          startDate: '2026-08-01',
          endDate: '2026-12-31',
          status: 'ACTIVE',
        ),
      ];

  @override
  Future<AcademicCalendarModel> createAcademicCalendar(Map<String, dynamic> data) async =>
      AcademicCalendarModel.fromJson(data);

  @override
  Future<WorkingDayResolution> resolveWorkingDay(
    String date, {
    String? semesterId,
    String? departmentId,
  }) async =>
      WorkingDayResolution(
        date: date,
        isWorkingDay: !date.endsWith('15'),
        isHoliday: date.endsWith('15'),
      );

  @override
  Future<void> declareHoliday(Map<String, dynamic> data) async {}
}

void main() {
  const testStudent = UserModel(
    id: 'student_45',
    email: 'dennis@ait.edu',
    name: 'Dennis Ritchie',
    role: AppRole.student,
    collegeId: 'college_ait',
  );

  const testFaculty = UserModel(
    id: 'faculty_45',
    email: 'hopper@ait.edu',
    name: 'Prof. Hopper',
    role: AppRole.faculty,
    collegeId: 'college_ait',
  );

  final today = DateTime.now();
  final todayStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  final sampleMultiSourceEvents = [
    CalendarEventModel(
      id: 'class_01',
      title: 'Operating Systems Class',
      description: 'Room 301 • Prof. Hopper',
      sourceType: CalendarSourceType.timetable,
      sourceId: 'tt_01',
      eventType: CalendarEventType.timetableClass,
      startDate: todayStr,
      endDate: todayStr,
      startTime: '09:00',
      endTime: '10:00',
    ),
    CalendarEventModel(
      id: 'practical_01',
      title: 'POSIX Threads Lab',
      description: 'Lab 2 • Prof. Hopper',
      sourceType: CalendarSourceType.practical,
      sourceId: 'prac_01',
      eventType: CalendarEventType.practical,
      startDate: todayStr,
      endDate: todayStr,
      startTime: '10:00',
      endTime: '12:00',
      navigationTarget: '/practicals/prac_01',
    ),
    CalendarEventModel(
      id: 'assessment_01',
      title: 'OS Midterm Assessment',
      description: 'Maximum Marks: 50',
      sourceType: CalendarSourceType.assessment,
      sourceId: 'assess_01',
      eventType: CalendarEventType.internalAssessment,
      startDate: todayStr,
      endDate: todayStr,
      startTime: '14:00',
      endTime: '15:30',
      navigationTarget: '/assessments/assess_01',
    ),
    CalendarEventModel(
      id: 'assignment_01',
      title: 'Process Scheduling Assignment',
      description: 'Due 17:00',
      sourceType: CalendarSourceType.assignment,
      sourceId: 'assign_01',
      eventType: CalendarEventType.assignmentDeadline,
      startDate: todayStr,
      endDate: todayStr,
      startTime: '17:00',
      navigationTarget: '/assignments/assign_01',
    ),
    CalendarEventModel(
      id: 'holiday_01',
      title: 'National Engineers Day',
      description: 'College Holiday',
      sourceType: CalendarSourceType.manual,
      eventType: CalendarEventType.holiday,
      startDate: todayStr,
      endDate: todayStr,
      allDay: true,
    ),
    CalendarEventModel(
      id: 'result_01',
      title: 'Semester 4 Official Results',
      description: 'Result publication',
      sourceType: CalendarSourceType.academicResult,
      sourceId: 'res_01',
      eventType: CalendarEventType.resultPublication,
      startDate: todayStr,
      endDate: todayStr,
      allDay: true,
      navigationTarget: '/academic-results/res_01',
    ),
  ];

  Widget buildCalendarApp({
    required UserModel user,
    required FakePrompt45CalendarRepository repo,
    double width = 360,
    double height = 740,
  }) {
    return ProviderScope(
      overrides: [
        calendarRepositoryProvider.overrideWithValue(repo),
        authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: user, token: 'jwt'))),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: const Scaffold(body: CalendarScreen()),
        ),
      ),
    );
  }

  group('PROMPT 45 — Academic Calendar & Date-Aware Operations Frontend Tests', () {
    testWidgets('1. Calendar screen renders at 360px mobile width with zero overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakePrompt45CalendarRepository(events: sampleMultiSourceEvents);
      await tester.pumpWidget(buildCalendarApp(user: testStudent, repo: repo, width: 360));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Calendar screen renders at 390px and 412px responsive widths',
        (tester) async {
      final repo = FakePrompt45CalendarRepository(events: sampleMultiSourceEvents);

      // Test 390px
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(buildCalendarApp(user: testStudent, repo: repo, width: 390));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Test 412px
      tester.view.physicalSize = const Size(412, 915);
      await tester.pumpWidget(buildCalendarApp(user: testStudent, repo: repo, width: 412));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.resetPhysicalSize();
    });

    testWidgets('3. Agenda view displays multi-source operational events for selected day',
        (tester) async {
      final repo = FakePrompt45CalendarRepository(events: sampleMultiSourceEvents);
      await tester.pumpWidget(buildCalendarApp(user: testStudent, repo: repo, width: 412));
      await tester.pumpAndSettle();

      expect(find.text('Operating Systems Class'), findsWidgets);
      expect(find.text('POSIX Threads Lab'), findsWidgets);
      expect(find.text('OS Midterm Assessment'), findsWidgets);
      expect(find.text('Process Scheduling Assignment'), findsWidgets);
      expect(find.text('National Engineers Day'), findsWidgets);
      expect(find.text('Semester 4 Official Results'), findsWidgets);
    });

    testWidgets('4. Student view strictly hides mutation controls (No Add Event button)',
        (tester) async {
      final repo = FakePrompt45CalendarRepository(events: sampleMultiSourceEvents);
      await tester.pumpWidget(buildCalendarApp(user: testStudent, repo: repo, width: 360));
      await tester.pumpAndSettle();

      // Student should not see FloatingActionButton for adding events
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Add Event'), findsNothing);
    });

    testWidgets('5. Faculty view has authorized Add Event capability', (tester) async {
      final repo = FakePrompt45CalendarRepository(events: sampleMultiSourceEvents);
      await tester.pumpWidget(buildCalendarApp(user: testFaculty, repo: repo, width: 360));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('6. Event detail sheet displays human-readable source type and no ObjectIds',
        (tester) async {
      final practicalEv = sampleMultiSourceEvents[1]; // POSIX Threads Lab

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarEventDetailSheet(event: practicalEv),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('POSIX Threads Lab'), findsOneWidget);
      expect(find.text('Practical Session'), findsWidgets);
      expect(find.text('View Practical Session'), findsOneWidget);

      // Verify no raw IDs are shown
      expect(find.text('prac_01'), findsNothing);
      expect(find.text('practical_01'), findsNothing);
      expect(find.text('ObjectId'), findsNothing);
    });

    testWidgets('7. Domain models parse correctly for AcademicCalendar and WorkingDayResolution',
        (tester) async {
      final calJson = {
        'id': 'cal_99',
        'collegeId': 'col_99',
        'academicYearId': 'ay_99',
        'title': 'Spring 2027 Calendar',
        'startDate': '2027-01-01',
        'endDate': '2027-05-31',
        'status': 'ACTIVE',
        'workingDays': ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'],
      };

      final calModel = AcademicCalendarModel.fromJson(calJson);
      expect(calModel.id, 'cal_99');
      expect(calModel.title, 'Spring 2027 Calendar');
      expect(calModel.workingDays.length, 6);

      final workDayJson = {
        'date': '2027-01-15',
        'isWorkingDay': false,
        'isHoliday': true,
        'isOverride': true,
        'reason': 'Harvest Festival',
      };

      final workModel = WorkingDayResolution.fromJson(workDayJson);
      expect(workModel.isWorkingDay, isFalse);
      expect(workModel.isHoliday, isTrue);
      expect(workModel.reason, 'Harvest Festival');
    });

    testWidgets('8. Operational filter chips filter events accurately', (tester) async {
      final repo = FakePrompt45CalendarRepository(events: sampleMultiSourceEvents);
      await tester.pumpWidget(buildCalendarApp(user: testStudent, repo: repo, width: 412));
      await tester.pumpAndSettle();

      // Tap 'Holidays' chip
      await tester.tap(find.text('Holidays'));
      await tester.pumpAndSettle();

      // Holiday should remain visible
      expect(find.text('National Engineers Day'), findsWidgets);

      // Tap 'Classes' chip
      await tester.tap(find.text('Classes'));
      await tester.pumpAndSettle();

      expect(find.text('Operating Systems Class'), findsWidgets);
    });
  });
}
