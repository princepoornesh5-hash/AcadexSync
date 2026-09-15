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
import 'package:campus_management/features/academic_structure/presentation/screens/semester_screens.dart';
import 'package:campus_management/features/academic_structure/presentation/widgets/fresh_department_setup_card.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testHodUser = UserModel(
    id: 'user-hod-01',
    name: 'Dr. Turing',
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
    departmentId: 'dept-cme',
    courseId: 'course-cme-01',
    academicYearId: 'ay-2026',
    name: 'Semester 1',
    number: 1,
    status: 'active',
    isCurrent: true,
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

  group('ACADEX — HOD Academic Foundation UI & Responsiveness Tests', () {
    testWidgets('1. CourseListScreen renders FreshDepartmentSetupCard when no courses exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testHodUser,
                  token: 'test-token',
                ))),
            coursesProvider.overrideWith(() => TestEmptyCourseNotifier()),
            departmentMapProvider.overrideWithValue({'dept-cme': testDepartment}),
          ],
          child: const MaterialApp(
            home: CourseListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FreshDepartmentSetupCard), findsOneWidget);
      expect(find.text('Academic Foundation Setup'), findsOneWidget);
      expect(find.text('Add First Course'), findsOneWidget);
      expect(find.text('Degree Program / Course'), findsOneWidget);
    });

    testWidgets('2. CourseListScreen renders Course cards when courses exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testHodUser,
                  token: 'test-token',
                ))),
            coursesProvider.overrideWith(() => TestPopulatedCourseNotifier([testCourse])),
            departmentMapProvider.overrideWithValue({'dept-cme': testDepartment}),
          ],
          child: const MaterialApp(
            home: CourseListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Diploma in Computer Engineering'), findsOneWidget);
      expect(find.text('DCME'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
    });

    testWidgets('3. SemesterListScreen renders contextual filters (Course & Academic Year)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testHodUser,
                  token: 'test-token',
                ))),
            coursesProvider.overrideWith(() => TestPopulatedCourseNotifier([testCourse])),
            academicYearsProvider.overrideWith(() => TestPopulatedAcademicYearNotifier([testYear])),
            semestersProvider.overrideWith(() => TestPopulatedSemesterNotifier([testSemester])),
          ],
          child: const MaterialApp(
            home: SemesterListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('All Courses'), findsOneWidget);
      expect(find.text('All Academic Years'), findsOneWidget);
      expect(find.text('Semester 1'), findsOneWidget);
      expect(find.text('Term 1'), findsOneWidget);
    });

    testWidgets('4. Responsive layout verification: 360dp, 390dp, 412dp with font scales 1.0, 1.15, 1.25', (tester) async {
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
                semestersProvider.overrideWith(() => TestPopulatedSemesterNotifier([testSemester])),
              ],
              child: MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: const SemesterListScreen(),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Ensure no horizontal overflow occurred and primary UI elements remain mounted
          expect(tester.takeException(), isNull);
          expect(find.text('Semester 1'), findsOneWidget);
        }
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
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
