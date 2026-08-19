import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/firebase/firebase_exceptions.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/data/repositories/mock_timetable_repository.dart';
import 'package:campus_management/features/notes/domain/models/note_model.dart';
import 'package:campus_management/features/notes/data/repositories/mock_notes_repository.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_session.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_record.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_status.dart';
import 'package:campus_management/features/attendance/data/repositories/mock_attendance_repository.dart';

void main() {
  group('College Academic Hierarchy + Assignment Engine Tests', () {
    late MockAcademicRepository repo;
    late UserModel superAdminUser;
    late UserModel collegeAdminUser;
    late UserModel hodUser;
    late UserModel facultyUser;
    late UserModel studentUser;

    setUp(() {
      superAdminUser = const UserModel(
        id: 'super_admin_1',
        email: 'superadmin@acadex.com',
        name: 'Global Super Admin',
        role: AppRole.superAdmin,
      );

      collegeAdminUser = const UserModel(
        id: 'college_admin_1',
        email: 'admin@git.edu',
        name: 'College Admin',
        role: AppRole.collegeAdmin,
        collegeId: 'c1',
      );

      hodUser = const UserModel(
        id: 'hod_1',
        email: 'hod.cs@git.edu',
        name: 'Prof. Alan Turing',
        role: AppRole.hod,
        collegeId: 'c1',
        departmentId: 'd1',
      );

      facultyUser = const UserModel(
        id: 'f1',
        email: 'alan@git.edu',
        name: 'Prof. Alan Turing',
        role: AppRole.faculty,
        collegeId: 'c1',
        departmentId: 'd1',
      );

      studentUser = const UserModel(
        id: 's1',
        email: 'john@student.git.edu',
        name: 'John Doe',
        role: AppRole.student,
        collegeId: 'c1',
        departmentId: 'd1',
        semesterId: 'sem1',
        sectionId: 'sec1',
      );

      repo = MockAcademicRepository(currentUser: collegeAdminUser);
    });

    test('1. College Admin can create a new Department', () async {
      final dept = Department(
        id: 'dept_ece',
        collegeId: 'c1',
        name: 'Electronics & Communication',
        code: 'ECE',
        hodId: '',
        description: 'Circuits and Embedded Systems',
        isActive: true,
      );

      await repo.addDepartment(dept);
      final depts = await repo.getDepartments();
      expect(depts.any((d) => d.id == 'dept_ece' && d.name == 'Electronics & Communication'), isTrue);
    });

    test('2. College Admin can assign HOD to a Department', () async {
      await repo.assignHodToDepartment('d1', 'f1');
      final depts = await repo.getDepartments();
      final dept = depts.firstWhere((d) => d.id == 'd1');
      expect(dept.hodId, equals('f1'));
    });

    test('3. Cannot assign HOD from another college', () async {
      final superRepo = MockAcademicRepository(currentUser: superAdminUser);
      await superRepo.addCollege(College(
        id: 'c2',
        name: 'Apex Institute of Technology',
        code: 'AIT',
        address: '456 Tech Park',
        email: 'info@ait.edu',
        phone: '1112223333',
        principal: 'Dr. Smith',
      ));
      await superRepo.addDepartment(Department(
        id: 'd_other',
        collegeId: 'c2',
        name: 'Aerospace Engineering',
        code: 'AERO',
        hodId: '',
        description: 'Flight dynamics',
      ));

      final facultyFromOtherCollege = Faculty(
        id: 'f_other',
        collegeId: 'c2', // Different college!
        departmentId: 'd_other',
        name: 'Prof. Other',
        employeeId: 'EMP999',
        email: 'other@other.edu',
        phone: '1112223333',
      );
      await superRepo.addFaculty(facultyFromOtherCollege);

      expect(
        () => superRepo.assignHodToDepartment('d1', 'f_other'),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('4. HOD can only operate within their own department', () async {
      final hodRepo = MockAcademicRepository(currentUser: hodUser);
      
      // HOD d1 tries to add course to d2 (Mechanical Engineering)
      final courseInOtherDept = Course(
        id: 'cr_invalid',
        collegeId: 'c1',
        departmentId: 'd2', // Not hodUser's department!
        name: 'Robotics',
        code: 'ME-ROB',
      );

      expect(
        () => hodRepo.addCourse(courseInOtherDept),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('5. HOD can assign Faculty to Subject + Section + Semester + Academic Year', () async {
      final assignment = FacultyAssignment(
        id: 'fa_new_1',
        collegeId: 'c1',
        departmentId: 'd1',
        facultyId: 'f1',
        facultyName: 'Prof. Alan Turing',
        courseId: 'cr1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        subjectId: 'sub1',
        academicYearId: 'ay1',
        isActive: true,
      );

      // Remove existing fa1 to avoid duplicate check
      await repo.removeFacultyAssignment('fa1');
      await repo.createFacultyAssignment(assignment);

      final assignments = await repo.getFacultyAssignments(facultyId: 'f1');
      expect(assignments.any((a) => a.id == 'fa_new_1' && a.subjectId == 'sub1' && a.sectionId == 'sec1'), isTrue);
    });

    test('6. Faculty assignment validates subject ownership / department scope', () async {
      // Create ECE subject
      final eceSubject = Subject(
        id: 'sub_ece_1',
        collegeId: 'c1',
        departmentId: 'd3', // CE or ECE department
        semesterId: 'sem1',
        name: 'Fluid Dynamics',
        code: 'CE101',
        credits: 3,
        type: 'Theory',
      );
      await repo.addSubject(eceSubject);

      // Try assigning CSE faculty (f1 in d1) to Civil Engineering subject (d3)
      final invalidAssignment = FacultyAssignment(
        id: 'fa_invalid',
        collegeId: 'c1',
        departmentId: 'd1',
        facultyId: 'f1',
        facultyName: 'Prof. Alan Turing',
        courseId: 'cr1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        subjectId: 'sub_ece_1', // belongs to d3!
        academicYearId: 'ay1',
        isActive: true,
      );

      expect(
        () => repo.createFacultyAssignment(invalidAssignment),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('7. Duplicate faculty assignment is strictly rejected', () async {
      final duplicateAssignment = FacultyAssignment(
        id: 'fa_dup',
        collegeId: 'c1',
        departmentId: 'd1',
        facultyId: 'f1',
        facultyName: 'Prof. Alan Turing',
        courseId: 'cr1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        subjectId: 'sub1',
        academicYearId: 'ay1',
        isActive: true,
      );

      // fa1 is already initialized in mock repo with f1, sub1, sec1, sem1, ay1
      expect(
        () => repo.createFacultyAssignment(duplicateAssignment),
        throwsA(isA<BackendValidationException>()),
      );
    });

    test('8. Students cannot perform academic mutations', () async {
      final studentRepo = MockAcademicRepository(currentUser: studentUser);

      final section = Section(
        id: 'sec_malicious',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem1',
        academicYearId: 'ay1',
        name: 'Hacked Section',
        capacity: 30,
        status: 'active',
      );

      expect(
        () => studentRepo.addSection(section),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('9. Faculty department transfer invalidates old assignments', () async {
      // f1 is in d1 with assignment fa1
      final initialAssignments = await repo.getFacultyAssignments(facultyId: 'f1');
      expect(initialAssignments.isNotEmpty, isTrue);

      // Transfer f1 from d1 to d2 (Mechanical Engineering)
      await repo.transferFacultyDepartment('f1', 'd2');

      final updatedFaculty = await repo.getFacultyById('f1');
      expect(updatedFaculty?.departmentId, equals('d2'));
      expect(updatedFaculty?.subjectIds, isEmpty);
      expect(updatedFaculty?.sectionIds, isEmpty);

      // Old assignments should now be inactive
      final postTransferAssignments = await repo.getFacultyAssignments(facultyId: 'f1');
      expect(postTransferAssignments.where((a) => a.departmentId == 'd1' && a.isActive), isEmpty);
    });

    test('10. Deactivating department checks dependencies (assignments & students)', () async {
      // d1 has active faculty assignments and students
      expect(
        () => repo.deactivateDepartment('d1'),
        throwsA(isA<BackendValidationException>()),
      );
    });

    test('11. Accurately calculates Department Student & Faculty counts', () async {
      final facCounts = await repo.getDepartmentFacultyCounts();
      final stuCounts = await repo.getDepartmentStudentCounts();

      expect(facCounts['d1'], greaterThanOrEqualTo(1));
      expect(stuCounts['d1'], greaterThanOrEqualTo(1));
    });

    test('12. Accurately generates Faculty Workload Summaries for HOD', () async {
      final workloadList = await repo.getFacultyWorkloadSummaries(departmentId: 'd1');
      expect(workloadList.isNotEmpty, isTrue);

      final alanWorkload = workloadList.firstWhere((w) => w.facultyId == 'f1');
      expect(alanWorkload.facultyName, contains('Alan Turing'));
      expect(alanWorkload.hasAttendanceResponsibility, isTrue);
      expect(alanWorkload.weeklyClasses, greaterThan(0));
    });

    test('13. Downstream Timetable integrates with Faculty Assignment', () async {
      final timetableRepo = MockTimetableRepository();
      
      // Faculty schedules class for assigned section
      final entry = TimetableModel(
        id: 'tt_1',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        subjectId: 'sub1',
        facultyId: 'f1',
        dayOfWeek: TimetableDay.monday,
        startTime: '09:00',
        endTime: '10:00',
        roomNumber: 'Lab 101',
        building: 'Main Block',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await timetableRepo.createEntry(entry);

      // Student s1 in sec1 watches timetable
      final studentStream = timetableRepo.watchTimetable(
        role: AppRole.student,
        userId: 's1',
        collegeId: 'c1',
        sectionId: 'sec1',
      );

      final studentTimetable = await studentStream.first;
      expect(studentTimetable.any((e) => e.subjectId == 'sub1' && e.sectionId == 'sec1'), isTrue);

      // Student in another section should not see this entry
      final otherSectionStream = timetableRepo.watchTimetable(
        role: AppRole.student,
        userId: 's3',
        collegeId: 'c1',
        sectionId: 'sec2',
      );

      final otherTimetable = await otherSectionStream.first;
      expect(otherTimetable.any((e) => e.subjectId == 'sub1' && e.sectionId == 'sec1'), isFalse);
    });

    test('14. Downstream Attendance integrates with Faculty Assignment & Student Section', () async {
      final attendanceRepo = MockAttendanceRepository();

      // Attendance session under sec1
      final session = AttendanceSession(
        id: 'att_sess_1',
        collegeId: 'c1',
        departmentId: 'd1',
        facultyId: 'f1',
        subjectId: 'sub1',
        subjectName: 'Data Structures',
        sectionId: 'sec1',
        sectionName: 'Section A',
        timeSlot: '09:00 - 10:00',
        date: DateTime.now(),
        isSubmitted: true,
        isLocked: false,
        createdAt: DateTime.now(),
        createdBy: 'f1',
        lastModifiedAt: DateTime.now(),
        lastModifiedBy: 'f1',
        version: 1,
        records: [
          AttendanceRecord(id: 'r1', studentId: 's1', studentName: 'John Doe', rollNumber: 'CS2025001', sectionId: 'sec1', status: AttendanceStatus.present),
          AttendanceRecord(id: 'r2', studentId: 's2', studentName: 'Jane Smith', rollNumber: 'CS2025002', sectionId: 'sec1', status: AttendanceStatus.absent),
        ],
      );

      await attendanceRepo.saveSession(session);

      // Faculty only sees their sessions
      final facultySessions = await attendanceRepo.getRecentSessions('f1');
      expect(facultySessions.any((s) => s.id == 'att_sess_1'), isTrue);

      // Student s1 in sec1 gets attendance record
      final studentHistory = await attendanceRepo.getStudentAttendanceHistory('s1');
      expect(studentHistory.any((r) => r.subjectId == 'sub1' && r.status == AttendanceStatus.present), isTrue);
    });

    test('15. Downstream Notes creation and student visibility matches assignment', () async {
      final assignment = FacultyAssignment(
        id: 'fa_os',
        collegeId: 'c1',
        departmentId: 'd1',
        facultyId: 'f1',
        facultyName: 'Alan Turing',
        courseId: 'cr1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        subjectId: 'sub1',
        academicYearId: 'ay1',
        isActive: true,
      );

      final notesRepo = MockNotesRepository(
        currentUser: facultyUser,
        assignments: [assignment],
      );

      // Faculty creates a note for assigned subject and section
      final note = NoteModel(
        id: 'note_ds_1',
        title: 'Binary Search Trees',
        description: 'Complete guide on BST operations.',
        content: 'A binary search tree is a rooted binary tree data structure...',
        resourceType: ResourceType.textNote,
        chapter: 'Trees',
        subjectId: 'sub1',
        sectionId: 'sec1',
        courseId: 'cr1',
        departmentId: 'd1',
        collegeId: 'c1',
        semesterId: 'sem1',
        facultyId: 'f1',
        authorUserId: 'f1',
        status: NoteStatus.published,
        publishedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await notesRepo.createNote(note);

      // Student s1 (in c1, d1, sem1, sec1) streams notes
      final studentNotesStream = notesRepo.watchNotes(
        role: AppRole.student,
        userId: 's1',
        collegeId: 'c1',
        departmentId: 'd1',
        semesterId: 'sem1',
        sectionId: 'sec1',
      );

      final studentNotes = await studentNotesStream.first;
      expect(studentNotes.any((n) => n.id == 'note_ds_1'), isTrue);

      // Student in sec2 should not receive notes targetted strictly at sec1
      final otherStudentNotesStream = notesRepo.watchNotes(
        role: AppRole.student,
        userId: 's2',
        collegeId: 'c1',
        departmentId: 'd1',
        semesterId: 'sem1',
        sectionId: 'sec2',
      );

      final otherNotes = await otherStudentNotesStream.first;
      expect(otherNotes.any((n) => n.id == 'note_ds_1' && n.sectionId == 'sec1'), isFalse);
    });

    test('16. Super Admin boundary enforcement', () async {
      // Super admin manages colleges
      final superRepo = MockAcademicRepository(currentUser: superAdminUser);

      final newCollege = College(
        id: 'col_global_2',
        name: 'National Tech University',
        code: 'NTU',
        address: '500 Campus Blvd',
        email: 'admin@ntu.edu',
        phone: '1234567890',
        principal: 'Dr. Watson',
      );

      await superRepo.addCollege(newCollege);
      final colleges = await superRepo.getColleges();
      expect(colleges.any((c) => c.id == 'col_global_2'), isTrue);

      // College admin cannot add new colleges (platform boundary)
      final collegeAdminRepo = MockAcademicRepository(currentUser: collegeAdminUser);
      expect(
        () => collegeAdminRepo.addCollege(College(
          id: 'col_unauthorized',
          name: 'Unauthorized College',
          code: 'UC',
          address: 'No where',
          email: 'bad@bad.com',
          phone: '000',
          principal: 'None',
        )),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('17. Full End-to-End Hierarchy Workflow Test', () async {
      // 1. College Admin creates Department: CSE
      final cseDept = Department(
        id: 'dept_cse_flow',
        collegeId: 'c1',
        name: 'Computer Science & Engineering',
        code: 'CSE',
        hodId: '',
        description: 'Software & Algorithms',
      );
      await repo.addDepartment(cseDept);

      // 2. College Admin creates Course: DCME
      final dcmeCourse = Course(
        id: 'crs_dcme_flow',
        collegeId: 'c1',
        departmentId: 'dept_cse_flow',
        name: 'Diploma in CME',
        code: 'DCME',
      );
      await repo.addCourse(dcmeCourse);

      // 3. College Admin creates Academic Year & Semester: 3rd Sem
      final ay = AcademicYear(
        id: 'ay_2026_flow',
        collegeId: 'c1',
        name: '2026-2027',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2027, 7, 31),
        status: 'active',
        isCurrent: true,
      );
      await repo.addAcademicYear(ay);

      final sem3 = Semester(
        id: 'sem_3_flow',
        collegeId: 'c1',
        departmentId: 'dept_cse_flow',
        courseId: 'crs_dcme_flow',
        academicYearId: 'ay_2026_flow',
        name: '3rd Semester',
        number: 3,
        status: 'active',
        isCurrent: true,
      );
      await repo.addSemester(sem3);

      // 4. College Admin creates Section: A
      final secA = Section(
        id: 'sec_a_flow',
        collegeId: 'c1',
        departmentId: 'dept_cse_flow',
        courseId: 'crs_dcme_flow',
        academicYearId: 'ay_2026_flow',
        semesterId: 'sem_3_flow',
        name: 'A',
        capacity: 60,
        status: 'active',
      );
      await repo.addSection(secA);

      // 5. College Admin creates Subject: Java Programming
      final javaSubject = Subject(
        id: 'sub_java_flow',
        collegeId: 'c1',
        departmentId: 'dept_cse_flow',
        semesterId: 'sem_3_flow',
        name: 'Java Programming',
        code: 'CS301',
        credits: 4,
        type: 'Theory',
      );
      await repo.addSubject(javaSubject);

      // 6. College Admin creates Faculty: Ravi Kumar
      final raviFaculty = Faculty(
        id: 'fac_ravi_flow',
        collegeId: 'c1',
        departmentId: 'dept_cse_flow',
        name: 'Ravi Kumar',
        employeeId: 'EMP_RAVI',
        email: 'ravi@git.edu',
        phone: '9876543299',
      );
      await repo.addFaculty(raviFaculty);

      // 7. Assign Ravi Kumar to Java + DCME + 3rd Sem + Section A
      final assignment = FacultyAssignment(
        id: 'fa_ravi_java',
        collegeId: 'c1',
        departmentId: 'dept_cse_flow',
        facultyId: 'fac_ravi_flow',
        facultyName: 'Ravi Kumar',
        courseId: 'crs_dcme_flow',
        semesterId: 'sem_3_flow',
        sectionId: 'sec_a_flow',
        subjectId: 'sub_java_flow',
        academicYearId: 'ay_2026_flow',
        isActive: true,
      );
      await repo.createFacultyAssignment(assignment);

      // 8. Create Student: Poornesh & assign placement
      final poorneshStudent = Student(
        id: 'stu_poornesh_flow',
        collegeId: 'c1',
        departmentId: 'dept_cse_flow',
        courseId: 'crs_dcme_flow',
        academicYearId: 'ay_2026_flow',
        semesterId: 'sem_3_flow',
        sectionId: 'sec_a_flow',
        name: 'Poornesh',
        rollNumber: 'DCME2026001',
        email: 'poornesh@student.git.edu',
        phone: '9988776655',
      );
      await repo.admitStudent(poorneshStudent);

      // 9. Verify Ravi Kumar sees his assignment
      final raviAssignments = await repo.getFacultyAssignments(facultyId: 'fac_ravi_flow');
      expect(raviAssignments.any((a) => a.subjectId == 'sub_java_flow' && a.sectionId == 'sec_a_flow'), isTrue);

      // 10. Verify Poornesh Academic Profile resolves completely
      final poorneshProfile = await repo.getStudentAcademicProfile('stu_poornesh_flow');
      expect(poorneshProfile.student.name, equals('Poornesh'));
      expect(poorneshProfile.department?.name, equals('Computer Science & Engineering'));
      expect(poorneshProfile.course?.code, equals('DCME'));
      expect(poorneshProfile.semester?.name, equals('3rd Semester'));
      expect(poorneshProfile.section?.name, equals('A'));
    });
  });
}
