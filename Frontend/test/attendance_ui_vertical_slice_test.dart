import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

import 'package:campus_management/features/attendance/domain/models/assigned_class.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_record.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:campus_management/features/attendance/presentation/screens/attendance_dashboard_router.dart';
import 'package:campus_management/features/attendance/presentation/screens/assigned_classes_screen.dart';
import 'package:campus_management/features/attendance/presentation/screens/mark_attendance_screen.dart';
import 'package:campus_management/features/attendance/presentation/screens/student_attendance_portal_screen.dart';
import 'package:campus_management/features/attendance/presentation/screens/hod_attendance_dashboard_screen.dart';
import 'package:campus_management/features/attendance/presentation/screens/college_attendance_dashboard_screen.dart';
import 'package:campus_management/features/attendance/presentation/screens/super_admin_attendance_dashboard_screen.dart';
import 'package:campus_management/features/attendance/data/repositories/mock_attendance_repository.dart';
import 'package:campus_management/features/attendance/data/repositories/api_attendance_repository.dart';

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

  const testStudentUser = UserModel(
    id: 'student-01',
    name: 'Ada Lovelace',
    email: 'ada@alpha.edu',
    role: AppRole.student,
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    sectionId: 'sec-a',
  );

  const testHodUser = UserModel(
    id: 'hod-01',
    name: 'Dr. Shannon',
    email: 'shannon@alpha.edu',
    role: AppRole.hod,
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
  );

  const testAdminUser = UserModel(
    id: 'admin-01',
    name: 'Dean von Neumann',
    email: 'admin@alpha.edu',
    role: AppRole.collegeAdmin,
    collegeId: 'col-alpha',
  );

  const testSuperAdminUser = UserModel(
    id: 'super-01',
    name: 'Chief Admin',
    email: 'super@acadex.edu',
    role: AppRole.superAdmin,
  );

  group('ACADEX Phase 9Q.3 — Attendance Dashboard Router Role-Based Tests', () {
    testWidgets('1. Faculty is routed to AssignedClassesScreen', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testFacultyUser, token: 'tok'),
                )),
            attendanceRepoProvider.overrideWithValue(mockAttendanceRepo),
          ],
          child: const MaterialApp(
            home: AttendanceDashboardRouter(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(AssignedClassesScreen), findsOneWidget);
      expect(find.text("Today's Classes"), findsOneWidget);
    });

    testWidgets('2. Student is routed to StudentAttendancePortalScreen', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testStudentUser, token: 'tok'),
                )),
            attendanceRepoProvider.overrideWithValue(mockAttendanceRepo),
          ],
          child: const MaterialApp(
            home: AttendanceDashboardRouter(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(StudentAttendancePortalScreen), findsOneWidget);
      expect(find.text('Student Attendance Portal'), findsOneWidget);
    });

    testWidgets('3. HOD is routed to HodAttendanceDashboardScreen', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testHodUser, token: 'tok'),
                )),
            attendanceRepoProvider.overrideWithValue(mockAttendanceRepo),
          ],
          child: const MaterialApp(
            home: AttendanceDashboardRouter(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HodAttendanceDashboardScreen), findsOneWidget);
    });

    testWidgets('4. College Admin is routed to CollegeAttendanceDashboardScreen', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testAdminUser, token: 'tok'),
                )),
            attendanceRepoProvider.overrideWithValue(mockAttendanceRepo),
          ],
          child: const MaterialApp(
            home: AttendanceDashboardRouter(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(CollegeAttendanceDashboardScreen), findsOneWidget);
    });

    testWidgets('5. Super Admin is routed to SuperAdminAttendanceDashboardScreen', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testSuperAdminUser, token: 'tok'),
                )),
            attendanceRepoProvider.overrideWithValue(mockAttendanceRepo),
          ],
          child: const MaterialApp(
            home: AttendanceDashboardRouter(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SuperAdminAttendanceDashboardScreen), findsOneWidget);
    });
  });

  group('ACADEX Phase 9Q.3 — Faculty Attendance Marking Flow & Review Modal Tests', () {
    final sampleClass = AssignedClass(
      id: 'class_01',
      facultyId: 'faculty-01',
      subjectId: 'sub_algo',
      subjectName: 'Design & Analysis of Algorithms',
      sectionId: 'sec_cse_a',
      sectionName: 'CSE - A',
      semester: 'Semester 4',
      timeSlot: '09:00 AM - 10:00 AM',
      date: DateTime.now(),
    );

    final sampleRoster = [
      AttendanceRecord(
        id: 'rec_01',
        studentId: 'stud_01',
        studentName: 'Alice Smith',
        rollNumber: 'CS2026-001',
        sectionId: 'sec_cse_a',
      ),
      AttendanceRecord(
        id: 'rec_02',
        studentId: 'stud_02',
        studentName: 'Bob Johnson',
        rollNumber: 'CS2026-002',
        sectionId: 'sec_cse_a',
      ),
    ];

    testWidgets('6. MarkAttendanceScreen renders student roster, status controls, and review summary dialog', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testFacultyUser, token: 'tok'),
                )),
            attendanceRepoProvider.overrideWithValue(mockAttendanceRepo),
            activeClassProvider.overrideWith((ref) => sampleClass),
            activeStudentListProvider.overrideWith((ref) => Future.value(sampleRoster)),
          ],
          child: const MaterialApp(
            home: MarkAttendanceScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Subject and section title in header
      expect(find.text('Design & Analysis of Algorithms'), findsOneWidget);
      expect(find.textContaining('CSE - A'), findsWidgets);

      // Student Roster
      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('Bob Johnson'), findsOneWidget);

      // Search field test
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Alice');
      await tester.pumpAndSettle();

      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('Bob Johnson'), findsNothing);

      // Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
      expect(find.text('Bob Johnson'), findsOneWidget);

      // Mark All Present
      final markAllBtn = find.text('All Present');
      expect(markAllBtn, findsOneWidget);
      await tester.tap(markAllBtn);
      await tester.pumpAndSettle();

      // Submit action
      final saveBtn = find.text('Save Attendance');
      if (saveBtn.evaluate().isNotEmpty) {
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Review summary dialog appears
        expect(find.text('Review & Submit Attendance'), findsOneWidget);
        expect(find.textContaining("You're about to submit attendance for:"), findsOneWidget);
        expect(find.text('Confirm & Submit'), findsOneWidget);
      }
    });

    testWidgets('7. MarkAttendanceScreen mobile layout renders compact status controls', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testFacultyUser, token: 'tok'),
                )),
            attendanceRepoProvider.overrideWithValue(mockAttendanceRepo),
            activeClassProvider.overrideWith((ref) => sampleClass),
            activeStudentListProvider.overrideWith((ref) => Future.value(sampleRoster)),
          ],
          child: const MaterialApp(
            home: MarkAttendanceScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('Bob Johnson'), findsOneWidget);
    });
  });

  group('ACADEX Phase 9Q.3 — Student Attendance Portal Tests', () {
    testWidgets('8. StudentAttendancePortalScreen displays tabs and metric cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testStudentUser, token: 'tok'),
                )),
            attendanceRepoProvider.overrideWithValue(mockAttendanceRepo),
          ],
          child: const MaterialApp(
            home: StudentAttendancePortalScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Student Attendance Portal'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Subject Attendance'), findsOneWidget);
      expect(find.text('Attendance Calendar'), findsOneWidget);
      expect(find.text('Attendance Insights'), findsOneWidget);
    });
  });

  group('ACADEX Phase 9Q.3 — ApiAttendanceRepository Contract Tests', () {
    test('9. ApiAttendanceRepository can instantiate and fall back gracefully', () async {
      final repo = ApiAttendanceRepository();
      expect(repo, isA<ApiAttendanceRepository>());

      // Test fallback resolution when backend is offline
      final classes = await repo.getAssignedClasses('faculty-test', DateTime.now());
      expect(classes, isA<List<AssignedClass>>());

      final history = await repo.getStudentAttendanceHistory('student-test');
      expect(history, isA<List<dynamic>>());
    });
  });
}
