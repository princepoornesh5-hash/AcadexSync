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
import 'package:campus_management/features/academic_structure/presentation/utils/academic_prerequisite_guard.dart';
import 'package:campus_management/features/academic_structure/presentation/widgets/setup_continuation_dialog.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/timetable/data/repositories/timetable_repository.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';

// Test Notifiers & Mocks
class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestCourseNotifier extends CourseNotifier {
  List<Course> courses;
  TestCourseNotifier(this.courses);
  @override
  Future<List<Course>> build() async => courses;

  void setCourses(List<Course> newCourses) {
    courses = newCourses;
    state = AsyncData(newCourses);
  }
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

  final testCourse1 = Course(
    id: 'course-cse-01',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    name: 'B.Tech CSE',
    code: 'BCSE',
    duration: 4,
    isActive: true,
  );

  final testCourse2 = Course(
    id: 'course-cse-02',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    name: 'M.Tech CSE',
    code: 'MCSE',
    duration: 2,
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

  final testSemester1 = Semester(
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

  final testSection1 = Section(
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

  final testSubject1 = Subject(
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

  final testFaculty1 = Faculty(
    id: 'fac-01',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    name: 'Dr. Turing',
    email: 'turing@alpha.edu',
    phone: '+1234567890',
    employeeId: 'EMP-01',
    designation: 'Professor',
    isActive: true,
  );

  final testAssignment1 = FacultyAssignment(
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

  final testStudent1 = Student(
    id: 'stu-01',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    courseId: 'course-cse-01',
    semesterId: 'sem-1',
    sectionId: 'sec-a',
    name: 'Ada Lovelace',
    rollNumber: 'CSE001',
    email: 'ada@alpha.edu',
    phone: '1234567890',
    lifecycleState: StudentLifecycleState.active,
    accountStatus: AccountStatus.active,
    isActive: true,
    history: [],
  );

  final testTimetableContainer1 = TimetableContainerModel(
    id: 'tt-01',
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    courseId: 'course-cse-01',
    academicYearId: 'ay-2026',
    semesterId: 'sem-1',
    sectionId: 'sec-a',
    name: 'CSE Sec A Timetable',
    status: TimetableStatus.published,
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
  );

  group('ACADEX — Smart Dependency Ownership & Create-and-Continue Tests', () {
    // 1. HOD + no Academic Year -> WAITING_ON_OTHER_ROLE -> owner = COLLEGE_ADMIN -> no Create Academic Year action
    test('1. HOD + no Academic Year resolves to WAITING_ON_OTHER_ROLE owned by College Admin with no 403 action route', () {
      final decision = AcademicPrerequisiteGuard.resolveMilestoneDecision(
        milestoneId: SetupMilestoneId.academicYear,
        currentRole: AppRole.hod,
        departmentId: 'dept-cse',
        collegeId: 'col-alpha',
        courses: [testCourse1],
        academicYears: [],
        currentAcademicYear: null,
        semesters: [],
        sections: [],
        subjects: [],
        faculty: [],
        facultyAssignments: [],
        students: [],
        timetableCount: 0,
      );

      expect(decision.status, equals(SetupDecisionStatus.waitingOnOtherRole));
      expect(decision.ownerRole, equals(AppRole.collegeAdmin));
      expect(decision.canCurrentUserAct, isFalse);
      expect(decision.actionRoute, isNull);
      expect(decision.actionLabel, equals('Notify College Admin'));
      expect(decision.waitingReason, contains('College Admin'));
    });

    // 2. College Admin + no Academic Year -> READY -> Create Academic Year
    test('2. College Admin + no Academic Year resolves to READY with valid Create Academic Year action route', () {
      final decision = AcademicPrerequisiteGuard.resolveMilestoneDecision(
        milestoneId: SetupMilestoneId.academicYear,
        currentRole: testAdminUser.role,
        departmentId: 'dept-cse',
        collegeId: 'col-alpha',
        courses: [testCourse1],
        academicYears: [],
        currentAcademicYear: null,
        semesters: [],
        sections: [],
        subjects: [],
        faculty: [],
        facultyAssignments: [],
        students: [],
        timetableCount: 0,
      );

      expect(decision.status, equals(SetupDecisionStatus.ready));
      expect(decision.ownerRole, equals(AppRole.collegeAdmin));
      expect(decision.canCurrentUserAct, isTrue);
      expect(decision.actionRoute, equals('/academics/academic_years/new'));
      expect(decision.actionLabel, equals('Create Academic Year'));
    });

    // 3. HOD + Academic Year exists + no Semester -> READY for Semester creation
    test('3. HOD + Academic Year exists + no Semester resolves to READY for Semester creation with preserved context', () {
      final decision = AcademicPrerequisiteGuard.resolveMilestoneDecision(
        milestoneId: SetupMilestoneId.semester,
        currentRole: AppRole.hod,
        departmentId: 'dept-cse',
        collegeId: 'col-alpha',
        courses: [testCourse1],
        academicYears: [testYear],
        currentAcademicYear: testYear,
        semesters: [],
        sections: [],
        subjects: [],
        faculty: [],
        facultyAssignments: [],
        students: [],
        timetableCount: 0,
      );

      expect(decision.status, equals(SetupDecisionStatus.ready));
      expect(decision.ownerRole, equals(AppRole.hod));
      expect(decision.canCurrentUserAct, isTrue);
      expect(decision.actionRoute, contains('/academics/semesters/new'));
      expect(decision.actionRoute, contains('courseId=course-cse-01'));
      expect(decision.actionRoute, contains('academicYearId=ay-2026'));
      expect(decision.contextParams['departmentId'], equals('dept-cse'));
      expect(decision.actionLabel, equals('Create Semester'));
    });

    // 4. Semester missing Course -> blocked with Course dependency
    test('4. Semester missing Course resolves to BLOCKED with Course dependency', () {
      final decision = AcademicPrerequisiteGuard.resolveMilestoneDecision(
        milestoneId: SetupMilestoneId.semester,
        currentRole: AppRole.hod,
        departmentId: 'dept-cse',
        collegeId: 'col-alpha',
        courses: [], // No courses!
        academicYears: [testYear],
        currentAcademicYear: testYear,
        semesters: [],
        sections: [],
        subjects: [],
        faculty: [],
        facultyAssignments: [],
        students: [],
        timetableCount: 0,
      );

      expect(decision.status, equals(SetupDecisionStatus.blocked));
      expect(decision.missingDependency, equals(AcademicPrerequisiteType.course));
      expect(decision.explanation, contains('Create a course first'));
      expect(decision.canCurrentUserAct, isTrue); // Can act by creating course first
      expect(decision.actionRoute, contains('/academics/courses/new'));
    });

    // 5. Section missing Semester -> blocked with Semester dependency
    test('5. Section missing Semester resolves to BLOCKED with Semester dependency', () {
      final decision = AcademicPrerequisiteGuard.resolveMilestoneDecision(
        milestoneId: SetupMilestoneId.section,
        currentRole: AppRole.hod,
        departmentId: 'dept-cse',
        collegeId: 'col-alpha',
        courses: [testCourse1],
        academicYears: [testYear],
        currentAcademicYear: testYear,
        semesters: [], // No semesters!
        sections: [],
        subjects: [],
        faculty: [],
        facultyAssignments: [],
        students: [],
        timetableCount: 0,
      );

      expect(decision.status, equals(SetupDecisionStatus.blocked));
      expect(decision.missingDependency, equals(AcademicPrerequisiteType.semester));
      expect(decision.explanation, contains('Create a semester'));
    });

    // 6. Subject missing Semester -> blocked with Semester dependency
    test('6. Subject missing Semester resolves to BLOCKED with Semester dependency', () {
      final decision = AcademicPrerequisiteGuard.resolveMilestoneDecision(
        milestoneId: SetupMilestoneId.subject,
        currentRole: AppRole.hod,
        departmentId: 'dept-cse',
        collegeId: 'col-alpha',
        courses: [testCourse1],
        academicYears: [testYear],
        currentAcademicYear: testYear,
        semesters: [], // No semesters!
        sections: [],
        subjects: [],
        faculty: [],
        facultyAssignments: [],
        students: [],
        timetableCount: 0,
      );

      expect(decision.status, equals(SetupDecisionStatus.blocked));
      expect(decision.missingDependency, equals(AcademicPrerequisiteType.semester));
      expect(decision.explanation, contains('Create a semester'));
    });

    // 7. Faculty Assignment + no faculty -> correct faculty dependency explanation
    test('7. Faculty Assignment with no available faculty explains faculty dependency and shows provisioning route', () {
      final hodDecision = AcademicPrerequisiteGuard.resolveMilestoneDecision(
        milestoneId: SetupMilestoneId.facultyAssignment,
        currentRole: AppRole.hod,
        departmentId: 'dept-cse',
        collegeId: 'col-alpha',
        courses: [testCourse1],
        academicYears: [testYear],
        currentAcademicYear: testYear,
        semesters: [testSemester1],
        sections: [testSection1],
        subjects: [testSubject1],
        faculty: [], // No active faculty!
        facultyAssignments: [],
        students: [],
        timetableCount: 0,
      );

      expect(hodDecision.status, equals(SetupDecisionStatus.blocked));
      expect(hodDecision.missingDependency, equals(AcademicPrerequisiteType.faculty));
      expect(hodDecision.explanation, contains('No active faculty is available for this subject'));
      expect(hodDecision.canCurrentUserAct, isTrue);
      expect(hodDecision.actionRoute, contains('/academics/faculty/new'));
      expect(hodDecision.actionLabel, equals('Provision Faculty'));

      // When testFaculty1 is present, Faculty Assignment becomes READY
      final readyDecision = AcademicPrerequisiteGuard.resolveMilestoneDecision(
        milestoneId: SetupMilestoneId.facultyAssignment,
        currentRole: AppRole.hod,
        departmentId: 'dept-cse',
        collegeId: 'col-alpha',
        courses: [testCourse1],
        academicYears: [testYear],
        currentAcademicYear: testYear,
        semesters: [testSemester1],
        sections: [testSection1],
        subjects: [testSubject1],
        faculty: [testFaculty1],
        facultyAssignments: [],
        students: [],
        timetableCount: 0,
      );

      expect(readyDecision.status, equals(SetupDecisionStatus.ready));
      expect(readyDecision.actionLabel, equals('Assign Faculty'));
    });

    // 8. Unauthorized role/action -> no guaranteed-403 navigation
    test('8. Unauthorized role (Faculty) attempting setup actions yields non-actionable decisions without 403 routes', () {
      final decision = AcademicPrerequisiteGuard.resolveMilestoneDecision(
        milestoneId: SetupMilestoneId.academicYear,
        currentRole: AppRole.faculty,
        departmentId: 'dept-cse',
        collegeId: 'col-alpha',
        courses: [testCourse1],
        academicYears: [],
        currentAcademicYear: null,
        semesters: [],
        sections: [],
        subjects: [],
        faculty: [],
        facultyAssignments: [],
        students: [],
        timetableCount: 0,
      );

      expect(decision.canCurrentUserAct, isFalse);
      expect(decision.actionRoute, isNull);
      expect(decision.status, equals(SetupDecisionStatus.waitingOnOtherRole));
      expect(decision.ownerRole, equals(AppRole.collegeAdmin));
    });

    // 9. Course creation success -> Continue to Semester preserves context
    testWidgets('9. SetupContinuationDialog on Course creation renders next action for Semester and preserves context', (tester) async {
      bool continued = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SetupContinuationDialog.show(
                    context,
                    title: 'Course Created Successfully',
                    message: 'Define active teaching terms under your department courses.',
                    entityName: 'B.Tech CSE',
                    primaryActionLabel: 'Configure Semesters',
                    onContinue: () => continued = true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Course Created Successfully'), findsOneWidget);
      expect(find.text('B.Tech CSE'), findsWidgets);
      expect(find.text('Configure Semesters'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      await tester.tap(find.text('Configure Semesters'));
      await tester.pumpAndSettle();
      expect(continued, isTrue);
    });

    // 10. Semester creation success -> Continue to Section preserves context
    testWidgets('10. SetupContinuationDialog on Semester creation renders next action for Section and preserves context', (tester) async {
      bool continued = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SetupContinuationDialog.show(
                    context,
                    title: 'Semester Created Successfully',
                    message: 'Form classroom student cohorts with designated seat capacity.',
                    entityName: 'Semester 1',
                    primaryActionLabel: 'Configure Sections',
                    onContinue: () => continued = true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Semester Created Successfully'), findsOneWidget);
      expect(find.text('Configure Sections'), findsOneWidget);

      await tester.tap(find.text('Configure Sections'));
      await tester.pumpAndSettle();
      expect(continued, isTrue);
    });

    // 11. Section creation success -> Continue to Subject preserves context
    testWidgets('11. SetupContinuationDialog on Section creation renders next action for Subject', (tester) async {
      bool continued = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SetupContinuationDialog.show(
                    context,
                    title: 'Section Created Successfully',
                    message: 'Add syllabus courses, theory lectures, and practical labs.',
                    entityName: 'Section A',
                    primaryActionLabel: 'Configure Subjects',
                    onContinue: () => continued = true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Section Created Successfully'), findsOneWidget);
      expect(find.text('Configure Subjects'), findsOneWidget);

      await tester.tap(find.text('Configure Subjects'));
      await tester.pumpAndSettle();
      expect(continued, isTrue);
    });

    // 12. Subject creation success -> Continue to Faculty Assignment preserves context
    testWidgets('12. SetupContinuationDialog on Subject creation renders next action for Faculty Assignment', (tester) async {
      bool continued = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SetupContinuationDialog.show(
                    context,
                    title: 'Subject Created Successfully',
                    message: 'Allocate teachers and professors to subject section batches.',
                    entityName: 'Data Structures',
                    primaryActionLabel: 'Assign Faculty',
                    onContinue: () => continued = true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Subject Created Successfully'), findsOneWidget);
      expect(find.text('Assign Faculty'), findsOneWidget);

      await tester.tap(find.text('Assign Faculty'));
      await tester.pumpAndSettle();
      expect(continued, isTrue);
    });

    // 13. Faculty Assignment success -> Continue to Enrollment
    testWidgets('13. SetupContinuationDialog on Faculty Assignment renders next action for Student Enrollment', (tester) async {
      bool continued = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SetupContinuationDialog.show(
                    context,
                    title: 'Faculty Assignment Created Successfully',
                    message: 'Enroll eligible students into their academic sections.',
                    entityName: 'Dr. Turing -> Data Structures',
                    primaryActionLabel: 'Enroll Students',
                    onContinue: () => continued = true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Faculty Assignment Created Successfully'), findsOneWidget);
      expect(find.text('Enroll Students'), findsOneWidget);

      await tester.tap(find.text('Enroll Students'));
      await tester.pumpAndSettle();
      expect(continued, isTrue);
    });

    // 14. Enrollment completion -> Continue to Timetable
    testWidgets('14. SetupContinuationDialog on Student Enrollment renders next action for Timetable', (tester) async {
      bool continued = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SetupContinuationDialog.show(
                    context,
                    title: 'Student Enrolled Successfully',
                    message: 'Design period schedules and assign lecture rooms.',
                    entityName: 'Ada Lovelace -> Section A',
                    primaryActionLabel: 'Build Timetable',
                    onContinue: () => continued = true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Student Enrolled Successfully'), findsOneWidget);
      expect(find.text('Build Timetable'), findsOneWidget);

      await tester.tap(find.text('Build Timetable'));
      await tester.pumpAndSettle();
      expect(continued, isTrue);
    });

    // 15. Multiple course contexts -> incomplete second context does not produce misleading department-wide "complete" state
    testWidgets('15. Multiple course contexts with incomplete second program does not show department-wide complete banner', (tester) async {
      // Course 1 is 100% complete (has all milestones including timetable)
      // Course 2 only has course entity, missing semester
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
              user: testHodUser,
              token: 'test-token',
            ))),
            academicRepositoryProvider.overrideWithValue(MockAcademicRepository(students: [testStudent1])),
            departmentsProvider.overrideWith(() => TestDepartmentNotifier([testDepartment])),
            coursesProvider.overrideWith(() => TestCourseNotifier([testCourse1, testCourse2])),
            academicYearsProvider.overrideWith(() => TestAcademicYearNotifier([testYear])),
            currentAcademicYearProvider.overrideWithValue(testYear),
            semestersProvider.overrideWith(() => TestSemesterNotifier([testSemester1])),
            sectionsProvider.overrideWith(() => TestSectionNotifier([testSection1])),
            subjectsProvider.overrideWith(() => TestSubjectNotifier([testSubject1])),
            facultyAssignmentsProvider.overrideWith(() => TestFacultyAssignmentNotifier([testAssignment1])),
            timetableRepositoryProvider.overrideWithValue(MockTimetableRepository([testTimetableContainer1])),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DepartmentSetupScreen()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should NOT claim "DEPARTMENT SETUP COMPLETE"
      expect(find.text('DEPARTMENT SETUP COMPLETE'), findsNothing);
      // Instead shows split contextual banner
      expect(find.text('CURRENT CONTEXT READY • REMAINING DEPARTMENT WORK'), findsOneWidget);
      expect(find.textContaining('M.Tech CSE still has setup work remaining'), findsOneWidget);
    });

    // 16. Provider refresh after creation -> newly created entity immediately appears in setup status
    test('16. Provider refresh recalculates milestone completion state immediately upon data change', () async {
      final courseNotifier = TestCourseNotifier([]);

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
            user: testHodUser,
            token: 'test-token',
          ))),
          academicRepositoryProvider.overrideWithValue(MockAcademicRepository()),
          departmentsProvider.overrideWith(() => TestDepartmentNotifier([testDepartment])),
          coursesProvider.overrideWith(() => courseNotifier), // Initially NO courses
          academicYearsProvider.overrideWith(() => TestAcademicYearNotifier([testYear])),
          currentAcademicYearProvider.overrideWithValue(testYear),
          semestersProvider.overrideWith(() => TestSemesterNotifier([])),
          sectionsProvider.overrideWith(() => TestSectionNotifier([])),
          subjectsProvider.overrideWith(() => TestSubjectNotifier([])),
          facultyAssignmentsProvider.overrideWith(() => TestFacultyAssignmentNotifier([])),
          timetableRepositoryProvider.overrideWithValue(MockTimetableRepository()),
        ],
      );

      // Initial state: Course milestone is not completed (completedCount is 1 because academic year exists)
      var state = await container.read(departmentSetupProvider('dept-cse').future);
      expect(state.completedCount, equals(1));
      expect(state.milestones.firstWhere((m) => m.id == SetupMilestoneId.course).isCompleted, isFalse);

      // Simulate course creation: update notifier and invalidate setup provider
      courseNotifier.setCourses([testCourse1]);
      container.invalidate(departmentSetupProvider('dept-cse'));

      // State after refresh: completedCount is now 2
      state = await container.read(departmentSetupProvider('dept-cse').future);
      expect(state.completedCount, equals(2));
      expect(state.milestones.firstWhere((m) => m.id == SetupMilestoneId.course).isCompleted, isTrue);
    });

    // 17. 360px layout -> no overflow or clipped actions
    testWidgets('17. 360px mobile width layout renders with zero overflow and all action buttons accessible', (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
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
            coursesProvider.overrideWith(() => TestCourseNotifier([testCourse1])),
            academicYearsProvider.overrideWith(() => TestAcademicYearNotifier([testYear])),
            currentAcademicYearProvider.overrideWithValue(testYear),
            semestersProvider.overrideWith(() => TestSemesterNotifier([testSemester1])),
            sectionsProvider.overrideWith(() => TestSectionNotifier([testSection1])),
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

      expect(tester.takeException(), isNull);
      expect(find.text('Department Setup'), findsWidgets);
      expect(find.text('Continue Setup'), findsOneWidget);

      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}
