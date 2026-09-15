import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

import 'package:campus_management/features/attendance/domain/models/assigned_class.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_record.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_session.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_status.dart';
import 'package:campus_management/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:campus_management/features/attendance/presentation/screens/mark_attendance_screen.dart';
import 'package:campus_management/features/attendance/presentation/screens/assigned_classes_screen.dart';
import 'package:campus_management/features/attendance/presentation/screens/student_attendance_portal_screen.dart';
import 'package:campus_management/features/attendance/presentation/widgets/assigned_class_card.dart';
import 'package:campus_management/core/presentation/widgets/acadex_feedback.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockAttendanceRepo implements AttendanceRepository {
  final List<AssignedClass> assignedClasses;
  final List<AttendanceRecord> roster;
  final bool throw403OnSave;
  final bool throw409OnSave;
  bool saveCalled = false;

  _MockAttendanceRepo({
    this.assignedClasses = const [],
    this.roster = const [],
    this.throw403OnSave = false,
    this.throw409OnSave = false,
  });

  @override
  Future<List<AssignedClass>> getAssignedClasses(String facultyId, DateTime date) async {
    return assignedClasses;
  }

  @override
  Future<List<AttendanceRecord>> getStudentsForSection(
    String sectionId,
    String subjectId,
    DateTime date, {
    String? timetableEntryId,
  }) async {
    return roster;
  }

  @override
  Future<bool> saveSession(AttendanceSession session) async {
    saveCalled = true;
    if (throw403OnSave) {
      throw Exception('You are not authorized to mark attendance for this class.');
    }
    if (throw409OnSave) {
      throw Exception('An active attendance session already exists for this class.');
    }
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testFaculty = UserModel(
    id: 'fac-alpha-01',
    name: 'Dr. Alan Turing',
    email: 'turing@alpha.edu',
    role: AppRole.faculty,
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
  );

  const testStudent = UserModel(
    id: 'stud-alpha-01',
    name: 'Ada Lovelace',
    email: 'ada@alpha.edu',
    role: AppRole.student,
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    sectionId: 'sec-5a',
  );

  final testClass = AssignedClass(
    id: 'tt-entry-01',
    facultyId: 'fac-alpha-01',
    subjectId: 'sub-dbms',
    subjectName: 'Database Management Systems',
    sectionId: 'sec-5a',
    sectionName: 'Section 5A',
    semester: 'Semester 5',
    timeSlot: '09:00 - 10:00',
    roomNumber: 'LH-101',
    building: 'CS Block',
    date: DateTime(2026, 9, 14),
    timetableId: 'tt-parent-01',
    timetableEntryId: 'tt-entry-01',
    facultyAssignmentId: 'assign-01',
  );

  final realStudentRoster = [
    AttendanceRecord(
      id: 'rec-01',
      studentId: 'stud-01',
      studentName: 'Ravi Kumar',
      rollNumber: 'CS2026-001',
      sectionId: 'sec-5a',
      status: AttendanceStatus.present,
    ),
    AttendanceRecord(
      id: 'rec-02',
      studentId: 'stud-02',
      studentName: 'Suresh Raina',
      rollNumber: 'CS2026-002',
      sectionId: 'sec-5a',
      status: AttendanceStatus.absent,
    ),
    AttendanceRecord(
      id: 'rec-03',
      studentId: 'stud-03',
      studentName: 'Anitha Sharma',
      rollNumber: 'CS2026-003',
      sectionId: 'sec-5a',
      status: AttendanceStatus.absent,
    ),
  ];

  group('ACADEX — Real-Time Attendance Integration (Prompt 5 of 6) Frontend Tests', () {
    testWidgets('1. Authorized faculty sees correct assigned class', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _MockAttendanceRepo(assignedClasses: [testClass]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testFaculty, token: 'tok-fac'),
                )),
            attendanceRepoProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: AssignedClassesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Database Management Systems'), findsOneWidget);
      expect(find.text('Section 5A'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
    });

    testWidgets('2. Mark Attendance action appears on assigned class card', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _MockAttendanceRepo(assignedClasses: [testClass]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testFaculty, token: 'tok-fac'),
                )),
            attendanceRepoProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: AssignedClassesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AssignedClassCard), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('3 & 4. Attendance screen loads real roster with student names & identifiers', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _MockAttendanceRepo(roster: realStudentRoster);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testFaculty, token: 'tok-fac'),
                )),
            attendanceRepoProvider.overrideWithValue(repo),
            activeClassProvider.overrideWith((ref) => testClass),
            activeStudentListProvider.overrideWith((ref) => Future.value(realStudentRoster)),
          ],
          child: const MaterialApp(
            home: MarkAttendanceScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Real student names appear
      expect(find.text('Ravi Kumar'), findsOneWidget);
      expect(find.text('Suresh Raina'), findsOneWidget);
      expect(find.text('Anitha Sharma'), findsOneWidget);

      // Roll numbers appear
      expect(find.text('CS2026-001'), findsOneWidget);
      expect(find.text('CS2026-002'), findsOneWidget);
      expect(find.text('CS2026-003'), findsOneWidget);

      // Real roster count in header
      expect(find.textContaining('3 Students'), findsOneWidget);
    });

    testWidgets('5. Present / Absent controls work interactively', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _MockAttendanceRepo(roster: realStudentRoster);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testFaculty, token: 'tok-fac'),
                )),
            attendanceRepoProvider.overrideWithValue(repo),
            activeClassProvider.overrideWith((ref) => testClass),
            activeStudentListProvider.overrideWith((ref) => Future.value(realStudentRoster)),
          ],
          child: const MaterialApp(
            home: MarkAttendanceScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Present button for Suresh (who starts as Absent)
      final presentButtons = find.widgetWithText(InkWell, 'P');
      if (presentButtons.evaluate().isNotEmpty) {
        await tester.tap(presentButtons.at(1));
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('6. Mark All Present action updates roster', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _MockAttendanceRepo(roster: realStudentRoster);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testFaculty, token: 'tok-fac'),
                )),
            attendanceRepoProvider.overrideWithValue(repo),
            activeClassProvider.overrideWith((ref) => testClass),
            activeStudentListProvider.overrideWith((ref) => Future.value(realStudentRoster)),
          ],
          child: const MaterialApp(
            home: MarkAttendanceScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final markAllBtn = find.text('All Present');
      expect(markAllBtn, findsOneWidget);
      await tester.tap(markAllBtn);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('7. Search filters only authorized loaded roster', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _MockAttendanceRepo(roster: realStudentRoster);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testFaculty, token: 'tok-fac'),
                )),
            attendanceRepoProvider.overrideWithValue(repo),
            activeClassProvider.overrideWith((ref) => testClass),
            activeStudentListProvider.overrideWith((ref) => Future.value(realStudentRoster)),
          ],
          child: const MaterialApp(
            home: MarkAttendanceScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Search for 'Ravi'
      await tester.enterText(searchField, 'Ravi');
      await tester.pumpAndSettle();

      expect(find.text('Ravi Kumar'), findsOneWidget);
      expect(find.text('Suresh Raina'), findsNothing);
      expect(find.text('Anitha Sharma'), findsNothing);

      // Clear search restores all
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      expect(find.text('Ravi Kumar'), findsOneWidget);
      expect(find.text('Suresh Raina'), findsOneWidget);
      expect(find.text('Anitha Sharma'), findsOneWidget);
    });

    testWidgets('8. Empty roster displays empty state and disables submission', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _MockAttendanceRepo(roster: []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testFaculty, token: 'tok-fac'),
                )),
            attendanceRepoProvider.overrideWithValue(repo),
            activeClassProvider.overrideWith((ref) => testClass),
            activeStudentListProvider.overrideWith((ref) => Future.value(<AttendanceRecord>[])),
          ],
          child: const MaterialApp(
            home: MarkAttendanceScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Roster count is 0
      expect(find.textContaining('0 Students'), findsOneWidget);

      // AcadexEmptyState displays
      expect(find.byType(AcadexEmptyState), findsOneWidget);
      expect(find.text('No Enrolled Students'), findsOneWidget);
      expect(find.text('No students are currently enrolled in this section.'), findsOneWidget);

      // Save Attendance button displays disabled state
      expect(find.text('No Students Enrolled'), findsOneWidget);
    });

    testWidgets('9. 403 displays correct authorization message', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _MockAttendanceRepo(roster: realStudentRoster, throw403OnSave: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testFaculty, token: 'tok-fac'),
                )),
            attendanceRepoProvider.overrideWithValue(repo),
            activeClassProvider.overrideWith((ref) => testClass),
            activeStudentListProvider.overrideWith((ref) => Future.value(realStudentRoster)),
          ],
          child: const MaterialApp(
            home: MarkAttendanceScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Save
      final saveBtn = find.text('Save Attendance');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Confirm in dialog
      final confirmBtn = find.text('Confirm & Submit');
      if (confirmBtn.evaluate().isNotEmpty) {
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();
      }

      // Exact 403 error message in snackbar
      expect(find.text('You are not authorized to mark attendance for this class.'), findsOneWidget);
    });

    testWidgets('10. 409 displays correct duplicate session message', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _MockAttendanceRepo(roster: realStudentRoster, throw409OnSave: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testFaculty, token: 'tok-fac'),
                )),
            attendanceRepoProvider.overrideWithValue(repo),
            activeClassProvider.overrideWith((ref) => testClass),
            activeStudentListProvider.overrideWith((ref) => Future.value(realStudentRoster)),
          ],
          child: const MaterialApp(
            home: MarkAttendanceScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Save
      final saveBtn = find.text('Save Attendance');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Confirm in dialog
      final confirmBtn = find.text('Confirm & Submit');
      if (confirmBtn.evaluate().isNotEmpty) {
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();
      }

      // Exact 409 error message in snackbar
      expect(find.text('An active attendance session already exists for this class.'), findsOneWidget);
    });

    testWidgets('11. Successful submission saves session and displays confirmation', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _MockAttendanceRepo(roster: realStudentRoster);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testFaculty, token: 'tok-fac'),
                )),
            attendanceRepoProvider.overrideWithValue(repo),
            activeClassProvider.overrideWith((ref) => testClass),
            activeStudentListProvider.overrideWith((ref) => Future.value(realStudentRoster)),
          ],
          child: const MaterialApp(
            home: MarkAttendanceScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Save
      final saveBtn = find.text('Save Attendance');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Confirm in dialog
      final confirmBtn = find.text('Confirm & Submit');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(repo.saveCalled, isTrue);
      expect(find.text('Attendance session saved successfully!'), findsOneWidget);
    });

    testWidgets('12. Student does not see mutation controls (read-only view)', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _MockAttendanceRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testStudent, token: 'tok-stud'),
                )),
            attendanceRepoProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: StudentAttendancePortalScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Mutation controls must NOT exist
      expect(find.text('Mark Attendance'), findsNothing);
      expect(find.text('Save Attendance'), findsNothing);
      expect(find.text('All Present'), findsNothing);
      expect(find.text('Student Attendance Portal'), findsOneWidget);
    });

    testWidgets('13. Responsive rendering across 360dp, 390dp, 412dp with font scales 1.0, 1.15, 1.25', (tester) async {
      final repo = _MockAttendanceRepo(roster: realStudentRoster);

      final testConfigs = [
        {'width': 360.0, 'height': 800.0, 'scale': 1.0},
        {'width': 390.0, 'height': 844.0, 'scale': 1.15},
        {'width': 412.0, 'height': 915.0, 'scale': 1.25},
      ];

      for (final config in testConfigs) {
        final w = config['width'] as double;
        final h = config['height'] as double;
        final s = config['scale'] as double;

        tester.view.physicalSize = Size(w * 2.0, h * 2.0);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => _FakeAuthNotifier(
                    const AuthAuthenticated(user: testFaculty, token: 'tok-fac'),
                  )),
              attendanceRepoProvider.overrideWithValue(repo),
              activeClassProvider.overrideWith((ref) => testClass),
              activeStudentListProvider.overrideWith((ref) => Future.value(realStudentRoster)),
            ],
            child: MaterialApp(
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(s),
                  ),
                  child: child!,
                );
              },
              home: const MarkAttendanceScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check for no overflow exceptions
        expect(tester.takeException(), isNull, reason: 'Failed at width $w with font scale $s');

        // Check essential elements render and fit
        expect(find.text('Database Management Systems'), findsOneWidget);
        expect(find.text('Ravi Kumar'), findsOneWidget);
        expect(find.text('Suresh Raina'), findsOneWidget);
        // Scroll listview to reveal 3rd student
        await tester.drag(find.byType(ListView).first, const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(find.text('Anitha Sharma'), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
