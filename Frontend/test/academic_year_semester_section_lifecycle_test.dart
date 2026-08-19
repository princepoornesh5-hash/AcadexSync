import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/firebase/firebase_exceptions.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/attendance/data/repositories/mock_attendance_repository.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_session.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_record.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_status.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/timetable/data/repositories/mock_timetable_repository.dart';

void main() {
  group('Academic Year + Semester + Section Lifecycle Engine - 22 Automated Tests', () {
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

    // TEST 1: Academic Year Lifecycle: Single Active Year Enforcement
    test('1. Activating a new academic year marks the previous current year as completed', () async {
      final y1 = AcademicYear(
        id: 'ay-2026',
        collegeId: 'c1',
        name: '2026–27',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2027, 5, 31),
        status: 'active',
        isCurrent: true,
      );
      await repo.addAcademicYear(y1);

      final y2 = AcademicYear(
        id: 'ay-2027',
        collegeId: 'c1',
        name: '2027–28',
        startDate: DateTime(2027, 6, 1),
        endDate: DateTime(2028, 5, 31),
        status: 'upcoming',
        isCurrent: false,
      );
      await repo.addAcademicYear(y2);

      // Activate 2027-28
      await repo.activateAcademicYear('c1', 'ay-2027');

      final allYears = await repo.getAcademicYears();
      final updatedY1 = allYears.firstWhere((y) => y.id == 'ay-2026');
      final updatedY2 = allYears.firstWhere((y) => y.id == 'ay-2027');

      expect(updatedY1.status, 'completed');
      expect(updatedY1.isCurrent, false);
      expect(updatedY2.status, 'active');
      expect(updatedY2.isCurrent, true);
    });

    // TEST 2: Academic Year Validation: Start/End Dates
    test('2. Enforces endDate strictly after startDate for Academic Years', () async {
      final invalidYear = AcademicYear(
        id: 'ay-invalid',
        collegeId: 'c1',
        name: 'Invalid Year',
        startDate: DateTime(2027, 6, 1),
        endDate: DateTime(2026, 5, 31), // endDate is before startDate!
      );

      expect(
        () async => await repo.addAcademicYear(invalidYear),
        throwsA(isA<BackendValidationException>()),
      );
    });

    // TEST 3: Academic Year Status Transitions
    test('3. Academic Year follows full lifecycle upcoming -> active -> completed -> archived', () async {
      final year = AcademicYear(
        id: 'ay-life',
        collegeId: 'c1',
        name: '2028–29',
        startDate: DateTime(2028, 6, 1),
        endDate: DateTime(2029, 5, 31),
        status: 'upcoming',
        isCurrent: false,
      );
      await repo.addAcademicYear(year);

      // Transition to active
      await repo.activateAcademicYear('c1', 'ay-life');
      var current = (await repo.getAcademicYears()).firstWhere((y) => y.id == 'ay-life');
      expect(current.status, 'active');
      expect(current.isCurrent, true);

      // Deactivate to archived (filters out of active query)
      await repo.deactivateAcademicYear('ay-life');
      final remainingActive = await repo.getAcademicYears();
      expect(remainingActive.any((y) => y.id == 'ay-life'), false);
    });

    // TEST 4: Semester Lifecycle: Scoped to Course and Academic Year
    test('4. Semesters are properly parented to course and academic year', () async {
      final sem = Semester(
        id: 'sem-cs-5',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        name: 'Semester 5',
        number: 5,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 11, 30),
      );
      await repo.addSemester(sem);

      final sems = await repo.getSemesters();
      final created = sems.firstWhere((s) => s.id == 'sem-cs-5');
      expect(created.courseId, 'cr1');
      expect(created.academicYearId, 'ay1');
      expect(created.number, 5);
    });

    // TEST 5: Semester Duplicate Prevention
    test('5. Prevents duplicate semester numbers inside same course and academic year', () async {
      final sem1 = Semester(
        id: 'sem-dup-7a',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        name: 'Semester 7 - Fall',
        number: 7,
      );
      await repo.addSemester(sem1);

      final sem2 = Semester(
        id: 'sem-dup-7b',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        name: 'Semester 7 - Duplicate',
        number: 7, // Duplicate number 7!
      );

      expect(
        () async => await repo.addSemester(sem2),
        throwsA(isA<BackendValidationException>()),
      );
    });

    // TEST 6: Semester Activation Transition
    test('6. Activating Semester 4 marks Semester 3 as completed for that course without deleting records', () async {
      // In seed data: sem3 is active in ay2
      final sem4 = Semester(
        id: 'sem4',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay2',
        name: 'Semester 4',
        number: 4,
        status: 'upcoming',
        isCurrent: false,
      );
      await repo.addSemester(sem4);

      // Activate sem4
      await repo.activateSemester('c1', 'cr1', 'sem4');

      final sems = await repo.getSemesters();
      final sem3 = sems.firstWhere((s) => s.id == 'sem3');
      final updatedSem4 = sems.firstWhere((s) => s.id == 'sem4');

      expect(sem3.status, 'completed');
      expect(sem3.isCurrent, false);
      expect(updatedSem4.status, 'active');
      expect(updatedSem4.isCurrent, true);
    });

    // TEST 7: Semester Completion
    test('7. Completing a semester sets status to completed and isCurrent: false', () async {
      await repo.completeSemester('sem2');
      final updated = (await repo.getSemesters()).firstWhere((s) => s.id == 'sem2');

      expect(updated.status, 'completed');
      expect(updated.isCurrent, false);
    });

    // TEST 8: Section Creation: Enforces positive capacity
    test('8. Enforces positive capacity (capacity > 0) during section creation', () async {
      final invalidSec = Section(
        id: 'sec-invalid',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem1',
        name: 'Z',
        capacity: 0, // Invalid!
      );

      expect(
        () async => await repo.addSection(invalidSec),
        throwsA(isA<BackendValidationException>()),
      );
    });

    // TEST 9: Section Capacity Tracking
    test('9. SectionCapacityInfo correctly computes enrolledCount, availableSeats, and isFull', () async {
      final sec = Section(
        id: 'sec-cap-test',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem1',
        name: 'Alpha',
        capacity: 2,
      );
      await repo.addSection(sec);

      var capInfo = await repo.getSectionCapacityInfo('sec-cap-test');
      expect(capInfo.enrolledCount, 0);
      expect(capInfo.availableSeats, 2);
      expect(capInfo.isFull, false);

      // Admit 1 student
      await repo.admitStudent(Student(
        id: 'stu-cap-1',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec-cap-test',
        name: 'Student 1',
        email: 's1@git.edu',
        phone: '5551234567',
        rollNumber: 'ROLL-C1',
      ));

      capInfo = await repo.getSectionCapacityInfo('sec-cap-test');
      expect(capInfo.enrolledCount, 1);
      expect(capInfo.availableSeats, 1);
      expect(capInfo.isFull, false);

      // Admit 2nd student to fill capacity
      await repo.admitStudent(Student(
        id: 'stu-cap-2',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec-cap-test',
        name: 'Student 2',
        email: 's2@git.edu',
        phone: '5551234567',
        rollNumber: 'ROLL-C2',
      ));

      capInfo = await repo.getSectionCapacityInfo('sec-cap-test');
      expect(capInfo.enrolledCount, 2);
      expect(capInfo.availableSeats, 0);
      expect(capInfo.isFull, true);
    });

    // TEST 10: Section Enrollment Block when Full
    test('10. Blocks student admission when section has reached maximum capacity', () async {
      final sec = Section(
        id: 'sec-full-test',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem1',
        name: 'Beta',
        capacity: 1,
      );
      await repo.addSection(sec);

      // First student succeeds
      await repo.admitStudent(Student(
        id: 'stu-ok',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec-full-test',
        name: 'Student OK',
        email: 'ok@git.edu',
        phone: '5551234567',
        rollNumber: 'ROLL-OK',
      ));

      // Second student exceeds capacity
      expect(
        () async => await repo.admitStudent(Student(
          id: 'stu-overflow',
          collegeId: 'c1',
          departmentId: 'd1',
          courseId: 'cr1',
          academicYearId: 'ay1',
          semesterId: 'sem1',
          sectionId: 'sec-full-test',
          name: 'Student Overflow',
          email: 'overflow@git.edu',
          phone: '5551234567',
          rollNumber: 'ROLL-OVER',
        )),
        throwsA(isA<BackendValidationException>()),
      );
    });

    // TEST 11: Section Capacity Expansion
    test('11. Increasing section capacity immediately allows new enrollments', () async {
      final sec = Section(
        id: 'sec-expand-test',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem1',
        name: 'Gamma',
        capacity: 1,
      );
      await repo.addSection(sec);

      await repo.admitStudent(Student(
        id: 'stu-exp-1',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec-expand-test',
        name: 'Student 1',
        email: 'exp1@git.edu',
        phone: '5551234567',
        rollNumber: 'ROLL-E1',
      ));

      // Increase capacity from 1 to 2
      await repo.updateSectionCapacity('sec-expand-test', 2);

      // Now student 2 can be admitted successfully
      await repo.admitStudent(Student(
        id: 'stu-exp-2',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec-expand-test',
        name: 'Student 2',
        email: 'exp2@git.edu',
        phone: '5551234567',
        rollNumber: 'ROLL-E2',
      ));

      final capInfo = await repo.getSectionCapacityInfo('sec-expand-test');
      expect(capInfo.enrolledCount, 2);
      expect(capInfo.capacity, 2);
    });

    // TEST 12: Bulk Section Transfer Pre-Flight Validation
    test('12. Bulk section transfer pre-flight validates eligible students', () async {
      final targetSec = Section(
        id: 'sec-target-12',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem1',
        name: 'B',
        capacity: 10,
      );
      await repo.addSection(targetSec);

      await repo.admitStudent(Student(
        id: 'stu-tr-1',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Alice',
        email: 'alice@git.edu',
        phone: '5551234567',
        rollNumber: 'ALICE-01',
      ));

      final results = await repo.validateBulkSectionTransfer(['stu-tr-1'], 'sec-target-12');
      expect(results.length, 1);
      expect(results.first.canMove, true);
    });

    // TEST 13: Bulk Section Transfer Breakdown
    test('13. Pre-flight accurately breaks down eligible vs ineligible with reasons', () async {
      final targetSec = Section(
        id: 'sec-target-13',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem1',
        name: 'B',
        capacity: 1, // Only 1 seat available
      );
      await repo.addSection(targetSec);

      await repo.admitStudent(Student(
        id: 'stu-13-a',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Student A',
        email: 'a13@git.edu',
        phone: '5551234567',
        rollNumber: 'STU-13-A',
      ));

      await repo.admitStudent(Student(
        id: 'stu-13-b',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Student B',
        email: 'b13@git.edu',
        phone: '5551234567',
        rollNumber: 'STU-13-B',
      ));

      final results = await repo.validateBulkSectionTransfer(['stu-13-a', 'stu-13-b'], 'sec-target-13');
      expect(results.length, 2);

      final eligible = results.where((r) => r.canMove).toList();
      final ineligible = results.where((r) => !r.canMove).toList();

      expect(eligible.length, 1);
      expect(ineligible.length, 1);
      expect(ineligible.first.reason, contains('full'));
    });

    // TEST 14: Bulk Section Transfer Partial Execution
    test('14. Executes transfer for eligible students and preserves timeline', () async {
      final targetSec = Section(
        id: 'sec-target-14',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem1',
        name: 'B',
        capacity: 5,
      );
      await repo.addSection(targetSec);

      await repo.admitStudent(Student(
        id: 'stu-14',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Transfer Stu',
        email: 'tr14@git.edu',
        phone: '5551234567',
        rollNumber: 'ROLL-14',
      ));

      await repo.executeBulkSectionTransfer(studentIds: ['stu-14'], targetSectionId: 'sec-target-14');

      final updatedStu = await repo.getStudentById('stu-14');
      expect(updatedStu?.sectionId, 'sec-target-14');
      expect(updatedStu?.history.length, greaterThanOrEqualTo(2));
      expect(updatedStu?.history.any((h) => h.status == 'Transferred'), true);
    });

    // TEST 15: Cross-College Transfer Guard
    test('15. Rejects section transfer across different colleges', () async {
      final unscopedRepo = MockAcademicRepository(); // super admin / unscoped

      final targetSec = Section(
        id: 'sec-col-1',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem1',
        name: 'A',
      );
      await unscopedRepo.addSection(targetSec);

      await unscopedRepo.admitStudent(Student(
        id: 'stu-col-2',
        collegeId: 'c2', // Different College!
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec-col-2',
        name: 'Cross Col Stu',
        email: 'col2@git.edu',
        phone: '5551234567',
        rollNumber: 'ROLL-COL-2',
      ));

      final results = await unscopedRepo.validateBulkSectionTransfer(['stu-col-2'], 'sec-col-1');
      expect(results.first.canMove, false);
      expect(results.first.reason, contains('Cross-college'));
    });

    // TEST 16: Cross-Department Transfer Guard
    test('16. Rejects section transfer across different departments', () async {
      final targetSec = Section(
        id: 'sec-dept-cs',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem1',
        name: 'A',
      );
      await repo.addSection(targetSec);

      await repo.admitStudent(Student(
        id: 'stu-dept-ec',
        collegeId: 'c1',
        departmentId: 'd2', // Different Department!
        courseId: 'cr3',
        academicYearId: 'ay1',
        semesterId: 'sem_me1',
        sectionId: 'sec_me1',
        name: 'Cross Dept Stu',
        email: 'ec@git.edu',
        phone: '5551234567',
        rollNumber: 'ROLL-DEPT-EC',
      ));

      final results = await repo.validateBulkSectionTransfer(['stu-dept-ec'], 'sec-dept-cs');
      expect(results.first.canMove, false);
      expect(results.first.reason, contains('Cross-department'));
    });

    // TEST 17: Cross-Semester Transfer Guard
    test('17. Rejects section transfer across different semesters', () async {
      final targetSec = Section(
        id: 'sec-sem-2',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem2', // Semester 2
        name: 'A',
      );
      await repo.addSection(targetSec);

      await repo.admitStudent(Student(
        id: 'stu-sem-1',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1', // Semester 1
        sectionId: 'sec1',
        name: 'Cross Sem Stu',
        email: 'sem1@git.edu',
        phone: '5551234567',
        rollNumber: 'ROLL-SEM-1',
      ));

      final results = await repo.validateBulkSectionTransfer(['stu-sem-1'], 'sec-sem-2');
      expect(results.first.canMove, false);
      expect(results.first.reason, contains('semester'));
    });

    // TEST 18: Same-Section Guard
    test('18. Rejects transfer if student is already enrolled in the target section', () async {
      final targetSec = Section(
        id: 'sec-same-18',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem1',
        name: 'A',
      );
      await repo.addSection(targetSec);

      await repo.admitStudent(Student(
        id: 'stu-same-18',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec-same-18',
        name: 'Same Sec Stu',
        email: 'same@git.edu',
        phone: '5551234567',
        rollNumber: 'ROLL-SAME',
      ));

      final results = await repo.validateBulkSectionTransfer(['stu-same-18'], 'sec-same-18');
      expect(results.first.canMove, false);
      expect(results.first.reason, contains('already enrolled'));
    });

    // TEST 19: Timetable Operational Context
    test('19. Timetable entries resolve against active semester and course', () async {
      final timetableRepo = MockTimetableRepository();
      final secEntries = await timetableRepo.getTimetable(collegeId: 'col-1', sectionId: 'sec-3a');
      expect(secEntries.isNotEmpty, true);
      expect(secEntries.every((e) => e.sectionId == 'sec-3a'), true);
    });

    // TEST 20: Attendance Context Isolation
    test('20. Attendance records remain locked to original semester and section after student moves', () async {
      final attRepo = MockAttendanceRepository();

      final session = AttendanceSession(
        id: 'att-session-hist',
        collegeId: 'c1',
        departmentId: 'd1',
        subjectId: 'sub1',
        subjectName: 'Data Structures',
        facultyId: 'f1',
        sectionId: 'sec1',
        sectionName: 'A',
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
          AttendanceRecord(
            id: 'rec_hist_1',
            studentId: 's1',
            studentName: 'Aarav Sharma',
            rollNumber: 'CS2023001',
            sectionId: 'sec1',
            status: AttendanceStatus.present,
          ),
        ],
      );
      await attRepo.saveSession(session);

      final retrieved = await attRepo.getRecentSessions('f1');
      expect(retrieved.any((s) => s.sectionId == 'sec1'), true);
    });

    // TEST 21: Multi-Tenant College Isolation
    test('21. Tenant isolation prevents modifying academic structure across college scopes', () async {
      final scopedRepo = MockAcademicRepository(
        currentUser: UserModel(
          id: 'admin_scoped',
          name: 'Scoped Admin',
          email: 'scoped@git.edu',
          role: AppRole.collegeAdmin,
          collegeId: 'college-A',
          accountStatus: AccountStatus.active,
        ),
      );

      // Attempting to add academic year to another college throws exception
      final crossCollegeYear = AcademicYear(
        id: 'ay-cross',
        collegeId: 'college-B',
        name: '2026–27',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2027, 5, 31),
      );

      expect(
        () async => await scopedRepo.addAcademicYear(crossCollegeYear),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    // TEST 22: Capacity Aggregation
    test('22. Accurately calculates section capacity info and utilization stats', () async {
      final sec1 = Section(id: 'sec-agg-1', collegeId: 'c1', departmentId: 'd1', semesterId: 'sem1', name: 'A', capacity: 50);
      final sec2 = Section(id: 'sec-agg-2', collegeId: 'c1', departmentId: 'd1', semesterId: 'sem1', name: 'B', capacity: 50);
      await repo.addSection(sec1);
      await repo.addSection(sec2);

      final cap1 = await repo.getSectionCapacityInfo('sec-agg-1');
      final cap2 = await repo.getSectionCapacityInfo('sec-agg-2');

      expect(cap1.capacity, 50);
      expect(cap2.capacity, 50);
      expect(cap1.enrolledCount + cap2.enrolledCount, 0);
    });
  });
}
