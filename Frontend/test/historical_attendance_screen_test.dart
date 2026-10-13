import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/attendance/presentation/screens/historical_attendance_screen.dart';
import 'package:campus_management/features/attendance/data/repositories/mock_attendance_repository.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_providers.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testFacultyUser = UserModel(
    id: 'faculty-01',
    name: 'Prof. Turing',
    email: 'turing@alpha.edu',
    role: AppRole.faculty,
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
  );

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _FakeAuthNotifier(
          const AuthAuthenticated(user: testFacultyUser, token: 'mock-jwt-token'),
        )),
        attendanceRepoProvider.overrideWithValue(MockAttendanceRepository()),
      ],
      child: const MaterialApp(
        home: HistoricalAttendanceScreen(),
      ),
    );
  }

  group('HistoricalAttendanceScreen Widget & Workflow Tests', () {
    testWidgets('1. Renders Historical Attendance Screen with Header and Tabs', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Historical Attendance Entry'), findsOneWidget);
      expect(find.text('Detailed Session'), findsOneWidget);
      expect(find.text('Historical Summary'), findsOneWidget);
      expect(find.text('Student Correction'), findsOneWidget);
      expect(find.text('HISTORICAL ACADEMIC ARCHIVE WORKFLOW'), findsOneWidget);
      expect(find.text('AUDITED'), findsOneWidget);
    });

    testWidgets('2. Displays Mode A Academic Context and Session Parameters', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Academic Context & Scope'), findsOneWidget);
      expect(find.text('Session Date & Period'), findsOneWidget);
      expect(find.text('Load Historical Roster'), findsOneWidget);
      expect(find.text('No Historical Roster Loaded'), findsOneWidget);
    });

    testWidgets('3. Switches to Mode B Historical Summary Tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Historical Summary tab
      await tester.tap(find.text('Historical Summary'));
      await tester.pumpAndSettle();

      expect(find.text('Summary Aggregation Specification'), findsOneWidget);
      expect(find.text('Classes Count'), findsOneWidget);
      expect(find.text('Percentage Only (%)'), findsOneWidget);
    });

    testWidgets('4. Switches to Mode C Student Correction Tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Student Correction tab
      await tester.tap(find.text('Student Correction'));
      await tester.pumpAndSettle();

      expect(find.text('Student-Specific Historical Correction'), findsOneWidget);
      expect(find.text('Submit Audited Correction'), findsOneWidget);
    });
  });
}
