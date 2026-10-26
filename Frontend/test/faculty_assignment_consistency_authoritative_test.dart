import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/domain/repositories/academic_repository.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/presentation/screens/my_assignments_screen.dart';
import 'package:campus_management/features/notes/presentation/screens/note_form_screen.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/presentation/widgets/timetable_entry_detail_sheet.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_providers.dart';

class MockTestAcademicRepository implements AcademicRepository {
  List<FacultyAssignment> mockMyAssignments = [];
  bool shouldThrowError = false;
  List<Subject> mockSubjects = [];
  List<Section> mockSections = [];
  List<Semester> mockSemesters = [];
  List<Course> mockCourses = [];
  List<AcademicYear> mockAcademicYears = [];

  @override
  Future<List<FacultyAssignment>> getMyFacultyAssignments() async {
    if (shouldThrowError) {
      throw Exception('Network or Server Error');
    }
    return mockMyAssignments;
  }

  @override
  Future<List<Subject>> getSubjects({String? collegeId, String? departmentId, String? courseId, String? semesterId}) async => mockSubjects;

  @override
  Future<List<Section>> getSections({String? collegeId, String? departmentId, String? courseId, String? academicYearId, String? semesterId}) async => mockSections;

  @override
  Future<List<Semester>> getSemesters({String? collegeId, String? departmentId, String? courseId, String? academicYearId}) async => mockSemesters;

  @override
  Future<List<Course>> getCourses({String? collegeId, String? departmentId, String? search}) async => mockCourses;

  @override
  Future<List<AcademicYear>> getAcademicYears({String? collegeId}) async => mockAcademicYears;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  void setUser(UserModel user) {
    state = AuthAuthenticated(user: user, token: 'jwt_token');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testFacultyUser = UserModel(
    id: 'usr_mani_123',
    name: 'T Masila Mani',
    email: 'mani@alpha.edu',
    role: AppRole.faculty,
    collegeId: 'col_alpha',
    departmentId: 'dept_cme',
  );

  final iotAssignment = FacultyAssignment(
    id: 'fa_iot_001',
    collegeId: 'col_alpha',
    departmentId: 'dept_cme',
    courseId: 'crs_dcme',
    academicYearId: 'ay_2026',
    semesterId: 'sem_5',
    sectionId: 'sec_a',
    subjectId: 'sub_iot',
    facultyId: 'fac_mani_profile_456', // Distinct from usr_mani_123!
    facultyName: 'T Masila Mani',
    status: 'active',
    isActive: true,
  );

  final testSubjectIot = Subject(
    id: 'sub_iot',
    collegeId: 'col_alpha',
    departmentId: 'dept_cme',
    courseId: 'crs_dcme',
    semesterId: 'sem_5',
    name: 'Internet of Things',
    code: 'CM-504',
    type: 'Theory',
    isActive: true,
  );

  final testSectionA = Section(
    id: 'sec_a',
    collegeId: 'col_alpha',
    departmentId: 'dept_cme',
    courseId: 'crs_dcme',
    academicYearId: 'ay_2026',
    semesterId: 'sem_5',
    name: 'Section A',
    capacity: 60,
    isActive: true,
  );

  final testCourse = Course(
    id: 'crs_dcme',
    collegeId: 'col_alpha',
    departmentId: 'dept_cme',
    name: 'Diploma in Computer Engineering',
    code: 'DCME',
    duration: 3,
    isActive: true,
  );

  final testSemester = Semester(
    id: 'sem_5',
    collegeId: 'col_alpha',
    departmentId: 'dept_cme',
    courseId: 'crs_dcme',
    academicYearId: 'ay_2026',
    name: 'Semester 5',
    number: 5,
    status: 'active',
    isCurrent: true,
    isActive: true,
  );

  group('ACADEX Faculty Assignment Consistency Tests', () {
    testWidgets('1. My Classes displays valid IoT teaching assignment resolved via canonical contract', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockTestAcademicRepository();
      mockRepo.mockMyAssignments = [iotAssignment];
      mockRepo.mockSubjects = [testSubjectIot];
      mockRepo.mockSections = [testSectionA];
      mockRepo.mockCourses = [testCourse];
      mockRepo.mockSemesters = [testSemester];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
              user: testFacultyUser,
              token: 'jwt_token',
            ))),
            academicRepositoryProvider.overrideWithValue(mockRepo),
            subjectMapProvider.overrideWithValue({'sub_iot': testSubjectIot}),
            sectionMapProvider.overrideWithValue({'sec_a': testSectionA}),
            courseMapProvider.overrideWithValue({'crs_dcme': testCourse}),
            semesterMapProvider.overrideWithValue({'sem_5': testSemester}),
          ],
          child: const MaterialApp(
            home: MyAssignmentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // IoT Assignment should be rendered
      expect(find.text('Internet of Things'), findsOneWidget);
      expect(find.text('Allocated Classes'), findsOneWidget);
      expect(find.text('Take Attendance'), findsOneWidget);
      expect(find.text('No Active Teaching Assignments'), findsNothing);
    });

    testWidgets('2. My Classes displays distinct empty state when no assignments exist', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockTestAcademicRepository();
      mockRepo.mockMyAssignments = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
              user: testFacultyUser,
              token: 'jwt_token',
            ))),
            academicRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: MyAssignmentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Active Teaching Assignments'), findsOneWidget);
      expect(find.textContaining('You currently have no classes or subjects allocated'), findsOneWidget);
    });

    testWidgets('3. My Classes displays distinct error state with retry on API failure', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockTestAcademicRepository();
      mockRepo.shouldThrowError = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
              user: testFacultyUser,
              token: 'jwt_token',
            ))),
            academicRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: MyAssignmentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to Load Teaching Assignments'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('No Active Teaching Assignments'), findsNothing);
    });

    testWidgets('4. Create Note displays authoritative IoT class when eligible assignment exists', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockTestAcademicRepository();
      mockRepo.mockMyAssignments = [iotAssignment];
      mockRepo.mockSubjects = [testSubjectIot];
      mockRepo.mockSections = [testSectionA];
      mockRepo.mockSemesters = [testSemester];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
              user: testFacultyUser,
              token: 'jwt_token',
            ))),
            academicRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: NoteFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Dropdown should be loaded with class
      expect(find.textContaining('Internet of Things'), findsAtLeastNWidgets(1));
      expect(find.text('No active teaching assignments are available for your account.'), findsNothing);
    });

    testWidgets('5. Create Note displays warning message when no teaching assignments are available', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockTestAcademicRepository();
      mockRepo.mockMyAssignments = [];
      mockRepo.mockSubjects = [testSubjectIot];
      mockRepo.mockSections = [testSectionA];
      mockRepo.mockSemesters = [testSemester];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
              user: testFacultyUser,
              token: 'jwt_token',
            ))),
            academicRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: NoteFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No active teaching assignments are available for your account.'), findsOneWidget);
    });

    testWidgets('6. Timetable entry detail sheet rejects orphaned entry without valid assignment', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final orphanedEntry = TimetableModel(
        id: 'tt_entry_orphaned',
        collegeId: 'col_alpha',
        departmentId: 'dept_cme',
        courseId: 'crs_dcme',
        academicYearId: 'ay_2026',
        semesterId: 'sem_5',
        sectionId: 'sec_a',
        subjectId: 'sub_unknown_orphaned',
        facultyId: 'fac_mani_profile_456',
        facultyAssignmentId: null, // Missing assignment!
        dayOfWeek: TimetableDay.tuesday,
        startTime: '11:00',
        endTime: '13:00',
        roomNumber: 'LAB-3',
        sessionType: TimetableSessionType.lab,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockRepo = MockTestAcademicRepository();
      mockRepo.mockMyAssignments = [iotAssignment]; // Assigned to sub_iot, NOT sub_unknown_orphaned

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
              user: testFacultyUser,
              token: 'jwt_token',
            ))),
            academicRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TimetableEntryDetailSheet(entry: orphanedEntry),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Mark Attendance button and tap
      final markAttendanceBtn = find.text('Mark Attendance');
      expect(markAttendanceBtn, findsOneWidget);
      await tester.tap(markAttendanceBtn);
      await tester.pumpAndSettle();

      // Should show SnackBar error refusing attendance marking for orphaned entry
      expect(find.text('Cannot mark attendance: This timetable entry is not associated with an authorized teaching assignment.'), findsOneWidget);
    });

    testWidgets('7. Timetable entry detail sheet resolves valid IoT entry to canonical assignment', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final validEntry = TimetableModel(
        id: 'tt_entry_iot',
        collegeId: 'col_alpha',
        departmentId: 'dept_cme',
        courseId: 'crs_dcme',
        academicYearId: 'ay_2026',
        semesterId: 'sem_5',
        sectionId: 'sec_a',
        subjectId: 'sub_iot',
        facultyId: 'fac_mani_profile_456',
        facultyAssignmentId: 'fa_iot_001',
        dayOfWeek: TimetableDay.tuesday,
        startTime: '11:00',
        endTime: '13:00',
        roomNumber: 'LAB-3',
        sessionType: TimetableSessionType.lab,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockRepo = MockTestAcademicRepository();
      mockRepo.mockMyAssignments = [iotAssignment];

      late WidgetRef rootRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
              user: testFacultyUser,
              token: 'jwt_token',
            ))),
            academicRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              rootRef = ref;
              return MaterialApp(
                routes: {
                  '/attendance/mark': (ctx) => const Scaffold(body: Text('Mark Attendance Screen')),
                },
                home: Scaffold(
                  body: TimetableEntryDetailSheet(entry: validEntry),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      final markAttendanceBtn = find.text('Mark Attendance');
      expect(markAttendanceBtn, findsOneWidget);
      await tester.tap(markAttendanceBtn);
      await tester.pumpAndSettle();

      // Attendance state should be populated with canonical assignment ID
      final activeClass = rootRef.read(activeClassProvider);
      expect(activeClass?.facultyAssignmentId, 'fa_iot_001');
      expect(activeClass?.subjectId, 'sub_iot');
    });

    test('8. Workspace switching invalidates personal assignments provider', () async {
      final mockRepo = MockTestAcademicRepository();
      mockRepo.mockMyAssignments = [iotAssignment];

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
            user: testFacultyUser,
            token: 'jwt_token',
          ))),
          academicRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Initial read
      final assignments = await container.read(myFacultyAssignmentsAsyncProvider.future);
      expect(assignments.length, 1);
      expect(assignments.first.id, 'fa_iot_001');

      // Simulate workspace switch: mock repo now returns empty for new workspace
      mockRepo.mockMyAssignments = [];
      container.invalidate(myFacultyAssignmentsAsyncProvider);

      final refreshed = await container.read(myFacultyAssignmentsAsyncProvider.future);
      expect(refreshed.isEmpty, true);
    });
  });
}
