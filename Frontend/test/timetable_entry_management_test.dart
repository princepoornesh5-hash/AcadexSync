import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:campus_management/core/network/api_client.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/domain/repositories/academic_repository.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/data/repositories/api_timetable_repository.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_lookup_providers.dart';
import 'package:campus_management/features/timetable/presentation/screens/timetable_management_screen.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FastMockAcademicRepository implements AcademicRepository {
  final List<Department> departments = [
    Department(id: 'dept_cs', collegeId: 'col_123', name: 'Computer Science', code: 'CS', hodId: 'hod_1', description: ''),
  ];
  final List<Course> courses = [
    Course(id: 'cr1', collegeId: 'col_123', departmentId: 'dept_cs', name: 'B.Tech CS', code: 'BTECH-CS'),
  ];
  final List<AcademicYear> academicYears = [
    AcademicYear(id: 'ay2', collegeId: 'col_123', name: '2026-2027', startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 12, 31), isCurrent: true),
  ];
  final List<Semester> semesters = [
    Semester(id: 'sem1', collegeId: 'col_123', departmentId: 'dept_cs', courseId: 'cr1', academicYearId: 'ay2', name: 'Semester 1', number: 1),
  ];
  final List<Section> sections = [
    Section(id: 'sec1', collegeId: 'col_123', departmentId: 'dept_cs', semesterId: 'sem1', name: 'A'),
  ];

  @override
  Future<List<College>> getColleges({String? search, String? status}) async => [];
  @override
  Future<List<Department>> getDepartments({String? collegeId, String? search, String? status}) async => List.from(departments);
  @override
  Future<List<Course>> getCourses({String? collegeId, String? departmentId, String? search}) async => List.from(courses);
  @override
  Future<List<AcademicYear>> getAcademicYears({String? collegeId}) async => List.from(academicYears);
  @override
  Future<List<Semester>> getSemesters({String? academicYearId, String? collegeId, String? courseId}) async => List.from(semesters);
  @override
  Future<List<Section>> getSections({String? collegeId, String? courseId, String? semesterId}) async => List.from(sections);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testTimetableId = '65f1234567890abcdef12345';
  const entryId1 = '65faaa111111111111111111';
  const entryId2 = '65fbbb222222222222222222';
  const entryId3 = '65fccc333333333333333333';

  group('Timetable Prompt 2: Entry Management & Container Authoritative Deletion', () {
    // =========================================================================
    // A, B, C, D, E: Container PUT, Real IDs, Preserving Other Entries
    // =========================================================================
    test('A-E. Removing one entry sends PUT /timetables/:id with real ObjectId, removing only target entry and preserving others', () async {
      RequestOptions? putRequest;
      Map<String, dynamic>? putData;

      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/timetables/$testTimetableId' && options.method == 'GET') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'id': testTimetableId,
                  'name': 'CS-A Timetable',
                  'status': 'draft',
                  'periods': [],
                  'breaks': [],
                  'entries': [
                    {'id': entryId1, 'dayOfWeek': 'monday', 'startPeriodIndex': 1, 'periodSpan': 1, 'startTime': '09:00', 'endTime': '10:00', 'subjectId': 'sub1', 'facultyId': 'fac1', 'roomNumber': '101', 'sessionType': 'lecture'},
                    {'id': entryId2, 'dayOfWeek': 'monday', 'startPeriodIndex': 2, 'periodSpan': 1, 'startTime': '10:00', 'endTime': '11:00', 'subjectId': 'sub2', 'facultyId': 'fac2', 'roomNumber': '102', 'sessionType': 'lecture'},
                    {'id': entryId3, 'dayOfWeek': 'tuesday', 'startPeriodIndex': 1, 'periodSpan': 1, 'startTime': '09:00', 'endTime': '10:00', 'subjectId': 'sub3', 'facultyId': 'fac3', 'roomNumber': '103', 'sessionType': 'lab'},
                  ],
                },
              },
            ));
          } else if (options.path == '/timetables/$testTimetableId' && options.method == 'PUT') {
            putRequest = options;
            putData = options.data as Map<String, dynamic>?;
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'id': testTimetableId,
                  'entries': putData?['entries'] ?? [],
                },
              },
            ));
          }
          return handler.next(options);
        },
      ));

      final client = ApiClient(customDio: dio);
      final repo = ApiTimetableRepository(client);

      // Perform deletion of entryId2
      await repo.deleteGridEntry(testTimetableId, entryId2);

      // C & D: Verify PUT /timetables/:id with real MongoDB ObjectId
      expect(putRequest, isNotNull);
      expect(putRequest!.method, equals('PUT'));
      expect(putRequest!.path, equals('/timetables/$testTimetableId'));

      // A & B: Verify only entryId2 was removed and other entries preserved
      expect(putData, isNotNull);
      final entriesList = putData!['entries'] as List<dynamic>;
      expect(entriesList.length, equals(2));

      final remainingIds = entriesList.map((e) => (e as Map)['id']).toList();
      // E: Real timetableEntryIds
      expect(remainingIds, contains(entryId1));
      expect(remainingIds, contains(entryId3));
      expect(remainingIds.contains(entryId2), isFalse);

      // Verify cached entries
      final cached = await repo.getGridEntries(testTimetableId);
      expect(cached.length, equals(2));
      expect(cached.map((e) => e.id), containsAll([entryId1, entryId3]));
    });

    // =========================================================================
    // F. Rejecting modification of a published timetable
    // =========================================================================
    test('F. Deleting an entry from a PUBLISHED timetable is strictly rejected', () async {
      const publishedTimetableId = '65f999999999999999999999';
      bool putAttempted = false;

      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/timetables/$publishedTimetableId' && options.method == 'GET') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'id': publishedTimetableId,
                  'name': 'Published Timetable',
                  'status': 'published',
                  'entries': [
                    {'id': entryId1, 'dayOfWeek': 'monday', 'startPeriodIndex': 1, 'startTime': '09:00', 'endTime': '10:00', 'subjectId': 'sub1', 'facultyId': 'fac1', 'roomNumber': '101', 'sessionType': 'lecture'},
                  ],
                },
              },
            ));
          } else if (options.method == 'PUT') {
            putAttempted = true;
          }
          return handler.next(options);
        },
      ));

      final client = ApiClient(customDio: dio);
      final repo = ApiTimetableRepository(client);

      // Attempting to delete an entry from published timetable must throw StateError
      expect(
        () => repo.deleteGridEntry(publishedTimetableId, entryId1),
        throwsA(isA<StateError>()),
      );

      // Ensure no PUT request was sent to server
      expect(putAttempted, isFalse);
    });

    // =========================================================================
    // G & H. Authoring State: Success updates frontend, Failure keeps state intact
    // =========================================================================
    test('G. Successful server deletion updates TimetableAuthoringNotifier state', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/timetables/$testTimetableId' && options.method == 'GET') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'id': testTimetableId,
                  'name': 'CS-A Timetable',
                  'status': 'draft',
                  'entries': [
                    {'id': entryId1, 'dayOfWeek': 'monday', 'startPeriodIndex': 1, 'startTime': '09:00', 'endTime': '10:00', 'subjectId': 'sub1', 'facultyId': 'fac1', 'roomNumber': '101', 'sessionType': 'lecture'},
                    {'id': entryId2, 'dayOfWeek': 'monday', 'startPeriodIndex': 2, 'startTime': '10:00', 'endTime': '11:00', 'subjectId': 'sub2', 'facultyId': 'fac2', 'roomNumber': '102', 'sessionType': 'lecture'},
                  ],
                },
              },
            ));
          } else if (options.path == '/timetables/$testTimetableId' && options.method == 'PUT') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {'id': testTimetableId},
              },
            ));
          }
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': true, 'data': {}},
          ));
        },
      ));

      final client = ApiClient(customDio: dio);
      final repo = ApiTimetableRepository(client);

      final hodUser = UserModel(
        id: 'hod_1',
        collegeId: 'col_123',
        departmentId: 'dept_cs',
        email: 'hod.cs@acadex.edu',
        name: 'Dr. Alan Turing',
        role: AppRole.hod,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(hodUser),
          authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: hodUser, token: 'mock-token'))),
          timetableRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(timetableAuthoringProvider(testTimetableId), (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(timetableAuthoringProvider(testTimetableId).notifier);

      // Pre-seed local state with 2 entries
      notifier.state = notifier.state.copyWith(
        container: TimetableContainerModel(
          id: testTimetableId,
          collegeId: 'col_123',
          departmentId: 'dept_cs',
          courseId: 'cr1',
          academicYearId: 'ay2',
          semesterId: 'sem1',
          sectionId: 'sec1',
          name: 'CS-A Timetable',
          status: TimetableStatus.draft,
          version: 1,
          activeDays: [TimetableDay.monday],
          timingMode: TimetableTimingMode.sameEveryDay,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        entries: [
          TimetableGridEntryModel(id: entryId1, dayOfWeek: TimetableDay.monday, startPeriodIndex: 1, startTime: '09:00', endTime: '10:00', subjectId: 'sub1', facultyId: 'fac1', roomNumber: '101', sessionType: TimetableSessionType.lecture),
          TimetableGridEntryModel(id: entryId2, dayOfWeek: TimetableDay.monday, startPeriodIndex: 2, startTime: '10:00', endTime: '11:00', subjectId: 'sub2', facultyId: 'fac2', roomNumber: '102', sessionType: TimetableSessionType.lecture),
        ],
      );

      // Call authoritative deletion
      await notifier.deleteEntryAuthoritatively(entryId1);

      final state = container.read(timetableAuthoringProvider(testTimetableId));
      expect(state.isSaving, isFalse);
      expect(state.isDirty, isFalse);
      expect(state.entries.length, equals(1));
      expect(state.entries.first.id, equals(entryId2));
    });

    test('H. Failed server response leaves authoritative state completely intact', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/timetables/$testTimetableId' && options.method == 'GET') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'id': testTimetableId,
                  'status': 'draft',
                  'entries': [
                    {'id': entryId1, 'dayOfWeek': 'monday', 'startPeriodIndex': 1, 'startTime': '09:00', 'endTime': '10:00', 'subjectId': 'sub1', 'facultyId': 'fac1', 'roomNumber': '101', 'sessionType': 'lecture'},
                    {'id': entryId2, 'dayOfWeek': 'monday', 'startPeriodIndex': 2, 'startTime': '10:00', 'endTime': '11:00', 'subjectId': 'sub2', 'facultyId': 'fac2', 'roomNumber': '102', 'sessionType': 'lecture'},
                  ],
                },
              },
            ));
          } else if (options.path == '/timetables/$testTimetableId' && options.method == 'PUT') {
            return handler.reject(DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 500,
                data: {'success': false, 'message': 'Internal Server Error on Update'},
              ),
              message: 'Server error during timetable update',
            ));
          }
          return handler.next(options);
        },
      ));

      final client = ApiClient(customDio: dio);
      final repo = ApiTimetableRepository(client);

      // Pre-seed entries cache
      await repo.getGridEntries(testTimetableId);

      // Attempt deletion which fails on backend
      expect(
        () => repo.deleteGridEntry(testTimetableId, entryId1),
        throwsA(isA<Exception>()),
      );

      // Authoritative state must be intact: both entries must still exist
      final entriesAfterFail = await repo.getGridEntries(testTimetableId);
      expect(entriesAfterFail.length, equals(2));
      expect(entriesAfterFail.map((e) => e.id), containsAll([entryId1, entryId2]));
    });

    // =========================================================================
    // I. No call to deprecated individual-entry CRUD methods
    // =========================================================================
    test('I. Calling deprecated deleteEntry on TimetableManagementNotifier throws UnsupportedError', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(timetableManagementProvider.notifier);

      expect(
        () => notifier.deleteEntry('any_id'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    // =========================================================================
    // UI Verification: TimetableManagementScreen delete action is container-aware
    // =========================================================================
    testWidgets('UI. TimetableManagementScreen section authoring delete button calls container PUT', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool putCalled = false;
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/timetables/$testTimetableId' && options.method == 'PUT') {
            putCalled = true;
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {'success': true, 'data': {}},
            ));
          } else if (options.path == '/timetables/$testTimetableId' && options.method == 'GET') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'id': testTimetableId,
                  'name': 'CS-A Timetable',
                  'status': 'draft',
                  'periods': [
                    {'id': 'p1', 'name': 'P1', 'index': 1, 'startTime': '09:00', 'endTime': '10:00'},
                  ],
                  'breaks': [],
                  'entries': [
                    {'id': entryId1, 'dayOfWeek': 'monday', 'startPeriodIndex': 1, 'startTime': '09:00', 'endTime': '10:00', 'subjectId': 'sub1', 'facultyId': 'fac1', 'roomNumber': '101', 'sessionType': 'lecture'},
                  ],
                },
              },
            ));
          }
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': true, 'data': []},
          ));
        },
      ));

      final client = ApiClient(customDio: dio);
      final repo = ApiTimetableRepository(client);
      final mockAcademicRepo = FastMockAcademicRepository();

      final hodUser = UserModel(
        id: 'hod_1',
        collegeId: 'col_123',
        departmentId: 'dept_cs',
        email: 'hod.cs@acadex.edu',
        name: 'Dr. Alan Turing',
        role: AppRole.hod,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final deptMap = {for (var d in mockAcademicRepo.departments) d.id: d};
      final courseMap = {for (var c in mockAcademicRepo.courses) c.id: c};
      final sectionMap = {for (var s in mockAcademicRepo.sections) s.id: s};
      final yearMap = {for (var y in mockAcademicRepo.academicYears) y.id: y};

      final draftContainer = TimetableContainerModel(
        id: testTimetableId,
        collegeId: 'col_123',
        departmentId: 'dept_cs',
        courseId: 'cr1',
        academicYearId: 'ay2',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'CS-A Timetable',
        status: TimetableStatus.draft,
        version: 1,
        activeDays: [TimetableDay.monday],
        timingMode: TimetableTimingMode.sameEveryDay,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: hodUser, token: 'mock-token'))),
            currentUserProvider.overrideWithValue(hodUser),
            timetableRepositoryProvider.overrideWithValue(repo),
            academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
            timetableSubjectMapProvider.overrideWithValue({'sub1': Subject(id: 'sub1', collegeId: 'col_123', departmentId: 'dept_cs', semesterId: 'sem1', name: 'Algorithms', code: 'CS101', credits: 4)}),
            timetableFacultyMapProvider.overrideWithValue({'fac1': Faculty(id: 'fac1', collegeId: 'col_123', departmentId: 'dept_cs', name: 'Dr. Grace Hopper', employeeId: 'EMP001', email: 'hopper@acadex.edu', phone: '1234567890')}),
            timetableDepartmentMapProvider.overrideWithValue(deptMap),
            timetableCourseMapProvider.overrideWithValue(courseMap),
            timetableSectionMapProvider.overrideWithValue(sectionMap),
            timetableAcademicYearMapProvider.overrideWithValue(yearMap),
            managementContainersProvider.overrideWith((ref) => Future.value([draftContainer])),
            timetableFilterProvider.overrideWith((ref) => TimetableFilterState(
              departmentId: 'dept_cs',
              courseId: 'cr1',
              semesterId: 'sem1',
              sectionId: 'sec1',
            )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TimetableManagementScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify class is rendered in the section authoring view
      expect(find.textContaining('Algorithms'), findsOneWidget);

      // Tap the Delete Class icon button
      final trashBtn = find.byTooltip('Delete Class');
      expect(trashBtn, findsOneWidget);
      await tester.tap(trashBtn);
      await tester.pumpAndSettle();

      // Verify Confirmation Dialog is shown
      expect(find.text('Delete Class Entry?'), findsOneWidget);

      // Tap Delete in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      // Verify PUT /timetables/:id was called on server
      expect(putCalled, isTrue);
    });
  });
}
