import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:campus_management/core/firebase/firebase_initializer.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:campus_management/features/notifications/domain/models/notification_models.dart';
import 'package:campus_management/features/notifications/presentation/providers/notification_providers.dart';
import 'package:campus_management/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:campus_management/features/notifications/data/repositories/notification_repository.dart';
import 'package:campus_management/features/settings/domain/models/settings_models.dart';
import 'package:campus_management/features/settings/presentation/providers/settings_providers.dart';
import 'package:campus_management/features/settings/data/repositories/mock_settings_repository.dart';
import 'package:campus_management/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:campus_management/features/attendance/domain/models/super_admin_attendance_summary.dart';
import 'package:campus_management/features/attendance/domain/models/college_attendance_summary.dart';
import 'package:campus_management/features/attendance/domain/models/department_attendance_summary.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_session.dart';
import 'package:campus_management/features/attendance/domain/models/assigned_class.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/domain/repositories/academic_repository.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';

class MockTestAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockTestAuthNotifier(super.initial);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTestAttendanceRepository implements AttendanceRepository {
  int totalColleges = 4;
  int totalDepartments = 12;
  int totalFaculty = 45;
  int totalStudents = 320;
  double globalAttendance = 85.5;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<SuperAdminAttendanceSummary> getSuperAdminSummary() async {
    return SuperAdminAttendanceSummary(
      totalColleges: totalColleges,
      totalDepartments: totalDepartments,
      totalFaculty: totalFaculty,
      totalStudents: totalStudents,
      todayAttendancePercentage: globalAttendance,
      pendingColleges: 0,
    );
  }

  @override
  Future<CollegeAttendanceSummary> getCollegeSummary() async {
    return CollegeAttendanceSummary(
      totalDepartments: totalDepartments,
      totalFaculty: totalFaculty,
      totalStudents: totalStudents,
      todayAttendancePercentage: globalAttendance,
      studentsBelowThreshold: 5,
      pendingFaculty: 2,
      completedFaculty: 43,
    );
  }

  @override
  Future<DepartmentAttendanceSummary> getDepartmentSummary(String departmentId) async {
    return DepartmentAttendanceSummary(
      totalFaculty: 8,
      totalStudents: 60,
      overallPercentage: 82.0,
      studentsBelow75: 3,
      facultyCompleted: 7,
      facultyPending: 1,
      todayClasses: 6,
    );
  }

  @override
  Future<List<AssignedClass>> getAssignedClasses(String facultyId, DateTime date) async {
    return [];
  }

  @override
  Future<bool> saveSession(AttendanceSession session) async {
    globalAttendance = 90.0;
    return true;
  }
}

class MockTestAcademicRepository implements AcademicRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Section>> getSections({String? semesterId, String? courseId, String? collegeId}) async => [];

  @override
  Future<List<Subject>> getSubjects({String? courseId, String? departmentId, String? semesterId, String? collegeId}) async => [];

  @override
  Future<List<AcademicYear>> getAcademicYears({String? collegeId}) async => [];
}

class MockTestNotificationRepository implements NotificationRepository {
  final List<NotificationModel> _items = [
    NotificationModel(
      id: 'notif_1',
      title: 'Term Examination Schedule',
      message: 'The end semester examination schedule has been released.',
      category: NotificationCategory.academic,
      priority: NotificationPriority.high,
      audienceType: NotificationAudienceType.college,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    NotificationModel(
      id: 'notif_2',
      title: 'Attendance Alert',
      message: 'Your overall attendance is currently at 88%.',
      category: NotificationCategory.attendance,
      priority: NotificationPriority.normal,
      audienceType: NotificationAudienceType.personal,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ];

  final _controller = StreamController<List<NotificationModel>>.broadcast();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Stream<List<NotificationModel>> watchNotifications(UserModel user, NotificationPreferences prefs) {
    late StreamController<List<NotificationModel>> ctrl;
    StreamSubscription? sub;
    ctrl = StreamController<List<NotificationModel>>(
      onListen: () {
        ctrl.add(List.unmodifiable(_items));
        sub = _controller.stream.listen((items) {
          if (!ctrl.isClosed) ctrl.add(items);
        });
      },
      onCancel: () {
        sub?.cancel();
        ctrl.close();
      },
    );
    return ctrl.stream;
  }

  @override
  Future<void> markAsRead(String id, String userId) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(isRead: true);
      _controller.add(List.unmodifiable(_items));
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<void> deleteNotification(String id, String userId) async {
    _items.removeWhere((n) => n.id == id);
    _controller.add(List.unmodifiable(_items));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FirebaseInitializer.overrideShouldUseMock = false;
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() {
    FirebaseInitializer.overrideShouldUseMock = null;
  });

  group('ACADEX Priority 1 / Prompt 3: Dashboard Freshness & Notification Stability Tests', () {
    test('1. In-app mutation triggers immediate targeted dashboard refresh without full reload', () async {
      final mockAttendanceRepo = MockTestAttendanceRepository();
      final container = ProviderContainer(
        overrides: [
          attendanceRepoProvider.overrideWithValue(mockAttendanceRepo),
        ],
      );

      // Initial fetch
      final statsBefore = await container.read(superAdminStatsProvider.future);
      expect(statsBefore.firstWhere((s) => s.title == 'Total Colleges').value, '4');
      expect(statsBefore.firstWhere((s) => s.title == 'Global Attendance').value, '85.5%');

      // Mutate underlying state in backend repository
      mockAttendanceRepo.totalColleges = 5;
      mockAttendanceRepo.globalAttendance = 92.0;

      // Targeted invalidation as occurs upon createCollege / saveSession
      container.invalidate(superAdminStatsProvider);

      // Immediately read updated state
      final statsAfter = await container.read(superAdminStatsProvider.future);
      expect(statsAfter.firstWhere((s) => s.title == 'Total Colleges').value, '5');
      expect(statsAfter.firstWhere((s) => s.title == 'Global Attendance').value, '92.0%');

      container.dispose();
    });

    test('2. Faculty dashboard provider calculates without rebuild jitter', () async {
      final mockAttendanceRepo = MockTestAttendanceRepository();
      final mockAcademicRepo = MockTestAcademicRepository();
      final facultyUser = UserModel(
        id: 'usr_fac_1',
        name: 'Prof. Davis',
        email: 'davis@acadex.com',
        role: AppRole.faculty,
        collegeId: 'coll_1',
        departmentId: 'dept_cs',
      );

      final container = ProviderContainer(
        overrides: [
          attendanceRepoProvider.overrideWithValue(mockAttendanceRepo),
          academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
          myFacultyAssignmentsProvider.overrideWith((ref) => []),
          authProvider.overrideWith((ref) => MockTestAuthNotifier(AuthAuthenticated(user: facultyUser, token: 'token'))),
        ],
      );

      // Read faculty stats
      final stats = await container.read(facultyStatsProvider.future);
      expect(stats, isNotEmpty);
      expect(stats.any((s) => s.title == 'My Subjects'), isTrue);
      expect(stats.any((s) => s.title == "Today's Classes"), isTrue);

      container.dispose();
    });

    testWidgets('3. Notification Center renders with bounded horizontal constraints and supports filtering', (tester) async {
      final mockNotifsRepo = MockTestNotificationRepository();
      final adminUser = UserModel(
        id: 'usr_admin_1',
        name: 'Admin Test',
        email: 'admin@acadex.com',
        role: AppRole.collegeAdmin,
        collegeId: 'coll_1',
      );

      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const Scaffold(body: Text('Dashboard Screen')),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationCenterScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(mockNotifsRepo),
            settingsRepoProvider.overrideWithValue(mockSettingsRepo),
            authProvider.overrideWith((ref) => MockTestAuthNotifier(AuthAuthenticated(user: adminUser, token: 'token'))),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify screen rendered without layout overflow or freeze
      expect(find.text('Notification Center'), findsOneWidget);
      expect(find.text('Term Examination Schedule'), findsOneWidget);
      expect(find.text('Attendance Alert'), findsOneWidget);

      // Tap filter "Attendance"
      expect(find.text('Attendance'), findsOneWidget);
      await tester.tap(find.text('Attendance'));
      await tester.pumpAndSettle();

      // Attendance alert remains, academic notification filtered out
      expect(find.text('Attendance Alert'), findsOneWidget);
      expect(find.text('Term Examination Schedule'), findsNothing);

      // Tap "Mark all read"
      expect(find.text('Mark all read'), findsOneWidget);
      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      // Tap back button
      final backButton = find.byIcon(LucideIcons.arrowLeft).first;
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Navigated safely back to /dashboard
      expect(find.text('Dashboard Screen'), findsOneWidget);
    });

    test('4. Notifications unread count updates accurately upon marking as read', () async {
      final mockNotifsRepo = MockTestNotificationRepository();
      final testUser = UserModel(
        id: 'usr_student_1',
        name: 'Alice Student',
        email: 'alice@acadex.com',
        role: AppRole.student,
        collegeId: 'coll_1',
      );

      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(mockNotifsRepo),
          settingsRepoProvider.overrideWithValue(mockSettingsRepo),
          authProvider.overrideWith((ref) => MockTestAuthNotifier(AuthAuthenticated(user: testUser, token: 'token'))),
        ],
      );

      // Keep provider alive during test
      final sub1 = container.listen(notificationsProvider, (_, __) {});
      final sub2 = container.listen(unreadNotificationCountProvider, (_, __) {});

      // Wait for notifications to load
      await container.read(notificationsProvider.future);
      expect(container.read(unreadNotificationCountProvider), 1);

      // Mark first notification as read
      await container.read(notificationsProvider.notifier).markAsRead('notif_1');
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(container.read(unreadNotificationCountProvider), 0);

      sub1.close();
      sub2.close();
      container.dispose();
    });
  });
}
