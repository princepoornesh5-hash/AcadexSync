import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/presentation/screens/academic_structure_home_screen.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';

void main() {
  const testCollegeAdminUser = UserModel(
    id: 'user-admin-01',
    name: 'Dr. Admin',
    email: 'admin@alpha.edu',
    role: AppRole.collegeAdmin,
    collegeId: 'col-alpha',
  );

  const testFacultyUser = UserModel(
    id: 'user-fac-01',
    name: 'Prof. Turing',
    email: 'turing@alpha.edu',
    role: AppRole.faculty,
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
  );

  const testStudentUser = UserModel(
    id: 'user-stud-01',
    name: 'Ada Lovelace',
    email: 'ada@alpha.edu',
    role: AppRole.student,
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    sectionId: 'sec-a',
  );

  const testHodUser = UserModel(
    id: 'user-hod-01',
    name: 'Prof. Hopper',
    email: 'hod@alpha.edu',
    role: AppRole.hod,
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
  );

  group('ACADEX Phase 9Q.2 — Academic Structure Home Screen UI/UX Tests', () {
    testWidgets('Renders Page Title, KPI Stat Deck and all 5 Hierarchy Tabs', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testCollegeAdminUser,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
          ],
          child: const MaterialApp(
            home: AcademicStructureHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Title & Subtitle
      expect(find.text('Academic Structure'), findsOneWidget);
      expect(find.text('Departments'), findsWidgets);
      expect(find.text('Courses'), findsWidgets);
      expect(find.text('Semesters'), findsWidgets);
      expect(find.text('Sections'), findsWidgets);
      expect(find.text('Subjects Catalog'), findsWidgets);

      // KPI Metric Cards
      expect(find.text('Active Units'), findsOneWidget);
      expect(find.text('Degree Programs'), findsOneWidget);
      expect(find.text('Academic Terms'), findsOneWidget);
      expect(find.text('Classrooms'), findsOneWidget);
      expect(find.text('Curriculum Items'), findsOneWidget);
    });

    testWidgets('College Admin sees Create Department action button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testCollegeAdminUser,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
          ],
          child: const MaterialApp(
            home: AcademicStructureHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Create Department'), findsOneWidget);
    });

    testWidgets('HOD sees Department Setup and Create Course action buttons', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testHodUser,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
          ],
          child: const MaterialApp(
            home: AcademicStructureHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Department Setup'), findsOneWidget);
      expect(find.text('Create Course'), findsOneWidget);
    });

    testWidgets('Faculty sees personalized Workload & Class Schedule banner', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testFacultyUser,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
          ],
          child: const MaterialApp(
            home: AcademicStructureHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Faculty Workload & Class Roster'), findsOneWidget);
      expect(find.text('My Workload'), findsOneWidget);
    });

    testWidgets('Student sees personalized Curriculum & Schedule banner', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testStudentUser,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
          ],
          child: const MaterialApp(
            home: AcademicStructureHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Student Curriculum & Schedule'), findsOneWidget);
      expect(find.text('My Timetable'), findsOneWidget);
    });

    testWidgets('Search input filters academic entities dynamically and shows empty state on no match', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
                  user: testCollegeAdminUser,
                  token: 'test-token',
                ))),
            academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
          ],
          child: const MaterialApp(
            home: AcademicStructureHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'NON_EXISTENT_DEPARTMENT_QUERY_XYZ');
      await tester.pumpAndSettle();

      expect(find.text('No Departments Found'), findsOneWidget);
    });
  });

  group('ACADEX Phase 9Q.2 — Academic Domain Models & Serialization Tests', () {
    test('Department, Course, Semester, Section, Subject models serialize accurately', () {
      final deptJson = {
        'id': 'dept-cse',
        'collegeId': 'col-1',
        'name': 'Computer Science',
        'code': 'CSE',
        'hodId': 'hod-1',
        'description': 'CSE Department',
        'isActive': true,
      };
      final dept = Department.fromJson(deptJson);
      expect(dept.name, 'Computer Science');
      expect(dept.code, 'CSE');
      expect(dept.toJson()['code'], 'CSE');

      final courseJson = {
        'id': 'course-btech',
        'collegeId': 'col-1',
        'departmentId': 'dept-cse',
        'name': 'Bachelor of Technology',
        'code': 'BTECH-CS',
        'isActive': true,
      };
      final course = Course.fromJson(courseJson);
      expect(course.name, 'Bachelor of Technology');
      expect(course.code, 'BTECH-CS');

      final semJson = {
        'id': 'sem-1',
        'collegeId': 'col-1',
        'departmentId': 'dept-cse',
        'courseId': 'course-btech',
        'academicYearId': 'ay-2026',
        'name': 'Semester 1',
        'number': 1,
        'status': 'active',
      };
      final sem = Semester.fromJson(semJson);
      expect(sem.number, 1);
      expect(sem.status, 'active');

      final secJson = {
        'id': 'sec-a',
        'collegeId': 'col-1',
        'departmentId': 'dept-cse',
        'semesterId': 'sem-1',
        'name': 'A',
        'capacity': 60,
        'status': 'active',
      };
      final sec = Section.fromJson(secJson);
      expect(sec.name, 'A');
      expect(sec.capacity, 60);

      final subJson = {
        'id': 'sub-ds',
        'collegeId': 'col-1',
        'departmentId': 'dept-cse',
        'semesterId': 'sem-1',
        'name': 'Data Structures',
        'code': 'CS201',
        'credits': 4,
        'type': 'THEORY',
      };
      final sub = Subject.fromJson(subJson);
      expect(sub.code, 'CS201');
      expect(sub.credits, 4);
    });
  });
}

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
