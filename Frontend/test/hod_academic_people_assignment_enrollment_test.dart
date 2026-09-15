import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/core/providers/pagination_provider.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/presentation/screens/faculty_assignments_management_screen.dart';
import 'package:campus_management/features/academic_structure/presentation/screens/section_detail_screen.dart';
import 'package:campus_management/features/academic_structure/presentation/widgets/faculty_assignment_dialog.dart';
import 'package:campus_management/features/academic_structure/presentation/widgets/enroll_student_dialog.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testHodUser = UserModel(
    id: 'user-hod-01',
    name: 'Dr. Alan Turing',
    email: 'hod.cme@alpha.edu',
    role: AppRole.hod,
    collegeId: 'col-alpha',
    departmentId: 'dept-cme',
  );

  final testDepartment = Department(
    id: 'dept-cme',
    collegeId: 'col-alpha',
    hodId: 'user-hod-01',
    name: 'Computer Engineering',
    code: 'CME',
    description: 'Computer Engineering Department',
    isActive: true,
  );

  final testCourse = Course(
    id: 'course-cme-01',
    collegeId: 'col-alpha',
    departmentId: 'dept-cme',
    name: 'Diploma in Computer Engineering',
    code: 'DCME',
    duration: 3,
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
    departmentId: 'dept-cme',
    courseId: 'course-cme-01',
    academicYearId: 'ay-2026',
    name: 'Semester 1',
    number: 1,
    status: 'active',
    isCurrent: true,
    isActive: true,
  );

  final testSectionA = Section(
    id: 'sec-1',
    collegeId: 'col-alpha',
    departmentId: 'dept-cme',
    courseId: 'course-cme-01',
    academicYearId: 'ay-2026',
    semesterId: 'sem-1',
    name: 'A',
    capacity: 60,
    status: 'active',
    isActive: true,
  );

  final testSubject1 = Subject(
    id: 'sub-1',
    collegeId: 'col-alpha',
    departmentId: 'dept-cme',
    courseId: 'course-cme-01',
    semesterId: 'sem-1',
    name: 'Database Management Systems',
    code: 'CE501',
    credits: 4,
    type: 'Theory',
    isActive: true,
  );

  final testSubject2 = Subject(
    id: 'sub-2',
    collegeId: 'col-alpha',
    departmentId: 'dept-cme',
    courseId: 'course-cme-01',
    semesterId: 'sem-1',
    name: 'Data Structures Lab',
    code: 'CE502',
    credits: 2,
    type: 'Practical',
    isActive: true,
  );

  final testFaculty1 = Faculty(
    id: 'fac-1',
    collegeId: 'col-alpha',
    departmentId: 'dept-cme',
    employeeId: 'EMP-CME-01',
    name: 'Prof. Grace Hopper',
    email: 'ghopper@alpha.edu',
    phone: '555-0101',
    designation: 'Associate Professor',
    qualification: 'Ph.D. Computer Science',
    isActive: true,
  );

  final testAssignment1 = FacultyAssignment(
    id: 'asgn-1',
    collegeId: 'col-alpha',
    facultyId: 'fac-1',
    facultyName: 'Prof. Grace Hopper',
    departmentId: 'dept-cme',
    courseId: 'course-cme-01',
    academicYearId: 'ay-2026',
    semesterId: 'sem-1',
    sectionId: 'sec-1',
    subjectId: 'sub-1',
    assignmentType: 'Theory',
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testStudent1 = Student(
    id: 'stu-1',
    collegeId: 'col-alpha',
    departmentId: 'dept-cme',
    courseId: 'course-cme-01',
    academicYearId: 'ay-2026',
    semesterId: 'sem-1',
    sectionId: 'sec-1',
    name: 'Alice Johnson',
    rollNumber: 'CME2026001',
    email: 'alice.johnson@alpha.edu',
    phone: '555-0201',
    isActive: true,
  );

  final testEnrollment1 = StudentEnrollment(
    id: 'enr-1',
    collegeId: 'col-alpha',
    departmentId: 'dept-cme',
    courseId: 'course-cme-01',
    academicYearId: 'ay-2026',
    semesterId: 'sem-1',
    sectionId: 'sec-1',
    studentId: 'stu-1',
    status: 'active',
    enrollmentDate: DateTime(2026, 6, 15),
    student: {
      'id': 'stu-1',
      'name': 'Alice Johnson',
      'rollNumber': 'CME2026001',
      'email': 'alice.johnson@alpha.edu',
    },
  );

  group('ACADEX — Faculty Assignment & Student Enrollment Tests (Prompt 3 of 6)', () {
    testWidgets('1. FacultyAssignmentsManagementScreen renders unassigned subjects banner and assign action', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testHodUser,
                  token: 'test-token',
                ))),
            coursesProvider.overrideWith(() => TestPopulatedCourseNotifier([testCourse])),
            academicYearsProvider.overrideWith(() => TestPopulatedAcademicYearNotifier([testYear])),
            semestersProvider.overrideWith(() => TestPopulatedSemesterNotifier([testSemester1])),
            sectionsProvider.overrideWith(() => TestPopulatedSectionNotifier([testSectionA])),
            subjectsProvider.overrideWith(() => TestPopulatedSubjectNotifier([testSubject1, testSubject2])),
            facultyAssignmentsProvider.overrideWith(() => TestEmptyFacultyAssignmentsNotifier()),
            departmentMapProvider.overrideWithValue({'dept-cme': testDepartment}),
            facultyProvider(null).overrideWith((ref) => TestFacultyNotifier([testFaculty1])),
          ],
          child: const MaterialApp(
            home: FacultyAssignmentsManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Faculty Assignments'), findsWidgets);
      expect(find.text('Assign Faculty'), findsWidgets);
      // Unassigned subjects banner should detect unassigned subjects
      expect(find.textContaining('Unassigned Subjects'), findsWidgets);
    });

    testWidgets('2. FacultyAssignmentsManagementScreen displays existing assignments in table', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testHodUser,
                  token: 'test-token',
                ))),
            coursesProvider.overrideWith(() => TestPopulatedCourseNotifier([testCourse])),
            academicYearsProvider.overrideWith(() => TestPopulatedAcademicYearNotifier([testYear])),
            semestersProvider.overrideWith(() => TestPopulatedSemesterNotifier([testSemester1])),
            sectionsProvider.overrideWith(() => TestPopulatedSectionNotifier([testSectionA])),
            subjectsProvider.overrideWith(() => TestPopulatedSubjectNotifier([testSubject1])),
            facultyAssignmentsProvider.overrideWith(() => TestPopulatedFacultyAssignmentsNotifier([testAssignment1])),
            facultyProvider(null).overrideWith((ref) => TestFacultyNotifier([testFaculty1])),
            departmentMapProvider.overrideWithValue({'dept-cme': testDepartment}),
            courseMapProvider.overrideWithValue({'course-cme-01': testCourse}),
            semesterMapProvider.overrideWithValue({'sem-1': testSemester1}),
            sectionMapProvider.overrideWithValue({'sec-1': testSectionA}),
            subjectMapProvider.overrideWithValue({'sub-1': testSubject1}),
            academicYearMapProvider.overrideWithValue({'ay-2026': testYear}),
          ],
          child: const MaterialApp(
            home: FacultyAssignmentsManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Prof. Grace Hopper'), findsWidgets);
      expect(find.text('Database Management Systems'), findsWidgets);
      expect(find.text('Active'), findsWidgets);
    });

    testWidgets('3. FacultyAssignmentDialog displays compact summary card before submission', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testHodUser,
                  token: 'test-token',
                ))),
            coursesProvider.overrideWith(() => TestPopulatedCourseNotifier([testCourse])),
            academicYearsProvider.overrideWith(() => TestPopulatedAcademicYearNotifier([testYear])),
            semestersProvider.overrideWith(() => TestPopulatedSemesterNotifier([testSemester1])),
            sectionsProvider.overrideWith(() => TestPopulatedSectionNotifier([testSectionA])),
            subjectsProvider.overrideWith(() => TestPopulatedSubjectNotifier([testSubject1])),
            facultyProvider(null).overrideWith((ref) => TestFacultyNotifier([testFaculty1])),
            departmentMapProvider.overrideWithValue({'dept-cme': testDepartment}),
            departmentsProvider.overrideWith(() => TestPopulatedDepartmentNotifier([testDepartment])),
            facultyAssignmentsProvider.overrideWith(() => TestEmptyFacultyAssignmentsNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FacultyAssignmentDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Faculty Subject & Class Assignment'), findsOneWidget);
      expect(find.text('ASSIGNMENT PREVIEW'), findsOneWidget);
      expect(find.text('Course: '), findsOneWidget);
      expect(find.text('Subject: '), findsOneWidget);
    });

    testWidgets('4. SectionDetailScreen displays live student count badge and student roster', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testHodUser,
                  token: 'test-token',
                ))),
            sectionByIdProvider('sec-1').overrideWith((ref) => Future.value(testSectionA)),
            coursesProvider.overrideWith(() => TestPopulatedCourseNotifier([testCourse])),
            semestersProvider.overrideWith(() => TestPopulatedSemesterNotifier([testSemester1])),
            academicYearsProvider.overrideWith(() => TestPopulatedAcademicYearNotifier([testYear])),
            departmentsProvider.overrideWith(() => TestPopulatedDepartmentNotifier([testDepartment])),
            sectionEnrollmentsNotifierProvider.overrideWith(() => TestPopulatedEnrollmentsNotifier([testEnrollment1])),
            sectionActiveEnrollmentCountProvider('sec-1').overrideWithValue(1),
          ],
          child: const MaterialApp(
            home: SectionDetailScreen(sectionId: 'sec-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Section Hero card displays live student count
      expect(find.text('Section A'), findsWidgets);
      expect(find.text('Students: 1'), findsOneWidget);
      expect(find.text('60 Seats'), findsOneWidget);

      // Verify Section Student Roster
      expect(find.textContaining('Student Roster'), findsOneWidget);
      expect(find.text('Enroll Student'), findsWidgets);
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.textContaining('CME2026001'), findsOneWidget);
    });

    testWidgets('5. EnrollStudentDialog displays department students search and select', (tester) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testHodUser,
                  token: 'test-token',
                ))),
            studentsProvider((sectionId: null, departmentId: 'dept-cme'))
                .overrideWith((ref) => TestStudentNotifier([testStudent1])),
            sectionEnrollmentsNotifierProvider.overrideWith(() => TestEmptyEnrollmentsNotifier()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: EnrollStudentDialog(
                section: testSectionA,
                course: testCourse,
                semester: testSemester1,
                academicYear: testYear,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Enroll Student in Section'), findsOneWidget);
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.textContaining('CME2026001'), findsOneWidget);
      expect(find.text('Enroll in Section'), findsOneWidget);
    });

    testWidgets('6. FacultyAssignmentsManagementScreen displays error state with retry action', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testHodUser,
                  token: 'test-token',
                ))),
            facultyAssignmentsProvider.overrideWith(() => TestErrorFacultyAssignmentsNotifier()),
          ],
          child: const MaterialApp(
            home: FacultyAssignmentsManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load faculty assignments'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('7. SectionDetailScreen displays error state with retry action when section fetch fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testHodUser,
                  token: 'test-token',
                ))),
            sectionByIdProvider('sec-invalid').overrideWith((ref) => Future.error('Section not found')),
          ],
          child: const MaterialApp(
            home: SectionDetailScreen(sectionId: 'sec-invalid'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Error loading section'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('8. Responsive layout verification for FacultyAssignmentsManagementScreen (360dp, 390dp, 412dp)', (tester) async {
      final viewports = [
        const Size(360, 640),
        const Size(390, 844),
        const Size(412, 915),
      ];
      final textScales = [1.0, 1.15, 1.25];

      for (final size in viewports) {
        for (final scale in textScales) {
          tester.view.physicalSize = Size(size.width * 2.0, size.height * 2.0);
          tester.view.devicePixelRatio = 2.0;

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                      user: testHodUser,
                      token: 'test-token',
                    ))),
                coursesProvider.overrideWith(() => TestPopulatedCourseNotifier([testCourse])),
                academicYearsProvider.overrideWith(() => TestPopulatedAcademicYearNotifier([testYear])),
                semestersProvider.overrideWith(() => TestPopulatedSemesterNotifier([testSemester1])),
                sectionsProvider.overrideWith(() => TestPopulatedSectionNotifier([testSectionA])),
                subjectsProvider.overrideWith(() => TestPopulatedSubjectNotifier([testSubject1])),
                facultyAssignmentsProvider.overrideWith(() => TestPopulatedFacultyAssignmentsNotifier([testAssignment1])),
                facultyProvider(null).overrideWith((ref) => TestFacultyNotifier([testFaculty1])),
                departmentMapProvider.overrideWithValue({'dept-cme': testDepartment}),
                courseMapProvider.overrideWithValue({'course-cme-01': testCourse}),
                semesterMapProvider.overrideWithValue({'sem-1': testSemester1}),
                sectionMapProvider.overrideWithValue({'sec-1': testSectionA}),
                subjectMapProvider.overrideWithValue({'sub-1': testSubject1}),
                academicYearMapProvider.overrideWithValue({'ay-2026': testYear}),
              ],
              child: MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: const FacultyAssignmentsManagementScreen(),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Faculty Assignments'), findsWidgets);
        }
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('9. Responsive layout verification for SectionDetailScreen (360dp, 390dp, 412dp)', (tester) async {
      final viewports = [
        const Size(360, 640),
        const Size(390, 844),
        const Size(412, 915),
      ];
      final textScales = [1.0, 1.15, 1.25];

      for (final size in viewports) {
        for (final scale in textScales) {
          tester.view.physicalSize = Size(size.width * 2.0, size.height * 2.0);
          tester.view.devicePixelRatio = 2.0;

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                      user: testHodUser,
                      token: 'test-token',
                    ))),
                sectionByIdProvider('sec-1').overrideWith((ref) => Future.value(testSectionA)),
                coursesProvider.overrideWith(() => TestPopulatedCourseNotifier([testCourse])),
                semestersProvider.overrideWith(() => TestPopulatedSemesterNotifier([testSemester1])),
                academicYearsProvider.overrideWith(() => TestPopulatedAcademicYearNotifier([testYear])),
                departmentsProvider.overrideWith(() => TestPopulatedDepartmentNotifier([testDepartment])),
                sectionEnrollmentsNotifierProvider.overrideWith(() => TestPopulatedEnrollmentsNotifier([testEnrollment1])),
                sectionActiveEnrollmentCountProvider('sec-1').overrideWithValue(1),
              ],
              child: MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: const SectionDetailScreen(sectionId: 'sec-1'),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Section A'), findsWidgets);
          expect(find.textContaining('Student Roster'), findsOneWidget);
        }
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}

// ── Test Notifier Classes ──────────────────────────────────────────────────

class TestPopulatedCourseNotifier extends AutoDisposeAsyncNotifier<List<Course>> implements CourseNotifier {
  final List<Course> items;
  TestPopulatedCourseNotifier(this.items);

  @override
  Future<List<Course>> build() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestPopulatedAcademicYearNotifier extends AutoDisposeAsyncNotifier<List<AcademicYear>> implements AcademicYearNotifier {
  final List<AcademicYear> items;
  TestPopulatedAcademicYearNotifier(this.items);

  @override
  Future<List<AcademicYear>> build() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestPopulatedSemesterNotifier extends AutoDisposeAsyncNotifier<List<Semester>> implements SemesterNotifier {
  final List<Semester> items;
  TestPopulatedSemesterNotifier(this.items);

  @override
  Future<List<Semester>> build() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestPopulatedSectionNotifier extends AutoDisposeAsyncNotifier<List<Section>> implements SectionNotifier {
  final List<Section> items;
  TestPopulatedSectionNotifier(this.items);

  @override
  Future<List<Section>> build() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestPopulatedDepartmentNotifier extends AutoDisposeAsyncNotifier<List<Department>> implements DepartmentNotifier {
  final List<Department> items;
  TestPopulatedDepartmentNotifier(this.items);

  @override
  Future<List<Department>> build() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestPopulatedSubjectNotifier extends AutoDisposeAsyncNotifier<List<Subject>> implements SubjectNotifier {
  final List<Subject> items;
  TestPopulatedSubjectNotifier(this.items);

  @override
  Future<List<Subject>> build() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestEmptyFacultyAssignmentsNotifier extends AutoDisposeAsyncNotifier<List<FacultyAssignment>> implements FacultyAssignmentsNotifier {
  @override
  Future<List<FacultyAssignment>> build() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestPopulatedFacultyAssignmentsNotifier extends AutoDisposeAsyncNotifier<List<FacultyAssignment>> implements FacultyAssignmentsNotifier {
  final List<FacultyAssignment> items;
  TestPopulatedFacultyAssignmentsNotifier(this.items);

  @override
  Future<List<FacultyAssignment>> build() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestErrorFacultyAssignmentsNotifier extends AutoDisposeAsyncNotifier<List<FacultyAssignment>> implements FacultyAssignmentsNotifier {
  @override
  Future<List<FacultyAssignment>> build() async => throw Exception('Failed to load faculty assignments');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestEmptyEnrollmentsNotifier extends StudentEnrollmentsNotifier {
  @override
  Future<List<StudentEnrollment>> build(String arg) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestPopulatedEnrollmentsNotifier extends StudentEnrollmentsNotifier {
  final List<StudentEnrollment> items;
  TestPopulatedEnrollmentsNotifier(this.items);

  @override
  Future<List<StudentEnrollment>> build(String arg) async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestFacultyNotifier extends StateNotifier<PaginatedState<Faculty>> implements FacultyNotifier {
  TestFacultyNotifier(List<Faculty> items)
      : super(PaginatedState<Faculty>(items: items, isLoading: false, hasReachedMax: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestStudentNotifier extends StateNotifier<PaginatedState<Student>> implements StudentNotifier {
  TestStudentNotifier(List<Student> items)
      : super(PaginatedState<Student>(items: items, isLoading: false, hasReachedMax: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
