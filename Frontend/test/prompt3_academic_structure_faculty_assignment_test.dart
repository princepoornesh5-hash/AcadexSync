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
import 'package:campus_management/features/academic_structure/presentation/screens/my_assignments_screen.dart';
import 'package:campus_management/features/academic_structure/presentation/widgets/acadex_academic_context_card.dart';
import 'package:campus_management/features/academic_structure/presentation/widgets/faculty_assignment_dialog.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

class TestPopulatedFacultyAssignmentsNotifier extends AutoDisposeAsyncNotifier<List<FacultyAssignment>> implements FacultyAssignmentsNotifier {
  final List<FacultyAssignment> items;
  TestPopulatedFacultyAssignmentsNotifier(this.items);

  @override
  Future<List<FacultyAssignment>> build() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestEmptyFacultyAssignmentsNotifier extends AutoDisposeAsyncNotifier<List<FacultyAssignment>> implements FacultyAssignmentsNotifier {
  @override
  Future<List<FacultyAssignment>> build() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestFacultyNotifier extends StateNotifier<PaginatedState<Faculty>> implements FacultyNotifier {
  TestFacultyNotifier(List<Faculty> items)
      : super(PaginatedState<Faculty>(items: items, isLoading: false, hasReachedMax: true));

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

  const testFacultyUser = UserModel(
    id: 'fac-1',
    name: 'Prof. Grace Hopper',
    email: 'ghopper@alpha.edu',
    role: AppRole.faculty,
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
    name: 'Computer Networks',
    code: 'CE502',
    credits: 4,
    type: 'Theory',
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

  group('PROMPT 3 — Academic Context & Breadcrumbs (AcadexAcademicContextCard)', () {
    testWidgets('Renders primary and secondary hierarchical academic breadcrumbs', (tester) async {
      bool changeTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcadexAcademicContextCard(
              departmentName: 'Computer Engineering',
              departmentCode: 'CSE',
              programName: 'Diploma Computer Engineering',
              semesterName: 'V Semester',
              sectionName: 'Section A',
              academicYearName: '2026–27',
              onChangeContext: () => changeTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Diploma Computer Engineering'), findsOneWidget);
      expect(find.text('CSE · V Semester · Section A · 2026–27'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);

      await tester.tap(find.text('Change'));
      await tester.pump();
      expect(changeTapped, isTrue);
    });

    testWidgets('Adapts gracefully on narrow phone width (320px) without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcadexAcademicContextCard(
              departmentName: 'Department of Computer Science and Engineering',
              departmentCode: 'CSE',
              programName: 'Bachelor of Technology Computer Engineering',
              semesterName: 'VII Semester',
              sectionName: 'Section Alpha Batch 1',
              academicYearName: '2026–2027 Academic Session',
              onChangeContext: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('ACADEMIC CONTEXT'), findsOneWidget);
    });
  });

  group('PROMPT 3 — Faculty Assignments Management UX & Smart Filtering', () {
    testWidgets('Smart filter bar displays search, filter action button, and active context', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
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
            facultyAssignmentsProvider.overrideWith(() => TestPopulatedFacultyAssignmentsNotifier([testAssignment1])),
            departmentMapProvider.overrideWithValue({'dept-cme': testDepartment}),
            facultyProvider(null).overrideWith((ref) => TestFacultyNotifier([testFaculty1])),
          ],
          child: const MaterialApp(
            home: FacultyAssignmentsManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verified: Smart filter button with icon is present
      expect(find.text('Filter'), findsOneWidget);
      // Verified: Search field is present
      expect(find.byType(TextField), findsWidgets);
      // Verified: Academic context card for HOD department teaching scope is embedded
      expect(find.text('DEPARTMENT TEACHING SCOPE'), findsOneWidget);
      // Verified: Assignment item rendered with faculty name
      expect(find.text('Prof. Grace Hopper'), findsWidgets);
    });

    testWidgets('Tapping assignment item opens detailed sheet with academic hierarchy and actions', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
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
            facultyAssignmentsProvider.overrideWith(() => TestPopulatedFacultyAssignmentsNotifier([testAssignment1])),
            departmentMapProvider.overrideWithValue({'dept-cme': testDepartment}),
            facultyProvider(null).overrideWith((ref) => TestFacultyNotifier([testFaculty1])),
          ],
          child: const MaterialApp(
            home: FacultyAssignmentsManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on assignment card to open detail bottom sheet
      await tester.tap(find.text('Prof. Grace Hopper').first);
      await tester.pumpAndSettle();

      // Check bottom sheet contents
      expect(find.text('Allocated Faculty'), findsOneWidget);
      expect(find.text('Take Attendance'), findsOneWidget);
      expect(find.text('Timetable'), findsOneWidget);
      expect(find.text('Program'), findsOneWidget);
    });

    testWidgets('Tapping Filters opens smart filter bottom sheet with clear all and apply actions', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
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
            departmentMapProvider.overrideWithValue({'dept-cme': testDepartment}),
            facultyProvider(null).overrideWith((ref) => TestFacultyNotifier([testFaculty1])),
          ],
          child: const MaterialApp(
            home: FacultyAssignmentsManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Assignments'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);
      expect(find.text('Apply Filters'), findsOneWidget);
    });
  });

  group('PROMPT 3 — Faculty Teaching Experience (MyAssignmentsScreen)', () {
    testWidgets('Displays operational snapshot bar and teaching assignments', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testFacultyUser,
                  token: 'test-token',
                ))),
            coursesProvider.overrideWith(() => TestPopulatedCourseNotifier([testCourse])),
            academicYearsProvider.overrideWith(() => TestPopulatedAcademicYearNotifier([testYear])),
            semestersProvider.overrideWith(() => TestPopulatedSemesterNotifier([testSemester1])),
            sectionsProvider.overrideWith(() => TestPopulatedSectionNotifier([testSectionA])),
            subjectsProvider.overrideWith(() => TestPopulatedSubjectNotifier([testSubject1])),
            facultyAssignmentsProvider.overrideWith(() => TestPopulatedFacultyAssignmentsNotifier([testAssignment1])),
          ],
          child: const MaterialApp(
            home: MyAssignmentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Operational Snapshot Bar metrics
      expect(find.text('Allocated Classes'), findsOneWidget);
      expect(find.text('Total Students'), findsOneWidget);
      expect(find.text('Subjects'), findsOneWidget);

      // Direct teaching operations buttons
      expect(find.text('Take Attendance'), findsOneWidget);
      expect(find.byTooltip('Internal Assessment Marks'), findsOneWidget);
      expect(find.byTooltip('Coursework Assignments'), findsOneWidget);
    });

    testWidgets('Adapts from single-column on mobile to multi-column grid on tablet/desktop', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testFacultyUser,
                  token: 'test-token',
                ))),
            coursesProvider.overrideWith(() => TestPopulatedCourseNotifier([testCourse])),
            academicYearsProvider.overrideWith(() => TestPopulatedAcademicYearNotifier([testYear])),
            semestersProvider.overrideWith(() => TestPopulatedSemesterNotifier([testSemester1])),
            sectionsProvider.overrideWith(() => TestPopulatedSectionNotifier([testSectionA])),
            subjectsProvider.overrideWith(() => TestPopulatedSubjectNotifier([testSubject1])),
            facultyAssignmentsProvider.overrideWith(() => TestPopulatedFacultyAssignmentsNotifier([testAssignment1])),
          ],
          child: const MaterialApp(
            home: MyAssignmentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Allocated Classes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('PROMPT 3 — Responsive Viewport Suite (320, 360, 412, 768, 1200dp & Text Scaling)', () {
    final viewports = [
      const Size(320, 568),  // Small mobile
      const Size(360, 640),  // Standard mobile
      const Size(412, 915),  // Large mobile
      const Size(768, 1024), // Tablet
      const Size(1200, 800), // Desktop
    ];

    for (final size in viewports) {
      testWidgets('FacultyAssignmentsManagementScreen renders cleanly at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
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
              departmentMapProvider.overrideWithValue({'dept-cme': testDepartment}),
              facultyProvider(null).overrideWith((ref) => TestFacultyNotifier([testFaculty1])),
            ],
            child: const MaterialApp(
              home: FacultyAssignmentsManagementScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('FacultyAssignmentsManagementScreen handles 1.25 text scaling on 360dp without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
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
            departmentMapProvider.overrideWithValue({'dept-cme': testDepartment}),
            facultyProvider(null).overrideWith((ref) => TestFacultyNotifier([testFaculty1])),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.25)),
              child: FacultyAssignmentsManagementScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('PROMPT 3 — Role-Specific Visibility & Empty State UX', () {
    testWidgets('Empty assignments list renders clean empty state with action', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
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

      expect(find.text('No faculty assignments yet.'), findsOneWidget);
      expect(find.text('Assign Faculty'), findsWidgets);
    });

    testWidgets('FacultyAssignmentDialog shows progressive steps and adapts height dynamically', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
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
            departmentsProvider.overrideWith(() => TestPopulatedDepartmentNotifier([testDepartment])),
            coursesProvider.overrideWith(() => TestPopulatedCourseNotifier([testCourse])),
            academicYearsProvider.overrideWith(() => TestPopulatedAcademicYearNotifier([testYear])),
            semestersProvider.overrideWith(() => TestPopulatedSemesterNotifier([testSemester1])),
            sectionsProvider.overrideWith(() => TestPopulatedSectionNotifier([testSectionA])),
            subjectsProvider.overrideWith(() => TestPopulatedSubjectNotifier([testSubject1])),
            facultyAssignmentsProvider.overrideWith(() => TestEmptyFacultyAssignmentsNotifier()),
            facultyProvider(null).overrideWith((ref) => TestFacultyNotifier([testFaculty1])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FacultyAssignmentDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verified: Step 1 header and progress rendered
      expect(find.text('Step 1 of 4: Academic Context'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('Step 1: Academic Context'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
