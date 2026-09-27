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
import 'package:campus_management/features/calendar/presentation/widgets/calendar_event_card.dart';
import 'package:campus_management/features/calendar/presentation/widgets/calendar_event_detail_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCalendarRepository implements CalendarRepository {
  List<CalendarEventModel> events;

  FakeCalendarRepository({this.events = const []});

  @override
  Future<List<CalendarEventModel>> getCalendar({
    String? startDate,
    String? endDate,
    String? eventType,
  }) async {
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
}

void main() {
  const testStudentUser = UserModel(
    id: 'student_user_1',
    email: 'alice@coea.edu',
    name: 'Alice Student',
    role: AppRole.student,
    collegeId: 'college_01',
  );

  const testAdminUser = UserModel(
    id: 'admin_user_1',
    email: 'admin@coea.edu',
    name: 'College Admin',
    role: AppRole.collegeAdmin,
    collegeId: 'college_01',
  );

  const annualDayEvent = CalendarEventModel(
    id: 'cal_event_01',
    title: 'Annual Day Celebrations',
    description: 'Grand annual day of College A',
    sourceType: CalendarSourceType.manual,
    eventType: CalendarEventType.event,
    scope: CalendarEventScope.college,
    startDate: '2026-09-24',
    endDate: '2026-09-24',
    startTime: '10:00',
    endTime: '16:00',
    allDay: false,
    academicContext: 'Entire College',
    status: CalendarEventStatus.published,
    creatorName: 'Admin Alice',
    creatorRole: AppRole.collegeAdmin,
  );

  const assignmentEvent = CalendarEventModel(
    id: 'derived_assignment_101',
    title: 'DBMS Assignment 3',
    description: 'Due at 23:59',
    sourceType: CalendarSourceType.derived,
    sourceId: 'assign_101',
    eventType: CalendarEventType.deadline,
    scope: CalendarEventScope.classScope,
    startDate: '2026-09-24',
    endDate: '2026-09-24',
    startTime: '23:59',
    endTime: '23:59',
    allDay: false,
    academicContext: 'Database Management Systems • Section A',
    status: CalendarEventStatus.published,
    creatorName: 'Prof. Alan Turing',
    creatorRole: AppRole.faculty,
    navigationTarget: '/assignments/assign_101',
  );

  const publicHolidayEvent = CalendarEventModel(
    id: 'cal_holiday_01',
    title: 'Public Holiday',
    description: 'National holiday',
    sourceType: CalendarSourceType.system,
    eventType: CalendarEventType.publicHoliday,
    scope: CalendarEventScope.college,
    startDate: '2026-09-25',
    endDate: '2026-09-25',
    allDay: true,
    academicContext: 'Entire College',
    status: CalendarEventStatus.published,
    creatorName: 'Admin Alice',
    creatorRole: AppRole.collegeAdmin,
  );

  const examEvent = CalendarEventModel(
    id: 'cal_exam_01',
    title: 'Mid-Term Examination',
    description: 'Computer Engineering Department Exam',
    sourceType: CalendarSourceType.manual,
    eventType: CalendarEventType.exam,
    scope: CalendarEventScope.department,
    startDate: '2026-09-24',
    endDate: '2026-09-24',
    startTime: '14:00',
    endTime: '16:00',
    allDay: false,
    academicContext: 'Computer Science',
    status: CalendarEventStatus.published,
    creatorName: 'Dr. Grace Hopper',
    creatorRole: AppRole.hod,
    canCancel: true,
  );

  group('Prompt 23 — Academic Calendar Domain & Model Tests', () {
    test('1. CalendarEventModel parses manual event correctly', () {
      final json = {
        'id': 'ev_99',
        'title': 'College Fest',
        'description': 'Cultural festival',
        'sourceType': 'MANUAL',
        'eventType': 'EVENT',
        'scope': 'COLLEGE',
        'startDate': '2026-11-10',
        'endDate': '2026-11-12',
        'allDay': true,
        'academicContext': 'Entire College',
        'status': 'PUBLISHED',
        'creatorRole': 'COLLEGE_ADMIN',
        'creatorName': 'Principal Office',
        'canEdit': true,
        'canCancel': true,
      };

      final model = CalendarEventModel.fromJson(json);
      expect(model.id, 'ev_99');
      expect(model.title, 'College Fest');
      expect(model.sourceType, CalendarSourceType.manual);
      expect(model.eventType, CalendarEventType.event);
      expect(model.scope, CalendarEventScope.college);
      expect(model.allDay, isTrue);
      expect(model.startDate, '2026-11-10');
      expect(model.endDate, '2026-11-12');
      expect(model.canEdit, isTrue);
      expect(model.canCancel, isTrue);
    });

    test('2. CalendarEventModel parses derived assignment deadline with navigation target', () {
      final json = {
        'id': 'derived_assignment_55',
        'title': 'DBMS Lab 1',
        'description': 'Due at 18:00',
        'sourceType': 'DERIVED',
        'sourceId': 'assign_55',
        'eventType': 'DEADLINE',
        'scope': 'CLASS',
        'startDate': '2026-09-29',
        'endDate': '2026-09-29',
        'startTime': '18:00',
        'endTime': '18:00',
        'allDay': false,
        'status': 'PUBLISHED',
        'creatorRole': 'FACULTY',
        'creatorName': 'Prof. Turing',
        'navigationTarget': '/assignments/assign_55',
      };

      final model = CalendarEventModel.fromJson(json);
      expect(model.sourceType, CalendarSourceType.derived);
      expect(model.eventType, CalendarEventType.deadline);
      expect(model.navigationTarget, '/assignments/assign_55');
      expect(model.canEdit, isFalse);
    });
  });

  group('Prompt 23 — Academic Calendar UI Widget Tests', () {
    testWidgets('3. CalendarEventCard renders event title, time, and type badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalendarEventCard(event: annualDayEvent),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Annual Day Celebrations'), findsOneWidget);
      expect(find.text('Entire College'), findsOneWidget);
      expect(find.text('10:00 – 16:00'), findsOneWidget);
      expect(find.text('College Event'), findsOneWidget);
      expect(find.byIcon(LucideIcons.calendar), findsOneWidget);
    });

    testWidgets('4. CalendarEventCard for assignment deadline renders clock icon and deadline badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalendarEventCard(event: assignmentEvent),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('DBMS Assignment 3'), findsOneWidget);
      expect(find.text('Assignment Deadline'), findsOneWidget);
      expect(find.byIcon(LucideIcons.clock), findsWidgets);
    });

    testWidgets('5. CalendarEventDetailSheet displays full event details and cancel button if allowed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalendarEventDetailSheet(event: examEvent),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mid-Term Examination'), findsOneWidget);
      expect(find.text('Computer Engineering Department Exam'), findsOneWidget);
      expect(find.text('Scope: '), findsOneWidget);
      expect(find.text('Computer Science'), findsOneWidget);
      expect(find.text('Published by: '), findsOneWidget);
      expect(find.text('Dr. Grace Hopper (HOD)'), findsOneWidget);
      expect(find.text('Cancel Event'), findsOneWidget);
    });

    testWidgets('6. CalendarScreen renders calendar grid, date header, and events', (tester) async {
      final fakeRepo = FakeCalendarRepository(
        events: [annualDayEvent, assignmentEvent, examEvent, publicHolidayEvent],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: testStudentUser, token: 'jwt')),
            ),
            calendarRepositoryProvider.overrideWithValue(fakeRepo),
            selectedCalendarDateProvider.overrideWith((ref) => DateTime(2026, 9, 24)),
            currentMonthProvider.overrideWith((ref) => DateTime(2026, 9, 1)),
          ],
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check month header
      expect(find.text('September 2026'), findsOneWidget);

      // Check weekday headers
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);

      // Check filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Holidays'), findsOneWidget);
      expect(find.text('Exams'), findsOneWidget);
      expect(find.text('Deadlines'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);

      // Check selected date events (3 events on 24th: Annual Day, DBMS Assignment, Mid-Term Exam)
      expect(find.text('Annual Day Celebrations'), findsWidgets);
      expect(find.text('DBMS Assignment 3'), findsWidgets);
      expect(find.text('Mid-Term Examination'), findsWidgets);

      // Check events count badge
      expect(find.text('3 events'), findsOneWidget);
    });

    testWidgets('7. Student sees NO "Add Event" FAB; College Admin sees "Add Event" FAB', (tester) async {
      final fakeRepo = FakeCalendarRepository(events: []);

      // 1. As Student:
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('student_scope'),
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: testStudentUser, token: 'jwt')),
            ),
            calendarRepositoryProvider.overrideWithValue(fakeRepo),
            selectedCalendarDateProvider.overrideWith((ref) => DateTime(2026, 9, 24)),
            currentMonthProvider.overrideWith((ref) => DateTime(2026, 9, 1)),
          ],
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add Event'), findsNothing);

      // 2. As College Admin:
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('admin_scope'),
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: testAdminUser, token: 'jwt')),
            ),
            calendarRepositoryProvider.overrideWithValue(fakeRepo),
            selectedCalendarDateProvider.overrideWith((ref) => DateTime(2026, 9, 24)),
            currentMonthProvider.overrideWith((ref) => DateTime(2026, 9, 1)),
          ],
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add Event'), findsOneWidget);
    });

    testWidgets('8. Empty state renders when selected date has no events', (tester) async {
      final fakeRepo = FakeCalendarRepository(events: []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: testStudentUser, token: 'jwt')),
            ),
            calendarRepositoryProvider.overrideWithValue(fakeRepo),
            selectedCalendarDateProvider.overrideWith((ref) => DateTime(2026, 9, 20)),
            currentMonthProvider.overrideWith((ref) => DateTime(2026, 9, 1)),
          ],
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No events for this day.'), findsOneWidget);
      expect(find.text('No upcoming events.'), findsOneWidget);
    });

    testWidgets('9. Tapping date cell updates selected date', (tester) async {
      final fakeRepo = FakeCalendarRepository(events: []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: testStudentUser, token: 'jwt')),
            ),
            calendarRepositoryProvider.overrideWithValue(fakeRepo),
            selectedCalendarDateProvider.overrideWith((ref) => DateTime(2026, 9, 24)),
            currentMonthProvider.overrideWith((ref) => DateTime(2026, 9, 1)),
          ],
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find cell with text '15' and tap
      await tester.tap(find.text('15').first);
      await tester.pumpAndSettle();

      // Selected date header updates to 15 September 2026
      expect(find.textContaining('15 September 2026'), findsOneWidget);
    });
  });
}
