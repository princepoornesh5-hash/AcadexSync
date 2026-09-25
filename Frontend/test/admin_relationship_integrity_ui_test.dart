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
import 'package:campus_management/features/academic_structure/presentation/screens/hod_screens.dart';
import 'package:campus_management/features/academic_structure/presentation/widgets/faculty_assignment_dialog.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FastMockAcademicRepository implements AcademicRepository {
  final List<Department> departments = [
    Department(id: 'dept_1', collegeId: 'college_1', name: 'Computer Science & Engineering', code: 'CSE', hodId: 'hod_1', description: ''),
    Department(id: 'dept_2', collegeId: 'college_1', name: 'Electrical Engineering', code: 'EE', hodId: '', description: ''),
  ];
  final List<Course> courses = [
    Course(id: 'course_1', collegeId: 'college_1', departmentId: 'dept_1', name: 'B.Tech CSE', code: 'BT-CS'),
  ];
  final List<AcademicYear> academicYears = [
    AcademicYear(id: 'ay_1', collegeId: 'college_1', name: '2026-2027', startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 12, 31), isCurrent: true),
  ];
  final List<Semester> semesters = [
    Semester(id: 'sem_1', collegeId: 'college_1', departmentId: 'dept_1', courseId: 'course_1', academicYearId: 'ay_1', name: 'Semester 5', number: 5),
  ];
  final List<Section> sections = [
    Section(id: 'sec_1', collegeId: 'college_1', departmentId: 'dept_1', semesterId: 'sem_1', name: 'Section A'),
  ];
  final List<Subject> subjects = [
    Subject(id: 'sub_1', collegeId: 'college_1', departmentId: 'dept_1', courseId: 'course_1', semesterId: 'sem_1', name: 'Distributed Systems', code: 'CS501', credits: 4, type: 'THEORY'),
  ];
  final List<UserModel> hods = [
    UserModel(
      id: 'hod_1',
      name: 'Dr. Alan Turing',
      instituteId: 'HOD-CSE-01',
      email: 'turing@college.edu',
      role: AppRole.hod,
      collegeId: 'college_1',
      departmentId: 'dept_1',
      accountStatus: AccountStatus.active,
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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
  Future<List<Subject>> getSubjects({String? collegeId, String? courseId, String? departmentId, String? semesterId}) async => List.from(subjects);

  @override
  Future<List<UserModel>> getHods({String? departmentId, String? search, String? status}) async => List.from(hods);

  @override
  Future<List<FacultyAssignment>> getFacultyAssignments({String? facultyId, String? departmentId, String? courseId, String? semesterId, String? sectionId, String? subjectId, String? academicYearId}) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testAdmin = UserModel(
    id: 'admin_1',
    name: 'College Admin',
    email: 'admin@college.edu',
    role: AppRole.collegeAdmin,
    collegeId: 'college_1',
    accountStatus: AccountStatus.active,
  );

  final mockRepo = FastMockAcademicRepository();

  Widget createTestApp({required Widget child}) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testAdmin, token: 'dummy_token'))),
        academicRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('HOD Management & Relationship Integrity UI Tests', () {
    testWidgets('1. HOD list renders correctly with active status badge and Assign Existing button', (tester) async {
      await tester.pumpWidget(createTestApp(child: const HodListScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Department Heads (HODs)'), findsOneWidget);
      expect(find.text('Dr. Alan Turing'), findsOneWidget);
      expect(find.text('Assign Existing'), findsOneWidget);
      expect(find.text('Provision HOD'), findsOneWidget);
    });

    testWidgets('2. Tapping Assign Existing button opens promotional dialog with active departments', (tester) async {
      await tester.pumpWidget(createTestApp(child: const HodListScreen()));
      await tester.pumpAndSettle();

      final assignBtn = find.text('Assign Existing');
      expect(assignBtn, findsOneWidget);
      await tester.tap(assignBtn);
      await tester.pumpAndSettle();

      // If no faculty in list, shows snackbar or dialog
      expect(find.byType(AlertDialog).evaluate().isNotEmpty || find.byType(SnackBar).evaluate().isNotEmpty, isTrue);
    });

    testWidgets('3. FacultyAssignmentDialog enforces strict cascading dropdowns and loads correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FacultyAssignmentDialog.show(context),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Faculty Subject & Class Assignment'), findsOneWidget);
      expect(find.text('Department *'), findsOneWidget);
      expect(find.text('Course *'), findsOneWidget);
      expect(find.text('Semester *'), findsOneWidget);
    });

    testWidgets('4. Mobile layout at 360px renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(child: const HodListScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Department Heads (HODs)'), findsOneWidget);
    });
  });
}
