import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/certificates/domain/models/certificate.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_type.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_status.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_request_model.dart';
import 'package:campus_management/features/certificates/data/repositories/mock_certificate_repository.dart';
import 'package:campus_management/features/certificates/presentation/providers/certificate_providers.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Certificate End-to-End Workflow Tests', () {
    late ProviderContainer container;
    late MockCertificateRepository mockCertRepo;

    final studentUser = UserModel(
      id: 'student-workflow-1',
      firebaseUid: 'student_auth_uid_1',
      name: 'Emma Watson',
      email: 'emma@campus.edu',
      role: AppRole.student,
      collegeId: 'COL-001',
      departmentId: 'DEP-CSE',
      sectionId: 'SEC-A',
      semesterId: 'SEM-6',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final facultyUser = UserModel(
      id: 'faculty-workflow-1',
      firebaseUid: 'faculty_auth_uid_1',
      name: 'Dr. Minerva McGonagall',
      email: 'minerva@campus.edu',
      role: AppRole.faculty,
      collegeId: 'COL-001',
      departmentId: 'DEP-CSE',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      mockCertRepo = MockCertificateRepository();
      container = ProviderContainer(
        overrides: [
          certificateRepositoryProvider.overrideWithValue(mockCertRepo),
          authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: studentUser, token: 'mock-token'))),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Student uploads certificate -> Stream emits record -> Faculty verifies -> Status transitions to verified', () async {
      final now = DateTime.now();
      final newCert = Certificate(
        id: 'flow-cert-1',
        studentId: studentUser.id,
        studentUid: studentUser.firebaseUid ?? studentUser.id,
        studentName: studentUser.name,
        collegeId: studentUser.collegeId ?? '',
        departmentId: studentUser.departmentId ?? '',
        title: 'Oracle Certified Java Developer',
        type: CertificateType.technical,
        issuer: 'Oracle Corporation',
        issueDate: now,
        fileName: 'oracle_java.pdf',
        fileType: 'pdf',
        fileSizeBytes: 420000,
        storageFileId: 'file-java-1',
        storagePath: 'certificates/student_auth_uid_1/oracle_java.pdf',
        status: CertificateStatus.active,
        uploadedAt: now,
        updatedAt: now,
        uploadedBy: studentUser.firebaseUid ?? studentUser.id,
        isVerified: false,
      );

      // 1. Upload certificate
      await mockCertRepo.createCertificate(newCert);

      // 2. Student views certificates
      final studentCerts = await mockCertRepo.watchStudentCertificates(studentUser.firebaseUid!).first;
      expect(studentCerts.length, 1);
      expect(studentCerts.first.title, 'Oracle Certified Java Developer');
      expect(studentCerts.first.isVerified, isFalse);

      // 3. Faculty verifies certificate
      await mockCertRepo.verifyCertificate(
        certificateId: 'flow-cert-1',
        verifierUid: facultyUser.firebaseUid!,
        verifierName: facultyUser.name,
      );

      // 4. Verify updated record
      final updatedCert = await mockCertRepo.getCertificate('flow-cert-1');
      expect(updatedCert?.isVerified, isTrue);
      expect(updatedCert?.verifiedBy, 'faculty_auth_uid_1');
      expect(updatedCert?.status, CertificateStatus.verified);
    });

    test('Student Certificate Filters & Search Query Provider', () async {
      final now = DateTime.now();
      await mockCertRepo.createCertificate(Certificate(
        id: 'cert-filter-1',
        studentId: studentUser.id,
        studentUid: studentUser.firebaseUid!,
        studentName: studentUser.name,
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        title: 'AWS Machine Learning',
        type: CertificateType.technical,
        issuer: 'Amazon',
        issueDate: now,
        fileName: 'aws.pdf',
        fileType: 'pdf',
        fileSizeBytes: 200000,
        storageFileId: 'f1',
        storagePath: 'mock/aws.pdf',
        status: CertificateStatus.active,
        uploadedAt: now,
        updatedAt: now,
        uploadedBy: studentUser.firebaseUid!,
        isVerified: true,
      ));

      await mockCertRepo.createCertificate(Certificate(
        id: 'cert-filter-2',
        studentId: studentUser.id,
        studentUid: studentUser.firebaseUid!,
        studentName: studentUser.name,
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        title: 'Basketball Championship',
        type: CertificateType.sports,
        issuer: 'State Sports Authority',
        issueDate: now,
        fileName: 'sports.jpg',
        fileType: 'jpg',
        fileSizeBytes: 100000,
        storageFileId: 'f2',
        storagePath: 'mock/sports.jpg',
        status: CertificateStatus.active,
        uploadedAt: now,
        updatedAt: now,
        uploadedBy: studentUser.firebaseUid!,
        isVerified: false,
      ));

      // Wait for underlying stream provider to emit
      await container.read(studentCertificatesProvider.future);

      // Test Search query filter
      container.read(certificateSearchQueryProvider.notifier).state = 'Basketball';
      final filteredBySearch = container.read(filteredStudentCertificatesProvider).value!;
      expect(filteredBySearch.length, 1);
      expect(filteredBySearch.first.title, 'Basketball Championship');

      // Test Category filter
      container.read(certificateSearchQueryProvider.notifier).state = '';
      container.read(certificateFilterProvider.notifier).state = const CertificateFilter(type: CertificateType.technical);
      final filteredByType = container.read(filteredStudentCertificatesProvider).value!;
      expect(filteredByType.length, 1);
      expect(filteredByType.first.title, 'AWS Machine Learning');

      // Test Verified filter
      container.read(certificateFilterProvider.notifier).state = const CertificateFilter(isVerified: true);
      final filteredByVerified = container.read(filteredStudentCertificatesProvider).value!;
      expect(filteredByVerified.length, 1);
      expect(filteredByVerified.first.isVerified, isTrue);
    });

    test('Certificate Request Lifecycle: submit -> review -> approve -> mark ready -> complete', () async {
      final req = CertificateRequest(
        id: 'req-lifecycle-1',
        studentId: studentUser.id,
        studentUserId: studentUser.firebaseUid!,
        collegeId: studentUser.collegeId!,
        departmentId: studentUser.departmentId!,
        courseId: 'CRS-BTECH',
        academicYearId: 'AY-2025-26',
        certificateTypeId: 'type-bonafide',
        certificateTypeName: 'Bonafide Certificate',
        reason: 'Education loan application',
        purpose: 'Bank Loan Verification',
        status: CertificateRequestStatus.pending,
        requestedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(req.status, CertificateRequestStatus.pending);

      // Admin approves
      final approved = req.copyWith(
        status: CertificateRequestStatus.approved,
        reviewedBy: 'College Admin',
        reviewedAt: DateTime.now(),
      );
      expect(approved.status, CertificateRequestStatus.approved);

      // Marked ready for pickup
      final ready = approved.copyWith(
        status: CertificateRequestStatus.ready,
        updatedAt: DateTime.now(),
      );
      expect(ready.status, CertificateRequestStatus.ready);

      // Completed / Collected
      final completed = ready.copyWith(
        status: CertificateRequestStatus.completed,
        updatedAt: DateTime.now(),
      );
      expect(completed.status, CertificateRequestStatus.completed);
    });

    test('Certificate Request Rejection captures rejection reason', () async {
      final req = CertificateRequest(
        id: 'req-reject-1',
        studentId: studentUser.id,
        studentUserId: studentUser.firebaseUid!,
        collegeId: studentUser.collegeId!,
        departmentId: studentUser.departmentId!,
        courseId: 'CRS-BTECH',
        academicYearId: 'AY-2025-26',
        certificateTypeId: 'type-study',
        certificateTypeName: 'Study Certificate',
        status: CertificateRequestStatus.pending,
        requestedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final rejected = req.copyWith(
        status: CertificateRequestStatus.rejected,
        rejectionReason: 'Pending semester tuition dues. Please clear dues with finance office.',
        reviewedBy: 'Dean Academic Affairs',
        reviewedAt: DateTime.now(),
      );

      expect(rejected.status, CertificateRequestStatus.rejected);
      expect(rejected.rejectionReason, contains('Pending semester tuition dues'));
    });
  });
}
