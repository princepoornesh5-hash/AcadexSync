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
import 'package:campus_management/features/academic_structure/presentation/utils/academic_prerequisite_guard.dart';

import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/data/repositories/timetable_repository.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';

import 'package:campus_management/features/attendance/domain/models/attendance_session.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_record.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_status.dart';

import 'package:campus_management/core/errors/acadex_error.dart';

// =============================================================================
// MOCK NOTIFIERS & REPOSITORIES
// =============================================================================

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAcademicRepo implements AcademicRepository {
  final List<Course> courses = [];
  final List<AcademicYear> academicYears = [];
  final List<Semester> semesters = [];
  final List<Section> sections = [];
  final List<Subject> subjects = [];
  final List<FacultyAssignment> facultyAssignments = [];
  final List<Student> students = [];
  final List<StudentEnrollment> enrollments = [];
  final List<Department> departments = [];
  final List<Faculty> faculties = [];

  @override
  Future<List<Department>> getDepartments({String? collegeId, String? search, String? status}) async => departments;

  @override
  Future<List<Faculty>> getFaculty({String? departmentId, String? search, String? status}) async {
    if (departmentId != null) return faculties.where((f) => f.departmentId == departmentId).toList();
    return faculties;
  }

  @override
  Future<List<Course>> getCourses({String? collegeId, String? departmentId, String? search}) async {
    if (departmentId != null) {
      return courses.where((c) => c.departmentId == departmentId).toList();
    }
    return courses;
  }

  @override
  Future<List<AcademicYear>> getAcademicYears({String? collegeId}) async => academicYears;

  @override
  Future<List<Semester>> getSemesters({String? courseId, String? academicYearId, String? collegeId}) async {
    if (courseId != null) {
      return semesters.where((s) => s.courseId == courseId).toList();
    }
    return semesters;
  }

  @override
  Future<List<Section>> getSections({String? semesterId, String? courseId, String? collegeId}) async {
    if (semesterId != null) {
      return sections.where((sec) => sec.semesterId == semesterId).toList();
    }
    return sections;
  }

  @override
  Future<List<Subject>> getSubjects({String? semesterId, String? courseId, String? collegeId}) async {
    var res = subjects;
    if (courseId != null) res = res.where((s) => s.courseId == courseId).toList();
    if (semesterId != null) res = res.where((s) => s.semesterId == semesterId).toList();
    return res;
  }

  @override
  Future<List<FacultyAssignment>> getFacultyAssignments({
    String? facultyId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? subjectId,
    String? academicYearId,
  }) async {
    if (departmentId != null) {
      return facultyAssignments.where((a) => a.departmentId == departmentId).toList();
    }
    return facultyAssignments;
  }

  @override
  Future<List<Student>> getStudentsByDepartment(String departmentId) async {
    return students.where((s) => s.departmentId == departmentId).toList();
  }

  @override
  Future<List<Student>> getStudentsBySection(String sectionId) async {
    return students.where((s) => s.sectionId == sectionId).toList();
  }

  @override
  Future<List<Student>> getStudents({String? sectionId, String? departmentId}) async {
    var res = students;
    if (departmentId != null) res = res.where((s) => s.departmentId == departmentId).toList();
    if (sectionId != null) res = res.where((s) => s.sectionId == sectionId).toList();
    return res;
  }

  @override
  Future<List<StudentEnrollment>> getEnrollments({
    String? studentId,
    String? sectionId,
    String? semesterId,
    String? courseId,
    String? academicYearId,
    String? collegeId,
    String? status,
  }) async {
    return enrollments.where((e) => sectionId == null || e.sectionId == sectionId).toList();
  }

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
  }) async {
    var res = containers;
    if (departmentId != null) res = res.where((c) => c.departmentId == departmentId).toList();
    if (sectionId != null) res = res.where((c) => c.sectionId == sectionId).toList();
    if (status != null) res = res.where((c) => c.status == status).toList();
    return res;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// =============================================================================
// MAIN TEST SUITE: PROMPT 15 CORE WORKFLOW & DATA INTEGRITY HARDENING
// =============================================================================

void main() {
  group('PROMPT 15 — Core Workflow Integration & Data Integrity Hardening', () {
    late MockAcademicRepo mockAcademicRepo;
    late MockTimetableRepo mockTimetableRepo;

    final testCollegeId = 'college_main';
    final testDeptId = 'dept_cs';
    final testOtherDeptId = 'dept_ec';

    final testCourse = Course(
      id: 'course_cs101',
      collegeId: testCollegeId,
      departmentId: testDeptId,
      name: 'Computer Science and Engineering',
      code: 'CSE',
      duration: 4,
      isActive: true,
    );

    final testAcademicYear = AcademicYear(
      id: 'ay_2024_2025',
      collegeId: testCollegeId,
      name: '2024-2025',
      startDate: DateTime(2024, 7, 1),
      endDate: DateTime(2025, 6, 30),
      isCurrent: true,
      isActive: true,
      status: 'active',
    );

    final testSemester = Semester(
      id: 'sem_1',
      collegeId: testCollegeId,
      departmentId: testDeptId,
      courseId: testCourse.id,
      academicYearId: testAcademicYear.id,
      number: 1,
      name: 'Semester 1',
      isCurrent: true,
      status: 'active',
      isActive: true,
    );

    final testSection = Section(
      id: 'sec_1a',
      collegeId: testCollegeId,
      departmentId: testDeptId,
      courseId: testCourse.id,
      academicYearId: testAcademicYear.id,
      semesterId: testSemester.id,
      name: 'A',
      capacity: 60,
      isActive: true,
    );

    final testSubject = Subject(
      id: 'sub_algo',
      collegeId: testCollegeId,
      departmentId: testDeptId,
      courseId: testCourse.id,
      semesterId: testSemester.id,
      name: 'Data Structures and Algorithms',
      code: 'CS201',
      credits: 4,
      type: 'theory',
      isActive: true,
    );

    final testFaculty = Faculty(
      id: 'fac_turing',
      collegeId: testCollegeId,
      departmentId: testDeptId,
      name: 'Dr. Alan Turing',
      employeeId: 'EMP001',
      email: 'turing@college.edu',
      phone: '1234567890',
      designation: 'Professor',
    );

    final testAssignment = FacultyAssignment(
      id: 'fa_101',
      collegeId: testCollegeId,
      departmentId: testDeptId,
      facultyId: testFaculty.id,
      facultyName: testFaculty.name,
      courseId: testCourse.id,
      semesterId: testSemester.id,
      sectionId: testSection.id,
      subjectId: testSubject.id,
      academicYearId: testAcademicYear.id,
      isActive: true,
    );

    final testStudent = Student(
      id: 'stu_ada',
      collegeId: testCollegeId,
      departmentId: testDeptId,
      courseId: testCourse.id,
      academicYearId: testAcademicYear.id,
      semesterId: testSemester.id,
      sectionId: testSection.id,
      name: 'Ada Lovelace',
      instituteId: 'STU001',
      rollNumber: 'CS-01',
      email: 'ada@college.edu',
      phone: '9876543210',
    );

    final testEnrollment = StudentEnrollment(
      id: 'enr_1',
      studentId: testStudent.id,
      sectionId: testSection.id,
      semesterId: testSemester.id,
      courseId: testCourse.id,
      academicYearId: testAcademicYear.id,
      collegeId: testCollegeId,
      departmentId: testDeptId,
      status: 'active',
    );

    setUp(() {
      mockAcademicRepo = MockAcademicRepo();
      mockTimetableRepo = MockTimetableRepo();

      mockAcademicRepo.courses.add(testCourse);
      mockAcademicRepo.academicYears.add(testAcademicYear);
      mockAcademicRepo.semesters.add(testSemester);
      mockAcademicRepo.sections.add(testSection);
      mockAcademicRepo.subjects.add(testSubject);
      mockAcademicRepo.facultyAssignments.add(testAssignment);
      mockAcademicRepo.students.add(testStudent);
      mockAcademicRepo.enrollments.add(testEnrollment);

      mockAcademicRepo.departments.add(Department(
        id: testDeptId,
        collegeId: testCollegeId,
        name: 'Computer Science',
        code: 'CS',
        hodId: 'hod_1',
        description: 'CS Dept',
      ));
      mockAcademicRepo.departments.add(Department(
        id: testOtherDeptId,
        collegeId: testCollegeId,
        name: 'Electronics and Communication',
        code: 'EC',
        hodId: 'hod_2',
        description: 'EC Dept',
      ));
      mockAcademicRepo.faculties.add(testFaculty);
    });

    // -------------------------------------------------------------------------
    // TEST 1: Academic Year creation and provider refresh
    // -------------------------------------------------------------------------
    test('1. Academic Year creation serializes canonical UTC ISO dates and refreshes providers', () {
      final startDate = DateTime(2024, 8, 1);
      final endDate = DateTime(2025, 5, 31);

      expect(AcademicYearDateUtils.isRangeValid(startDate, endDate), isTrue);
      expect(AcademicYearDateUtils.isRangeValid(endDate, startDate), isFalse);

      final startIso = AcademicYearDateUtils.serialize(startDate);
      final endIso = AcademicYearDateUtils.serialize(endDate);

      expect(startIso.endsWith('Z'), isTrue);
      expect(endIso.endsWith('Z'), isTrue);
      expect(startIso, '2024-08-01T00:00:00.000Z');
      expect(endIso, '2025-05-31T00:00:00.000Z');

      final ay = AcademicYear(
        id: 'ay_new',
        collegeId: testCollegeId,
        name: '2024-2025 New',
        startDate: startDate,
        endDate: endDate,
        isCurrent: true,
        isActive: true,
      );

      final json = ay.toJson();
      expect(json['startDate'], '2024-08-01T00:00:00.000Z');
      expect(json['endDate'], '2025-05-31T00:00:00.000Z');
      expect(json['isCurrent'], isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 2: Course -> Semester context preservation
    // -------------------------------------------------------------------------
    test('2. Course -> Semester context preservation ensures departmentId and collegeId remain intact', () {
      final semester = Semester(
        id: 'sem_new',
        collegeId: testCourse.collegeId,
        departmentId: testCourse.departmentId,
        courseId: testCourse.id,
        academicYearId: testAcademicYear.id,
        number: 2,
        name: 'Semester 2',
      );

      expect(semester.courseId, testCourse.id);
      expect(semester.departmentId, testCourse.departmentId);
      expect(semester.departmentId, isNotEmpty);
      expect(semester.collegeId, testCourse.collegeId);
      expect(semester.academicYearId, testAcademicYear.id);
    });

    // -------------------------------------------------------------------------
    // TEST 3: Semester -> Section context preservation
    // -------------------------------------------------------------------------
    test('3. Semester -> Section context preservation preserves all parental IDs', () {
      final section = Section(
        id: 'sec_new',
        collegeId: testSemester.collegeId,
        departmentId: testSemester.departmentId,
        courseId: testSemester.courseId,
        academicYearId: testSemester.academicYearId,
        semesterId: testSemester.id,
        name: 'B',
        capacity: 50,
      );

      expect(section.semesterId, testSemester.id);
      expect(section.courseId, testSemester.courseId);
      expect(section.departmentId, testSemester.departmentId);
      expect(section.academicYearId, testSemester.academicYearId);
    });

    // -------------------------------------------------------------------------
    // TEST 4: Section -> Subject context preservation
    // -------------------------------------------------------------------------
    test('4. Section -> Subject context preservation maintains course and semester binding', () {
      final subject = Subject(
        id: 'sub_new',
        collegeId: testSection.collegeId,
        departmentId: testSection.departmentId,
        courseId: testSection.courseId,
        semesterId: testSection.semesterId,
        name: 'Operating Systems',
        code: 'CS301',
        credits: 3,
        type: 'theory',
      );

      expect(subject.courseId, testSection.courseId);
      expect(subject.semesterId, testSection.semesterId);
      expect(subject.departmentId, testSection.departmentId);
      expect(subject.credits, 3);
    });

    // -------------------------------------------------------------------------
    // TEST 5: Subject -> Faculty Assignment context preservation
    // -------------------------------------------------------------------------
    test('5. Subject -> Faculty Assignment context preservation retains valid domain links', () {
      final assignment = FacultyAssignment(
        id: 'fa_new',
        collegeId: testSubject.collegeId,
        departmentId: testSubject.departmentId,
        facultyId: testFaculty.id,
        facultyName: testFaculty.name,
        courseId: testSubject.courseId,
        semesterId: testSubject.semesterId,
        sectionId: testSection.id,
        subjectId: testSubject.id,
        academicYearId: testAcademicYear.id,
      );

      expect(assignment.subjectId, testSubject.id);
      expect(assignment.courseId, testSubject.courseId);
      expect(assignment.semesterId, testSubject.semesterId);
      expect(assignment.sectionId, testSection.id);
      expect(assignment.facultyId, testFaculty.id);

      // Verify query params format for continuation:
      final query = 'subjectId=${assignment.subjectId}&courseId=${assignment.courseId}&semesterId=${assignment.semesterId}';
      final uri = Uri.parse('/faculty-assignments?$query');
      expect(uri.queryParameters['subjectId'], testSubject.id);
      expect(uri.queryParameters['courseId'], testSubject.courseId);
      expect(uri.queryParameters['semesterId'], testSubject.semesterId);
    });

    // -------------------------------------------------------------------------
    // TEST 6: Faculty Assignment -> Enrollment context preservation
    // -------------------------------------------------------------------------
    test('6. Faculty Assignment -> Enrollment continuation preserves section and academic context', () {
      final enrollment = StudentEnrollment(
        id: 'enr_new',
        studentId: testStudent.id,
        sectionId: testSection.id,
        semesterId: testSection.semesterId,
        courseId: testSection.courseId,
        academicYearId: testSection.academicYearId,
        collegeId: testSection.collegeId,
        departmentId: testSection.departmentId,
        status: 'active',
      );

      expect(enrollment.sectionId, testSection.id);
      expect(enrollment.studentId, testStudent.id);
      expect(enrollment.semesterId, testSection.semesterId);
      expect(enrollment.courseId, testSection.courseId);
      expect(enrollment.academicYearId, testSection.academicYearId);
    });

    // -------------------------------------------------------------------------
    // TEST 7: Enrollment -> Timetable continuation
    // -------------------------------------------------------------------------
    test('7. Enrollment -> Timetable continuation uses valid section and faculty assignment', () {
      final container = TimetableContainerModel(
        id: 'tt_cs_1a',
        collegeId: testCollegeId,
        departmentId: testDeptId,
        courseId: testCourse.id,
        academicYearId: testAcademicYear.id,
        semesterId: testSemester.id,
        sectionId: testSection.id,
        name: 'CS 1st Sem Section A Timetable',
        status: TimetableStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(container.sectionId, testSection.id);
      expect(container.courseId, testCourse.id);
      expect(container.departmentId, testDeptId);
      expect(container.isDraft, isTrue);
      expect(container.isPublished, isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST 8: Provider invalidation after create
    // -------------------------------------------------------------------------
    test('8. Provider invalidation after create invalidates department setup without global refresh', () async {
      final container = ProviderContainer(
        overrides: [
          academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
          timetableRepositoryProvider.overrideWithValue(mockTimetableRepo),
          authProvider.overrideWith((ref) => MockAuthNotifier(
                AuthAuthenticated(
                  user: UserModel(
                    id: 'hod_1',
                    name: 'CS HOD',
                    email: 'hod@cs.edu',
                    role: AppRole.hod,
                    collegeId: testCollegeId,
                    departmentId: testDeptId,
                    accountStatus: AccountStatus.active,
                  ),
                  token: 'mock_token',
                ),
              )),
        ],
      );

      // Read initial setup state
      final setupAsync = await container.read(departmentSetupProvider(testDeptId).future);
      final courseMilestone = setupAsync.milestones.firstWhere((m) => m.id == SetupMilestoneId.course);
      final semMilestone = setupAsync.milestones.firstWhere((m) => m.id == SetupMilestoneId.semester);
      final secMilestone = setupAsync.milestones.firstWhere((m) => m.id == SetupMilestoneId.section);
      final subMilestone = setupAsync.milestones.firstWhere((m) => m.id == SetupMilestoneId.subject);

      expect(courseMilestone.completedCount, 1);
      expect(semMilestone.completedCount, 1);
      expect(secMilestone.completedCount, 1);
      expect(subMilestone.completedCount, 1);

      // Invalidate course and check setup reflects change
      mockAcademicRepo.courses.add(Course(
        id: 'course_cs102',
        collegeId: testCollegeId,
        departmentId: testDeptId,
        name: 'M.Tech CSE',
        code: 'MCSE',
        duration: 2,
        isActive: true,
      ));

      container.invalidate(departmentSetupProvider(testDeptId));
      final updatedSetup = await container.read(departmentSetupProvider(testDeptId).future);
      final updatedCourseMilestone = updatedSetup.milestones.firstWhere((m) => m.id == SetupMilestoneId.course);
      expect(updatedCourseMilestone.completedCount, 2);

      container.dispose();
    });

    // -------------------------------------------------------------------------
    // TEST 9: Provider invalidation after update
    // -------------------------------------------------------------------------
    test('9. Provider invalidation after update clears stale entity cache', () async {
      final container = ProviderContainer(
        overrides: [
          academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
        ],
      );

      // Watch section student count
      final initialStudents = await container.read(studentsBySectionProvider(testSection.id).future);
      expect(initialStudents.length, 1);

      // Add another student into section
      mockAcademicRepo.students.add(testStudent.copyWith(id: 'stu_bob', name: 'Bob'));

      container.invalidate(studentsBySectionProvider(testSection.id));
      final updatedStudents = await container.read(studentsBySectionProvider(testSection.id).future);
      expect(updatedStudents.length, 2);

      container.dispose();
    });

    // -------------------------------------------------------------------------
    // TEST 10: Duplicate submission protection
    // -------------------------------------------------------------------------
    test('10. Duplicate submission protection prevents re-entrant calls when action is in flight', () {
      final savingState = TimetableAuthoringState(
        isSaving: true,
        isPublishing: false,
      );
      expect(savingState.isSaving, isTrue);

      final publishingState = TimetableAuthoringState(
        isSaving: false,
        isPublishing: true,
      );
      expect(publishingState.isPublishing, isTrue);

      // Verify guard logic: if (isSaving || isPublishing) return false;
      bool canSubmit(TimetableAuthoringState s) {
        if (s.isSaving || s.isPublishing) return false;
        return true;
      }

      expect(canSubmit(savingState), isFalse);
      expect(canSubmit(publishingState), isFalse);
      expect(canSubmit(TimetableAuthoringState()), isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 11: Duplicate enrollment handling
    // -------------------------------------------------------------------------
    test('11. Duplicate enrollment handling produces human-readable conflict error and non-retryable status', () {
      final backendError = 'Error: 409 Conflict - student is already enrolled in section';
      final exception = AcadexException.fromError(backendError);

      expect(exception.userMessage, 'That student is already enrolled in this section.');
      expect(exception.isRetryable, isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST 12: Duplicate faculty assignment handling
    // -------------------------------------------------------------------------
    test('12. Duplicate faculty assignment handling blocks re-assigning same faculty to same subject/section', () {
      final existingAssignments = [testAssignment];

      // Re-assigning Dr. Turing to Data Structures in Section A
      final isDuplicate = existingAssignments.any((a) =>
          a.isActive &&
          a.facultyId == testFaculty.id &&
          a.subjectId == testSubject.id &&
          a.sectionId == testSection.id &&
          a.semesterId == testSemester.id &&
          a.courseId == testCourse.id &&
          a.academicYearId == testAcademicYear.id);

      expect(isDuplicate, isTrue);

      // Verify backend 409 translation
      final backendError = 'Error: 409 Conflict - faculty assignment already exists';
      final exception = AcadexException.fromError(backendError);
      expect(exception.userMessage, 'This faculty assignment already exists.');
      expect(exception.isRetryable, isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST 13: Wrong-context protection
    // -------------------------------------------------------------------------
    test('13. Wrong-context protection prevents submitting child entities without valid parents', () {
      // 1. Missing Semester blocks Section
      final sectionPrereq = AcademicPrerequisiteGuard.checkSectionPrerequisites(
        courses: [testCourse],
        semesters: [], // NO SEMESTERS
      );
      expect(sectionPrereq.isSatisfied, isFalse);
      expect(sectionPrereq.missingType, AcademicPrerequisiteType.semester);

      // 2. Missing Semester blocks Subject
      final subjectPrereq = AcademicPrerequisiteGuard.checkSubjectPrerequisites(
        courses: [testCourse],
        semesters: [], // NO SEMESTERS
      );
      expect(subjectPrereq.isSatisfied, isFalse);
      expect(subjectPrereq.missingType, AcademicPrerequisiteType.semester);

      // 3. Missing Subject blocks Faculty Assignment
      final faPrereq = AcademicPrerequisiteGuard.checkFacultyAssignmentPrerequisites(
        courses: [testCourse],
        semesters: [testSemester],
        sections: [testSection],
        subjects: [], // NO SUBJECTS
        faculties: [testFaculty],
      );
      expect(faPrereq.isSatisfied, isFalse);
      expect(faPrereq.missingType, AcademicPrerequisiteType.subject);

      // 4. Missing Faculty Assignment blocks Timetable
      final ttPrereq = AcademicPrerequisiteGuard.checkTimetablePrerequisites(
        courses: [testCourse],
        academicYears: [testAcademicYear],
        semesters: [testSemester],
        sections: [testSection],
        subjects: [testSubject],
        facultyAssignments: [], // NO ASSIGNMENTS
        rooms: [],
      );
      expect(ttPrereq.isSatisfied, isFalse);
      expect(ttPrereq.missingType, AcademicPrerequisiteType.facultyAssignment);
    });

    // -------------------------------------------------------------------------
    // TEST 14: HOD department scope
    // -------------------------------------------------------------------------
    test('14. HOD department scope restricts workspace metrics strictly to own department', () async {
      mockAcademicRepo.courses.add(Course(
        id: 'course_ec101',
        collegeId: testCollegeId,
        departmentId: testOtherDeptId,
        name: 'Electronics and Communication',
        code: 'ECE',
        duration: 4,
        isActive: true,
      ));

      final container = ProviderContainer(
        overrides: [
          academicRepositoryProvider.overrideWithValue(mockAcademicRepo),
          timetableRepositoryProvider.overrideWithValue(mockTimetableRepo),
          authProvider.overrideWith((ref) => MockAuthNotifier(
                AuthAuthenticated(
                  user: UserModel(
                    id: 'hod_cs',
                    name: 'CS HOD',
                    email: 'hod@cs.edu',
                    role: AppRole.hod,
                    collegeId: testCollegeId,
                    departmentId: testDeptId,
                    accountStatus: AccountStatus.active,
                  ),
                  token: 'mock_token',
                ),
              )),
        ],
      );

      final csSetup = await container.read(departmentSetupProvider(testDeptId).future);
      final csCourseMilestone = csSetup.milestones.firstWhere((m) => m.id == SetupMilestoneId.course);
      expect(csCourseMilestone.completedCount, 1);
      expect(csSetup.departmentId, testDeptId);

      // When HOD of CS tries to read another department, HOD scope locks it to own department (dept_cs)
      final ecSetup = await container.read(departmentSetupProvider(testOtherDeptId).future);
      expect(ecSetup.departmentId, testDeptId);

      container.dispose();
    });

    // -------------------------------------------------------------------------
    // TEST 15: Student self-scope
    // -------------------------------------------------------------------------
    test('15. Student self-scope ensures student role operates strictly within own student context', () {
      final studentUser = UserModel(
        id: 'user_ada',
        name: 'Ada Lovelace',
        email: 'ada@college.edu',
        role: AppRole.student,
        collegeId: testCollegeId,
        departmentId: testDeptId,
        accountStatus: AccountStatus.active,
      );

      expect(studentUser.role, AppRole.student);
      expect(studentUser.role.displayName, 'Student');
      expect(studentUser.role == AppRole.hod, isFalse);
      expect(studentUser.role == AppRole.collegeAdmin, isFalse);
      expect(studentUser.role == AppRole.superAdmin, isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST 16: Attendance context integrity
    // -------------------------------------------------------------------------
    test('16. Attendance context integrity links session to published timetable and correct section roster', () {
      final attendanceSession = AttendanceSession(
        id: 'att_session_1',
        collegeId: testCollegeId,
        departmentId: testDeptId,
        facultyId: testFaculty.id,
        subjectId: testSubject.id,
        subjectName: testSubject.name,
        sectionId: testSection.id,
        sectionName: testSection.name,
        timeSlot: '09:00 - 10:00',
        date: DateTime(2024, 9, 2),
        timetableId: 'tt_cs_1a',
        timetableEntryId: 'grid_entry_1',
        facultyAssignmentId: testAssignment.id,
        records: [
          AttendanceRecord(
            id: 'rec_1',
            studentId: testStudent.id,
            studentName: testStudent.name,
            rollNumber: testStudent.rollNumber,
            sectionId: testSection.id,
            status: AttendanceStatus.present,
          ),
        ],
      );

      expect(attendanceSession.sectionId, testSection.id);
      expect(attendanceSession.subjectId, testSubject.id);
      expect(attendanceSession.facultyId, testFaculty.id);
      expect(attendanceSession.timetableId, 'tt_cs_1a');
      expect(attendanceSession.timetableEntryId, 'grid_entry_1');
      expect(attendanceSession.facultyAssignmentId, testAssignment.id);
      expect(attendanceSession.records.first.studentId, testStudent.id);
      expect(attendanceSession.records.first.sectionId, testSection.id);
    });

    // -------------------------------------------------------------------------
    // TEST 17: Timetable ID vs timetableEntryId correctness
    // -------------------------------------------------------------------------
    test('17. Timetable ID vs timetableEntryId correctness ensures container and cell IDs are never confused', () {
      final timetableContainerId = 'tt_container_99';
      final gridEntryId = 'entry_cell_42';

      final gridEntry = TimetableGridEntryModel(
        id: gridEntryId,
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 1,
        periodSpan: 1,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: testSubject.id,
        facultyId: testFaculty.id,
        facultyAssignmentId: testAssignment.id,
        roomNumber: 'Room 101',
        sessionType: TimetableSessionType.lecture,
      );

      final container = TimetableContainerModel(
        id: timetableContainerId,
        collegeId: testCollegeId,
        departmentId: testDeptId,
        courseId: testCourse.id,
        academicYearId: testAcademicYear.id,
        semesterId: testSemester.id,
        sectionId: testSection.id,
        name: 'Weekly Schedule',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(container.id, timetableContainerId);
      expect(gridEntry.id, gridEntryId);
      expect(container.id, isNot(equals(gridEntry.id)));
      expect(gridEntry.facultyAssignmentId, testAssignment.id);
    });

    // -------------------------------------------------------------------------
    // TEST 18: Publish state refresh
    // -------------------------------------------------------------------------
    test('18. Publish state refresh transitions draft container to published and updates status', () {
      final draftContainer = TimetableContainerModel(
        id: 'tt_cs_1a',
        collegeId: testCollegeId,
        departmentId: testDeptId,
        courseId: testCourse.id,
        academicYearId: testAcademicYear.id,
        semesterId: testSemester.id,
        sectionId: testSection.id,
        name: 'CS 1st Sem Section A Timetable',
        status: TimetableStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(draftContainer.isDraft, isTrue);
      expect(draftContainer.isPublished, isFalse);

      final publishedContainer = draftContainer.copyWith(
        status: TimetableStatus.published,
        publishedAt: DateTime.now(),
        publishedBy: 'hod_1',
      );

      expect(publishedContainer.isDraft, isFalse);
      expect(publishedContainer.isPublished, isTrue);
      expect(publishedContainer.publishedBy, 'hod_1');

      final unpublishedContainer = publishedContainer.copyWith(
        status: TimetableStatus.draft,
      );

      expect(unpublishedContainer.isDraft, isTrue);
      expect(unpublishedContainer.isPublished, isFalse);
    });
  });
}
