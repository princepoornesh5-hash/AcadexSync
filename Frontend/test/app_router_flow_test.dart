import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:campus_management/app/router/app_router.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:campus_management/features/dashboard/domain/models/dashboard_stat_model.dart';
import 'package:campus_management/features/dashboard/domain/models/activity_item_model.dart';
import 'package:campus_management/features/reports/presentation/providers/reports_providers.dart';
import 'package:campus_management/features/notifications/presentation/providers/notification_providers.dart';
import 'package:campus_management/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier([super.initial = const AuthUnauthenticated()]);

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

List<dynamic> commonOverrides(UserModel user) {
  return [
    authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: user, token: 'token-123'))),
    academicRepositoryProvider.overrideWithValue(MockAcademicRepository()),
    notificationRepositoryProvider.overrideWithValue(MockNotificationRepository()),
    superAdminStatsProvider.overrideWith((ref) async => <DashboardStatModel>[]),
    superAdminActivityProvider.overrideWith((ref) async => <ActivityItemModel>[]),
    collegeAdminStatsProvider.overrideWith((ref) async => <DashboardStatModel>[]),
    collegeAdminActivityProvider.overrideWith((ref) async => <ActivityItemModel>[]),
    hodStatsProvider.overrideWith((ref) async => <DashboardStatModel>[]),
    hodActivityProvider.overrideWith((ref) async => <ActivityItemModel>[]),
    facultyStatsProvider.overrideWith((ref) async => <DashboardStatModel>[]),
    facultyActivityProvider.overrideWith((ref) async => <ActivityItemModel>[]),
    studentStatsProvider.overrideWith((ref) async => <DashboardStatModel>[]),
    studentActivityProvider.overrideWith((ref) async => <ActivityItemModel>[]),
    roleDashboardReportProvider.overrideWith((ref) async => null),
    unreadNotificationCountProvider.overrideWith((ref) => 0),
    myFacultyAssignmentsProvider.overrideWith((ref) => []),
    todayScheduleProvider.overrideWith((ref) => const AsyncValue.data(<TimetableModel>[])),
    currentStudentAcademicProfileProvider.overrideWith((ref) async => null),
  ];
}

void main() {
  testWidgets('1. App Router unauthenticated flow redirects / to /login', (tester) async {
    final authNotifier = _FakeAuthNotifier(const AuthUnauthenticated());
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => authNotifier),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              routerConfig: router,
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('2. App Router authenticated Super Admin routes to /dashboard/super_admin', (tester) async {
    const user = UserModel(
      id: 'super-1',
      name: 'Super Admin User',
      email: 'admin@acadex.com',
      role: AppRole.superAdmin,
      accountStatus: AccountStatus.active,
    );
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: commonOverrides(user).cast(),
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              routerConfig: router,
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Platform Overview'), findsOneWidget);
    expect(find.text('SUPER ADMIN'), findsWidgets);
  });

  testWidgets('3. App Router authenticated College Admin routes to /dashboard/college_admin', (tester) async {
    const user = UserModel(
      id: 'college-admin-1',
      name: 'College Admin User',
      email: 'admin@mit.edu',
      collegeId: 'col-1',
      role: AppRole.collegeAdmin,
      accountStatus: AccountStatus.active,
    );
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: commonOverrides(user).cast(),
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              routerConfig: router,
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('COLLEGE ADMIN'), findsWidgets);
  });

  testWidgets('4. App Router authenticated HOD routes to /dashboard/hod', (tester) async {
    const user = UserModel(
      id: 'hod-1',
      name: 'HOD User',
      email: 'hod.cs@mit.edu',
      collegeId: 'col-1',
      departmentId: 'dept-1',
      role: AppRole.hod,
      accountStatus: AccountStatus.active,
    );
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: commonOverrides(user).cast(),
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              routerConfig: router,
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('HOD'), findsWidgets);
  });

  testWidgets('5. App Router authenticated Faculty routes to /dashboard/faculty', (tester) async {
    const user = UserModel(
      id: 'faculty-1',
      name: 'Faculty User',
      email: 'prof.smith@mit.edu',
      collegeId: 'col-1',
      departmentId: 'dept-1',
      role: AppRole.faculty,
      accountStatus: AccountStatus.active,
    );
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: commonOverrides(user).cast(),
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              routerConfig: router,
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('FACULTY'), findsWidgets);
  });

  testWidgets('6. App Router authenticated Student routes to /dashboard/student', (tester) async {
    const user = UserModel(
      id: 'student-1',
      name: 'Student User',
      email: 'john@mit.edu',
      collegeId: 'col-1',
      departmentId: 'dept-1',
      role: AppRole.student,
      accountStatus: AccountStatus.active,
    );
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: commonOverrides(user).cast(),
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              routerConfig: router,
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('STUDENT'), findsWidgets);
  });
}
