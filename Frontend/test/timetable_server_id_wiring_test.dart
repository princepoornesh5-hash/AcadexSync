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
import 'package:campus_management/features/timetable/presentation/screens/timetable_setup_screen.dart';
import 'package:campus_management/features/timetable/presentation/screens/timetable_designer_screen.dart';

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

  const testServerObjectId = '65f1234567890abcdef12345';
  const invalidShortId = 'bad_id';

  group('Timetable Server ID Wiring & Container Creation Tests', () {
    // =========================================================================
    // A. create timetable returns server ID
    // =========================================================================
    test('A1. ApiTimetableRepository.createTimetableContainer returns server MongoDB id', () async {
      RequestOptions? capturedRequest;
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          if (options.path == '/timetables' && options.method == 'POST') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 201,
              data: {
                'success': true,
                'message': 'Timetable created successfully',
                'data': {
                  'id': testServerObjectId,
                  '_id': testServerObjectId,
                  'name': 'CS-A Timetable',
                  'status': 'draft',
                  'timingMode': 'sameEveryDay',
                  'activeDays': ['monday', 'tuesday'],
                },
              },
            ));
          }
          return handler.next(options);
        },
      ));

      final client = ApiClient(customDio: dio);
      final repo = ApiTimetableRepository(client);

      final container = TimetableContainerModel(
        id: '',
        collegeId: 'col_123',
        departmentId: 'dept_cs',
        courseId: 'cr1',
        academicYearId: 'ay2',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'CS-A Timetable',
        status: TimetableStatus.draft,
        version: 1,
        activeDays: [TimetableDay.monday, TimetableDay.tuesday],
        timingMode: TimetableTimingMode.sameEveryDay,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final returnedId = await repo.createTimetableContainer(container);

      expect(returnedId, equals(testServerObjectId));
      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.path, equals('/timetables'));
      expect(capturedRequest!.method, equals('POST'));
    });

    test('A2. ApiTimetableRepository.createTimetableContainer extracts _id when id is absent', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/timetables' && options.method == 'POST') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 201,
              data: {
                'success': true,
                'data': {
                  '_id': testServerObjectId,
                  'name': 'CS-A Timetable',
                },
              },
            ));
          }
          return handler.next(options);
        },
      ));

      final client = ApiClient(customDio: dio);
      final repo = ApiTimetableRepository(client);

      final container = TimetableContainerModel(
        id: '',
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

      final returnedId = await repo.createTimetableContainer(container);
      expect(returnedId, equals(testServerObjectId));
    });

    test('A3. ApiTimetableRepository.createTimetableContainer throws if server returns missing/empty ID', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 201,
            data: {
              'success': true,
              'data': {
                'name': 'No ID container',
              },
            },
          ));
        },
      ));

      final client = ApiClient(customDio: dio);
      final repo = ApiTimetableRepository(client);

      final container = TimetableContainerModel(
        id: '',
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

      expect(
        () => repo.createTimetableContainer(container),
        throwsA(isA<Exception>()),
      );
    });

    // =========================================================================
    // B. Setup screen receives server ID & passes it to period/break batch saves
    // C. Designer receives server ID
    // =========================================================================
    testWidgets('B & C. TimetableSetupScreen receives server ID and passes it to batch saves & designer', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? periodsBatchTimetableId;
      String? breaksBatchTimetableId;

      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/timetables' && options.method == 'POST') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 201,
              data: {
                'success': true,
                'data': {
                  'id': testServerObjectId,
                  'name': 'CS-A Timetable',
                  'status': 'draft',
                  'periods': [],
                  'breaks': [],
                  'entries': [],
                },
              },
            ));
          } else if (options.path.startsWith('/timetables/$testServerObjectId') && options.method == 'PUT') {
            final data = options.data as Map<String, dynamic>?;
            if (data?.containsKey('periods') == true) {
              periodsBatchTimetableId = testServerObjectId;
            }
            if (data?.containsKey('breaks') == true) {
              breaksBatchTimetableId = testServerObjectId;
            }
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'id': testServerObjectId,
                  'periods': data?['periods'] ?? [],
                  'breaks': data?['breaks'] ?? [],
                  'entries': [],
                },
              },
            ));
          } else if (options.path == '/timetables/$testServerObjectId' && options.method == 'GET') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'id': testServerObjectId,
                  'collegeId': 'col_123',
                  'departmentId': 'dept_cs',
                  'courseId': 'cr1',
                  'academicYearId': 'ay2',
                  'semesterId': 'sem1',
                  'sectionId': 'sec1',
                  'name': 'CS-A Timetable',
                  'status': 'draft',
                  'timingMode': 'sameEveryDay',
                  'activeDays': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
                  'periods': [
                    {'id': 'p1', 'name': 'P1', 'index': 1, 'startTime': '09:00', 'endTime': '10:00'},
                  ],
                  'breaks': [],
                  'entries': [],
                },
              },
            ));
          } else if (options.path == '/timetables' && options.method == 'GET') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {'success': true, 'data': []},
            ));
          }
          return handler.next(options);
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: hodUser, token: 'mock-token'))),
            currentUserProvider.overrideWithValue(hodUser),
            timetableRepositoryProvider.overrideWithValue(repo),
            academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
            timetableSubjectMapProvider.overrideWithValue(const {}),
            timetableFacultyMapProvider.overrideWithValue(const {}),
            timetableDepartmentMapProvider.overrideWithValue(deptMap),
            timetableCourseMapProvider.overrideWithValue(courseMap),
            timetableSectionMapProvider.overrideWithValue(sectionMap),
            timetableAcademicYearMapProvider.overrideWithValue(yearMap),
          ],
          child: const MaterialApp(
            home: TimetableSetupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Academic Context
      expect(find.text('Step 1: Academic Hierarchy'), findsOneWidget);
      await tester.tap(find.text('Course / Degree Program *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B.Tech CS (BTECH-CS)').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Academic Year *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026-2027').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Semester *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semester 1').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Section *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A').last);
      await tester.pumpAndSettle();

      // Step 1 -> Step 2
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next Step'));
      await tester.pumpAndSettle();

      // Step 2 -> Step 3
      expect(find.text('Step 2: Working Days & Timing Mode'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next Step'));
      await tester.pumpAndSettle();

      // Step 3 -> Step 4
      expect(find.textContaining('Step 3: Period Slots'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next Step'));
      await tester.pumpAndSettle();

      // Step 4 -> Step 5
      expect(find.textContaining('Step 4: Configure Breaks'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next Step'));
      await tester.pumpAndSettle();

      // Step 5: Preview & Create
      expect(find.text('Timetable Configuration Summary'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create & Open Designer'));
      await tester.pumpAndSettle();

      // Verify TimetableDesignerScreen was navigated to with the real MongoDB ObjectId
      final designerFinder = find.byType(TimetableDesignerScreen);
      expect(designerFinder, findsOneWidget);
      final designerWidget = tester.widget<TimetableDesignerScreen>(designerFinder);
      expect(designerWidget.timetableId, equals(testServerObjectId));
      expect(periodsBatchTimetableId, equals(testServerObjectId));
      expect(breaksBatchTimetableId, equals(testServerObjectId));
    });

    // =========================================================================
    // D. update request uses MongoDB ObjectId
    // =========================================================================
    test('D. updateTimetableContainer and savePeriodsBatch use MongoDB ObjectId in URL', () async {
      final List<String> targetedUrls = [];
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          targetedUrls.add('${options.method} ${options.path}');
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': true, 'data': {}},
          ));
        },
      ));

      final client = ApiClient(customDio: dio);
      final repo = ApiTimetableRepository(client);

      final container = TimetableContainerModel(
        id: testServerObjectId,
        collegeId: 'col_123',
        departmentId: 'dept_cs',
        courseId: 'cr1',
        academicYearId: 'ay2',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'CS-A Timetable Updated',
        status: TimetableStatus.draft,
        version: 1,
        activeDays: [TimetableDay.monday],
        timingMode: TimetableTimingMode.sameEveryDay,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.updateTimetableContainer(container);
      await repo.savePeriodsBatch(testServerObjectId, [
        TimetablePeriodModel(id: 'p1', index: 1, name: 'P1', startTime: '09:00', endTime: '10:00'),
      ]);
      await repo.saveBreaksBatch(testServerObjectId, [
        TimetableBreakModel(id: 'b1', name: 'Recess', startTime: '11:00', endTime: '11:15', appliesToDays: [TimetableDay.monday]),
      ]);

      expect(targetedUrls, contains('PUT /timetables/$testServerObjectId'));
      // Verify all PUT targets are against the 24-character hex ObjectId
      for (final url in targetedUrls) {
        expect(url, contains(testServerObjectId));
        expect(url.contains(invalidShortId), isFalse);
      }
    });

    // =========================================================================
    // E. publish request uses MongoDB ObjectId
    // =========================================================================
    test('E. publishTimetable and unpublishTimetable use MongoDB ObjectId in URL', () async {
      final List<String> targetedUrls = [];
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          targetedUrls.add('${options.method} ${options.path}');
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': true, 'data': {}},
          ));
        },
      ));

      final client = ApiClient(customDio: dio);
      final repo = ApiTimetableRepository(client);

      await repo.publishTimetable(testServerObjectId, publishedBy: 'hod_1');
      await repo.unpublishTimetable(testServerObjectId);

      expect(targetedUrls, contains('POST /timetables/$testServerObjectId/publish'));
      expect(targetedUrls, contains('POST /timetables/$testServerObjectId/unpublish'));
      for (final url in targetedUrls) {
        expect(url, contains(testServerObjectId));
        expect(url.contains(invalidShortId), isFalse);
      }
    });
  });
}
