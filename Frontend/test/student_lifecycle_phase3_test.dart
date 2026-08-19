import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/core/firebase/firebase_exceptions.dart';

void main() {
  group('ACADEX Phase 3: Student Lifecycle Management Tests', () {
    late MockAcademicRepository repo;

    setUp(() {
      repo = MockAcademicRepository();
    });

    test('1. Student admission creates student, auto-generates roll number, and seeds initial timeline', () async {
      final generatedRoll = await repo.generateRollNumber('c1', 'cr1', 'ay1');
      expect(generatedRoll, isNotEmpty);
      expect(generatedRoll, contains('CS-'));

      final newStudent = Student(
        id: 'stu_new_1',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Grace Hopper',
        rollNumber: generatedRoll,
        email: 'grace@hopper.edu',
        phone: '1234567890',
        lifecycleState: StudentLifecycleState.admitted,
      );

      await repo.admitStudent(newStudent);

      final fetched = await repo.getStudentById('stu_new_1');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Grace Hopper'));
      expect(fetched.rollNumber, equals(generatedRoll));
      expect(fetched.lifecycleState, equals(StudentLifecycleState.admitted));
      expect(fetched.isActive, isTrue);
      expect(fetched.history.length, equals(1));
      expect(fetched.history.first.status, equals('Admitted'));
      expect(fetched.history.first.semesterId, equals('sem1'));
      expect(fetched.history.first.sectionId, equals('sec1'));
    });

    test('2. Automatic enrollment inherits faculty, subjects, and academic profile without duplicate mapping', () async {
      // First ensure student is admitted
      final student = Student(
        id: 'stu_enroll_test',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Ada Lovelace',
        rollNumber: 'CS-2026-099',
        email: 'ada@lovelace.edu',
        phone: '9876543210',
        lifecycleState: StudentLifecycleState.active,
      );
      await repo.admitStudent(student);

      final profile = await repo.getStudentAcademicProfile('stu_enroll_test');
      expect(profile, isNotNull);
      expect(profile.student.name, equals('Ada Lovelace'));
      expect(profile.department?.id, equals('d1'));
      expect(profile.course?.id, equals('cr1'));
      expect(profile.semester?.id, equals('sem1'));
      expect(profile.section?.id, equals('sec1'));
      expect(profile.enrolledSubjects, isNotEmpty);
      expect(profile.assignedFaculty, isNotEmpty);
      expect(profile.assignedFaculty.any((f) => f.name.contains('Alan Turing')), isTrue);
    });

    test('3. Student promotion advances semester and section while immutably preserving academic history', () async {
      final student = Student(
        id: 'stu_promo_test',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Claude Shannon',
        rollNumber: 'CS-2026-101',
        email: 'claude@shannon.edu',
        phone: '1122334455',
        lifecycleState: StudentLifecycleState.active,
      );
      await repo.admitStudent(student);

      // Promote to Semester 2, Section B
      await repo.promoteStudents(
        studentIds: ['stu_promo_test'],
        targetAcademicYearId: 'ay2',
        targetSemesterId: 'sem2',
        targetSectionId: 'sec2',
      );

      final promoted = await repo.getStudentById('stu_promo_test');
      expect(promoted, isNotNull);
      expect(promoted!.semesterId, equals('sem2'));
      expect(promoted.sectionId, equals('sec2'));
      expect(promoted.academicYearId, equals('ay2'));
      expect(promoted.lifecycleState, equals(StudentLifecycleState.active));
      
      // Check history preservation
      expect(promoted.history.length, equals(2));
      expect(promoted.history.first.status, equals('Admitted'));
      expect(promoted.history.last.status, equals('Promoted'));
      expect(promoted.history.last.semesterId, equals('sem1'));
      expect(promoted.history.last.sectionId, equals('sec1'));
    });

    test('4. Cross-department promotion is strictly prohibited', () async {
      final student = Student(
        id: 'stu_cross_dept',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Nikola Tesla',
        rollNumber: 'CS-2026-102',
        email: 'nikola@tesla.edu',
        phone: '9988776655',
      );
      await repo.admitStudent(student);

      // Attempt to promote into Mechanical Dept semester (d2)
      expect(
        () => repo.promoteStudents(
          studentIds: ['stu_cross_dept'],
          targetAcademicYearId: 'ay1',
          targetSemesterId: 'sem_me1', // sem_me1 is d2
          targetSectionId: 'sec_me1',
        ),
        throwsA(isA<BackendValidationException>()),
      );
    });

    test('5. Section transfer updates section and logs transfer milestone without overwriting history', () async {
      final student = Student(
        id: 'stu_transfer_test',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Katherine Johnson',
        rollNumber: 'CS-2026-103',
        email: 'katherine@johnson.edu',
        phone: '4455667788',
      );
      await repo.admitStudent(student);

      await repo.transferStudentsSection(
        studentIds: ['stu_transfer_test'],
        targetSectionId: 'sec2',
      );

      final transferred = await repo.getStudentById('stu_transfer_test');
      expect(transferred, isNotNull);
      expect(transferred!.sectionId, equals('sec2'));
      expect(transferred.history.length, equals(2));
      expect(transferred.history.last.status, equals('Transferred'));
      expect(transferred.history.last.sectionId, equals('sec1'));
    });

    test('6. Graduation locks active state, updates graduation date, and moves student to Alumni', () async {
      final student = Student(
        id: 'stu_grad_test',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'ay1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Margaret Hamilton',
        rollNumber: 'CS-2026-104',
        email: 'margaret@hamilton.edu',
        phone: '7788990011',
        lifecycleState: StudentLifecycleState.active,
      );
      await repo.admitStudent(student);

      await repo.bulkGraduateStudents(studentIds: ['stu_grad_test'], remarks: 'Graduated with honors');

      final graduated = await repo.getStudentById('stu_grad_test');
      expect(graduated, isNotNull);
      expect(graduated!.lifecycleState, equals(StudentLifecycleState.graduated));
      expect(graduated.isActive, isFalse);
      expect(graduated.graduationDate, isNotNull);
      expect(graduated.history.last.status, equals('Graduated'));

      // Move from graduated to alumni
      await repo.bulkArchiveAlumni(studentIds: ['stu_grad_test']);
      final alumni = await repo.getStudentById('stu_grad_test');
      expect(alumni!.lifecycleState, equals(StudentLifecycleState.alumni));
      expect(alumni.history.last.status, equals('Alumni'));
    });

    test('7. State Machine: Valid transitions succeed and invalid transitions are rejected', () async {
      expect(StudentLifecycleState.applicant.isValidTransition(StudentLifecycleState.admitted), isTrue);
      expect(StudentLifecycleState.admitted.isValidTransition(StudentLifecycleState.active), isTrue);
      expect(StudentLifecycleState.active.isValidTransition(StudentLifecycleState.onLeave), isTrue);
      expect(StudentLifecycleState.active.isValidTransition(StudentLifecycleState.graduated), isTrue);
      expect(StudentLifecycleState.graduated.isValidTransition(StudentLifecycleState.alumni), isTrue);

      // Terminal state: Alumni cannot transition back to Active
      expect(StudentLifecycleState.alumni.isValidTransition(StudentLifecycleState.active), isFalse);
      // Applicant cannot jump directly to Graduated
      expect(StudentLifecycleState.applicant.isValidTransition(StudentLifecycleState.graduated), isFalse);
    });

    test('8. Duplicate roll number rejection prevents conflicting student records', () async {
      final student1 = Student(
        id: 'stu_dup_1',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Linus Torvalds',
        rollNumber: 'CS-2026-DUP',
        email: 'linus@torvalds.org',
        phone: '1112223333',
      );
      await repo.admitStudent(student1);

      final student2 = Student(
        id: 'stu_dup_2',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Ken Thompson',
        rollNumber: 'CS-2026-DUP', // duplicate
        email: 'ken@thompson.org',
        phone: '4445556666',
      );

      expect(
        () => repo.admitStudent(student2),
        throwsA(isA<BackendValidationException>()),
      );
    });

    test('9. Scope validation prevents cross-college and unauthorized operations', () async {
      final foreignRepo = MockAcademicRepository(
        currentUser: UserModel(
          id: 'admin_c2',
          name: 'Foreign Admin',
          email: 'admin@c2.edu',
          role: AppRole.collegeAdmin,
          collegeId: 'c2',
          accountStatus: AccountStatus.active,
          createdAt: DateTime.now(),
        ),
      );

      final studentInC1 = Student(
        id: 'stu_c1_scope',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Barbara Liskov',
        rollNumber: 'CS-2026-909',
        email: 'barbara@liskov.edu',
        phone: '7778889999',
      );

      expect(
        () => foreignRepo.admitStudent(studentInC1),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('10. Bulk operations process cohorts with complete history logging', () async {
      final s1 = Student(
        id: 'bulk_s1',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Student One',
        rollNumber: 'CS-2026-B01',
        email: 's1@bulk.edu',
        phone: '1001',
      );
      final s2 = Student(
        id: 'bulk_s2',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        name: 'Student Two',
        rollNumber: 'CS-2026-B02',
        email: 's2@bulk.edu',
        phone: '1002',
      );

      await repo.bulkAdmitStudents([s1, s2]);

      // Bulk Promotion
      await repo.promoteStudents(
        studentIds: ['bulk_s1', 'bulk_s2'],
        targetAcademicYearId: 'ay2',
        targetSemesterId: 'sem2',
        targetSectionId: 'sec2',
      );

      final r1 = await repo.getStudentById('bulk_s1');
      final r2 = await repo.getStudentById('bulk_s2');

      expect(r1!.semesterId, equals('sem2'));
      expect(r2!.semesterId, equals('sem2'));
      expect(r1.history.length, equals(2));
      expect(r2.history.length, equals(2));
    });
  });
}
