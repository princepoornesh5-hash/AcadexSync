import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_lookup_providers.dart';
import 'package:campus_management/features/timetable/presentation/screens/timetable_dashboard_screen.dart';
import 'package:campus_management/features/timetable/presentation/screens/timetable_management_screen.dart';
import 'package:campus_management/features/timetable/presentation/widgets/next_class_card.dart';
import 'package:campus_management/features/timetable/presentation/widgets/today_schedule_timeline.dart';
import 'package:campus_management/features/timetable/presentation/widgets/timetable_widgets.dart';
import 'package:campus_management/features/timetable/data/repositories/mock_timetable_repository.dart';
import 'package:campus_management/features/timetable/data/repositories/api_timetable_repository.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.initial);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ACADEX Phase 9Q.4 — Timetable UI Vertical Slice Tests', () {
    final sampleClass1 = TimetableModel(
      id: 'tt_1',
      collegeId: 'col_123',
      departmentId: 'dept_cse',
      courseId: 'course_btech',
      academicYearId: 'ay_2026',
      semesterId: 'sem_6',
      sectionId: 'sec_a',
      subjectId: 'sub_algo',
      facultyId: 'fac_101',
      dayOfWeek: TimetableDay.monday,
      startTime: '09:00',
      endTime: '10:00',
      roomNumber: '204',
      building: 'Tech Block',
      sessionType: TimetableSessionType.lecture,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final sampleClass2 = TimetableModel(
      id: 'tt_2',
      collegeId: 'col_123',
      departmentId: 'dept_cse',
      courseId: 'course_btech',
      academicYearId: 'ay_2026',
      semesterId: 'sem_6',
      sectionId: 'sec_a',
      subjectId: 'sub_os',
      facultyId: 'fac_102',
      dayOfWeek: TimetableDay.monday,
      startTime: '10:15',
      endTime: '11:15',
      roomNumber: '302',
      sessionType: TimetableSessionType.lab,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final sampleContainer = TimetableContainerModel(
      id: 'cont_1',
      collegeId: 'col_123',
      departmentId: 'dept_cse',
      courseId: 'course_btech',
      academicYearId: 'ay_2026',
      semesterId: 'sem_6',
      sectionId: 'sec_a',
      name: 'CSE-6th Sem Section A (Draft)',
      status: TimetableStatus.draft,
      version: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testWidgets('1. Student sees TimetableDashboardScreen with view mode switcher', (tester) async {
      final studentUser = UserModel(
        id: 'student_1',
        name: 'Arjun Verma',
        email: 'arjun@acadex.edu',
        role: AppRole.student,
        collegeId: 'col_123',
        departmentId: 'dept_cse',
        sectionId: 'sec_a',
        accountStatus: AccountStatus.active,
      );

      final weeklyMap = {
        for (var day in TimetableDay.values) day: <TimetableModel>[],
      };
      weeklyMap[TimetableDay.monday] = [sampleClass1, sampleClass2];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: studentUser, token: 'fake-token')),
            ),
            weeklyTimetableProvider.overrideWith(
              (ref) => Stream.value(weeklyMap),
            ),
            timetableSelectedDayProvider.overrideWith((ref) => TimetableDay.monday),
            timetableViewModeProvider.overrideWith((ref) => TimetableViewMode.day),
          ],
          child: const MaterialApp(
            home: TimetableDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Timetable'), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('List'), findsOneWidget);
      // Student shouldn't see Manage & Create
      expect(find.text('Manage & Create'), findsNothing);
    });

    testWidgets('2. Faculty sees TimetableDashboardScreen with teaching subtitle', (tester) async {
      final facultyUser = UserModel(
        id: 'fac_101',
        name: 'Dr. Sarah Connor',
        email: 'sarah@acadex.edu',
        role: AppRole.faculty,
        collegeId: 'col_123',
        departmentId: 'dept_cse',
        accountStatus: AccountStatus.active,
      );

      final weeklyMap = {
        for (var day in TimetableDay.values) day: <TimetableModel>[],
      };
      weeklyMap[TimetableDay.monday] = [sampleClass1];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: facultyUser, token: 'fake-token')),
            ),
            weeklyTimetableProvider.overrideWith(
              (ref) => Stream.value(weeklyMap),
            ),
            timetableSelectedDayProvider.overrideWith((ref) => TimetableDay.monday),
          ],
          child: const MaterialApp(
            home: TimetableDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Timetable'), findsOneWidget);
      expect(find.text('Your teaching schedule and classroom allocations'), findsOneWidget);
    });

    testWidgets('3. HOD sees TimetableDashboardScreen with Manage & Create button', (tester) async {
      final hodUser = UserModel(
        id: 'hod_1',
        name: 'Prof. Alan Turing',
        email: 'hod.cse@acadex.edu',
        role: AppRole.hod,
        collegeId: 'col_123',
        departmentId: 'dept_cse',
        accountStatus: AccountStatus.active,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: hodUser, token: 'fake-token')),
            ),
            weeklyTimetableProvider.overrideWith(
              (ref) => Stream.value({for (var d in TimetableDay.values) d: [sampleClass1]}),
            ),
          ],
          child: const MaterialApp(
            home: TimetableDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Manage & Create'), findsOneWidget);
    });

    testWidgets('4. NextClassCard displays class details and time slot', (tester) async {
      final studentUser = UserModel(
        id: 'student_1',
        name: 'Arjun Verma',
        email: 'arjun@acadex.edu',
        role: AppRole.student,
        collegeId: 'col_123',
        departmentId: 'dept_cse',
        accountStatus: AccountStatus.active,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: studentUser, token: 'fake-token')),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NextClassCard(nextClass: sampleClass1),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('NEXT CLASS'), findsOneWidget);
      expect(find.text('09:00 – 10:00'), findsOneWidget);
      expect(find.text('Room 204 · Tech Block'), findsOneWidget);
      expect(find.text('View Attendance'), findsOneWidget);
    });

    testWidgets('5. NextClassCard shows friendly empty state when no upcoming classes', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NextClassCard(nextClass: null),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Upcoming Classes'), findsOneWidget);
      expect(find.text('You are all done with scheduled classes for today.'), findsOneWidget);
    });

    testWidgets('6. TodayScheduleTimeline displays list of classes', (tester) async {
      final facultyUser = UserModel(
        id: 'fac_101',
        name: 'Dr. Sarah Connor',
        email: 'sarah@acadex.edu',
        role: AppRole.faculty,
        collegeId: 'col_123',
        departmentId: 'dept_cse',
        accountStatus: AccountStatus.active,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: facultyUser, token: 'fake-token')),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TodayScheduleTimeline(classes: [sampleClass1, sampleClass2]),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('10:15'), findsOneWidget);
      expect(find.text('Lecture'), findsOneWidget);
      expect(find.text('Lab'), findsOneWidget);
    });

    testWidgets('7. WeeklyTimetableGrid renders days columns horizontally', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final weeklyMap = {
        for (var day in TimetableDay.values) day: <TimetableModel>[],
      };
      weeklyMap[TimetableDay.monday] = [sampleClass1];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WeeklyTimetableGrid(weeklyData: weeklyMap),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Tuesday'), findsOneWidget);
      expect(find.text('Wednesday'), findsOneWidget);
      expect(find.text('Thursday'), findsOneWidget);
      expect(find.text('Friday'), findsOneWidget);
    });

    testWidgets('8. TimetableManagementScreen renders filters and container list', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final hodUser = UserModel(
        id: 'hod_1',
        name: 'Prof. Alan Turing',
        email: 'hod.cse@acadex.edu',
        role: AppRole.hod,
        collegeId: 'col_123',
        departmentId: 'dept_cse',
        accountStatus: AccountStatus.active,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: hodUser, token: 'fake-token')),
            ),
            managementContainersProvider.overrideWith(
              (ref) async => [sampleContainer],
            ),
          ],
          child: const MaterialApp(
            home: TimetableManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Manage Timetable'), findsOneWidget);
      expect(find.text('CSE-6th Sem Section A (Draft)'), findsOneWidget);
      expect(find.text('DRAFT'), findsOneWidget);
      expect(find.text('Publish'), findsOneWidget);
    });

    testWidgets('9. ApiTimetableRepository can instantiate and fall back gracefully', (tester) async {
      final repo = ApiTimetableRepository();
      expect(repo, isA<ApiTimetableRepository>());

      final mockRepo = MockTimetableRepository();
      final containers = await mockRepo.getTimetableContainers(collegeId: 'col_fallback');
      expect(containers, isNotNull);
    });
  });
}
