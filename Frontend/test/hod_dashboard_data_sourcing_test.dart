import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/timetable/data/repositories/api_timetable_repository.dart';
import 'package:campus_management/features/dashboard/presentation/screens/hod_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:campus_management/features/academic_structure/domain/repositories/academic_repository.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:campus_management/features/attendance/domain/models/department_attendance_summary.dart';
import 'package:campus_management/core/presentation/widgets/acadex_feedback.dart';
import 'package:campus_management/core/network/api_client.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockAcademicRepo implements AcademicRepository {
  final List<Faculty> facultyList;
  final List<Department> departmentList;
  _MockAcademicRepo({
    this.facultyList = const [],
    this.departmentList = const [],
  });

  @override
  Future<List<Faculty>> getFaculty({String? departmentId, String? search, String? status}) async {
    if (departmentId != null) {
      return facultyList.where((f) => f.departmentId == departmentId).toList();
    }
    return facultyList;
  }

  @override
  Future<List<Department>> getDepartments({String? collegeId, String? search, String? status}) async => departmentList;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockAttendanceRepo implements AttendanceRepository {
  @override
  Future<DepartmentAttendanceSummary> getDepartmentSummary(String departmentId) async {
    return DepartmentAttendanceSummary(
      overallPercentage: 88.5,
      studentsBelow75: 2,
      facultyCompleted: 4,
      facultyPending: 1,
      todayClasses: 6,
      totalStudents: 120,
      totalFaculty: 5,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testHod = UserModel(
    id: 'hod-1',
    name: 'Dr. Jane Hopper',
    email: 'hod.cse@acadex.edu',
    role: AppRole.hod,
    collegeId: 'col-1',
    departmentId: 'dept-cse',
  );

  final testDept = Department(
    id: 'dept-cse',
    collegeId: 'col-1',
    name: 'Computer Science',
    code: 'CSE',
    hodId: 'hod-1',
    description: 'Computer Science Department',
  );

  group('ApiTimetableRepository Role-Aware Routing', () {
    test('HOD request routes to /timetables/departments/:id and NOT /timetables/students/me', () async {
      String? requestedPath;
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPath = options.path;
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': true, 'data': []},
          ));
        },
      ));

      final client = ApiClient(customDio: dio);
      final repo = ApiTimetableRepository(client);

      final result = await repo.getTimetable(
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        role: AppRole.hod,
      );

      expect(requestedPath, equals('/timetables/departments/dept-cse'));
      expect(result, isEmpty);
    });

    test('Non-student without department or section returns empty list without calling student endpoint', () async {
      var wasCalled = false;
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          wasCalled = true;
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': true, 'data': []},
          ));
        },
      ));

      final client = ApiClient(customDio: dio);
      final repo = ApiTimetableRepository(client);

      final result = await repo.getTimetable(
        collegeId: 'col-1',
        departmentId: null,
        sectionId: null,
        facultyId: null,
        role: AppRole.hod,
      );

      expect(wasCalled, isFalse);
      expect(result, isEmpty);
    });

    test('Student without department or section calls /timetables/students/me', () async {
      String? requestedPath;
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPath = options.path;
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': true, 'data': []},
          ));
        },
      ));

      final client = ApiClient(customDio: dio);
      final repo = ApiTimetableRepository(client);

      final result = await repo.getTimetable(
        collegeId: 'col-1',
        departmentId: null,
        sectionId: null,
        facultyId: null,
        role: AppRole.student,
      );

      expect(requestedPath, equals('/timetables/students/me'));
      expect(result, isEmpty);
    });
  });

  group('HOD Dashboard Faculty Count', () {
    test('hodStatsProvider matches canonical academic faculty source (Dept Faculty > 0)', () async {
      final mockFaculty = [
        Faculty(
          id: 'fac-1',
          name: 'Prof. Xavier',
          email: 'x@acadex.edu',
          phone: '9876543210',
          employeeId: 'EMP001',
          collegeId: 'col-1',
          departmentId: 'dept-cse',
          accountStatus: AccountStatus.active,
        ),
        Faculty(
          id: 'fac-2',
          name: 'Prof. Magneto',
          email: 'm@acadex.edu',
          phone: '9876543211',
          employeeId: 'EMP002',
          collegeId: 'col-1',
          departmentId: 'dept-cse',
          accountStatus: AccountStatus.active,
        ),
        Faculty(
          id: 'fac-3',
          name: 'Prof. Wolverine',
          email: 'w@acadex.edu',
          phone: '9876543212',
          employeeId: 'EMP003',
          collegeId: 'col-1',
          departmentId: 'dept-cse',
          accountStatus: AccountStatus.active,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier(const AuthAuthenticated(user: testHod, token: 'tok'))),
          academicRepositoryProvider.overrideWithValue(_MockAcademicRepo(
            facultyList: mockFaculty,
            departmentList: [testDept],
          )),
          attendanceRepoProvider.overrideWithValue(_MockAttendanceRepo()),
        ],
      );

      final stats = await container.read(hodStatsProvider.future);
      final facultyStat = stats.firstWhere((s) => s.title == 'Department Faculty');

      expect(facultyStat.value, equals('3'));
      container.dispose();
    });
  });

  group('HOD Dashboard Timetable State Handling', () {
    testWidgets('Displays contextual empty state "No timetable published yet" and "Manage Timetable" CTA', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(const AuthAuthenticated(user: testHod, token: 'tok'))),
            academicRepositoryProvider.overrideWithValue(_MockAcademicRepo(departmentList: [testDept])),
            todayScheduleProvider.overrideWithValue(const AsyncValue.data([])),
            hodStatsProvider.overrideWith((ref) async => []),
            hodActivityProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HodDashboard()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No timetable published yet'), findsOneWidget);
      expect(find.text('Manage Timetable'), findsOneWidget);
      expect(find.textContaining('Only students can access this endpoint'), findsNothing);
    });

    testWidgets('Displays user-friendly retryable error state when timetable fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(const AuthAuthenticated(user: testHod, token: 'tok'))),
            academicRepositoryProvider.overrideWithValue(_MockAcademicRepo(departmentList: [testDept])),
            todayScheduleProvider.overrideWithValue(AsyncValue.error(Exception('Connection timeout'), StackTrace.empty)),
            hodStatsProvider.overrideWith((ref) async => []),
            hodActivityProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HodDashboard()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final timetableErrorFinder = find.ancestor(
        of: find.text("Unable to load today's department timetable. Tap to retry."),
        matching: find.byType(AcadexErrorState),
      );
      expect(timetableErrorFinder, findsOneWidget);
      expect(find.descendant(of: timetableErrorFinder, matching: find.text('Try Again')), findsOneWidget);
      expect(find.textContaining('Connection timeout'), findsNothing);
    });
  });
}
