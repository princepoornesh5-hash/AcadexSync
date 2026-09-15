import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/presentation/screens/section_screens.dart';
import 'package:campus_management/features/academic_structure/presentation/screens/subject_screens.dart';
import 'package:campus_management/features/academic_structure/presentation/widgets/fresh_department_setup_card.dart';

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

  final testCourse = Course(
    id: 'course-cme-01',
    collegeId: 'col-alpha',
    departmentId: 'dept-cme',
    name: 'Diploma in Computer Engineering',
    code: 'DCME',
    duration: 3,
    isActive: true,
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

  final testSemester2 = Semester(
    id: 'sem-2',
    collegeId: 'col-alpha',
    departmentId: 'dept-cme',
    courseId: 'course-cme-01',
    academicYearId: 'ay-2026',
    name: 'Semester 2',
    number: 2,
    status: 'active',
    isCurrent: false,
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

  final testSectionB = Section(
    id: 'sec-2',
    collegeId: 'col-alpha',
    departmentId: 'dept-cme',
    courseId: 'course-cme-01',
    academicYearId: 'ay-2026',
    semesterId: 'sem-2',
    name: 'B',
    capacity: 45,
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
    semesterId: 'sem-2',
    name: 'Operating Systems',
    code: 'CE502',
    credits: 4,
    type: 'Theory',
    isActive: true,
  );

  group('ACADEX — HOD Academic Structure: Sections & Subjects Tests (Prompt 2 of 6)', () {
    testWidgets('1. SectionListScreen renders FreshDepartmentSetupCard when no sections exist', (tester) async {
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
            sectionsProvider.overrideWith(() => TestEmptySectionNotifier()),
          ],
          child: const MaterialApp(
            home: SectionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FreshDepartmentSetupCard), findsOneWidget);
      expect(find.text('Academic Foundation Setup'), findsOneWidget);
      expect(find.text('Add First Section'), findsOneWidget);
      expect(find.text('Sections & Batches'), findsWidgets);
    });

    testWidgets('2. SectionListScreen renders contextual filters and Section cards when sections exist', (tester) async {
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
          ],
          child: const MaterialApp(
            home: SectionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('All Courses'), findsOneWidget);
      expect(find.text('All Academic Years'), findsOneWidget);
      expect(find.text('All Semesters'), findsOneWidget);
      expect(find.text('Section A'), findsOneWidget);
      expect(find.textContaining('60'), findsWidgets);
      expect(find.text('Active'), findsWidgets);
    });

    testWidgets('3. SubjectListScreen renders FreshDepartmentSetupCard when no subjects exist', (tester) async {
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
            subjectsProvider.overrideWith(() => TestEmptySubjectNotifier()),
          ],
          child: const MaterialApp(
            home: SubjectListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FreshDepartmentSetupCard), findsOneWidget);
      expect(find.text('Academic Foundation Setup'), findsOneWidget);
      expect(find.text('Add First Subject'), findsOneWidget);
      expect(find.text('Curriculum Subjects'), findsWidgets);
    });

    testWidgets('4. SubjectListScreen renders contextual filters and Subject cards when subjects exist', (tester) async {
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
          ],
          child: const MaterialApp(
            home: SubjectListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('All Courses'), findsOneWidget);
      expect(find.text('All Academic Years'), findsOneWidget);
      expect(find.text('All Semesters'), findsOneWidget);
      expect(find.text('Database Management Systems'), findsOneWidget);
      expect(find.text('CE501'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
    });

    testWidgets('5. SectionListScreen shows error state and provides retry action', (tester) async {
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
            sectionsProvider.overrideWith(() => TestErrorSectionNotifier()),
          ],
          child: const MaterialApp(
            home: SectionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to load sections'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('6. SubjectListScreen shows error state and provides retry action', (tester) async {
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
            subjectsProvider.overrideWith(() => TestErrorSubjectNotifier()),
          ],
          child: const MaterialApp(
            home: SubjectListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to load subjects'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('7. SectionFormScreen displays HOD department banner and form controls', (tester) async {
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
            departmentMapProvider.overrideWithValue({'dept-cme': testDepartment}),
          ],
          child: const MaterialApp(
            home: SectionFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Add Section'), findsOneWidget);
      expect(find.text('YOUR DEPARTMENT'), findsOneWidget);
      expect(find.text('Computer Engineering'), findsOneWidget);
      expect(find.text('Section Name *'), findsOneWidget);
      expect(find.text('Seating Capacity *'), findsOneWidget);
    });

    testWidgets('8. SubjectFormScreen displays HOD department banner and form controls', (tester) async {
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
            departmentMapProvider.overrideWithValue({'dept-cme': testDepartment}),
          ],
          child: const MaterialApp(
            home: SubjectFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Add Subject'), findsOneWidget);
      expect(find.text('YOUR DEPARTMENT'), findsOneWidget);
      expect(find.text('Computer Engineering'), findsOneWidget);
      expect(find.text('Subject Name *'), findsOneWidget);
      expect(find.text('Subject Code *'), findsOneWidget);
      expect(find.text('Credits (0 to 10) *'), findsOneWidget);
    });

    testWidgets('9. Responsive layout verification for SectionListScreen (360dp, 390dp, 412dp)', (tester) async {
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
              ],
              child: MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: const SectionListScreen(),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Section A'), findsOneWidget);
        }
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('10. Responsive layout verification for SubjectListScreen (360dp, 390dp, 412dp)', (tester) async {
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
                subjectsProvider.overrideWith(() => TestPopulatedSubjectNotifier([testSubject1])),
              ],
              child: MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: const SubjectListScreen(),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Database Management Systems'), findsOneWidget);
        }
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('11. SectionFormScreen client validation checks required name and capacity', (tester) async {
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
            departmentMapProvider.overrideWithValue({'dept-cme': testDepartment}),
          ],
          child: const MaterialApp(
            home: SectionFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Clear capacity
      await tester.enterText(find.widgetWithText(TextFormField, '60'), '0');
      // Scroll to and tap Save Changes
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Min 1'), findsOneWidget);
    });

    testWidgets('12. SubjectFormScreen client validation checks required name, code, and credits', (tester) async {
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
            departmentMapProvider.overrideWithValue({'dept-cme': testDepartment}),
          ],
          child: const MaterialApp(
            home: SubjectFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Set invalid credits
      await tester.enterText(find.widgetWithText(TextFormField, '3'), '15');
      // Scroll to and tap Save Changes
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Code is required'), findsOneWidget);
      expect(find.text('0 to 10'), findsOneWidget);
    });

    testWidgets('13. SectionListScreen contextually filters sections by semester', (tester) async {
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
            semestersProvider.overrideWith(() => TestPopulatedSemesterNotifier([testSemester1, testSemester2])),
            sectionsProvider.overrideWith(() => TestPopulatedSectionNotifier([testSectionA, testSectionB])),
          ],
          child: const MaterialApp(
            home: SectionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Section A'), findsOneWidget);
      expect(find.text('Section B'), findsOneWidget);

      // Open Semesters dropdown and select Semester 1
      await tester.tap(find.text('All Semesters'));
      await tester.pumpAndSettle();

      // Tap Semester 1 in the popup menu
      await tester.tap(find.text('Semester 1 (Term 1)').last);
      await tester.pumpAndSettle();

      expect(find.text('Section A'), findsOneWidget);
      expect(find.text('Section B'), findsNothing);
    });

    testWidgets('14. SubjectListScreen contextually filters subjects by semester', (tester) async {
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
            semestersProvider.overrideWith(() => TestPopulatedSemesterNotifier([testSemester1, testSemester2])),
            subjectsProvider.overrideWith(() => TestPopulatedSubjectNotifier([testSubject1, testSubject2])),
          ],
          child: const MaterialApp(
            home: SubjectListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Database Management Systems'), findsOneWidget);
      expect(find.text('Operating Systems'), findsOneWidget);

      // Open Semesters dropdown and select Semester 1
      await tester.tap(find.text('All Semesters'));
      await tester.pumpAndSettle();

      // Tap Semester 1 in the popup menu
      await tester.tap(find.text('Semester 1 (Term 1)').last);
      await tester.pumpAndSettle();

      expect(find.text('Database Management Systems'), findsOneWidget);
      expect(find.text('Operating Systems'), findsNothing);
    });
  });
}

class TestEmptyCourseNotifier extends AutoDisposeAsyncNotifier<List<Course>> implements CourseNotifier {
  @override
  Future<List<Course>> build() async => [];

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

class TestEmptySectionNotifier extends AutoDisposeAsyncNotifier<List<Section>> implements SectionNotifier {
  @override
  Future<List<Section>> build() async => [];

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

class TestErrorSectionNotifier extends AutoDisposeAsyncNotifier<List<Section>> implements SectionNotifier {
  @override
  Future<List<Section>> build() async => throw Exception('Failed to load sections');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestEmptySubjectNotifier extends AutoDisposeAsyncNotifier<List<Subject>> implements SubjectNotifier {
  @override
  Future<List<Subject>> build() async => [];

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

class TestErrorSubjectNotifier extends AutoDisposeAsyncNotifier<List<Subject>> implements SubjectNotifier {
  @override
  Future<List<Subject>> build() async => throw Exception('Failed to load subjects');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
