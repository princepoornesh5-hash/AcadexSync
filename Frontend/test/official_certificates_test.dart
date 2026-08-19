import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/firebase/firebase_exceptions.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/certificates/domain/models/official_certificate_models.dart';
import 'package:campus_management/features/certificates/data/repositories/mock_official_certificate_repository.dart';

void main() {
  late UserModel collegeAdminUser;
  late UserModel hodCseUser;
  late UserModel hodEceUser;
  late UserModel studentCseUser;
  late UserModel studentEceUser;
  late UserModel facultyUser;
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
      name: 'Dr. Turing',
      email: 'hod_cse@college1.edu',
      role: AppRole.hod,
      collegeId: 'c1',
      departmentId: 'dept_cse',
      accountStatus: AccountStatus.active,
    );

    hodEceUser = const UserModel(
      id: 'hod_ece',
      name: 'Dr. Shannon',
      email: 'hod_ece@college1.edu',
      role: AppRole.hod,
      collegeId: 'c1',
      departmentId: 'dept_ece',
      accountStatus: AccountStatus.active,
    );

    studentCseUser = const UserModel(
      id: 'student_cse',
      name: 'Alice CSE',
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
      name: 'Bob ECE',
      email: 'bob@college1.edu',
      role: AppRole.student,
      collegeId: 'c1',
      departmentId: 'dept_ece',
      semesterId: 'sem_4',
      sectionId: 'sec_b',
      accountStatus: AccountStatus.active,
    );

    facultyUser = const UserModel(
      id: 'faculty_1',
      name: 'Prof. Gauss',
      email: 'gauss@college1.edu',
      role: AppRole.faculty,
      collegeId: 'c1',
      departmentId: 'dept_cse',
      accountStatus: AccountStatus.active,
    );
  });

  group('1. Official Certificate Requirement Management', () {
    test('Super Admin cannot manage routine college requirements', () async {
      final repo = MockOfficialCertificateRepository(
        currentUser: superAdminUser,
        initialRequirements: [],
        initialSubmissions: [],
      );

      final req = OfficialCertificateRequirement(
        id: 'req_sa',
        collegeId: 'c1',
        name: 'Super Admin Requirement',
        applicableTo: RequirementApplicability.college,
        createdBy: superAdminUser.name,
        createdAt: DateTime.now(),
      );

      expect(
        () => repo.createRequirement(req),
        throwsA(isA<BackendPermissionException>()),
      );
    });
    test('College Admin can create a college-wide requirement', () async {
      final repo = MockOfficialCertificateRepository(
        currentUser: collegeAdminUser,
        initialRequirements: [],
        initialSubmissions: [],
      );

      final req = OfficialCertificateRequirement(
        id: 'req_birth',
        collegeId: 'c1',
        name: 'Birth Certificate',
        category: 'General',
        applicableTo: RequirementApplicability.college,
        createdBy: collegeAdminUser.name,
        createdAt: DateTime.now(),
      );

      await repo.createRequirement(req);
      final fetched = await repo.getRequirementById('req_birth');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Birth Certificate');
      expect(fetched.isCollegeWide, isTrue);
    });

    test('HOD can create department-scoped requirement', () async {
      final repo = MockOfficialCertificateRepository(
        currentUser: hodCseUser,
        initialRequirements: [],
        initialSubmissions: [],
      );

      final req = OfficialCertificateRequirement(
        id: 'req_cse_study',
        collegeId: 'c1',
        departmentId: 'dept_cse',
        name: 'CSE Study Certificate',
        category: 'Academic',
        applicableTo: RequirementApplicability.department,
        createdBy: hodCseUser.name,
        createdAt: DateTime.now(),
      );

      await repo.createRequirement(req);
      final fetched = await repo.getRequirementById('req_cse_study');
      expect(fetched, isNotNull);
      expect(fetched!.departmentId, 'dept_cse');
    });

    test('ECE HOD can create ECE department requirement', () async {
      final repo = MockOfficialCertificateRepository(
        currentUser: hodEceUser,
        initialRequirements: [],
        initialSubmissions: [],
      );

      final req = OfficialCertificateRequirement(
        id: 'req_ece_doc',
        collegeId: 'c1',
        departmentId: 'dept_ece',
        name: 'ECE Lab Safety Certificate',
        applicableTo: RequirementApplicability.department,
        createdBy: hodEceUser.name,
        createdAt: DateTime.now(),
      );

      await repo.createRequirement(req);
      final fetched = await repo.getRequirementById('req_ece_doc');
      expect(fetched, isNotNull);
      expect(fetched!.departmentId, 'dept_ece');
    });

    test('HOD cannot create college-wide requirement', () async {
      final repo = MockOfficialCertificateRepository(
        currentUser: hodCseUser,
        initialRequirements: [],
        initialSubmissions: [],
      );

      final req = OfficialCertificateRequirement(
        id: 'req_invalid',
        collegeId: 'c1',
        name: 'Global Certificate',
        applicableTo: RequirementApplicability.college,
        createdBy: hodCseUser.name,
        createdAt: DateTime.now(),
      );

      expect(
        () => repo.createRequirement(req),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('HOD cannot create requirement for another department', () async {
      final repo = MockOfficialCertificateRepository(
        currentUser: hodCseUser,
        initialRequirements: [],
        initialSubmissions: [],
      );

      final req = OfficialCertificateRequirement(
        id: 'req_ece_study',
        collegeId: 'c1',
        departmentId: 'dept_ece', // Different department!
        name: 'ECE Study Certificate',
        applicableTo: RequirementApplicability.department,
        createdBy: hodCseUser.name,
        createdAt: DateTime.now(),
      );

      expect(
        () => repo.createRequirement(req),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('Students and Faculty cannot create requirements', () async {
      final studentRepo = MockOfficialCertificateRepository(
        currentUser: studentCseUser,
        initialRequirements: [],
        initialSubmissions: [],
      );
      final facultyRepo = MockOfficialCertificateRepository(
        currentUser: facultyUser,
        initialRequirements: [],
        initialSubmissions: [],
      );

      final req = OfficialCertificateRequirement(
        id: 'req_hack',
        collegeId: 'c1',
        name: 'Fake Req',
        createdBy: 'hacker',
        createdAt: DateTime.now(),
      );

      expect(() => studentRepo.createRequirement(req), throwsA(isA<BackendPermissionException>()));
      expect(() => facultyRepo.createRequirement(req), throwsA(isA<BackendPermissionException>()));
    });
  });

  group('2. Student Requirement Resolution & Scoping', () {
    test('Student receives only applicable requirements (College + own Dept/Course/Sem/Sec)', () async {
      final repo = MockOfficialCertificateRepository(
        currentUser: studentCseUser,
        initialRequirements: [
          OfficialCertificateRequirement(
            id: 'req_1_col',
            collegeId: 'c1',
            name: 'Birth Certificate',
            applicableTo: RequirementApplicability.college,
            status: RequirementStatus.active,
            createdBy: 'admin_1',
            createdAt: DateTime.now(),
          ),
          OfficialCertificateRequirement(
            id: 'req_2_cse',
            collegeId: 'c1',
            departmentId: 'dept_cse',
            name: 'CSE Mini-Project Cert',
            applicableTo: RequirementApplicability.department,
            status: RequirementStatus.active,
            createdBy: 'hod_cse',
            createdAt: DateTime.now(),
          ),
          OfficialCertificateRequirement(
            id: 'req_3_ece',
            collegeId: 'c1',
            departmentId: 'dept_ece', // ECE only!
            name: 'ECE VLSI Cert',
            applicableTo: RequirementApplicability.department,
            status: RequirementStatus.active,
            createdBy: 'hod_ece',
            createdAt: DateTime.now(),
          ),
          OfficialCertificateRequirement(
            id: 'req_4_inactive',
            collegeId: 'c1',
            departmentId: 'dept_cse',
            name: 'Old CSE Cert',
            applicableTo: RequirementApplicability.department,
            status: RequirementStatus.inactive, // Inactive!
            createdBy: 'hod_cse',
            createdAt: DateTime.now(),
          ),
        ],
        initialSubmissions: [],
      );

      final items = await repo.getRequirementsWithSubmissionsForStudent(student: studentCseUser);

      expect(items.length, 2);
      final reqIds = items.map((i) => i.requirement.id).toList();
      expect(reqIds, contains('req_1_col'));
      expect(reqIds, contains('req_2_cse'));
      expect(reqIds, isNot(contains('req_3_ece')));
      expect(reqIds, isNot(contains('req_4_inactive')));
    });
  });

  group('3. Student Submissions & File Validations', () {
    test('Student successfully submits document with automatic academic context', () async {
      final repo = MockOfficialCertificateRepository(
        currentUser: studentCseUser,
        initialRequirements: [
          OfficialCertificateRequirement(
            id: 'req_tc',
            collegeId: 'c1',
            name: 'Transfer Certificate',
            applicableTo: RequirementApplicability.college,
            createdBy: 'admin_1',
            createdAt: DateTime.now(),
          ),
        ],
        initialSubmissions: [],
      );

      final cert = OfficialCertificate(
        id: 'sub_tc_1',
        studentUid: studentCseUser.id,
        studentId: studentCseUser.id,
        studentName: studentCseUser.name,
        collegeId: studentCseUser.collegeId!,
        departmentId: studentCseUser.departmentId!,
        courseId: 'crs_btech',
        semesterId: studentCseUser.semesterId!,
        sectionId: studentCseUser.sectionId!,
        academicYearId: 'ay_2026',
        requirementId: 'req_tc',
        certificateName: 'Transfer Certificate',
        fileName: 'tc_alice.pdf',
        fileType: 'pdf',
        fileSizeBytes: 1024 * 500,
        storagePath: '/colleges/c1/students/student_cse/official-certificates/sub_tc_1_tc_alice.pdf',
        fileUrl: 'mock://storage/tc_alice.pdf',
        status: OfficialCertificateStatus.pending,
        uploadedAt: DateTime.now(),
      );

      await repo.submitCertificate(certificate: cert);

      final subs = await repo.getSubmissions(collegeId: 'c1', studentUid: studentCseUser.id);
      expect(subs.length, 1);
      expect(subs.first.status, OfficialCertificateStatus.pending);
      expect(subs.first.studentUid, studentCseUser.id);
      expect(subs.first.departmentId, 'dept_cse');
    });

    test('Student cannot submit for another student', () async {
      final repo = MockOfficialCertificateRepository(
        currentUser: studentCseUser,
        initialRequirements: [],
        initialSubmissions: [],
      );

      final cert = OfficialCertificate(
        id: 'sub_fraud',
        studentUid: 'student_bob', // Spoofed student!
        studentId: 'ECE001',
        studentName: 'Bob',
        collegeId: 'c1',
        departmentId: 'dept_ece',
        courseId: 'crs_btech',
        semesterId: 'sem_4',
        sectionId: 'sec_b',
        academicYearId: 'ay_2026',
        requirementId: 'req_tc',
        certificateName: 'TC',
        fileName: 'tc.pdf',
        fileType: 'pdf',
        fileSizeBytes: 1024,
        storagePath: 'mock/tc.pdf',
        fileUrl: 'mock://url',
        status: OfficialCertificateStatus.pending,
        uploadedAt: DateTime.now(),
      );

      expect(
        () => repo.submitCertificate(certificate: cert),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('Rejects file exceeding 10MB limit', () async {
      final repo = MockOfficialCertificateRepository(
        currentUser: studentCseUser,
        initialRequirements: [],
        initialSubmissions: [],
      );

      final largeCert = OfficialCertificate(
        id: 'sub_huge',
        studentUid: studentCseUser.id,
        studentId: studentCseUser.id,
        studentName: studentCseUser.name,
        collegeId: 'c1',
        departmentId: 'dept_cse',
        courseId: 'crs_btech',
        semesterId: 'sem_6',
        sectionId: 'sec_a',
        academicYearId: 'ay_2026',
        requirementId: 'req_tc',
        certificateName: 'TC',
        fileName: 'huge.pdf',
        fileType: 'pdf',
        fileSizeBytes: 15 * 1024 * 1024, // 15MB!
        storagePath: 'mock/huge.pdf',
        fileUrl: 'mock://url',
        status: OfficialCertificateStatus.pending,
        uploadedAt: DateTime.now(),
      );

      expect(
        () => repo.submitCertificate(certificate: largeCert),
        throwsA(isA<BackendValidationException>()),
      );
    });

    test('Rejects unsupported file formats', () async {
      final repo = MockOfficialCertificateRepository(
        currentUser: studentCseUser,
        initialRequirements: [],
        initialSubmissions: [],
      );

      final invalidCert = OfficialCertificate(
        id: 'sub_bad_ext',
        studentUid: studentCseUser.id,
        studentId: studentCseUser.id,
        studentName: studentCseUser.name,
        collegeId: 'c1',
        departmentId: 'dept_cse',
        courseId: 'crs_btech',
        semesterId: 'sem_6',
        sectionId: 'sec_a',
        academicYearId: 'ay_2026',
        requirementId: 'req_tc',
        certificateName: 'TC',
        fileName: 'malware.exe',
        fileType: 'exe', // Invalid format!
        fileSizeBytes: 1024,
        storagePath: 'mock/malware.exe',
        fileUrl: 'mock://url',
        status: OfficialCertificateStatus.pending,
        uploadedAt: DateTime.now(),
      );

      expect(
        () => repo.submitCertificate(certificate: invalidCert),
        throwsA(isA<BackendValidationException>()),
      );
    });
  });

  group('4. Verification & Resubmission Engine', () {
    test('HOD can verify submission for own department', () async {
      final initialCert = OfficialCertificate(
        id: 'sub_cse_1',
        studentUid: studentCseUser.id,
        studentId: studentCseUser.id,
        studentName: studentCseUser.name,
        collegeId: 'c1',
        departmentId: 'dept_cse',
        courseId: 'crs_btech',
        semesterId: 'sem_6',
        sectionId: 'sec_a',
        academicYearId: 'ay_2026',
        requirementId: 'req_cse_study',
        certificateName: 'Study Certificate',
        fileName: 'study.pdf',
        fileType: 'pdf',
        fileSizeBytes: 1024 * 500,
        storagePath: 'mock/study.pdf',
        fileUrl: 'mock://url',
        status: OfficialCertificateStatus.pending,
        uploadedAt: DateTime.now(),
      );

      final repo = MockOfficialCertificateRepository(
        currentUser: hodCseUser,
        initialRequirements: [],
        initialSubmissions: [initialCert],
      );

      await repo.verifySubmission(
        submissionId: 'sub_cse_1',
        verifiedBy: hodCseUser.name,
        status: OfficialCertificateStatus.verified,
      );

      final updated = await repo.getSubmissionById('sub_cse_1');
      expect(updated, isNotNull);
      expect(updated!.status, OfficialCertificateStatus.verified);
      expect(updated.verifiedBy, hodCseUser.name);
      expect(updated.isVerified, isTrue);
    });

    test('HOD cannot verify submission for another department', () async {
      final initialCert = OfficialCertificate(
        id: 'sub_ece_1',
        studentUid: studentEceUser.id,
        studentId: studentEceUser.id,
        studentName: studentEceUser.name,
        collegeId: 'c1',
        departmentId: 'dept_ece', // ECE department
        courseId: 'crs_btech',
        semesterId: 'sem_4',
        sectionId: 'sec_b',
        academicYearId: 'ay_2026',
        requirementId: 'req_ece_study',
        certificateName: 'Study Certificate',
        fileName: 'study_ece.pdf',
        fileType: 'pdf',
        fileSizeBytes: 1024 * 500,
        storagePath: 'mock/study_ece.pdf',
        fileUrl: 'mock://url',
        status: OfficialCertificateStatus.pending,
        uploadedAt: DateTime.now(),
      );

      final repo = MockOfficialCertificateRepository(
        currentUser: hodCseUser, // CSE HOD trying to verify ECE submission!
        initialRequirements: [],
        initialSubmissions: [initialCert],
      );

      expect(
        () => repo.verifySubmission(
          submissionId: 'sub_ece_1',
          verifiedBy: hodCseUser.name,
          status: OfficialCertificateStatus.verified,
        ),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('Rejection and Resubmission requests mandate a non-empty reason', () async {
      final initialCert = OfficialCertificate(
        id: 'sub_cse_2',
        studentUid: studentCseUser.id,
        studentId: studentCseUser.id,
        studentName: studentCseUser.name,
        collegeId: 'c1',
        departmentId: 'dept_cse',
        courseId: 'crs_btech',
        semesterId: 'sem_6',
        sectionId: 'sec_a',
        academicYearId: 'ay_2026',
        requirementId: 'req_cse_study',
        certificateName: 'Study Certificate',
        fileName: 'study.pdf',
        fileType: 'pdf',
        fileSizeBytes: 1024 * 500,
        storagePath: 'mock/study.pdf',
        fileUrl: 'mock://url',
        status: OfficialCertificateStatus.pending,
        uploadedAt: DateTime.now(),
      );

      final repo = MockOfficialCertificateRepository(
        currentUser: hodCseUser,
        initialRequirements: [],
        initialSubmissions: [initialCert],
      );

      // Rejection with empty reason fails
      expect(
        () => repo.verifySubmission(
          submissionId: 'sub_cse_2',
          verifiedBy: hodCseUser.name,
          status: OfficialCertificateStatus.resubmissionRequired,
          rejectionReason: '',
        ),
        throwsA(isA<BackendValidationException>()),
      );

      // Rejection with valid reason succeeds
      await repo.verifySubmission(
        submissionId: 'sub_cse_2',
        verifiedBy: hodCseUser.name,
        status: OfficialCertificateStatus.resubmissionRequired,
        rejectionReason: 'Scan is unreadable. Please upload a high-resolution PDF.',
      );

      final updated = await repo.getSubmissionById('sub_cse_2');
      expect(updated!.status, OfficialCertificateStatus.resubmissionRequired);
      expect(updated.rejectionReason, contains('unreadable'));
    });
  });

  group('5. Storage Lifecycle & Physical File Cleanup', () {
    test('Replacing document cleans up old storage file and tracks new one', () async {
      final repo = MockOfficialCertificateRepository(
        currentUser: studentCseUser,
        initialRequirements: [],
        initialSubmissions: [],
      );

      const oldPath = '/colleges/c1/students/student_cse/official-certificates/old_doc.pdf';
      const newPath = '/colleges/c1/students/student_cse/official-certificates/new_doc.pdf';

      final initialCert = OfficialCertificate(
        id: 'sub_clean',
        studentUid: studentCseUser.id,
        studentId: studentCseUser.id,
        studentName: studentCseUser.name,
        collegeId: 'c1',
        departmentId: 'dept_cse',
        courseId: 'crs_btech',
        semesterId: 'sem_6',
        sectionId: 'sec_a',
        academicYearId: 'ay_2026',
        requirementId: 'req_1',
        certificateName: 'Document',
        fileName: 'old_doc.pdf',
        fileType: 'pdf',
        fileSizeBytes: 1024 * 100,
        storagePath: oldPath,
        fileUrl: 'mock://old',
        status: OfficialCertificateStatus.resubmissionRequired,
        uploadedAt: DateTime.now(),
      );

      await repo.submitCertificate(certificate: initialCert);
      expect(repo.isStorageFilePresent(oldPath), isTrue);

      // Student re-uploads and replaces
      final replacement = initialCert.copyWith(
        fileName: 'new_doc.pdf',
        storagePath: newPath,
        fileUrl: 'mock://new',
        status: OfficialCertificateStatus.pending,
      );

      await repo.submitCertificate(
        certificate: replacement,
        oldStoragePath: oldPath,
      );

      expect(repo.isStorageFilePresent(oldPath), isFalse); // Old file deleted!
      expect(repo.isStorageFilePresent(newPath), isTrue); // New file present!
    });

    test('Deleting submission deletes physical file from storage', () async {
      final repo = MockOfficialCertificateRepository(
        currentUser: studentCseUser,
        initialRequirements: [],
        initialSubmissions: [],
      );

      const path = '/colleges/c1/students/student_cse/official-certificates/delete_me.pdf';
      final cert = OfficialCertificate(
        id: 'sub_del',
        studentUid: studentCseUser.id,
        studentId: studentCseUser.id,
        studentName: studentCseUser.name,
        collegeId: 'c1',
        departmentId: 'dept_cse',
        courseId: 'crs_btech',
        semesterId: 'sem_6',
        sectionId: 'sec_a',
        academicYearId: 'ay_2026',
        requirementId: 'req_1',
        certificateName: 'Document',
        fileName: 'delete_me.pdf',
        fileType: 'pdf',
        fileSizeBytes: 1024 * 100,
        storagePath: path,
        fileUrl: 'mock://path',
        status: OfficialCertificateStatus.pending,
        uploadedAt: DateTime.now(),
      );

      await repo.submitCertificate(certificate: cert);
      expect(repo.isStorageFilePresent(path), isTrue);

      await repo.deleteSubmission(submissionId: 'sub_del', storagePath: path);
      expect(repo.isStorageFilePresent(path), isFalse);
      expect(await repo.getSubmissionById('sub_del'), isNull);
    });
  });

  group('6. Full End-to-End Multi-Role Workflow Test', () {
    test('College Admin creates req -> Student submits -> HOD requests re-upload -> Student re-uploads -> HOD approves', () async {
      // Shared in-memory data store across role sessions
      final sharedRepo = MockOfficialCertificateRepository(
        currentUser: collegeAdminUser,
        initialRequirements: [],
        initialSubmissions: [],
      );

      // Step 1: College Admin creates requirement
      final req = OfficialCertificateRequirement(
        id: 'req_bonafide',
        collegeId: 'c1',
        name: 'Bonafide Certificate',
        description: 'Original institution bonafide document.',
        category: 'Academic',
        applicableTo: RequirementApplicability.college,
        required: true,
        verificationRequired: true,
        createdBy: collegeAdminUser.name,
        createdAt: DateTime.now(),
      );
      await sharedRepo.createRequirement(req);

      // Step 2: Student checks applicable requirements
      final studentSessionRepo = MockOfficialCertificateRepository(
        currentUser: studentCseUser,
        initialRequirements: (await sharedRepo.getRequirements(collegeId: 'c1')),
        initialSubmissions: (await sharedRepo.getSubmissions(collegeId: 'c1')),
      );

      final studentItems1 = await studentSessionRepo.getRequirementsWithSubmissionsForStudent(student: studentCseUser);
      expect(studentItems1.length, 1);
      expect(studentItems1.first.calculatedStatus, RequirementSubmissionStatus.notSubmitted);
      expect(studentItems1.first.canUpload, isTrue);

      // Step 3: Student uploads document
      const path1 = '/colleges/c1/students/student_cse/official-certificates/bonafide_v1.pdf';
      final submission1 = OfficialCertificate(
        id: 'sub_bonafide_1',
        studentUid: studentCseUser.id,
        studentId: studentCseUser.id,
        studentName: studentCseUser.name,
        collegeId: studentCseUser.collegeId!,
        departmentId: studentCseUser.departmentId!,
        courseId: 'crs_btech',
        semesterId: studentCseUser.semesterId!,
        sectionId: studentCseUser.sectionId!,
        academicYearId: 'ay_2026',
        requirementId: 'req_bonafide',
        certificateName: 'Bonafide Certificate',
        fileName: 'bonafide_v1.pdf',
        fileType: 'pdf',
        fileSizeBytes: 1024 * 300,
        storagePath: path1,
        fileUrl: 'mock://url/bonafide_v1.pdf',
        status: OfficialCertificateStatus.pending,
        uploadedAt: DateTime.now(),
      );
      await studentSessionRepo.submitCertificate(certificate: submission1);

      // Step 4: HOD reviews submission and requests re-upload with reason
      final hodSessionRepo = MockOfficialCertificateRepository(
        currentUser: hodCseUser,
        initialRequirements: (await studentSessionRepo.getRequirements(collegeId: 'c1')),
        initialSubmissions: (await studentSessionRepo.getSubmissions(collegeId: 'c1')),
      );

      final cseSubmissions = await hodSessionRepo.getSubmissions(
        collegeId: 'c1',
        departmentId: 'dept_cse',
      );
      expect(cseSubmissions.length, 1);
      expect(cseSubmissions.first.status, OfficialCertificateStatus.pending);

      await hodSessionRepo.verifySubmission(
        submissionId: 'sub_bonafide_1',
        verifiedBy: hodCseUser.name,
        status: OfficialCertificateStatus.resubmissionRequired,
        rejectionReason: 'The uploaded file is missing the principal signature.',
      );

      // Step 5: Student sees feedback and re-uploads document
      final studentSessionRepo2 = MockOfficialCertificateRepository(
        currentUser: studentCseUser,
        initialRequirements: (await hodSessionRepo.getRequirements(collegeId: 'c1')),
        initialSubmissions: (await hodSessionRepo.getSubmissions(collegeId: 'c1')),
      );

      final studentItems2 = await studentSessionRepo2.getRequirementsWithSubmissionsForStudent(student: studentCseUser);
      expect(studentItems2.first.calculatedStatus, RequirementSubmissionStatus.resubmissionRequired);
      expect(studentItems2.first.canUploadAgain, isTrue);

      const path2 = '/colleges/c1/students/student_cse/official-certificates/bonafide_signed.pdf';
      final submission2 = submission1.copyWith(
        fileName: 'bonafide_signed.pdf',
        storagePath: path2,
        fileUrl: 'mock://url/bonafide_signed.pdf',
        status: OfficialCertificateStatus.pending,
        rejectionReason: null,
      );
      await studentSessionRepo2.submitCertificate(
        certificate: submission2,
        oldStoragePath: path1,
      );

      // Step 6: HOD approves & verifies
      final hodSessionRepo2 = MockOfficialCertificateRepository(
        currentUser: hodCseUser,
        initialRequirements: (await studentSessionRepo2.getRequirements(collegeId: 'c1')),
        initialSubmissions: (await studentSessionRepo2.getSubmissions(collegeId: 'c1')),
      );

      await hodSessionRepo2.verifySubmission(
        submissionId: 'sub_bonafide_1',
        verifiedBy: hodCseUser.name,
        status: OfficialCertificateStatus.verified,
      );

      // Step 7: Student verifies final verified status
      final studentSessionRepo3 = MockOfficialCertificateRepository(
        currentUser: studentCseUser,
        initialRequirements: (await hodSessionRepo2.getRequirements(collegeId: 'c1')),
        initialSubmissions: (await hodSessionRepo2.getSubmissions(collegeId: 'c1')),
      );

      final studentItems3 = await studentSessionRepo3.getRequirementsWithSubmissionsForStudent(student: studentCseUser);
      expect(studentItems3.first.calculatedStatus, RequirementSubmissionStatus.verified);
      expect(studentItems3.first.canViewDocument, isTrue);
      expect(studentItems3.first.submission!.isVerified, isTrue);
      expect(studentItems3.first.submission!.verifiedBy, hodCseUser.name);
    });
  });
}
