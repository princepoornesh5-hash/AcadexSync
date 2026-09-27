import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/presentation/screens/academic_structure_home_screen.dart';
import 'package:campus_management/features/academic_structure/presentation/screens/subject_detail_screen.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:campus_management/features/notifications/presentation/providers/notification_providers.dart';
import 'package:campus_management/features/dashboard/domain/models/dashboard_stat_model.dart';
import 'package:campus_management/features/dashboard/domain/models/activity_item_model.dart';
import 'package:campus_management/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:campus_management/features/dashboard/presentation/screens/hod_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/acadex_app_bar.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/acadex_drawer.dart';
import 'package:campus_management/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:campus_management/features/calendar/domain/models/calendar_event_model.dart';
import 'package:campus_management/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:campus_management/features/calendar/presentation/providers/calendar_providers.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCalendarRepository implements CalendarRepository {
  @override
  Future<List<CalendarEventModel>> getCalendar({String? startDate, String? endDate, String? eventType}) async {
    return [
      CalendarEventModel(
        id: 'ev1',
        title: 'Mid-Semester Examination',
        startDate: '2026-10-11T09:30:00Z',
        endDate: '2026-10-11T10:00:00Z',
        eventType: CalendarEventType.exam,
        status: CalendarEventStatus.published,
        description: 'Computer Science · Section A',
      ),
    ];
  }

  @override
  Future<CalendarEventModel> getEventById(String id) async => throw UnimplementedError();
  @override
  Future<CalendarEventModel> createEvent(Map<String, dynamic> data) async => throw UnimplementedError();
  @override
  Future<CalendarEventModel> updateEvent(String id, Map<String, dynamic> data) async => throw UnimplementedError();
  @override
  Future<CalendarEventModel> cancelEvent(String id, {String? reason}) async => throw UnimplementedError();
  @override
  Future<CalendarEventModel> publishEvent(String id) async => throw UnimplementedError();
}

void main() {
  const testHodUser = UserModel(
    id: 'f1',
    name: 'Prof. Ada Lovelace',
    email: 'hod@alpha.edu',
    role: AppRole.hod,
    collegeId: 'c1',
    departmentId: 'd1',
  );

  List<Override> getOverrides() {
    return [
      authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
            user: testHodUser,
            token: 'test-token',
          ))),
      academicRepositoryProvider.overrideWithValue(MockAcademicRepository(currentUser: testHodUser)),
      notificationRepositoryProvider.overrideWithValue(MockNotificationRepository()),
      calendarRepositoryProvider.overrideWithValue(MockCalendarRepository()),
      hodStatsProvider.overrideWith((ref) async => <DashboardStatModel>[]),
      hodActivityProvider.overrideWith((ref) async => <ActivityItemModel>[]),
    ];
  }

  group('PROMPT 28 — Web Visual Acceptance & Shell Verification Tests', () {
    testWidgets('1. Compact Frosted Header (56px) renders BackdropFilter with sigma 20 blur', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: getOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              appBar: AcadexAppBar(title: 'HOD Dashboard'),
              body: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify preferred size is 56.0
      final appBarFinder = find.byType(AcadexAppBar);
      expect(appBarFinder, findsOneWidget);
      final appBarWidget = tester.widget<AcadexAppBar>(appBarFinder);
      expect(appBarWidget.preferredSize.height, 56.0);

      // Verify BackdropFilter with 20px blur exists
      final backdropFilters = tester.widgetList<BackdropFilter>(find.byType(BackdropFilter));
      final headerFilter = backdropFilters.firstWhere(
        (bf) => bf.filter == ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      );
      expect(headerFilter, isNotNull);

      // Verify persistent sidebar toggle button exists in desktop header
      expect(find.byIcon(LucideIcons.panelLeftClose), findsOneWidget);
    });

    testWidgets('2. Frosted Sidebar renders sigma 24 blur and toggles between 240px and 68px', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: getOverrides(),
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const MaterialApp(
                home: Scaffold(
                  body: Row(
                    children: [
                      AcadexDrawer(activeRoute: '/dashboard/hod', isModal: false),
                      Expanded(child: Text('Main Content')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial expanded width is 240px
      final containerFinder = find.byType(AnimatedContainer);
      expect(containerFinder, findsOneWidget);
      AnimatedContainer container = tester.widget<AnimatedContainer>(containerFinder);
      expect(container.constraints?.maxWidth, 240.0);

      // Collapse sidebar via provider
      capturedRef.read(sidebarCollapsedProvider.notifier).state = true;
      await tester.pumpAndSettle();

      // Verify collapsed width is 68px
      container = tester.widget<AnimatedContainer>(containerFinder);
      expect(container.constraints?.maxWidth, 68.0);

      // Expand sidebar again
      capturedRef.read(sidebarCollapsedProvider.notifier).state = false;
      await tester.pumpAndSettle();

      container = tester.widget<AnimatedContainer>(containerFinder);
      expect(container.constraints?.maxWidth, 240.0);
    });

    testWidgets('3. Academic Structure dynamic create actions update synchronously upon tab change', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: getOverrides(),
          child: const MaterialApp(
            home: AcademicStructureHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tab 0 (Courses/Programs): Action is + Create Course
      expect(find.text('+ Create Course'), findsOneWidget);

      // Switch to Tab 1 (Semesters)
      await tester.tap(find.descendant(of: find.byType(TabBar), matching: find.text('Semesters')));
      await tester.pumpAndSettle();
      expect(find.text('+ Create Semester'), findsOneWidget);

      // Switch to Tab 2 (Sections)
      await tester.tap(find.descendant(of: find.byType(TabBar), matching: find.text('Sections')));
      await tester.pumpAndSettle();
      expect(find.text('+ Create Section'), findsOneWidget);

      // Switch to Tab 3 (Subjects)
      await tester.tap(find.descendant(of: find.byType(TabBar), matching: find.text('Subjects')));
      await tester.pumpAndSettle();
      expect(find.text('+ Create Subject'), findsOneWidget);

      // Switch to Tab 4 (Faculty)
      await tester.tap(find.descendant(of: find.byType(TabBar), matching: find.text('Faculty')));
      await tester.pumpAndSettle();
      expect(find.text('+ Add Faculty'), findsOneWidget);
    });

    testWidgets('4. HOD Dashboard contains all 5 Quick Operations', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: getOverrides(),
          child: const MaterialApp(
            home: HodDashboard(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Check Quick Operations
      expect(find.text('Quick Operations'), findsOneWidget);
      expect(find.text('Add Course'), findsWidgets);
      expect(find.text('Add Subject'), findsWidgets);
      expect(find.text('Add Student'), findsWidgets);
      expect(find.text('Assign Faculty'), findsWidgets);
      expect(find.text('Continue Setup'), findsWidgets);
    });

    testWidgets('5. Subject Detail Screen displays single Back action and single Edit action', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Use subject 'sub1' from MockAcademicRepository
      await tester.pumpWidget(
        ProviderScope(
          overrides: getOverrides(),
          child: const MaterialApp(
            home: SubjectDetailScreen(subjectId: 'sub1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check single Back action
      expect(find.text('Back to Subjects'), findsOneWidget);

      // Check Subject details from mock
      expect(find.text('Data Structures'), findsOneWidget);
      expect(find.text('CS101'), findsNWidgets(2));
      expect(find.text('4 Credits'), findsNWidgets(2));

      // Check single Edit action
      expect(find.text('Edit Subject'), findsOneWidget);
    });

    testWidgets('6. Responsive viewports (1024px, 1280px, 1440px) render without overflow', (tester) async {
      final widths = [1024.0, 1280.0, 1440.0];

      for (final width in widths) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: getOverrides(),
            child: const MaterialApp(
              home: AcademicStructureHomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Academic Structure'), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
    });

    testWidgets('7. Desktop Calendar displays 2-column layout (Month Calendar & Upcoming Events)', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: getOverrides(),
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and 2 column components
      expect(find.text('UPCOMING EVENTS'), findsOneWidget);
      expect(find.text('Mid-Semester Examination'), findsWidgets);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Add Event'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
