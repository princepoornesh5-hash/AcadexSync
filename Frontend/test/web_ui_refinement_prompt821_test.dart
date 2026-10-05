import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:campus_management/core/presentation/widgets/acadex_character_loading.dart';
import 'package:campus_management/core/presentation/widgets/acadex_feedback.dart';
import 'package:campus_management/core/presentation/widgets/acadex_page_header.dart';
import 'package:campus_management/features/dashboard/presentation/screens/student_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/screens/faculty_dashboard.dart';
import 'package:campus_management/features/dashboard/domain/models/home_dashboard_models.dart';
import 'package:campus_management/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/acadex_drawer.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/acadex_app_bar.dart';
import 'package:campus_management/features/notifications/presentation/providers/notification_providers.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUser = UserModel(
    id: 'user-web-1',
    email: 'faculty@acadex.edu',
    name: 'Dr. Prof. Long Named Faculty Member',
    role: AppRole.faculty,
    collegeId: 'col-1',
  );

  group('ACADEX Prompt 8.2.1 Web UI & Platform Refinement Tests', () {
    testWidgets('1. Snowman loading mascot renders with Dock bounce animation and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexCharacterLoading(
              message: 'Preparing your academic dashboard...',
            ),
          ),
        ),
      );

      expect(find.byType(AcadexCharacterLoading), findsOneWidget);
      expect(find.text('Preparing your academic dashboard...'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Verify bounce animation cycles without exception
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Snowman loading mascot respects reduced-motion accessibility', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: AcadexCharacterLoading(
                message: 'Reduced motion active',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Reduced motion active'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. AcadexPageHeader provides desktop-proportioned title & compact spacing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1280, 800)),
            child: Scaffold(
              body: AcadexPageHeader(
                title: 'My Teaching Assignments',
                subtitle: 'Active courses, subjects, and sections allocated for your instruction.',
                actions: [
                  ElevatedButton(onPressed: () {}, child: const Text('Export')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('My Teaching Assignments'), findsOneWidget);
      expect(find.text('Active courses, subjects, and sections allocated for your instruction.'), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);

      final titleWidget = tester.widget<Text>(find.text('My Teaching Assignments'));
      expect(titleWidget.style?.fontSize, 20);
    });

    testWidgets('4. AcadexEmptyState has compact vertical padding without excessive blank space', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexEmptyState(
              title: 'No Active Teaching Assignments',
              subtitle: 'You currently have no classes or subjects allocated.',
              icon: LucideIcons.bookOpen,
            ),
          ),
        ),
      );

      expect(find.text('No Active Teaching Assignments'), findsOneWidget);
      expect(find.text('You currently have no classes or subjects allocated.'), findsOneWidget);
      expect(find.byIcon(LucideIcons.bookOpen), findsOneWidget);

      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      final padding = container.padding as EdgeInsets;
      // Compact vertical padding (<= 24dp)
      expect(padding.top, lessThanOrEqualTo(24.0));
      expect(padding.bottom, lessThanOrEqualTo(24.0));
    });

    testWidgets('5. Student Web Dashboard renders 4-column compact Academic Snapshot on desktop', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockStudentDashboard = HomeDashboardModel(
        role: 'STUDENT',
        greeting: const DashboardGreetingModel(
          displayName: 'John Student',
          role: 'STUDENT',
          greetingText: 'Welcome back',
        ),
        context: const DashboardContextModel(
          collegeId: 'col-1',
          collegeName: 'Acadex Engineering',
          departmentId: 'dept-1',
          departmentName: 'Computer Science',
        ),
        summary: const DashboardSummaryModel(
          attendancePercentage: 88.5,
          assignmentsCompleted: 6,
          assignmentsPending: 2,
          practicalsCompleted: 4,
          practicalsScheduled: 1,
          latestResultStatus: 'AVAILABLE',
        ),
        upcoming: [],
        recent: [],
        alerts: [],
        pendingActions: [],
        quickActions: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeDashboardProvider.overrideWith((ref) => mockStudentDashboard),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StudentDashboard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Academic Snapshot'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Assignments'), findsOneWidget);
      expect(find.text('Practicals'), findsOneWidget);
      expect(find.text('Official Results'), findsOneWidget);

      // Verify GridView crossAxisCount is 4 on desktop
      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);
      final grid = tester.widget<GridView>(gridFinder);
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 4);
    });

    testWidgets('6. Faculty Web Dashboard renders 4-column compact Teaching & Evaluation Snapshot on desktop', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockFacultyDashboard = HomeDashboardModel(
        role: 'FACULTY',
        greeting: const DashboardGreetingModel(
          displayName: 'Dr. Jane Smith',
          role: 'FACULTY',
          greetingText: 'Good morning',
        ),
        context: const DashboardContextModel(
          collegeId: 'col-1',
          collegeName: 'Acadex Engineering',
          departmentId: 'dept-1',
          departmentName: 'Computer Science',
        ),
        summary: const DashboardSummaryModel(
          assignedClassesCount: 3,
          submissionsAwaitingReview: 5,
          pendingAttendanceSessions: 1,
          pendingAssessmentMarks: 0,
        ),
        upcoming: [],
        recent: [],
        alerts: [],
        pendingActions: [],
        quickActions: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeDashboardProvider.overrideWith((ref) => mockFacultyDashboard),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FacultyDashboard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Teaching & Evaluation Snapshot'), findsOneWidget);
      expect(find.text('Assigned Classes'), findsOneWidget);
      expect(find.text('Pending Reviews'), findsOneWidget);
      expect(find.text('Pending Attendance'), findsOneWidget);
      expect(find.text('Assessment Marks'), findsOneWidget);

      // Verify GridView crossAxisCount is 4 on desktop
      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);
      final grid = tester.widget<GridView>(gridFinder);
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 4);
    });

    testWidgets('7. Mobile retains 2-column compact grid without regression', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockFacultyDashboard = HomeDashboardModel(
        role: 'FACULTY',
        greeting: const DashboardGreetingModel(
          displayName: 'Dr. Jane Smith',
          role: 'FACULTY',
          greetingText: 'Good morning',
        ),
        context: const DashboardContextModel(
          collegeId: 'col-1',
          collegeName: 'Acadex Engineering',
          departmentId: 'dept-1',
          departmentName: 'Computer Science',
        ),
        summary: const DashboardSummaryModel(
          assignedClassesCount: 3,
          submissionsAwaitingReview: 5,
          pendingAttendanceSessions: 1,
          pendingAssessmentMarks: 0,
        ),
        upcoming: [],
        recent: [],
        alerts: [],
        pendingActions: [],
        quickActions: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeDashboardProvider.overrideWith((ref) => mockFacultyDashboard),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FacultyDashboard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);
      final grid = tester.widget<GridView>(gridFinder);
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
    });

    testWidgets('8. Desktop Sidebar renders clean solid surface without glassmorphism', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'test-jwt-token'))),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AcadexDrawer(
                activeRoute: '/faculty-assignments',
                isModal: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ACADEX'), findsOneWidget);
      expect(find.text('Dr. Prof. Long Named Faculty Member'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
      expect(find.text('Faculty'), findsOneWidget);
    });

    testWidgets('9. Desktop Top Bar renders solid container, search bar, and action controls', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'test-jwt-token'))),
            unreadNotificationCountProvider.overrideWithValue(0),
          ],
          child: const MaterialApp(
            home: Scaffold(
              appBar: AcadexAppBar(
                title: 'Dashboard',
                showTitle: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Desktop search field
      expect(find.byIcon(LucideIcons.bell), findsOneWidget); // Notification badge
    });
  });
}
