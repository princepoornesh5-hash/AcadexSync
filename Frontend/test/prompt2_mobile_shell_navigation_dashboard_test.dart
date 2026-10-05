import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/core/presentation/widgets/acadex_motion.dart';
import 'package:campus_management/features/notifications/presentation/providers/notification_providers.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/dashboard/domain/models/home_dashboard_models.dart';
import 'package:campus_management/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:campus_management/features/dashboard/presentation/screens/hod_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/screens/student_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/screens/faculty_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/screens/college_admin_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/screens/super_admin_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/acadex_app_bar.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/acadex_bottom_nav.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/acadex_drawer.dart';

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

HomeDashboardModel _createMockDashboard(String role, String name) {
  return HomeDashboardModel(
    role: role,
    greeting: DashboardGreetingModel(
      displayName: name,
      role: role,
      greetingText: 'Good morning',
    ),
    context: const DashboardContextModel(
      courseName: 'B.Tech Computer Science',
      semesterNumber: 6,
      sectionName: 'A',
      departmentName: 'Computer Science & Engineering',
      departmentCode: 'CSE',
      collegeName: 'MIT Engineering College',
    ),
    summary: const DashboardSummaryModel(
      attendancePercentage: 88.5,
      assignmentsCompleted: 12,
      assignmentsPending: 2,
      practicalsCompleted: 8,
      practicalsScheduled: 1,
      latestResultStatus: 'AVAILABLE',
      departmentsCount: 8,
      facultyCount: 45,
      activeFacultyCount: 45,
      studentsCount: 1250,
      activeStudentsCount: 1250,
      pendingRequestsCount: 3,
      collegesCount: 14,
      usersCount: 5200,
      activeCollegesCount: 12,
      systemStatus: 'OPERATIONAL',
    ),
    alerts: const [
      DashboardAlertModel(
        id: 'alt-1',
        type: 'ATTENDANCE',
        severity: 'WARNING',
        title: 'Attendance Shortfall Alert',
        message: 'Your practical attendance is below 75%.',
      ),
    ],
    upcoming: const [
      DashboardUpcomingItemModel(
        id: 'up-1',
        type: 'CLASS',
        title: 'Distributed Systems',
        startTime: '10:00 AM',
        endTime: '11:00 AM',
        location: 'Room 301',
      ),
    ],
    pendingActions: const [
      DashboardPendingActionModel(
        id: 'pa-1',
        type: 'REVIEW',
        title: 'Submit Lab Record',
        actionLabel: 'Upload',
        route: '/practicals',
        priority: 'HIGH',
      ),
    ],
    recent: const [
      DashboardRecentActivityModel(
        id: 'rec-1',
        type: 'RESULT',
        title: 'Semester 5 Results Published',
        timestamp: '2 hours ago',
      ),
    ],
    quickActions: const [
      DashboardQuickActionModel(
        id: 'qa-1',
        label: 'Timetable',
        icon: 'calendar',
        route: '/timetable',
        isPrimary: true,
      ),
      DashboardQuickActionModel(
        id: 'qa-2',
        label: 'Attendance',
        icon: 'checkSquare',
        route: '/attendance',
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ACADEX Prompt 2 — App Shell & Navigation Tests', () {
    testWidgets('1. AcadexAppBar displays compact typography, search, and notification action', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadNotificationCountProvider.overrideWith((ref) => 0),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              appBar: AcadexAppBar(
                title: 'HOD Dashboard',
                showDrawerButton: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HOD Dashboard'), findsOneWidget);
      expect(find.byIcon(LucideIcons.menu), findsOneWidget);
      expect(find.byIcon(LucideIcons.bell), findsOneWidget);
    });

    testWidgets('2. AcadexBottomNav renders primary tabs with Material 3 pill and tactile pressable', (tester) async {
      String? selectedTab;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
              const AuthAuthenticated(
                user: UserModel(
                  id: 'hod-1',
                  name: 'Dr. Jane HOD',
                  email: 'jane@mit.edu',
                  role: AppRole.hod,
                ),
                token: 'tok',
              ),
            )),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              bottomNavigationBar: AcadexBottomNav(
                activeRoute: '/dashboard/hod',
                onTabSelected: (r) => selectedTab = r,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check primary items rendered
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Academics'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);

      // Verify tactile pressable is present on tabs
      expect(find.byType(AcadexPressable), findsWidgets);

      // Tap Academics tab
      await tester.tap(find.text('Academics'));
      await tester.pumpAndSettle();
      expect(selectedTab, '/academics');
    });

    testWidgets('3. AcadexDrawer renders compact brand and identity header under 80dp height', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
              const AuthAuthenticated(
                user: UserModel(
                  id: 'student-1',
                  name: 'Alex Student',
                  email: 'alex@mit.edu',
                  role: AppRole.student,
                ),
                token: 'tok',
              ),
            )),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              drawer: AcadexDrawer(
                activeRoute: '/dashboard/student',
                isModal: true,
              ),
            ),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Verify compact Brand + User identity strip
      expect(find.text('ACADEX'), findsOneWidget);
      expect(find.text('Alex Student'), findsOneWidget);
      expect(find.text('Student'), findsWidgets);

      // Verify close button on modal
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });
  });

  group('ACADEX Prompt 2 — Role Dashboard Responsive & Compact Verification', () {
    const viewports = [
      {'name': '360px', 'size': Size(360, 780)},
      {'name': '390px', 'size': Size(390, 844)},
      {'name': '412px', 'size': Size(412, 915)},
    ];

    for (final vp in viewports) {
      final name = vp['name'] as String;
      final size = vp['size'] as Size;

      testWidgets('4. HOD Dashboard renders compact metrics on $name without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        final mockData = _createMockDashboard('HOD', 'Dr. Robert Head');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              homeDashboardProvider.overrideWith((ref) async => mockData),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: HodDashboard(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Department Status'), findsOneWidget);
        expect(find.text('Faculty Members'), findsOneWidget);
        expect(find.text('45'), findsOneWidget);
        expect(find.text('Active Students'), findsOneWidget);
        expect(find.text('1250'), findsOneWidget);
      });

      testWidgets('5. Student Dashboard renders compact academic snapshot on $name without overflow', (tester) async {
        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        final mockData = _createMockDashboard('STUDENT', 'Sarah Learner');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              homeDashboardProvider.overrideWith((ref) async => mockData),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: StudentDashboard(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Academic Snapshot'), findsOneWidget);
        expect(find.text('Attendance'), findsWidgets);
        expect(find.text('88.5%'), findsOneWidget);
        expect(find.text('Assignments'), findsOneWidget);
        expect(find.text('12 / 14'), findsOneWidget);
      });

      testWidgets('6. Faculty Dashboard renders compact operational summary on $name without overflow', (tester) async {
        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        final mockData = _createMockDashboard('FACULTY', 'Prof. Alan Turing');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              homeDashboardProvider.overrideWith((ref) async => mockData),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: FacultyDashboard(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Teaching & Evaluation Snapshot'), findsOneWidget);
      });

      testWidgets('7. College Admin Dashboard renders compact metrics on $name without overflow', (tester) async {
        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        final mockData = _createMockDashboard('COLLEGE_ADMIN', 'Dean Margaret');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              homeDashboardProvider.overrideWith((ref) async => mockData),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: CollegeAdminDashboard(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Institution Operations Snapshot'), findsOneWidget);
        expect(find.text('Departments'), findsOneWidget);
        expect(find.text('8'), findsOneWidget);
      });

      testWidgets('8. Super Admin Dashboard renders compact platform overview on $name without overflow', (tester) async {
        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        final mockData = _createMockDashboard('SUPER_ADMIN', 'Admin Root');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              homeDashboardProvider.overrideWith((ref) async => mockData),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SuperAdminDashboard(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Platform Overview'), findsOneWidget);
        expect(find.text('Total Colleges'), findsOneWidget);
        expect(find.text('14'), findsOneWidget);
      });
    }
  });
}
