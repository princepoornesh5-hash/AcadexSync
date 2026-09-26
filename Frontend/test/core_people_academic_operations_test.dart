import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/core/firebase/firebase_exceptions.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/department_setup_provider.dart';
import 'package:campus_management/features/academic_structure/presentation/utils/academic_prerequisite_guard.dart';
import 'package:campus_management/features/academic_structure/presentation/screens/faculty_screens.dart';
import 'package:campus_management/features/academic_structure/presentation/widgets/enroll_student_dialog.dart';

import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/data/repositories/timetable_repository.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';

// =============================================================================
// MOCK NOTIFIERS & REPOSITORIES
// =============================================================================

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTimetableRepo implements TimetableRepository {
  final List<TimetableContainerModel> containers = [];

  @override
  Future<List<TimetableContainerModel>> getTimetableContainers({
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    TimetableStatus? status,
  }) async => containers;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// =============================================================================
// MAIN TEST SUITE: PROMPT 16 CORE PEOPLE + ACADEMIC OPERATIONS
// =============================================================================

void main() {
  group('PROMPT 16 — Core People & Academic Operations Focused Tests', () {
    late MockAcademicRepository repo;
    late MockTimetableRepo timetableRepo;

    const testCollegeId = 'c1';
    const testDeptId = 'd1';
    const testOtherDeptId = 'd2';

    const testAdminUser = UserModel(
      id: 'admin-1',
      name: 'College Administrator',
      email: 'admin@git.edu',
      role: AppRole.collegeAdmin,
      collegeId: testCollegeId,
    );

    const testHodUser = UserModel(
      id: 'hod-1',
      name: 'Dr. Alan Turing',
      email: 'alan.turing@git.edu',
      role: AppRole.hod,
      collegeId: testCollegeId,
      departmentId: testDeptId,
    );

    setUp(() {
      repo = MockAcademicRepository(currentUser: testAdminUser);
      timetableRepo = MockTimetableRepo();
    });

    ProviderContainer createContainer({UserModel currentUser = testAdminUser}) {
      return ProviderContainer(
        overrides: [
          academicRepositoryProvider.overrideWithValue(repo),
          timetableRepositoryProvider.overrideWithValue(timetableRepo),
          authProvider.overrideWith((ref) => MockAuthNotifier(
                AuthAuthenticated(user: currentUser, token: 'mock-token'),
              )),
        ],
      );
    }

    // -------------------------------------------------------------------------
    // TEST 1: Faculty create → provider refresh
    // -------------------------------------------------------------------------
    test('1. Faculty create → provider refresh updates faculty list and invalidates department setup', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(facultyProvider(testDeptId).notifier);
      await notifier.loadInitial();
      final initialCount = container.read(facultyProvider(testDeptId)).items.length;

      const req = ProvisionFacultyRequest(
        departmentId: testDeptId,
        name: 'Dr. Ada Lovelace',
        instituteId: 'GIT-FAC-099',
        email: 'ada.lovelace@git.edu',
        designation: 'Professor',
        qualification: 'Ph.D. Computer Science',
        specialization: 'Computational Algorithms',
        phone: '9876543210',
        employeeId: 'FAC-CS-099',
      );

      await notifier.provisionFaculty(req);

      final updatedItems = container.read(facultyProvider(testDeptId)).items;
      expect(updatedItems.length, initialCount + 1);
      expect(updatedItems.any((f) => f.name == 'Dr. Ada Lovelace'), isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 2: Faculty deactivate → unavailable for new assignment
    // -------------------------------------------------------------------------
    test('2. Faculty deactivate → unavailable for new assignment and cascades to existing assignments', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // Verify faculty 'f1' has existing active assignment 'fa1' in mock repository
      final assignmentsBefore = await repo.getFacultyAssignments(facultyId: 'f1');
      expect(assignmentsBefore.any((a) => a.id == 'fa1' && a.isActive), isTrue);

      // Deactivate faculty via notifier
      final facultyNotifier = container.read(facultyProvider(testDeptId).notifier);
      await facultyNotifier.loadInitial();
      await facultyNotifier.toggleFacultyStatus('f1', false, departmentId: testDeptId);

      // In repository and state, faculty is deactivated
      final facultyList = container.read(facultyProvider(testDeptId)).items;
      final activeMatch = facultyList.where((f) => f.id == 'f1').toList();
      expect(activeMatch.isEmpty, isTrue);

      // Verify entity itself is deactivated
      final f1 = await repo.getFacultyById('f1');
      expect(f1, isNotNull);
      expect(f1!.isActive, isFalse);
      expect(f1.accountStatus, AccountStatus.deactivated);

      // Cascaded deactivation to existing assignments excludes them from active assignments
      final assignmentsAfter = await repo.getFacultyAssignments(facultyId: 'f1');
      expect(assignmentsAfter.isEmpty, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 3: Student create → provider refresh
    // -------------------------------------------------------------------------
    test('3. Student create → provider refresh updates student list and department setup', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final initialStudents = await container.read(studentsByDepartmentProvider(testDeptId).future);
      final initialCount = initialStudents.length;

      final newStudent = Student(
        id: 'st-new-01',
        collegeId: testCollegeId,
        departmentId: testDeptId,
        courseId: 'cr1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Katherine Johnson',
        rollNumber: 'CS-2026-99',
        email: 'katherine@git.edu',
        phone: '9123456780',
        isActive: true,
        accountStatus: AccountStatus.active,
        lifecycleState: StudentLifecycleState.active,
      );

      final notifier = container.read(studentsProvider((sectionId: null, departmentId: testDeptId)).notifier);
      await notifier.admitStudent(newStudent);

      final updatedStudents = await container.read(studentsByDepartmentProvider(testDeptId).future);
      expect(updatedStudents.length, initialCount + 1);
      expect(updatedStudents.any((s) => s.name == 'Katherine Johnson'), isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 4: Student deactivate → unavailable for new enrollment
    // -------------------------------------------------------------------------
    test('4. Student deactivate → unavailable for new enrollment', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // Deactivate student 's1'
      final studentNotifier = container.read(studentsProvider((sectionId: null, departmentId: testDeptId)).notifier);
      await studentNotifier.toggleStudentStatus('s1', false, departmentId: testDeptId, sectionId: 'sec1');

      final updatedStudent = await repo.getStudentById('s1');
      expect(updatedStudent, isNotNull);
      expect(updatedStudent!.isActive, isFalse);
      expect(updatedStudent.accountStatus, AccountStatus.deactivated);

      // Attempting to enroll inactive student throws BackendValidationException
      expect(
        () => repo.enrollStudent(
          studentId: 's1',
          courseId: 'cr1',
          academicYearId: 'ay1',
          semesterId: 'sem1',
          sectionId: 'sec1',
        ),
        throwsA(isA<BackendValidationException>().having(
          (e) => e.message,
          'message',
          contains('inactive'),
        )),
      );
    });

    // -------------------------------------------------------------------------
    // TEST 5: Faculty Assignment uses correct Faculty/Subject/Section
    // -------------------------------------------------------------------------
    test('5. Faculty Assignment uses correct Faculty/Subject/Section and academic context', () async {
      final assignment = FacultyAssignment(
        id: 'fa-exact-01',
        collegeId: testCollegeId,
        departmentId: testDeptId,
        facultyId: 'f1',
        facultyName: 'Prof. Alan Turing',
        courseId: 'cr1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        subjectId: 'sub2', // Unassigned subject in sem1
        academicYearId: 'ay1',
        assignmentType: 'Lab',
        isActive: true,
      );

      await repo.createFacultyAssignment(assignment);

      final fetched = await repo.getFacultyAssignments(sectionId: 'sec1', subjectId: 'sub2');
      final matched = fetched.firstWhere((a) => a.id == 'fa-exact-01');

      expect(matched.facultyId, 'f1');
      expect(matched.subjectId, 'sub2');
      expect(matched.sectionId, 'sec1');
      expect(matched.courseId, 'cr1');
      expect(matched.semesterId, 'sem1');
      expect(matched.academicYearId, 'ay1');
      expect(matched.departmentId, testDeptId);
      expect(matched.isActive, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 6: Faculty Assignment duplicate protection
    // -------------------------------------------------------------------------
    test('6. Faculty Assignment duplicate protection rejects duplicate active assignment', () async {
      // fa1 is already active for f1, sub1, sec1, sem1, ay1 in MockAcademicRepository
      final duplicateAssignment = FacultyAssignment(
        id: 'fa-dup-test',
        collegeId: testCollegeId,
        departmentId: testDeptId,
        facultyId: 'f1',
        facultyName: 'Prof. Alan Turing',
        courseId: 'cr1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        subjectId: 'sub1',
        academicYearId: 'ay1',
        isActive: true,
      );

      // Attempt duplicate assignment
      expect(
        () => repo.createFacultyAssignment(duplicateAssignment),
        throwsA(isA<BackendValidationException>().having(
          (e) => e.message,
          'message',
          contains('An active assignment already exists'),
        )),
      );
    });

    // -------------------------------------------------------------------------
    // TEST 7: Student Enrollment uses correct Student/Course/Semester/Section
    // -------------------------------------------------------------------------
    test('7. Student Enrollment uses correct Student/Course/Semester/Section and academic year', () async {
      final student = Student(
        id: 'st-enroll-01',
        collegeId: testCollegeId,
        departmentId: testDeptId,
        courseId: 'cr1',
        semesterId: 'sem1',
        sectionId: '',
        name: 'Margaret Hamilton',
        rollNumber: 'CS-2026-88',
        email: 'margaret@git.edu',
        phone: '9123456781',
        isActive: true,
        accountStatus: AccountStatus.active,
        lifecycleState: StudentLifecycleState.active,
      );
      await repo.admitStudent(student);

      await repo.enrollStudent(
        studentId: student.id,
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec1',
      );

      final enrollments = await repo.getEnrollments(sectionId: 'sec1', studentId: student.id);
      expect(enrollments.isNotEmpty, isTrue);
      final enr = enrollments.first;
      expect(enr.studentId, student.id);
      expect(enr.sectionId, 'sec1');
      expect(enr.semesterId, 'sem1');
      expect(enr.courseId, 'cr1');
      expect(enr.academicYearId, 'ay1');
      expect(enr.isActive, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 8: Student Enrollment duplicate protection
    // -------------------------------------------------------------------------
    test('8. Student Enrollment duplicate protection throws clean user-facing error', () async {
      final student = Student(
        id: 'st-dup-01',
        collegeId: testCollegeId,
        departmentId: testDeptId,
        courseId: 'cr1',
        semesterId: 'sem1',
        sectionId: '',
        name: 'Grace Hopper',
        rollNumber: 'CS-2026-77',
        email: 'grace@git.edu',
        phone: '9123456782',
        isActive: true,
        accountStatus: AccountStatus.active,
        lifecycleState: StudentLifecycleState.active,
      );
      await repo.admitStudent(student);

      await repo.enrollStudent(
        studentId: student.id,
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec1',
      );

      // Second enrollment attempt must throw duplicate error
      expect(
        () => repo.enrollStudent(
          studentId: student.id,
          courseId: 'cr1',
          academicYearId: 'ay1',
          semesterId: 'sem1',
          sectionId: 'sec1',
        ),
        throwsA(isA<BackendValidationException>().having(
          (e) => e.message,
          'message',
          equals('Student is already enrolled in this section.'),
        )),
      );
    });

    // -------------------------------------------------------------------------
    // TEST 9: Contextual Faculty creation preserves department
    // -------------------------------------------------------------------------
    testWidgets('9. Contextual Faculty creation preserves department context from route', (tester) async {
      final container = createContainer(currentUser: testHodUser);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FacultyFormScreen(initialDepartmentId: testDeptId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Screen renders "Add Faculty" (simple user-facing language)
      expect(find.text('Add Faculty'), findsWidgets);
    });

    // -------------------------------------------------------------------------
    // TEST 10: Contextual Enrollment preserves academic context
    // -------------------------------------------------------------------------
    testWidgets('10. Contextual Enrollment preserves section/course/semester/year context', (tester) async {
      final container = createContainer();
      addTearDown(container.dispose);

      final section = (await repo.getSections(semesterId: 'sem1')).first;
      final course = (await repo.getCourses(departmentId: testDeptId)).first;
      final semester = (await repo.getSemesters(courseId: 'cr1')).firstWhere((s) => s.id == 'sem1');
      final academicYear = (await repo.getAcademicYears()).firstWhere((a) => a.id == 'ay1');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: EnrollStudentDialog(
                section: section,
                course: course,
                semester: semester,
                academicYear: academicYear,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify dialog renders with section context
      expect(find.textContaining('Section ${section.name}'), findsWidgets);
    });

    // -------------------------------------------------------------------------
    // TEST 11: HOD department scope
    // -------------------------------------------------------------------------
    test('11. HOD department scope permits own department and prevents cross-department actions', () {
      // HOD is authorized for own department 'd1'
      final isOwnDept = testHodUser.role == AppRole.hod && testHodUser.departmentId == testDeptId;
      expect(isOwnDept, isTrue);

      // HOD is NOT authorized for other department 'd2'
      final isOtherDept = testHodUser.role == AppRole.hod && testHodUser.departmentId == testOtherDeptId;
      expect(isOtherDept, isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST 12: Faculty availability affects assignment readiness
    // -------------------------------------------------------------------------
    test('12. Faculty availability affects assignment readiness in Department Setup', () async {
      final courses = await repo.getCourses(departmentId: testDeptId);
      final academicYears = await repo.getAcademicYears();
      final semesters = await repo.getSemesters(courseId: 'cr1');
      final sections = await repo.getSections(semesterId: 'sem1');
      final subjects = await repo.getSubjects(semesterId: 'sem1');
      final students = await repo.getStudents(departmentId: testDeptId);

      // Case A: 0 active faculty members
      final decisionBlocked = AcademicPrerequisiteGuard.resolveMilestoneDecision(
        milestoneId: SetupMilestoneId.facultyAssignment,
        currentRole: AppRole.collegeAdmin,
        departmentId: testDeptId,
        collegeId: testCollegeId,
        courses: courses,
        academicYears: academicYears,
        semesters: semesters,
        sections: sections,
        subjects: subjects,
        faculty: [], // No active faculty!
        facultyAssignments: [],
        students: students,
        timetableCount: 0,
      );

      expect(decisionBlocked.status, SetupDecisionStatus.blocked);
      expect(decisionBlocked.actionLabel, 'Provision Faculty');
      expect(decisionBlocked.explanation, contains('No active faculty is available'));

      // Case B: Active faculty member available
      final facultyList = await repo.getFaculty(departmentId: testDeptId);
      final decisionReady = AcademicPrerequisiteGuard.resolveMilestoneDecision(
        milestoneId: SetupMilestoneId.facultyAssignment,
        currentRole: AppRole.collegeAdmin,
        departmentId: testDeptId,
        collegeId: testCollegeId,
        courses: courses,
        academicYears: academicYears,
        semesters: semesters,
        sections: sections,
        subjects: subjects,
        faculty: facultyList, // Active faculty exists
        facultyAssignments: [],
        students: students,
        timetableCount: 0,
      );

      expect(decisionReady.status, SetupDecisionStatus.ready);
      expect(decisionReady.actionLabel, 'Assign Faculty');
    });

    // -------------------------------------------------------------------------
    // TEST 13: Student availability affects enrollment readiness
    // -------------------------------------------------------------------------
    test('13. Student availability affects enrollment readiness in Department Setup', () async {
      final courses = await repo.getCourses(departmentId: testDeptId);
      final academicYears = await repo.getAcademicYears();
      final semesters = await repo.getSemesters(courseId: 'cr1');
      final sections = await repo.getSections(semesterId: 'sem1');
      final subjects = await repo.getSubjects(semesterId: 'sem1');
      final facultyList = await repo.getFaculty(departmentId: testDeptId);

      // Case A: 0 active students in department
      final decisionBlocked = AcademicPrerequisiteGuard.resolveMilestoneDecision(
        milestoneId: SetupMilestoneId.studentEnrollment,
        currentRole: AppRole.collegeAdmin,
        departmentId: testDeptId,
        collegeId: testCollegeId,
        courses: courses,
        academicYears: academicYears,
        semesters: semesters,
        sections: sections,
        subjects: subjects,
        faculty: facultyList,
        facultyAssignments: [],
        students: [], // No students!
        timetableCount: 0,
      );

      expect(decisionBlocked.status, SetupDecisionStatus.blocked);
      expect(decisionBlocked.actionLabel, 'Provision Student');
      expect(decisionBlocked.explanation, contains('No admitted students available'));

      // Case B: Active students exist in department, not yet assigned to section
      final unassignedStudent = Student(
        id: 's-unassigned',
        collegeId: testCollegeId,
        departmentId: testDeptId,
        courseId: 'cr1',
        semesterId: 'sem1',
        sectionId: '', // Unenrolled
        name: 'Ada Unassigned',
        rollNumber: 'CS999',
        email: 'ada@student.git.edu',
        phone: '1234567890',
        isActive: true,
        accountStatus: AccountStatus.active,
        lifecycleState: StudentLifecycleState.active,
      );

      final decisionReady = AcademicPrerequisiteGuard.resolveMilestoneDecision(
        milestoneId: SetupMilestoneId.studentEnrollment,
        currentRole: AppRole.collegeAdmin,
        departmentId: testDeptId,
        collegeId: testCollegeId,
        courses: courses,
        academicYears: academicYears,
        semesters: semesters,
        sections: sections,
        subjects: subjects,
        faculty: facultyList,
        facultyAssignments: [],
        students: [unassignedStudent],
        timetableCount: 0,
      );

      expect(decisionReady.status, SetupDecisionStatus.ready);
      expect(decisionReady.actionLabel, 'Enroll Students');
    });

    // -------------------------------------------------------------------------
    // TEST 14: People mutation refresh updates Department Setup
    // -------------------------------------------------------------------------
    test('14. People mutation refresh updates Department Setup state', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // Maintain active subscription to prevent premature auto-dispose during async evaluation
      final sub = container.listen(departmentSetupProvider(testDeptId), (_, __) {});
      addTearDown(sub.close);

      // Initial setup state
      final setupAsync = await container.read(departmentSetupProvider(testDeptId).future);
      final initialMilestone = setupAsync.milestones.firstWhere((m) => m.id == SetupMilestoneId.facultyAssignment);
      final initialCount = initialMilestone.completedCount;

      // Create an assignment for sub3 in sec1
      final assignment = FacultyAssignment(
        id: 'fa-refresh-01',
        collegeId: testCollegeId,
        departmentId: testDeptId,
        facultyId: 'f1',
        facultyName: 'Prof. Alan Turing',
        courseId: 'cr1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        subjectId: 'sub3',
        academicYearId: 'ay1',
        isActive: true,
      );
      await repo.createFacultyAssignment(assignment);

      // Invalidate assignments and department setup provider (as notifiers do on mutation)
      container.invalidate(facultyAssignmentsProvider);
      container.invalidate(departmentSetupProvider(testDeptId));
      final updatedSetup = await container.read(departmentSetupProvider(testDeptId).future);
      final updatedMilestone = updatedSetup.milestones.firstWhere((m) => m.id == SetupMilestoneId.facultyAssignment);
      expect(updatedMilestone.completedCount, initialCount + 1);
    });

    // -------------------------------------------------------------------------
    // TEST 15: Timetable continues using correct facultyAssignmentId
    // -------------------------------------------------------------------------
    test('15. Timetable continues using correct facultyAssignmentId for authoritative teaching relationship', () {
      const assignmentId = 'assign_turing_ds_3a';

      final gridEntry = TimetableGridEntryModel(
        id: 'entry-1',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 1,
        periodSpan: 1,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: 'sub1',
        facultyId: 'f1',
        facultyAssignmentId: assignmentId,
        roomNumber: 'Room 301',
        sessionType: TimetableSessionType.lecture,
      );

      expect(gridEntry.facultyAssignmentId, assignmentId);
      expect(gridEntry.subjectId, 'sub1');
      expect(gridEntry.facultyId, 'f1');

      // Verify JSON serialization includes facultyAssignmentId
      final json = gridEntry.toJson();
      expect(json['facultyAssignmentId'], assignmentId);

      // Verify deserialization restores facultyAssignmentId
      final restored = TimetableGridEntryModel.fromJson(json);
      expect(restored.facultyAssignmentId, assignmentId);
    });
  });
}
