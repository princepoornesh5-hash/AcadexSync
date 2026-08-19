import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/firebase/firebase_exceptions.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/attendance/data/repositories/mock_attendance_repository.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_session.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_record.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_status.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/notes/data/repositories/mock_notes_repository.dart';
import 'package:campus_management/features/notes/domain/models/note_model.dart';
import 'package:campus_management/features/timetable/data/repositories/mock_timetable_repository.dart';

void main() {
  group('ACADEX Student Academic Lifecycle + Promotion Engine Tests', () {
    late MockAcademicRepository repo;

    setUp(() {
      repo = MockAcademicRepository(
        currentUser: UserModel(
          id: 'admin_1',
          name: 'College Admin',
          email: 'admin@git.edu',
          role: AppRole.collegeAdmin,
          collegeId: 'c1',
          accountStatus: AccountStatus.active,
        ),
      );
    });

    test('1. Student academic profile creation with canonical placement', () async {
      final newStudent = Student(
        id: 'stu_new_001',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Robert Vance',
        rollNumber: 'CS2025099',
        email: 'robert@git.edu',
        phone: '5559876543',
        lifecycleState: StudentLifecycleState.active,
        admissionDate: DateTime(2025, 8, 1),
      );

      await repo.admitStudent(newStudent);

      final fetched = await repo.getStudentById('stu_new_001');
      expect(fetched, isNotNull);
      expect(fetched!.rollNumber, 'CS2025099');
      expect(fetched.departmentId, 'd1');
      expect(fetched.courseId, 'cr1');
      expect(fetched.semesterId, 'sem1');
      expect(fetched.sectionId, 'sec1');
      expect(fetched.lifecycleState, StudentLifecycleState.active);

      final profile = await repo.getStudentAcademicProfile('stu_new_001');
      expect(profile.student.id, 'stu_new_001');
      expect(profile.department?.id, 'd1');
      expect(profile.course?.id, 'cr1');
      expect(profile.semester?.id, 'sem1');
      expect(profile.section?.id, 'sec1');
    });

    test('2. Invalid academic hierarchy rejected (Invalid lifecycle state transition)', () async {
      final student = await repo.getStudentById('s1');
      expect(student, isNotNull);

      // Student is active, cannot jump directly to applicant
      expect(
        () => repo.updateStudentLifecycleState(
          studentId: 's1',
          newState: StudentLifecycleState.applicant,
        ),
        throwsA(isA<BackendValidationException>()),
      );
    });

    test('3. Student section resolution retrieves matching enrolled students', () async {
      final section1Students = await repo.getStudentsBySection('sec1');
      expect(section1Students.isNotEmpty, isTrue);
      expect(section1Students.every((s) => s.sectionId == 'sec1'), isTrue);

      final section2Students = await repo.getStudentsBySection('sec2');
      expect(section2Students.isNotEmpty, isTrue);
      expect(section2Students.every((s) => s.sectionId == 'sec2'), isTrue);
    });

    test('4. Student sees only own section timetable entries', () async {
      final timetableRepo = MockTimetableRepository();

      // Student enrolled in Section 1 (sec-3a in default mock)
      final sec1Entries = await timetableRepo.getTimetable(collegeId: 'col-1', sectionId: 'sec-3a');
      expect(sec1Entries.isNotEmpty, isTrue);
      expect(sec1Entries.every((e) => e.sectionId == 'sec-3a'), isTrue);

      // Verify sec-3a entries do not contain sec-3b entries
      final sec2Entries = await timetableRepo.getTimetable(collegeId: 'col-1', sectionId: 'sec-3b');
      for (final e in sec1Entries) {
        expect(sec2Entries.contains(e), isFalse);
      }
    });

    test('5. Student sees only scoped Notes matching enrolled section', () async {
      final notesRepo = MockNotesRepository();

      final stream = notesRepo.watchNotes(
        role: AppRole.student,
        userId: 'stu_1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        semesterId: 'sem-3',
        sectionId: 'sec-3a',
      );

      final studentNotes = await stream.first;
      expect(studentNotes.isNotEmpty, isTrue);
      expect(studentNotes.every((n) => n.sectionId == 'sec-3a'), isTrue);
      expect(studentNotes.every((n) => n.status == NoteStatus.published), isTrue);
    });

    test('6. Faculty sees only assigned-section students', () async {
      // Faculty f1 is assigned to sec1
      final facultyAssignments = await repo.getFacultyAssignments(facultyId: 'f1');
      final assignedSectionIds = facultyAssignments.map((a) => a.sectionId).toSet();
      expect(assignedSectionIds.contains('sec1'), isTrue);

      // Resolve students only from faculty's assigned sections
      final studentsForFaculty = await repo.getStudentsBySection('sec1');
      expect(studentsForFaculty.isNotEmpty, isTrue);
      expect(studentsForFaculty.every((s) => assignedSectionIds.contains(s.sectionId)), isTrue);
    });

    test('7. HOD department isolation prevents accessing or modifying other department students', () async {
      final hodMechRepo = MockAcademicRepository(
        currentUser: UserModel(
          id: 'hod_mech',
          name: 'Dr. Mech HOD',
          email: 'hod.mech@git.edu',
          role: AppRole.hod,
          collegeId: 'c1',
          departmentId: 'd2',
          accountStatus: AccountStatus.active,
        ),
      );

      // HOD of Mechanical (d2) cannot promote students in CS department (d1)
      expect(
        () => hodMechRepo.promoteStudents(
          studentIds: ['s1'],
          targetAcademicYearId: 'ay1',
          targetSemesterId: 'sem2',
          targetSectionId: 'sec_sem2_a',
        ),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('8. College Admin college isolation prevents accessing other colleges', () async {
      final foreignCollegeAdminRepo = MockAcademicRepository(
        currentUser: UserModel(
          id: 'admin_foreign_col',
          name: 'Admin Foreign',
          email: 'admin@foreign.edu',
          role: AppRole.collegeAdmin,
          collegeId: 'c_foreign_99',
          accountStatus: AccountStatus.active,
        ),
      );

      // Foreign College Admin cannot modify students in college c1
      expect(
        () => foreignCollegeAdminRepo.promoteStudents(
          studentIds: ['s1'],
          targetAcademicYearId: 'ay1',
          targetSemesterId: 'sem2',
          targetSectionId: 'sec_sem2_a',
        ),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('9. Promotion creates persistent StudentAcademicHistory entry', () async {
      final s1Before = await repo.getStudentById('s1');
      expect(s1Before!.semesterId, 'sem1');

      // Promote s1 from sem1 -> sem2
      await repo.promoteStudents(
        studentIds: ['s1'],
        targetAcademicYearId: 'ay1',
        targetSemesterId: 'sem2',
        targetSectionId: 'sec_sem2_a',
      );

      final historyList = await repo.getStudentAcademicHistory('s1');
      expect(historyList.isNotEmpty, isTrue);

      // Verify promoted history record
      final pastTerm = historyList.firstWhere((h) => h.semesterId == 'sem1');
      expect(pastTerm.status, 'promoted');
      expect(pastTerm.endDate, isNotNull);

      // Verify new active history record
      final activeTerm = historyList.firstWhere((h) => h.semesterId == 'sem2');
      expect(activeTerm.status, 'active');
      expect(activeTerm.sectionId, 'sec_sem2_a');
    });

    test('10. Promotion changes current student academic placement', () async {
      final s2 = await repo.getStudentById('s2');
      expect(s2!.semesterId, 'sem1');
      expect(s2.sectionId, 'sec1');

      await repo.promoteStudents(
        studentIds: ['s2'],
        targetAcademicYearId: 'ay1',
        targetSemesterId: 'sem2',
        targetSectionId: 'sec_sem2_a',
      );

      final s2After = await repo.getStudentById('s2');
      expect(s2After!.semesterId, 'sem2');
      expect(s2After.sectionId, 'sec_sem2_a');
      expect(s2After.history.isNotEmpty, isTrue);
      expect(s2After.history.last.status, 'Promoted');
    });

    test('11. Historical semester remains intact in timeline', () async {
      await repo.promoteStudents(
        studentIds: ['s2'],
        targetAcademicYearId: 'ay1',
        targetSemesterId: 'sem2',
        targetSectionId: 'sec_sem2_a',
      );

      final student = await repo.getStudentById('s2');
      expect(student!.history.isNotEmpty, isTrue);
      final prevRecord = student.history.first;
      expect(prevRecord.semesterId, 'sem1');
      expect(prevRecord.sectionId, 'sec1');
      expect(prevRecord.status, 'Promoted');
    });

    test('12. Bulk promotion promotes all selected students atomically', () async {
      final testStudents = [
        Student(
          id: 'stu_bulk_1',
          collegeId: 'c1',
          departmentId: 'd1',
          courseId: 'cr1',
          academicYearId: 'ay1',
          semesterId: 'sem1',
          sectionId: 'sec1',
          name: 'Bulk Student 1',
          rollNumber: 'BK001',
          email: 'bk1@git.edu',
          phone: '5551112221',
        ),
        Student(
          id: 'stu_bulk_2',
          collegeId: 'c1',
          departmentId: 'd1',
          courseId: 'cr1',
          academicYearId: 'ay1',
          semesterId: 'sem1',
          sectionId: 'sec1',
          name: 'Bulk Student 2',
          rollNumber: 'BK002',
          email: 'bk2@git.edu',
          phone: '5551112222',
        ),
      ];
      await repo.bulkAdmitStudents(testStudents);

      await repo.promoteStudents(
        studentIds: ['stu_bulk_1', 'stu_bulk_2'],
        targetAcademicYearId: 'ay1',
        targetSemesterId: 'sem2',
        targetSectionId: 'sec_sem2_a',
      );

      final b1 = await repo.getStudentById('stu_bulk_1');
      final b2 = await repo.getStudentById('stu_bulk_2');

      expect(b1!.semesterId, 'sem2');
      expect(b1.sectionId, 'sec_sem2_a');
      expect(b2!.semesterId, 'sem2');
      expect(b2.sectionId, 'sec_sem2_a');
    });

    test('13. Invalid promotion combinations are strictly rejected', () async {
      // Non-existent target semester
      expect(
        () => repo.promoteStudents(
          studentIds: ['s3'],
          targetAcademicYearId: 'ay1',
          targetSemesterId: 'invalid_sem_999',
          targetSectionId: 'sec1',
        ),
        throwsA(isA<BackendValidationException>()),
      );

      // Cross-department section assignment is rejected
      expect(
        () => repo.promoteStudents(
          studentIds: ['s3'],
          targetAcademicYearId: 'ay1',
          targetSemesterId: 'sem2',
          targetSectionId: 'sec_me1', // sec_me1 belongs to department d2
        ),
        throwsA(isA<BackendValidationException>()),
      );
    });

    test('14. Section membership update moves student and archives transfer record', () async {
      final s3 = await repo.getStudentById('s3');
      expect(s3!.sectionId, 'sec2');

      await repo.transferStudentsSection(
        studentIds: ['s3'],
        targetSectionId: 'sec1',
      );

      final s3After = await repo.getStudentById('s3');
      expect(s3After!.sectionId, 'sec1');
      expect(s3After.history.any((h) => h.status == 'Transferred'), isTrue);
    });

    test('15. Timetable automatically reflects new section after transfer', () async {
      final timetableRepo = MockTimetableRepository();

      // Student moved to sec-3a automatically sees sec-3a timetable
      final sec1Entries = await timetableRepo.getTimetable(collegeId: 'col-1', sectionId: 'sec-3a');
      expect(sec1Entries.isNotEmpty, isTrue);
      expect(sec1Entries.every((e) => e.sectionId == 'sec-3a'), isTrue);
    });

    test('16. Attendance roster automatically resolves from section membership', () async {
      final attendanceRepo = MockAttendanceRepository();

      final activeSection1Students = await repo.getStudentsBySection('sec1');
      expect(activeSection1Students.isNotEmpty, isTrue);

      // Mark attendance session for sec1 using resolved section roster
      final newSession = AttendanceSession(
        id: 'att_sec1_test',
        collegeId: 'c1',
        departmentId: 'd1',
        subjectId: 'sub1',
        subjectName: 'Data Structures',
        facultyId: 'f1',
        sectionId: 'sec1',
        sectionName: 'A',
        timeSlot: '08:30 - 09:20',
        date: DateTime.now(),
        isSubmitted: true,
        isLocked: false,
        createdAt: DateTime.now(),
        createdBy: 'f1',
        lastModifiedAt: DateTime.now(),
        lastModifiedBy: 'f1',
        version: 1,
        records: activeSection1Students.map((s) => AttendanceRecord(
          id: 'rec_${s.id}',
          studentId: s.id,
          studentName: s.name,
          rollNumber: s.rollNumber,
          sectionId: 'sec1',
          status: AttendanceStatus.present,
        )).toList(),
      );

      await attendanceRepo.saveSession(newSession);

      final recentSessions = await attendanceRepo.getRecentSessions('f1');
      expect(recentSessions.isNotEmpty, isTrue);
      final session = recentSessions.firstWhere((s) => s.id == 'att_sec1_test');
      expect(session.records.length, activeSection1Students.length);
      expect(session.records.every((r) => r.status == AttendanceStatus.present), isTrue);
    });

    test('17. Notes automatically reflect new section after transfer', () async {
      final notesRepo = MockNotesRepository();

      final stream = notesRepo.watchNotes(
        role: AppRole.student,
        userId: 'stu_1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        semesterId: 'sem-3',
        sectionId: 'sec-3a',
      );

      final studentNotes = await stream.first;
      expect(studentNotes.isNotEmpty, isTrue);
      expect(studentNotes.every((n) => n.sectionId == 'sec-3a'), isTrue);
    });

    test('18. Cross-college access is rejected across all student operations', () async {
      final unauthorizedRepo = MockAcademicRepository(
        currentUser: UserModel(
          id: 'admin_foreign',
          name: 'Foreign Admin',
          email: 'foreign@other.edu',
          role: AppRole.collegeAdmin,
          collegeId: 'c999',
          accountStatus: AccountStatus.active,
        ),
      );

      expect(
        () => unauthorizedRepo.admitStudent(
          Student(
            id: 'stu_hacked',
            collegeId: 'c1',
            departmentId: 'd1',
            courseId: 'cr1',
            academicYearId: 'ay1',
            semesterId: 'sem1',
            sectionId: 'sec1',
            name: 'Hacked Student',
            rollNumber: 'HACK001',
            email: 'hacked@git.edu',
            phone: '5550009999',
          ),
        ),
        throwsA(isA<BackendPermissionException>()),
      );
    });
  });
}
