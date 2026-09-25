import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/presentation/screens/course_screens.dart';
import 'package:campus_management/features/academic_structure/presentation/screens/course_detail_screen.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestableMockAcademicRepository extends MockAcademicRepository {
  final List<Course> customCourses;
  final List<Department> customDepartments;
  final List<Semester> customSemesters;
  final List<Section> customSections;
  final List<Subject> customSubjects;
  final bool shouldThrowDuplicateCode;

  TestableMockAcademicRepository({
    super.currentUser,
    List<Course>? courses,
    List<Department>? departments,
    List<Semester>? semesters,
    List<Section>? sections,
    List<Subject>? subjects,
    this.shouldThrowDuplicateCode = false,
  })  : customCourses = courses ??
            [
              Course(
                id: 'cr1',
                collegeId: 'c1',
                departmentId: 'd1',
                name: 'B.Tech',
                code: 'BTECH-CS',
                duration: 4,
                isActive: true,
              ),
              Course(
                id: 'cr2',
                collegeId: 'c1',
                departmentId: 'd1',
                name: 'M.Tech',
                code: 'MTECH-CS',
                duration: 2,
                isActive: true,
              ),
              Course(
                id: 'cr3',
                collegeId: 'c1',
                departmentId: 'd2',
                name: 'B.Tech ME',
                code: 'BTECH-ME',
                duration: 4,
                isActive: false,
              ),
            ],
        customDepartments = departments ??
            [
              Department(
                id: 'd1',
                collegeId: 'c1',
                name: 'Computer Engineering',
                code: 'CS',
                hodId: 'hod1',
                description: 'Dept of Computer Engineering',
                isActive: true,
              ),
              Department(
                id: 'd2',
                collegeId: 'c1',
                name: 'Mechanical Engineering',
                code: 'ME',
                hodId: 'hod2',
                description: 'Dept of Mechanical Engineering',
                isActive: true,
              ),
            ],
        customSemesters = semesters ??
            [
              Semester(
                id: 'sem1',
                collegeId: 'c1',
                departmentId: 'd1',
                courseId: 'cr1',
                academicYearId: 'ay1',
                name: 'Semester 1',
                number: 1,
                status: 'completed',
                isActive: true,
                startDate: DateTime(2025, 8, 1),
                endDate: DateTime(2025, 12, 31),
              ),
              Semester(
                id: 'sem2',
                collegeId: 'c1',
                departmentId: 'd1',
                courseId: 'cr1',
                academicYearId: 'ay1',
                name: 'Semester 2',
                number: 2,
                status: 'active',
                isActive: true,
                startDate: DateTime(2026, 1, 1),
                endDate: DateTime(2026, 6, 30),
              ),
            ],
        customSections = sections ??
            [
              Section(
                id: 'sec1',
                collegeId: 'c1',
                departmentId: 'd1',
                courseId: 'cr1',
                academicYearId: 'ay1',
                semesterId: 'sem1',
                name: 'Section A',
                capacity: 60,
                status: 'active',
                isActive: true,
              ),
              Section(
                id: 'sec2',
                collegeId: 'c1',
                departmentId: 'd1',
                courseId: 'cr1',
                academicYearId: 'ay1',
                semesterId: 'sem1',
                name: 'Section B',
                capacity: 60,
                status: 'active',
                isActive: true,
              ),
            ],
        customSubjects = subjects ??
            [
              Subject(
                id: 'sub1',
                collegeId: 'c1',
                departmentId: 'd1',
                courseId: 'cr1',
                semesterId: 'sem1',
                name: 'Data Structures',
                code: 'CS101',
                credits: 4,
                type: 'Theory',
                isActive: true,
              ),
              Subject(
                id: 'sub2',
                collegeId: 'c1',
                departmentId: 'd1',
                courseId: 'cr1',
                semesterId: 'sem1',
                name: 'Programming Lab',
                code: 'CS101L',
                credits: 2,
                type: 'Lab',
                isActive: true,
              ),
            ];

  @override
  Future<List<Course>> getCourses({String? collegeId, String? departmentId, String? search}) async {
    var list = List<Course>.from(customCourses);
    if (departmentId != null && departmentId.isNotEmpty) {
      list = list.where((c) => c.departmentId == departmentId).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((c) => c.name.toLowerCase().contains(q) || c.code.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Future<Course> getCourseById(String id) async {
    return customCourses.firstWhere((c) => c.id == id, orElse: () => throw Exception('Course not found'));
  }

  @override
  Future<void> addCourse(Course course) async {
    if (shouldThrowDuplicateCode || customCourses.any((c) => c.code == course.code && c.collegeId == course.collegeId)) {
      throw Exception('A course with code ${course.code} already exists in this college.');
    }
    final newCourse = course.id.isEmpty
        ? Course(
            id: 'cr_${DateTime.now().millisecondsSinceEpoch}',
            collegeId: course.collegeId,
            departmentId: course.departmentId,
            name: course.name,
            code: course.code,
            duration: course.duration,
            isActive: course.isActive,
          )
        : course;
    customCourses.add(newCourse);
  }

  @override
  Future<void> updateCourse(Course course) async {
    final idx = customCourses.indexWhere((c) => c.id == course.id);
    if (idx != -1) {
      customCourses[idx] = course;
    }
  }

  @override
  Future<void> updateCourseStatus(String id, bool isActive) async {
    final idx = customCourses.indexWhere((c) => c.id == id);
    if (idx != -1) {
      customCourses[idx] = customCourses[idx].copyWith(isActive: isActive);
    }
  }

  @override
  Future<List<Department>> getDepartments({String? collegeId, String? search, String? status}) async {
    return List.from(customDepartments);
  }

  @override
  Future<List<Semester>> getSemesters({String? courseId, String? academicYearId, String? collegeId}) async {
    return List.from(customSemesters.where((s) => courseId == null || s.courseId == courseId));
  }

  @override
  Future<List<Section>> getSections({String? semesterId, String? courseId, String? collegeId}) async {
    return List.from(customSections.where((sec) => courseId == null || sec.courseId == courseId));
  }

  @override
  Future<List<Subject>> getSubjects({String? semesterId, String? courseId, String? collegeId}) async {
    return List.from(customSubjects.where((sub) => courseId == null || sub.courseId == courseId));
  }
}

void main() {
  const testCollegeAdmin = UserModel(
    id: 'user-admin-01',
    name: 'Admin Alpha',
    email: 'admin@alpha.edu',
    role: AppRole.collegeAdmin,
    collegeId: 'c1',
  );

  const testHod = UserModel(
    id: 'user-hod-01',
    name: 'Dr. Turing',
    email: 'turing@alpha.edu',
    role: AppRole.hod,
    collegeId: 'c1',
    departmentId: 'd1',
  );

  const testFaculty = UserModel(
    id: 'user-fac-01',
    name: 'Prof. Gauss',
    email: 'gauss@alpha.edu',
    role: AppRole.faculty,
    collegeId: 'c1',
    departmentId: 'd1',
  );

  const testStudent = UserModel(
    id: 'user-stud-01',
    name: 'Ada Lovelace',
    email: 'ada@alpha.edu',
    role: AppRole.student,
    collegeId: 'c1',
    departmentId: 'd1',
  );

  group('ACADEX Course Management Module Frontend Tests (Prompt 11)', () {
    testWidgets('1. Course list loads from repository and displays courses', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = TestableMockAcademicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testCollegeAdmin,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CourseListScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Courses (Degree Programs)'), findsOneWidget);
      expect(find.text('B.Tech'), findsWidgets);
      expect(find.text('M.Tech'), findsWidgets);
      expect(find.text('BTECH-CS'), findsWidgets);
      expect(find.text('MTECH-CS'), findsWidgets);
    });

    testWidgets('2. Create Course form validation (empty name/code, short/invalid characters)', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = TestableMockAcademicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testCollegeAdmin,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: CourseFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Create Course'), findsOneWidget);

      // Tap Save without entering any fields
      final saveBtn = find.text('Save Changes');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Form validation errors triggered
      expect(find.text('Course Name is required'), findsOneWidget);
      expect(find.text('Course Code is required'), findsOneWidget);

      // Enter short name (< 2 chars)
      final nameField = find.widgetWithText(TextFormField, 'e.g. Bachelor of Technology in CS');
      await tester.enterText(nameField, 'A');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      expect(find.text('Must be at least 2 characters'), findsOneWidget);

      // Enter invalid code (e.g. special character not allowed)
      final codeField = find.widgetWithText(TextFormField, 'e.g. BTECH-CSE');
      await tester.enterText(codeField, 'INVALID@CODE!');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      expect(find.text('Only alphanumeric characters, hyphens, and underscores'), findsOneWidget);
    });

    testWidgets('3. Create Course success calls repository and creates course', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = TestableMockAcademicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testCollegeAdmin,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: CourseFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter valid fields
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Bachelor of Technology in CS'), 'Master of Science');
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. BTECH-CSE'), 'MSC-CS');

      // Select Department
      final deptDropdown = find.text('Select Department');
      expect(deptDropdown, findsOneWidget);
      await tester.tap(deptDropdown);
      await tester.pumpAndSettle();

      // Tap Computer Engineering
      final deptOption = find.text('Computer Engineering (CS)').last;
      await tester.tap(deptOption);
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Verify repo received new course
      expect(repo.customCourses.any((c) => c.code == 'MSC-CS' && c.name == 'Master of Science'), isTrue);
    });

    testWidgets('4. Create Course 409 conflict handling displays backend error', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Repo configured to throw conflict on code collision
      final repo = TestableMockAcademicRepository(shouldThrowDuplicateCode: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testCollegeAdmin,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: CourseFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Bachelor of Technology in CS'), 'B.Tech Duplicate');
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. BTECH-CSE'), 'BTECH-CS');

      final deptDropdown = find.text('Select Department');
      await tester.tap(deptDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Computer Engineering (CS)').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Verify error snackbar is displayed
      expect(find.textContaining('already exists in this college'), findsOneWidget);
    });

    testWidgets('5. Edit Course populates existing values and updates', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = TestableMockAcademicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testCollegeAdmin,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: CourseFormScreen(id: 'cr1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Course'), findsOneWidget);
      expect(find.text('B.Tech'), findsOneWidget);
      expect(find.text('BTECH-CS'), findsOneWidget);

      // Edit name
      final nameField = find.widgetWithText(TextFormField, 'B.Tech');
      await tester.enterText(nameField, 'B.Tech Honours');

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(repo.customCourses.firstWhere((c) => c.id == 'cr1').name, 'B.Tech Honours');
    });

    testWidgets('6. Course status toggle (deactivate / activate) dialog flow', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = TestableMockAcademicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testCollegeAdmin,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CourseDetailScreen(courseId: 'cr1'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Deactivate button
      final deactivateBtn = find.text('Deactivate');
      expect(deactivateBtn, findsOneWidget);
      await tester.tap(deactivateBtn);
      await tester.pumpAndSettle();

      // Check confirmation dialog
      expect(find.text('Deactivate Course?'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to deactivate B.Tech?'), findsOneWidget);

      // Tap confirm in dialog
      final confirmBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Deactivate'),
      );
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Status should now be updated in repo
      expect(repo.customCourses.firstWhere((c) => c.id == 'cr1').isActive, isFalse);
    });

    testWidgets('7. HOD department locked and derived from user identity in form', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = TestableMockAcademicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testHod,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: CourseFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Department dropdown should NOT be present for HOD
      expect(find.text('Select Department'), findsNothing);

      // Locked department display card/badge should be visible with 'YOUR DEPARTMENT' and department name
      expect(find.text('YOUR DEPARTMENT'), findsOneWidget);
      expect(find.text('Computer Engineering'), findsWidgets);
    });

    testWidgets('8. College Admin department selector dropdown is interactive', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = TestableMockAcademicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testCollegeAdmin,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: CourseFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // College Admin sees department selector dropdown
      expect(find.text('Select Department'), findsOneWidget);

      await tester.tap(find.text('Select Department'));
      await tester.pumpAndSettle();

      expect(find.text('Computer Engineering (CS)'), findsWidgets);
      expect(find.text('Mechanical Engineering (ME)'), findsWidgets);
    });

    testWidgets('9. Faculty / Student read-only view (no Add Course or Edit actions)', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = TestableMockAcademicRepository();

      // Render as Student
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testStudent,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CourseListScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Add Course button should NOT be rendered for Student
      expect(find.text('Add Course'), findsNothing);
      expect(find.byTooltip('Edit Course'), findsNothing);

      // Render as Faculty
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testFaculty,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CourseListScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Add Course button should NOT be rendered for Faculty
      expect(find.text('Add Course'), findsNothing);
      expect(find.byTooltip('Edit Course'), findsNothing);
    });

    testWidgets('10. Course Details screen displays hero, details, semesters, sections, and subjects', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = TestableMockAcademicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testCollegeAdmin,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CourseDetailScreen(courseId: 'cr1'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Hero info
      expect(find.text('B.Tech'), findsWidgets);
      expect(find.text('CODE: BTECH-CS'), findsOneWidget);
      expect(find.text('4 Years'), findsOneWidget);

      // Tab navigation
      expect(find.text('Semesters'), findsWidgets);
      expect(find.text('Sections'), findsWidgets);
      expect(find.text('Subjects'), findsWidgets);

      // Semesters tab active by default
      expect(find.text('Semester 1'), findsWidgets);
      expect(find.text('Semester 2'), findsWidgets);

      // Switch to Sections tab
      await tester.tap(find.text('Sections'));
      await tester.pumpAndSettle();
      expect(find.text('Section A'), findsWidgets);
      expect(find.text('Section B'), findsWidgets);

      // Switch to Subjects tab
      await tester.tap(find.text('Subjects'));
      await tester.pumpAndSettle();
      expect(find.text('Data Structures'), findsWidgets);
      expect(find.text('Programming Lab'), findsWidgets);
    });

    testWidgets('11. Empty state when no courses match search query', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = TestableMockAcademicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testCollegeAdmin,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CourseListScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Search for non-existent course
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'NonExistentDegreeProgramme');
      await tester.pumpAndSettle();

      expect(find.text('No Courses Found'), findsOneWidget);
    });

    testWidgets('12. Mobile layout responsiveness at 360px without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = TestableMockAcademicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testCollegeAdmin,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CourseListScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Must render cards on mobile without any overflow errors
      expect(find.text('B.Tech'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('13. Course status toggle: activate flow when course is inactive', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // cr3 is inactive in mock repo
      final repo = TestableMockAcademicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testCollegeAdmin,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CourseDetailScreen(courseId: 'cr3'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final activateBtn = find.text('Activate');
      expect(activateBtn, findsOneWidget);
      await tester.tap(activateBtn);
      await tester.pumpAndSettle();

      expect(find.text('Activate Course?'), findsOneWidget);
      final confirmBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Activate'),
      );
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(repo.customCourses.firstWhere((c) => c.id == 'cr3').isActive, isTrue);
    });

    testWidgets('14. Downstream Add Semester action is accessible with prefilled courseId', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = TestableMockAcademicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testCollegeAdmin,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CourseDetailScreen(courseId: 'cr1'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // On Semesters tab, Add Semester button should be present
      expect(find.text('Add Semester'), findsOneWidget);
    });

    testWidgets('15. Downstream Add Section action is accessible with prefilled courseId', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = TestableMockAcademicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testCollegeAdmin,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CourseDetailScreen(courseId: 'cr1'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Sections tab
      await tester.tap(find.text('Sections'));
      await tester.pumpAndSettle();

      expect(find.text('Add Section'), findsOneWidget);
    });

    testWidgets('16. Downstream Add Subject action is accessible with prefilled courseId', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = TestableMockAcademicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testCollegeAdmin,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CourseDetailScreen(courseId: 'cr1'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Subjects tab
      await tester.tap(find.text('Subjects'));
      await tester.pumpAndSettle();

      expect(find.text('Add Subject'), findsOneWidget);
    });
  });
}
