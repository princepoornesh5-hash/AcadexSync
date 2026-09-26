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
import 'package:campus_management/features/academic_structure/presentation/providers/department_setup_provider.dart';
import 'package:campus_management/features/academic_structure/presentation/screens/department_setup_screen.dart';
import 'package:campus_management/features/academic_structure/presentation/widgets/department_setup_card.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/timetable/data/repositories/timetable_repository.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestCourseNotifier extends CourseNotifier {
  final List<Course> initialCourses;
  TestCourseNotifier(this.initialCourses);
  @override
  Future<List<Course>> build() async => initialCourses;
}

class TestAcademicYearNotifier extends AcademicYearNotifier {
  final List<AcademicYear> initialYears;
  TestAcademicYearNotifier(this.initialYears);
  @override
  Future<List<AcademicYear>> build() async => initialYears;
}

class TestSemesterNotifier extends SemesterNotifier {
  final List<Semester> initialSemesters;
  TestSemesterNotifier(this.initialSemesters);
  @override
  Future<List<Semester>> build() async => initialSemesters;
}

class TestSectionNotifier extends SectionNotifier {
  final List<Section> initialSections;
  TestSectionNotifier(this.initialSections);
  @override
  Future<List<Section>> build() async => initialSections;
}

class TestSubjectNotifier extends SubjectNotifier {
  final List<Subject> initialSubjects;
  TestSubjectNotifier(this.initialSubjects);
  @override
  Future<List<Subject>> build() async => initialSubjects;
}

class TestFacultyAssignmentNotifier extends FacultyAssignmentsNotifier {
  final List<FacultyAssignment> initialAssignments;
  TestFacultyAssignmentNotifier(this.initialAssignments);
  @override
  Future<List<FacultyAssignment>> build() async => initialAssignments;
}

class TestDepartmentNotifier extends DepartmentNotifier {
  final List<Department> initialDepartments;
  TestDepartmentNotifier(this.initialDepartments);
  @override
  Future<List<Department>> build() async => initialDepartments;
}

class MockAcademicRepository implements AcademicRepository {
  final List<Student> students;
  MockAcademicRepository({this.students = const []});

  @override
  Future<List<Student>> getStudentsByDepartment(String departmentId) async {
    return students.where((s) => s.departmentId == departmentId).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTimetableRepository implements TimetableRepository {
  final List<TimetableContainerModel> containers;
  MockTimetableRepository([this.containers = const []]);

  @override
  Future<List<TimetableContainerModel>> getTimetableContainers({
    required String collegeId,
    String? departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    TimetableStatus? status,
  }) async {
    return containers.where((c) {
      if (departmentId != null && c.departmentId != departmentId) return false;
      return true;
    }).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testHodUser = UserModel(
    id: 'user-hod-01',
    name: 'Dr. Alan Turing',
    email: 'hod.cse@alpha.edu',
    role: AppRole.hod,
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
  );

  const testAdminUser = UserModel(
    id: 'user-admin-01',
    name: 'Admin Grace Hopper',
    email: 'admin@alpha.edu',
    role: AppRole.collegeAdmin,
    collegeId: 'col-alpha',
  );

  final testDepartment = Department(
    id: 'dept-cse',
    collegeId: 'col-alpha',
    hodId: 'user-hod-01',
    name: 'Computer Science & Engineering',
    code: 'CSE',
    description: 'CSE Department',
    isActive: true,
  );

  final testCourse = Course(
    id: 'course-cse-01',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    name: 'B.Tech CSE',
    code: 'BCSE',
    duration: 4,
    isActive: true,
  );

  final testYear = AcademicYear(
    id: 'ay-2026',
    collegeId: 'col-alpha',
    name: '2026–27',
    startDate: DateTime(2026, 6, 1),
    endDate: DateTime(2027, 5, 31),
    isCurrent: true,
    isActive: true,
  );

  final testSemester = Semester(
    id: 'sem-1',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    courseId: 'course-cse-01',
    academicYearId: 'ay-2026',
    name: 'Semester 1',
    number: 1,
    status: 'active',
    isCurrent: true,
    isActive: true,
  );

  final testSection = Section(
    id: 'sec-a',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    courseId: 'course-cse-01',
    academicYearId: 'ay-2026',
    semesterId: 'sem-1',
    name: 'Section A',
    capacity: 60,
    status: 'active',
    isActive: true,
  );

  final testSubject = Subject(
    id: 'sub-ds',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    courseId: 'course-cse-01',
    semesterId: 'sem-1',
    name: 'Data Structures',
    code: 'CS201',
    credits: 4,
    isActive: true,
  );

  final testAssignment = FacultyAssignment(
    id: 'fa-01',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    facultyId: 'fac-01',
    facultyName: 'Dr. Turing',
    courseId: 'course-cse-01',
    subjectId: 'sub-ds',
    sectionId: 'sec-a',
    academicYearId: 'ay-2026',
    semesterId: 'sem-1',
    isActive: true,
  );

  group('ACADEX — Department Setup Workspace & Progressive Onboarding Tests', () {
    testWidgets('1. Renders Department Setup workspace with department identity and milestones', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
              user: testHodUser,
              token: 'test-token',
            ))),
            academicRepositoryProvider.overrideWithValue(MockAcademicRepository()),
            departmentsProvider.overrideWith(() => TestDepartmentNotifier([testDepartment])),
            coursesProvider.overrideWith(() => TestCourseNotifier([testCourse])),
            academicYearsProvider.overrideWith(() => TestAcademicYearNotifier([testYear])),
            currentAcademicYearProvider.overrideWithValue(testYear),
            semestersProvider.overrideWith(() => TestSemesterNotifier([])),
            sectionsProvider.overrideWith(() => TestSectionNotifier([])),
            subjectsProvider.overrideWith(() => TestSubjectNotifier([])),
            facultyAssignmentsProvider.overrideWith(() => TestFacultyAssignmentNotifier([])),
            timetableRepositoryProvider.overrideWithValue(MockTimetableRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DepartmentSetupScreen()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Department Setup'), findsWidgets);
      expect(find.text('Computer Science & Engineering'), findsWidgets);
      expect(find.text('YOUR DEPARTMENT'), findsOneWidget);
      expect(find.text('Setup Progress'), findsOneWidget);
      expect(find.text('2 / 8 complete'), findsOneWidget);
      expect(find.text('Setup Milestones'), findsOneWidget);
      expect(find.text('Course'), findsWidgets);
      expect(find.text('Academic Year'), findsWidgets);
      expect(find.text('Semester'), findsWidgets);
    });

    testWidgets('2. Real completion state calculates 4 / 8 when Course, Academic Year, Semester, Section exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
              user: testHodUser,
              token: 'test-token',
            ))),
            academicRepositoryProvider.overrideWithValue(MockAcademicRepository()),
            departmentsProvider.overrideWith(() => TestDepartmentNotifier([testDepartment])),
            coursesProvider.overrideWith(() => TestCourseNotifier([testCourse])),
            academicYearsProvider.overrideWith(() => TestAcademicYearNotifier([testYear])),
            currentAcademicYearProvider.overrideWithValue(testYear),
            semestersProvider.overrideWith(() => TestSemesterNotifier([testSemester])),
            sectionsProvider.overrideWith(() => TestSectionNotifier([testSection])),
            subjectsProvider.overrideWith(() => TestSubjectNotifier([])),
            facultyAssignmentsProvider.overrideWith(() => TestFacultyAssignmentNotifier([])),
            timetableRepositoryProvider.overrideWithValue(MockTimetableRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DepartmentSetupScreen()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('4 / 8 complete'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('NEXT STEP'), findsOneWidget);
      expect(find.text('Configure Subjects to continue building your department foundation.'), findsOneWidget);
      expect(find.text('Continue Setup'), findsOneWidget);
    });

    testWidgets('3. HOD receives waiting guidance and [Notify College Admin] when Academic Year is missing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
              user: testHodUser,
              token: 'test-token',
            ))),
            academicRepositoryProvider.overrideWithValue(MockAcademicRepository()),
            departmentsProvider.overrideWith(() => TestDepartmentNotifier([testDepartment])),
            coursesProvider.overrideWith(() => TestCourseNotifier([testCourse])),
            academicYearsProvider.overrideWith(() => TestAcademicYearNotifier([])),
            currentAcademicYearProvider.overrideWithValue(null),
            semestersProvider.overrideWith(() => TestSemesterNotifier([])),
            sectionsProvider.overrideWith(() => TestSectionNotifier([])),
            subjectsProvider.overrideWith(() => TestSubjectNotifier([])),
            facultyAssignmentsProvider.overrideWith(() => TestFacultyAssignmentNotifier([])),
            timetableRepositoryProvider.overrideWithValue(MockTimetableRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DepartmentSetupScreen()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // HOD must NOT see 'Create Academic Year'
      expect(find.text('Create Academic Year'), findsNothing);
      expect(find.text('WAITING ON COLLEGE ADMIN'), findsOneWidget);
      expect(find.text('Notify College Admin'), findsWidgets);
      expect(find.textContaining('Your college has not configured an academic year yet'), findsWidgets);

      // Tap Notify College Admin
      await tester.tap(find.text('Notify College Admin').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Waiting for College Setup'), findsOneWidget);
      expect(find.text('Send Reminder'), findsOneWidget);
    });

    testWidgets('4. College Admin receives [Create Academic Year] action when Academic Year is missing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
              user: testAdminUser,
              token: 'test-token',
            ))),
            academicRepositoryProvider.overrideWithValue(MockAcademicRepository()),
            departmentsProvider.overrideWith(() => TestDepartmentNotifier([testDepartment])),
            coursesProvider.overrideWith(() => TestCourseNotifier([testCourse])),
            academicYearsProvider.overrideWith(() => TestAcademicYearNotifier([])),
            currentAcademicYearProvider.overrideWithValue(null),
            semestersProvider.overrideWith(() => TestSemesterNotifier([])),
            sectionsProvider.overrideWith(() => TestSectionNotifier([])),
            subjectsProvider.overrideWith(() => TestSubjectNotifier([])),
            facultyAssignmentsProvider.overrideWith(() => TestFacultyAssignmentNotifier([])),
            timetableRepositoryProvider.overrideWithValue(MockTimetableRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DepartmentSetupScreen()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Create Academic Year'), findsWidgets);
      expect(find.text('WAITING ON COLLEGE ADMIN'), findsNothing);
    });

    testWidgets('5. Full completion state renders celebratory banner and operational next steps', (tester) async {
      final timetableContainer = TimetableContainerModel(
        id: 'tt-01',
        collegeId: 'col-alpha',
        departmentId: 'dept-cse',
        courseId: 'course-cse-01',
        academicYearId: 'ay-2026',
        semesterId: 'sem-1',
        sectionId: 'sec-a',
        name: 'CSE Section A Timetable',
        status: TimetableStatus.published,
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      );

      final enrolledStudent = Student(
        id: 'stu-01',
        collegeId: 'col-alpha',
        departmentId: 'dept-cse',
        courseId: 'course-cse-01',
        semesterId: 'sem-1',
        sectionId: 'sec-a',
        name: 'John Doe',
        rollNumber: 'CSE001',
        email: 'john@alpha.edu',
        phone: '1234567890',
        lifecycleState: StudentLifecycleState.active,
        accountStatus: AccountStatus.active,
        isActive: true,
        history: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
              user: testHodUser,
              token: 'test-token',
            ))),
            academicRepositoryProvider.overrideWithValue(MockAcademicRepository(students: [enrolledStudent])),
            departmentsProvider.overrideWith(() => TestDepartmentNotifier([testDepartment])),
            coursesProvider.overrideWith(() => TestCourseNotifier([testCourse])),
            academicYearsProvider.overrideWith(() => TestAcademicYearNotifier([testYear])),
            currentAcademicYearProvider.overrideWithValue(testYear),
            semestersProvider.overrideWith(() => TestSemesterNotifier([testSemester])),
            sectionsProvider.overrideWith(() => TestSectionNotifier([testSection])),
            subjectsProvider.overrideWith(() => TestSubjectNotifier([testSubject])),
            facultyAssignmentsProvider.overrideWith(() => TestFacultyAssignmentNotifier([testAssignment])),
            timetableRepositoryProvider.overrideWithValue(MockTimetableRepository([timetableContainer])),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DepartmentSetupScreen()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('8 / 8 complete'), findsOneWidget);
      expect(find.text('DEPARTMENT SETUP COMPLETE'), findsOneWidget);
      expect(find.text('Your academic structure is ready. Faculty can manage classes, students can access schedules, and attendance can be conducted for published timetable periods.'), findsOneWidget);
      expect(find.text('View Academic Structure'), findsOneWidget);
    });

    testWidgets('6. Compact DepartmentSetupCard displays correct summary on dashboard', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
              user: testHodUser,
              token: 'test-token',
            ))),
            academicRepositoryProvider.overrideWithValue(MockAcademicRepository()),
            departmentsProvider.overrideWith(() => TestDepartmentNotifier([testDepartment])),
            coursesProvider.overrideWith(() => TestCourseNotifier([testCourse])),
            academicYearsProvider.overrideWith(() => TestAcademicYearNotifier([testYear])),
            currentAcademicYearProvider.overrideWithValue(testYear),
            semestersProvider.overrideWith(() => TestSemesterNotifier([testSemester])),
            sectionsProvider.overrideWith(() => TestSectionNotifier([])),
            subjectsProvider.overrideWith(() => TestSubjectNotifier([])),
            facultyAssignmentsProvider.overrideWith(() => TestFacultyAssignmentNotifier([])),
            timetableRepositoryProvider.overrideWithValue(MockTimetableRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DepartmentSetupCard(departmentId: 'dept-cse'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('DEPARTMENT SETUP'), findsOneWidget);
      expect(find.text('Computer Science & Engineering'), findsOneWidget);
      expect(find.text('3 / 8'), findsOneWidget);
      expect(find.text('Next: Create Section'), findsOneWidget);
      expect(find.text('Continue Setup'), findsOneWidget);
    });

    testWidgets('7. Responsive layout renders cleanly on 360dp, 390dp, and 412dp mobile screens without overflow', (tester) async {
      final screenWidths = [360.0, 390.0, 412.0];

      for (final width in screenWidths) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                user: testHodUser,
                token: 'test-token',
              ))),
              academicRepositoryProvider.overrideWithValue(MockAcademicRepository()),
              departmentsProvider.overrideWith(() => TestDepartmentNotifier([testDepartment])),
              coursesProvider.overrideWith(() => TestCourseNotifier([testCourse])),
              academicYearsProvider.overrideWith(() => TestAcademicYearNotifier([testYear])),
              currentAcademicYearProvider.overrideWithValue(testYear),
              semestersProvider.overrideWith(() => TestSemesterNotifier([testSemester])),
              sectionsProvider.overrideWith(() => TestSectionNotifier([])),
              subjectsProvider.overrideWith(() => TestSubjectNotifier([])),
              facultyAssignmentsProvider.overrideWith(() => TestFacultyAssignmentNotifier([])),
              timetableRepositoryProvider.overrideWithValue(MockTimetableRepository()),
            ],
            child: const MaterialApp(
              home: Scaffold(body: DepartmentSetupScreen()),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull, reason: 'Zero layout overflow errors on width $width');
        expect(find.text('Department Setup'), findsWidgets);
        expect(find.text('Continue Setup'), findsOneWidget);
      }

      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('8. Multi-course context displays contextual warning when a second course lacks semesters', (tester) async {
      final testCourse2 = Course(
        id: 'course-cse-02',
        collegeId: 'col-alpha',
        departmentId: 'dept-cse',
        name: 'M.Tech CSE',
        code: 'MCSE',
        duration: 2,
        isActive: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
              user: testHodUser,
              token: 'test-token',
            ))),
            academicRepositoryProvider.overrideWithValue(MockAcademicRepository()),
            departmentsProvider.overrideWith(() => TestDepartmentNotifier([testDepartment])),
            coursesProvider.overrideWith(() => TestCourseNotifier([testCourse, testCourse2])),
            academicYearsProvider.overrideWith(() => TestAcademicYearNotifier([testYear])),
            currentAcademicYearProvider.overrideWithValue(testYear),
            semestersProvider.overrideWith(() => TestSemesterNotifier([testSemester])),
            sectionsProvider.overrideWith(() => TestSectionNotifier([])),
            subjectsProvider.overrideWith(() => TestSubjectNotifier([])),
            facultyAssignmentsProvider.overrideWith(() => TestFacultyAssignmentNotifier([])),
            timetableRepositoryProvider.overrideWithValue(MockTimetableRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DepartmentSetupScreen()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Multiple courses detected: M.Tech CSE does not have an active semester configured yet.'), findsOneWidget);
    });

    test('9. Context preservation preserves courseId, academicYearId, and semesterId in milestone actionRoutes', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
            user: testHodUser,
            token: 'test-token',
          ))),
          academicRepositoryProvider.overrideWithValue(MockAcademicRepository()),
          departmentsProvider.overrideWith(() => TestDepartmentNotifier([testDepartment])),
          coursesProvider.overrideWith(() => TestCourseNotifier([testCourse])),
          academicYearsProvider.overrideWith(() => TestAcademicYearNotifier([testYear])),
          currentAcademicYearProvider.overrideWithValue(testYear),
          semestersProvider.overrideWith(() => TestSemesterNotifier([testSemester])),
          sectionsProvider.overrideWith(() => TestSectionNotifier([])),
          subjectsProvider.overrideWith(() => TestSubjectNotifier([])),
          facultyAssignmentsProvider.overrideWith(() => TestFacultyAssignmentNotifier([])),
          timetableRepositoryProvider.overrideWithValue(MockTimetableRepository()),
        ],
      );

      final state = await container.read(departmentSetupProvider('dept-cse').future);

      // Section milestone should prefill courseId and semesterId
      final sectionMilestone = state.milestones.firstWhere((m) => m.id == SetupMilestoneId.section);
      expect(sectionMilestone.actionRoute, contains('courseId=course-cse-01'));
      expect(sectionMilestone.actionRoute, contains('semesterId=sem-1'));
      expect(sectionMilestone.contextParams['courseId'], equals('course-cse-01'));
      expect(sectionMilestone.contextParams['semesterId'], equals('sem-1'));

      // Next actionable milestone should be Section
      expect(state.nextActionableMilestone?.id, equals(SetupMilestoneId.section));
    });
  });
}
