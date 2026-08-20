import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/dashboard/presentation/screens/role_dashboard_screen.dart';
import 'package:campus_management/features/reports/domain/models/report_models.dart';
import 'package:campus_management/features/reports/presentation/providers/reports_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RoleDashboardScreen renders Super Admin overview', (tester) async {
    const user = UserModel(
      id: 'admin1',
      name: 'System Admin',
      email: 'admin@acadex.edu',
      role: AppRole.superAdmin,
    );

    const report = RoleDashboardReportModel(
      role: 'SUPER_ADMIN',
      metrics: {
        'totalColleges': 8,
        'totalUsers': 3200,
        'overallAttendance': 91.5,
        'storageUsedMB': 850,
      },
      quickStats: {},
      recentActivity: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier(const AuthAuthenticated(user: user, token: 'tok'))),
          roleDashboardReportProvider.overrideWith((ref) async => report),
        ],
        child: const MaterialApp(
          home: RoleDashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ACADEX Dashboard'), findsOneWidget);
    expect(find.text('Platform Overview'), findsOneWidget);
    expect(find.text('Colleges'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('Total Users'), findsOneWidget);
    expect(find.text('3200'), findsOneWidget);
  });

  testWidgets('RoleDashboardScreen renders Student overview', (tester) async {
    const user = UserModel(
      id: 'student1',
      name: 'Alice Student',
      email: 'alice@acadex.edu',
      role: AppRole.student,
    );

    const report = RoleDashboardReportModel(
      role: 'STUDENT',
      metrics: {
        'overallAttendance': 85.0,
        'todayClassesCount': 4,
        'availableNotesCount': 12,
        'unreadAnnouncements': 1,
      },
      quickStats: {},
      recentActivity: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier(const AuthAuthenticated(user: user, token: 'tok'))),
          roleDashboardReportProvider.overrideWith((ref) async => report),
        ],
        child: const MaterialApp(
          home: RoleDashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ACADEX Dashboard'), findsOneWidget);
    expect(find.text('Student Portal'), findsOneWidget);
    expect(find.text('My Attendance'), findsOneWidget);
    expect(find.text('85.0%'), findsOneWidget);
    expect(find.text("Today's Periods"), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });
}

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
