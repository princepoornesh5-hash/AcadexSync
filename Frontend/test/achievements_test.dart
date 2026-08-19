import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/firebase/firebase_exceptions.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/achievements/domain/models/achievement_models.dart';
import 'package:campus_management/features/achievements/data/repositories/mock_achievement_repository.dart';

void main() {
  late UserModel collegeAdminUser;
  late UserModel hodCseUser;
  late UserModel hodEceUser;
  late UserModel facultyCseUser;
  late UserModel studentCseUser;
  late UserModel studentEceUser;
  late UserModel superAdminUser;

  setUp(() {
    superAdminUser = const UserModel(
      id: 'super_admin_1',
      name: 'Super Admin',
      email: 'super@acadex.edu',
      role: AppRole.superAdmin,
      accountStatus: AccountStatus.active,
    );

    collegeAdminUser = const UserModel(
      id: 'admin_1',
      name: 'College Admin',
      email: 'admin@college1.edu',
      role: AppRole.collegeAdmin,
      collegeId: 'c1',
      accountStatus: AccountStatus.active,
    );

    hodCseUser = const UserModel(
      id: 'hod_cse',
      name: 'Dr. Alan Turing',
      email: 'hod_cse@college1.edu',
      role: AppRole.hod,
      collegeId: 'c1',
      departmentId: 'dept_cse',
      accountStatus: AccountStatus.active,
    );

    hodEceUser = const UserModel(
      id: 'hod_ece',
      name: 'Dr. Claude Shannon',
      email: 'hod_ece@college1.edu',
      role: AppRole.hod,
      collegeId: 'c1',
      departmentId: 'dept_ece',
      accountStatus: AccountStatus.active,
    );

    facultyCseUser = const UserModel(
      id: 'faculty_cse',
      name: 'Prof. Ada Lovelace',
      email: 'ada@college1.edu',
      role: AppRole.faculty,
      collegeId: 'c1',
      departmentId: 'dept_cse',
      sectionId: 'sec_a',
      accountStatus: AccountStatus.active,
    );

    studentCseUser = const UserModel(
      id: 'student_cse',
      name: 'Alice Johnson',
      email: 'alice@college1.edu',
      role: AppRole.student,
      collegeId: 'c1',
      departmentId: 'dept_cse',
      semesterId: 'sem_6',
      sectionId: 'sec_a',
      accountStatus: AccountStatus.active,
    );

    studentEceUser = const UserModel(
      id: 'student_ece',
      name: 'Bob Miller',
      email: 'bob@college1.edu',
      role: AppRole.student,
      collegeId: 'c1',
      departmentId: 'dept_ece',
      semesterId: 'sem_4',
      sectionId: 'sec_b',
      accountStatus: AccountStatus.active,
    );
  });

  group('1. Achievement Creation & Academic Identity Attachment', () {
    test('Student creates achievement with automatic academic context', () async {
      final repo = MockAchievementRepository(
        currentUser: studentCseUser,
        initialAchievements: [],
      );

      final ach = Achievement(
        id: 'ach_hack_1',
        studentUid: studentCseUser.id,
        studentId: studentCseUser.id,
        studentName: studentCseUser.name,
        collegeId: studentCseUser.collegeId!,
        departmentId: studentCseUser.departmentId!,
        category: AchievementCategory.hackathon,
        title: 'National Hackathon Winner',
        issuer: 'IIT Bombay',
        achievementDate: DateTime.now(),
        skills: ['Flutter', 'Dart', 'Firebase'],
        fileName: 'cert.pdf',
        fileType: 'pdf',
        fileSizeBytes: 1024 * 500,
        storagePath: '/colleges/c1/students/student_cse/achievements/cert.pdf',
        fileUrl: 'mock://url/cert.pdf',
        createdAt: DateTime.now(),
        createdBy: studentCseUser.name,
        isVerificationRequested: false,
      );

      await repo.createAchievement(achievement: ach);

      final fetched = await repo.getAchievementById('ach_hack_1');
      expect(fetched, isNotNull);
      expect(fetched!.title, 'National Hackathon Winner');
      expect(fetched.studentUid, studentCseUser.id);
      expect(fetched.departmentId, 'dept_cse');
      expect(fetched.verificationStatus, AchievementVerificationStatus.unverified);
    });

    test('Student creating with verification request starts as pending', () async {
      final repo = MockAchievementRepository(
        currentUser: studentCseUser,
        initialAchievements: [],
      );

      final ach = Achievement(
        id: 'ach_cert_1',
        studentUid: studentCseUser.id,
        studentId: studentCseUser.id,
        studentName: studentCseUser.name,
        collegeId: studentCseUser.collegeId!,
        departmentId: studentCseUser.departmentId!,
        category: AchievementCategory.certification,
        title: 'AWS Certified Cloud Practitioner',
        issuer: 'Amazon Web Services',
        achievementDate: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: studentCseUser.name,
        isVerificationRequested: true, // Verification requested!
      );

      await repo.createAchievement(achievement: ach);

      final fetched = await repo.getAchievementById('ach_cert_1');
      expect(fetched!.verificationStatus, AchievementVerificationStatus.pending);
    });

    test('Student cannot spoof another student UID or Department', () async {
      final repo = MockAchievementRepository(
        currentUser: studentCseUser,
        initialAchievements: [],
      );

      final fraudulentAch = Achievement(
        id: 'ach_fake',
        studentUid: 'student_bob', // Spoofed student!
        studentId: 'student_bob',
        studentName: 'Bob',
        collegeId: 'c1',
        departmentId: 'dept_ece', // Mismatched department!
        category: AchievementCategory.hackathon,
        title: 'Fake Achievement',
        issuer: 'None',
        achievementDate: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: 'Hacker',
      );

      expect(
        () => repo.createAchievement(achievement: fraudulentAch),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('Super Admin cannot create routine student achievements', () async {
      final repo = MockAchievementRepository(
        currentUser: superAdminUser,
        initialAchievements: [],
      );

      final ach = Achievement(
        id: 'ach_sa',
        studentUid: 'student_cse',
        studentId: 'student_cse',
        studentName: 'Alice',
        collegeId: 'c1',
        departmentId: 'dept_cse',
        category: AchievementCategory.technical,
        title: 'SA Achievement',
        issuer: 'None',
        achievementDate: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: 'Super Admin',
      );

      expect(
        () => repo.createAchievement(achievement: ach),
        throwsA(isA<BackendPermissionException>()),
      );
    });
  });

  group('2. File Validations & Storage Lifecycle Cleanup', () {
    test('Rejects file exceeding 10MB limit', () async {
      final repo = MockAchievementRepository(
        currentUser: studentCseUser,
        initialAchievements: [],
      );

      final largeAch = Achievement(
        id: 'ach_huge',
        studentUid: studentCseUser.id,
        studentId: studentCseUser.id,
        studentName: studentCseUser.name,
        collegeId: 'c1',
        departmentId: 'dept_cse',
        category: AchievementCategory.technical,
        title: 'Huge Video Demo',
        issuer: 'Self',
        achievementDate: DateTime.now(),
        fileName: 'huge.pdf',
        fileType: 'pdf',
        fileSizeBytes: 15 * 1024 * 1024, // 15MB
        createdAt: DateTime.now(),
        createdBy: studentCseUser.name,
      );

      expect(
        () => repo.createAchievement(achievement: largeAch),
        throwsA(isA<BackendValidationException>()),
      );
    });

    test('Rejects unsupported file format', () async {
      final repo = MockAchievementRepository(
        currentUser: studentCseUser,
        initialAchievements: [],
      );

      final badExtAch = Achievement(
        id: 'ach_bad_ext',
        studentUid: studentCseUser.id,
        studentId: studentCseUser.id,
        studentName: studentCseUser.name,
        collegeId: 'c1',
        departmentId: 'dept_cse',
        category: AchievementCategory.technical,
        title: 'Malicious Executable',
        issuer: 'Unknown',
        achievementDate: DateTime.now(),
        fileName: 'exploit.exe',
        fileType: 'exe', // Invalid format!
        fileSizeBytes: 1024,
        createdAt: DateTime.now(),
        createdBy: studentCseUser.name,
      );

      expect(
        () => repo.createAchievement(achievement: badExtAch),
        throwsA(isA<BackendValidationException>()),
      );
    });

    test('Replacing proof document cleans up old storage file', () async {
      final repo = MockAchievementRepository(
        currentUser: studentCseUser,
        initialAchievements: [],
      );

      const oldPath = '/colleges/c1/students/student_cse/achievements/old_proof.pdf';
      const newPath = '/colleges/c1/students/student_cse/achievements/new_proof.pdf';

      final initialAch = Achievement(
        id: 'ach_replace',
        studentUid: studentCseUser.id,
        studentId: studentCseUser.id,
        studentName: studentCseUser.name,
        collegeId: 'c1',
        departmentId: 'dept_cse',
        category: AchievementCategory.technical,
        title: 'Open Source Contribution',
        issuer: 'GitHub',
        achievementDate: DateTime.now(),
        fileName: 'old_proof.pdf',
        fileType: 'pdf',
        fileSizeBytes: 1024 * 200,
        storagePath: oldPath,
        fileUrl: 'mock://old',
        createdAt: DateTime.now(),
        createdBy: studentCseUser.name,
      );

      await repo.createAchievement(achievement: initialAch);
      expect(repo.isStorageFilePresent(oldPath), isTrue);

      final updatedAch = initialAch.copyWith(
        fileName: 'new_proof.pdf',
        storagePath: newPath,
        fileUrl: 'mock://new',
      );

      await repo.updateAchievement(
        achievement: updatedAch,
        oldStoragePath: oldPath,
      );

      expect(repo.isStorageFilePresent(oldPath), isFalse); // Cleaned up!
      expect(repo.isStorageFilePresent(newPath), isTrue); // Present!
    });

    test('Deleting achievement cleans up physical storage file', () async {
      final repo = MockAchievementRepository(
        currentUser: studentCseUser,
        initialAchievements: [],
      );

      const path = '/colleges/c1/students/student_cse/achievements/to_delete.png';
      final ach = Achievement(
        id: 'ach_del',
        studentUid: studentCseUser.id,
        studentId: studentCseUser.id,
        studentName: studentCseUser.name,
        collegeId: 'c1',
        departmentId: 'dept_cse',
        category: AchievementCategory.sports,
        title: 'Sports Medal',
        issuer: 'Sports Club',
        achievementDate: DateTime.now(),
        fileName: 'to_delete.png',
        fileType: 'png',
        fileSizeBytes: 1024 * 300,
        storagePath: path,
        fileUrl: 'mock://delete',
        createdAt: DateTime.now(),
        createdBy: studentCseUser.name,
      );

      await repo.createAchievement(achievement: ach);
      expect(repo.isStorageFilePresent(path), isTrue);

      await repo.deleteAchievement(achievementId: 'ach_del', storagePath: path);
      expect(repo.isStorageFilePresent(path), isFalse);
      expect(await repo.getAchievementById('ach_del'), isNull);
    });
  });

  group('3. Scoped Queries & Role Boundaries', () {
    test('Student can only fetch their own achievements', () async {
      final repo = MockAchievementRepository(
        currentUser: studentCseUser,
        initialAchievements: [
          Achievement(
            id: 'ach_alice',
            studentUid: studentCseUser.id,
            studentId: studentCseUser.id,
            studentName: studentCseUser.name,
            collegeId: 'c1',
            departmentId: 'dept_cse',
            category: AchievementCategory.hackathon,
            title: 'Alice Hackathon',
            issuer: 'IIT',
            achievementDate: DateTime.now(),
            createdAt: DateTime.now(),
            createdBy: studentCseUser.name,
          ),
          Achievement(
            id: 'ach_bob',
            studentUid: studentEceUser.id,
            studentId: studentEceUser.id,
            studentName: studentEceUser.name,
            collegeId: 'c1',
            departmentId: 'dept_ece',
            category: AchievementCategory.sports,
            title: 'Bob Sports',
            issuer: 'Club',
            achievementDate: DateTime.now(),
            createdAt: DateTime.now(),
            createdBy: studentEceUser.name,
          ),
        ],
      );

      final aliceList = await repo.getScopedAchievements(requester: studentCseUser);
      expect(aliceList.length, 1);
      expect(aliceList.first.id, 'ach_alice');
    });

    test('HOD only sees achievements within their department', () async {
      final repo = MockAchievementRepository(
        currentUser: hodCseUser,
        initialAchievements: [
          Achievement(
            id: 'ach_cse',
            studentUid: studentCseUser.id,
            studentId: studentCseUser.id,
            studentName: studentCseUser.name,
            collegeId: 'c1',
            departmentId: 'dept_cse',
            category: AchievementCategory.technical,
            title: 'CSE Tech Project',
            issuer: 'CSE Dept',
            achievementDate: DateTime.now(),
            createdAt: DateTime.now(),
            createdBy: studentCseUser.name,
          ),
          Achievement(
            id: 'ach_ece',
            studentUid: studentEceUser.id,
            studentId: studentEceUser.id,
            studentName: studentEceUser.name,
            collegeId: 'c1',
            departmentId: 'dept_ece',
            category: AchievementCategory.technical,
            title: 'ECE Robotics',
            issuer: 'ECE Dept',
            achievementDate: DateTime.now(),
            createdAt: DateTime.now(),
            createdBy: studentEceUser.name,
          ),
        ],
      );

      final cseList = await repo.getScopedAchievements(requester: hodCseUser);
      expect(cseList.length, 1);
      expect(cseList.first.id, 'ach_cse');
    });

    test('College Admin sees achievements across all college departments', () async {
      final repo = MockAchievementRepository(
        currentUser: collegeAdminUser,
        initialAchievements: [
          Achievement(
            id: 'ach_cse',
            studentUid: studentCseUser.id,
            studentId: studentCseUser.id,
            studentName: studentCseUser.name,
            collegeId: 'c1',
            departmentId: 'dept_cse',
            category: AchievementCategory.technical,
            title: 'CSE Tech',
            issuer: 'CSE Dept',
            achievementDate: DateTime.now(),
            createdAt: DateTime.now(),
            createdBy: studentCseUser.name,
          ),
          Achievement(
            id: 'ach_ece',
            studentUid: studentEceUser.id,
            studentId: studentEceUser.id,
            studentName: studentEceUser.name,
            collegeId: 'c1',
            departmentId: 'dept_ece',
            category: AchievementCategory.technical,
            title: 'ECE Tech',
            issuer: 'ECE Dept',
            achievementDate: DateTime.now(),
            createdAt: DateTime.now(),
            createdBy: studentEceUser.name,
          ),
        ],
      );

      final adminList = await repo.getScopedAchievements(requester: collegeAdminUser);
      expect(adminList.length, 2);

      final eceList = await repo.getScopedAchievements(requester: hodEceUser);
      expect(eceList.length, 1);
      expect(eceList.first.id, 'ach_ece');

      final facultyList = await repo.getScopedAchievements(requester: facultyCseUser);
      expect(facultyList.length, 1);
      expect(facultyList.first.id, 'ach_cse');
    });
  });

  group('4. Verification Engine & Authority', () {
    test('HOD can verify achievement within department', () async {
      final ach = Achievement(
        id: 'ach_verify_1',
        studentUid: studentCseUser.id,
        studentId: studentCseUser.id,
        studentName: studentCseUser.name,
        collegeId: 'c1',
        departmentId: 'dept_cse',
        category: AchievementCategory.certification,
        title: 'Oracle Java Certified',
        issuer: 'Oracle',
        achievementDate: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: studentCseUser.name,
        isVerificationRequested: true,
        verificationStatus: AchievementVerificationStatus.pending,
      );

      final repo = MockAchievementRepository(
        currentUser: hodCseUser,
        initialAchievements: [ach],
      );

      await repo.reviewVerification(
        achievementId: 'ach_verify_1',
        reviewerUid: hodCseUser.id,
        reviewerName: hodCseUser.name,
        status: AchievementVerificationStatus.verified,
      );

      final updated = await repo.getAchievementById('ach_verify_1');
      expect(updated!.isVerified, isTrue);
      expect(updated.verifiedBy, hodCseUser.name);
    });

    test('HOD cannot verify achievement of another department', () async {
      final achEce = Achievement(
        id: 'ach_ece_verify',
        studentUid: studentEceUser.id,
        studentId: studentEceUser.id,
        studentName: studentEceUser.name,
        collegeId: 'c1',
        departmentId: 'dept_ece', // ECE
        category: AchievementCategory.sports,
        title: 'ECE Sports Trophy',
        issuer: 'Club',
        achievementDate: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: studentEceUser.name,
        isVerificationRequested: true,
        verificationStatus: AchievementVerificationStatus.pending,
      );

      final repo = MockAchievementRepository(
        currentUser: hodCseUser, // CSE HOD!
        initialAchievements: [achEce],
      );

      expect(
        () => repo.reviewVerification(
          achievementId: 'ach_ece_verify',
          reviewerUid: hodCseUser.id,
          reviewerName: hodCseUser.name,
          status: AchievementVerificationStatus.verified,
        ),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('Student cannot verify their own achievement', () async {
      final ach = Achievement(
        id: 'ach_self_verify',
        studentUid: studentCseUser.id,
        studentId: studentCseUser.id,
        studentName: studentCseUser.name,
        collegeId: 'c1',
        departmentId: 'dept_cse',
        category: AchievementCategory.hackathon,
        title: 'Hackathon',
        issuer: 'IIT',
        achievementDate: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: studentCseUser.name,
        isVerificationRequested: true,
        verificationStatus: AchievementVerificationStatus.pending,
      );

      final repo = MockAchievementRepository(
        currentUser: studentCseUser, // Student trying to verify!
        initialAchievements: [ach],
      );

      expect(
        () => repo.reviewVerification(
          achievementId: 'ach_self_verify',
          reviewerUid: studentCseUser.id,
          reviewerName: studentCseUser.name,
          status: AchievementVerificationStatus.verified,
        ),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('Rejection requires a non-empty verification note', () async {
      final ach = Achievement(
        id: 'ach_reject_test',
        studentUid: studentCseUser.id,
        studentId: studentCseUser.id,
        studentName: studentCseUser.name,
        collegeId: 'c1',
        departmentId: 'dept_cse',
        category: AchievementCategory.certification,
        title: 'Cert',
        issuer: 'AWS',
        achievementDate: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: studentCseUser.name,
        isVerificationRequested: true,
        verificationStatus: AchievementVerificationStatus.pending,
      );

      final repo = MockAchievementRepository(
        currentUser: hodCseUser,
        initialAchievements: [ach],
      );

      // Rejection with empty reason throws
      expect(
        () => repo.reviewVerification(
          achievementId: 'ach_reject_test',
          reviewerUid: hodCseUser.id,
          reviewerName: hodCseUser.name,
          status: AchievementVerificationStatus.rejected,
          verificationNote: '',
        ),
        throwsA(isA<BackendValidationException>()),
      );

      // Rejection with valid note succeeds
      await repo.reviewVerification(
        achievementId: 'ach_reject_test',
        reviewerUid: hodCseUser.id,
        reviewerName: hodCseUser.name,
        status: AchievementVerificationStatus.rejected,
        verificationNote: 'Document does not clearly display the student name.',
      );

      final updated = await repo.getAchievementById('ach_reject_test');
      expect(updated!.isRejected, isTrue);
      expect(updated.verificationNote, contains('student name'));
    });
  });

  group('5. Full End-to-End Multi-Role Workflow Test', () {
    test('Student creates -> requests verification -> HOD rejects with note -> Student replaces file & resubmits -> HOD verifies', () async {
      // Step 1: Student creates achievement and requests verification
      final studentSessionRepo = MockAchievementRepository(
        currentUser: studentCseUser,
        initialAchievements: [],
      );

      const path1 = '/colleges/c1/students/student_cse/achievements/hack_v1.pdf';
      final ach1 = Achievement(
        id: 'e2e_hack_1',
        studentUid: studentCseUser.id,
        studentId: studentCseUser.id,
        studentName: studentCseUser.name,
        collegeId: studentCseUser.collegeId!,
        departmentId: studentCseUser.departmentId!,
        category: AchievementCategory.hackathon,
        title: 'National Smart India Hackathon Winner',
        description: 'First prize in smart energy track.',
        issuer: 'Ministry of Education',
        achievementDate: DateTime(2026, 8, 15),
        skills: ['Flutter', 'IoT', 'Cloud'],
        fileName: 'hack_v1.pdf',
        fileType: 'pdf',
        fileSizeBytes: 1024 * 400,
        storagePath: path1,
        fileUrl: 'mock://url/hack_v1.pdf',
        createdAt: DateTime.now(),
        createdBy: studentCseUser.name,
        isVerificationRequested: true,
      );

      await studentSessionRepo.createAchievement(achievement: ach1);

      final studentItems1 = await studentSessionRepo.getStudentAchievements(
        studentUid: studentCseUser.id,
        collegeId: 'c1',
      );
      expect(studentItems1.length, 1);
      expect(studentItems1.first.verificationStatus, AchievementVerificationStatus.pending);

      // Step 2: HOD reviews verification queue and rejects with note
      final hodSessionRepo = MockAchievementRepository(
        currentUser: hodCseUser,
        initialAchievements: (await studentSessionRepo.getScopedAchievements(requester: collegeAdminUser)),
      );

      final pendingList = await hodSessionRepo.getScopedAchievements(
        requester: hodCseUser,
        verificationStatus: AchievementVerificationStatus.pending,
      );
      expect(pendingList.length, 1);

      await hodSessionRepo.reviewVerification(
        achievementId: 'e2e_hack_1',
        reviewerUid: hodCseUser.id,
        reviewerName: hodCseUser.name,
        status: AchievementVerificationStatus.rejected,
        verificationNote: 'Uploaded document is missing official stamp and seal.',
      );

      // Step 3: Student sees feedback and replaces proof file
      final studentSessionRepo2 = MockAchievementRepository(
        currentUser: studentCseUser,
        initialAchievements: (await hodSessionRepo.getScopedAchievements(requester: collegeAdminUser)),
      );

      final studentItems2 = await studentSessionRepo2.getStudentAchievements(
        studentUid: studentCseUser.id,
        collegeId: 'c1',
      );
      expect(studentItems2.first.isRejected, isTrue);
      expect(studentItems2.first.verificationNote, contains('stamp and seal'));

      const path2 = '/colleges/c1/students/student_cse/achievements/hack_stamped.pdf';
      final ach2 = studentItems2.first.copyWith(
        fileName: 'hack_stamped.pdf',
        storagePath: path2,
        fileUrl: 'mock://url/hack_stamped.pdf',
        isVerificationRequested: true,
      );

      await studentSessionRepo2.updateAchievement(
        achievement: ach2,
        oldStoragePath: path1,
      );

      // Step 4: HOD verifies updated submission
      final hodSessionRepo2 = MockAchievementRepository(
        currentUser: hodCseUser,
        initialAchievements: (await studentSessionRepo2.getScopedAchievements(requester: collegeAdminUser)),
      );

      await hodSessionRepo2.reviewVerification(
        achievementId: 'e2e_hack_1',
        reviewerUid: hodCseUser.id,
        reviewerName: hodCseUser.name,
        status: AchievementVerificationStatus.verified,
      );

      // Step 5: Student sees final verified status & metrics
      final studentSessionRepo3 = MockAchievementRepository(
        currentUser: studentCseUser,
        initialAchievements: (await hodSessionRepo2.getScopedAchievements(requester: collegeAdminUser)),
      );

      final finalAch = await studentSessionRepo3.getAchievementById('e2e_hack_1');
      expect(finalAch!.isVerified, isTrue);
      expect(finalAch.verifiedBy, hodCseUser.name);

      final metrics = await studentSessionRepo3.getStudentMetrics(
        studentUid: studentCseUser.id,
        collegeId: 'c1',
      );
      expect(metrics.total, 1);
      expect(metrics.verified, 1);
      expect(metrics.pending, 0);
    });
  });
}
