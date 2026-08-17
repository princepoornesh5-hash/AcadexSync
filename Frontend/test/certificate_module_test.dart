import 'package:flutter_test/flutter_test.dart';

import 'package:campus_management/features/certificates/domain/models/certificate.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_type.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_status.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_file_config.dart';
import 'package:campus_management/features/certificates/data/repositories/mock_certificate_repository.dart';

void main() {
  group('Certificate Model', () {
    test('serializes and deserializes correctly', () {
      final now = DateTime(2024, 6, 15);
      final cert = Certificate(
        id: 'c1',
        studentId: 's1',
        studentUid: 'uid1',
        studentName: 'Alice',
        collegeId: 'col1',
        departmentId: 'dept1',
        title: 'AWS Practitioner',
        type: CertificateType.technical,
        issuer: 'Amazon Web Services',
        issueDate: now,
        fileName: 'aws.pdf',
        fileType: 'pdf',
        fileSizeBytes: 1024 * 500,
        storageFileId: 'file-1',
        storagePath: 'mock/aws.pdf',
        status: CertificateStatus.active,
        uploadedAt: now,
        updatedAt: now,
        uploadedBy: 'uid1',
      );

      final json = cert.toJson();
      expect(json['type'], 'technical');
      expect(json['status'], 'active');
      expect(json['isVerified'], false);

      final restored = Certificate.fromJson(json);
      expect(restored.title, 'AWS Practitioner');
      expect(restored.type, CertificateType.technical);
      expect(restored.status, CertificateStatus.active);
    });

    test('fileSizeDisplay formats correctly', () {
      final cert = _dummyCert(fileSizeBytes: 512 * 1024);
      expect(cert.fileSizeDisplay, '512.0KB');
    });

    test('copyWith does not mutate ownership fields', () {
      final cert = _dummyCert();
      final updated = cert.copyWith(title: 'New Title');
      expect(updated.studentId, cert.studentId);
      expect(updated.studentUid, cert.studentUid);
      expect(updated.uploadedBy, cert.uploadedBy);
    });
  });

  group('CertificateType Enum', () {
    test('all types round-trip via fromValue', () {
      for (final type in CertificateType.values) {
        expect(CertificateTypeExtension.fromValue(type.value), type);
      }
    });

    test('unknown value returns other', () {
      expect(CertificateTypeExtension.fromValue('xyz'), CertificateType.other);
    });
  });

  group('CertificateStatus Enum', () {
    test('all statuses round-trip via fromValue', () {
      for (final status in CertificateStatus.values) {
        expect(CertificateStatusExtension.fromValue(status.value), status);
      }
    });

    test('isVisible returns true for active, pending, verified', () {
      expect(CertificateStatus.active.isVisible, isTrue);
      expect(CertificateStatus.pendingVerification.isVisible, isTrue);
      expect(CertificateStatus.verified.isVisible, isTrue);
      expect(CertificateStatus.removed.isVisible, isFalse);
      expect(CertificateStatus.archived.isVisible, isFalse);
    });
  });

  group('Certificate File Validation', () {
    test('rejects empty file', () {
      final err = validateCertificateFile(fileName: 'test.pdf', fileSizeBytes: 0);
      expect(err, isNotNull);
    });

    test('rejects oversized file', () {
      final err = validateCertificateFile(fileName: 'big.pdf', fileSizeBytes: 11 * 1024 * 1024);
      expect(err, contains('10MB'));
    });

    test('rejects executable extension', () {
      final err = validateCertificateFile(fileName: 'virus.exe', fileSizeBytes: 1024);
      expect(err, isNotNull);
      expect(err, contains('not allowed'));
    });

    test('rejects unsupported extension', () {
      final err = validateCertificateFile(fileName: 'archive.zip', fileSizeBytes: 1024);
      expect(err, isNotNull);
    });

    test('accepts valid pdf', () {
      final err = validateCertificateFile(fileName: 'cert.pdf', fileSizeBytes: 500 * 1024);
      expect(err, isNull);
    });

    test('accepts valid jpg', () {
      final err = validateCertificateFile(fileName: 'scan.jpg', fileSizeBytes: 2 * 1024 * 1024);
      expect(err, isNull);
    });

    test('accepts docx', () {
      final err = validateCertificateFile(fileName: 'certificate.docx', fileSizeBytes: 200 * 1024);
      expect(err, isNull);
    });
  });

  group('MockCertificateRepository', () {
    late MockCertificateRepository repo;

    setUp(() => repo = MockCertificateRepository());

    test('returns student-scoped certificates', () async {
      final certs = await repo.getStudentCertificates('student-demo-uid-1');
      expect(certs.every((c) => c.studentUid == 'student-demo-uid-1'), isTrue);
    });

    test('creates certificate and retrieves it', () async {
      final cert = _dummyCert(id: 'new-cert', studentUid: 'uid-test');
      await repo.createCertificate(cert);
      final result = await repo.getCertificate('new-cert');
      expect(result?.title, cert.title);
    });

    test('soft-delete marks status as removed, not physically deleted', () async {
      final cert = _dummyCert(id: 'del-cert', studentUid: 'uid-owner');
      await repo.createCertificate(cert);
      await repo.deleteCertificate('del-cert', 'uid-owner');
      final result = await repo.getCertificate('del-cert');
      expect(result?.status, CertificateStatus.removed);
    });

    test('deleteCertificate throws if requestingUid is not the owner — SECURITY', () async {
      final cert = _dummyCert(id: 'sec-cert', studentUid: 'student-a');
      await repo.createCertificate(cert);
      expect(
        () => repo.deleteCertificate('sec-cert', 'student-b'),
        throwsException,
      );
    });

    test('searchCertificates scoped to student UID — SECURITY', () async {
      await repo.createCertificate(_dummyCert(id: 'ca', studentUid: 'ua', title: 'Alpha cert'));
      await repo.createCertificate(_dummyCert(id: 'cb', studentUid: 'ub', title: 'Beta cert'));
      final results = await repo.searchCertificates('cert', scopeStudentUid: 'ua');
      expect(results.every((c) => c.studentUid == 'ua'), isTrue);
    });

    test('faculty scope is restricted by collegeId + departmentId — SECURITY', () async {
      await repo.createCertificate(_dummyCert(id: 'fc1', studentUid: 'uid1', collegeId: 'colA', departmentId: 'deptX'));
      await repo.createCertificate(_dummyCert(id: 'fc2', studentUid: 'uid2', collegeId: 'colB', departmentId: 'deptY'));
      final results = await repo.getFacultyStudentCertificates(
        facultyUid: 'f1',
        collegeId: 'colA',
        departmentId: 'deptX',
      );
      expect(results.every((c) => c.collegeId == 'colA' && c.departmentId == 'deptX'), isTrue);
    });

    test('verifyCertificate throws if verifier is the student owner — SECURITY', () async {
      final cert = _dummyCert(id: 'vc1', studentUid: 'self-uid');
      await repo.createCertificate(cert);
      expect(
        () => repo.verifyCertificate(certificateId: 'vc1', verifierUid: 'self-uid', verifierName: 'Alice'),
        throwsException,
      );
    });

    test('verifyCertificate succeeds for authorized faculty', () async {
      final cert = _dummyCert(id: 'vc2', studentUid: 'student-uid');
      await repo.createCertificate(cert);
      final verified = await repo.verifyCertificate(certificateId: 'vc2', verifierUid: 'faculty-uid', verifierName: 'Prof. X');
      expect(verified.isVerified, isTrue);
      expect(verified.verifiedBy, 'faculty-uid');
      expect(verified.status, CertificateStatus.verified);
    });

    test('graduated student certificates remain accessible by studentUid', () async {
      // Graduated student — section and semester can be changed or removed; cert still found by studentUid
      final cert = _dummyCert(
        id: 'grad-cert',
        studentUid: 'graduated-student-uid',
        sectionId: null, // graduated — no active section
      );
      await repo.createCertificate(cert);
      final results = await repo.getStudentCertificates('graduated-student-uid');
      expect(results.any((c) => c.id == 'grad-cert'), isTrue);
    });

    test('updateCertificate preserves ownership fields', () async {
      final cert = _dummyCert(id: 'upd-cert', studentUid: 'orig-uid');
      await repo.createCertificate(cert);
      final updated = cert.copyWith(title: 'Updated Title', updatedBy: 'faculty-uid');
      final result = await repo.updateCertificate(updated);
      // Title changed but ownership fields preserved
      expect(result.title, 'Updated Title');
      expect(result.studentUid, 'orig-uid');
      expect(result.uploadedBy, cert.uploadedBy);
    });

    test('filterCertificates correctly filters by type', () async {
      await repo.createCertificate(_dummyCert(id: 'f1', studentUid: 'u1', type: CertificateType.academic));
      await repo.createCertificate(_dummyCert(id: 'f2', studentUid: 'u1', type: CertificateType.sports));
      final results = await repo.filterCertificates(studentUid: 'u1', type: CertificateType.academic);
      expect(results.every((c) => c.type == CertificateType.academic), isTrue);
    });
  });
}

Certificate _dummyCert({
  String id = 'test-id',
  String studentId = 'student-1',
  String studentUid = 'student-uid-1',
  String studentName = 'Test Student',
  String? collegeId = 'col-1',
  String? departmentId = 'dept-1',
  String? sectionId = 'sec-1',
  CertificateType type = CertificateType.academic,
  int fileSizeBytes = 1024,
  String title = 'Test Certificate',
}) {
  final now = DateTime.now();
  return Certificate(
    id: id,
    studentId: studentId,
    studentUid: studentUid,
    studentName: studentName,
    collegeId: collegeId,
    departmentId: departmentId,
    sectionId: sectionId,
    title: title,
    type: type,
    issuer: 'Test Issuer',
    issueDate: now,
    fileName: 'cert.pdf',
    fileType: 'pdf',
    fileSizeBytes: fileSizeBytes,
    storageFileId: 'file-$id',
    storagePath: 'mock/$id/cert.pdf',
    uploadedAt: now,
    updatedAt: now,
    uploadedBy: studentUid,
  );
}
