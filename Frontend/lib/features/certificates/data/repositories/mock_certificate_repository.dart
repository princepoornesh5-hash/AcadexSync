import 'package:uuid/uuid.dart';

import '../../domain/models/certificate.dart';
import '../../domain/models/certificate_status.dart';
import '../../domain/models/certificate_type.dart';
import '../../domain/repositories/certificate_repository.dart';

class MockCertificateRepository implements CertificateRepository {
  final _uuid = const Uuid();

  // In-memory store keyed by certificate ID
  // Preserves certificates independent of student's current section/semester/status
  final Map<String, Certificate> _store = {};

  // Seed some demo data for development
  MockCertificateRepository() {
    _seedDemoData();
  }

  void _seedDemoData() {
    final now = DateTime.now();
    final certs = [
      Certificate(
        id: 'cert-demo-1',
        studentId: 'student-demo-1',
        studentUid: 'student-demo-uid-1',
        studentName: 'Alex Johnson',
        collegeId: 'college-1',
        departmentId: 'dept-cs',
        courseId: 'course-btech',
        semesterId: 'sem-5',
        sectionId: 'sec-a',
        title: 'AWS Cloud Practitioner',
        type: CertificateType.technical,
        description: 'Foundational cloud certification from Amazon Web Services',
        issuer: 'Amazon Web Services',
        issueDate: now.subtract(const Duration(days: 60)),
        fileName: 'aws_cert.pdf',
        fileType: 'pdf',
        fileSizeBytes: 512 * 1024,
        storageFileId: 'mock-file-1',
        storagePath: 'mock/storage/cert-demo-1/aws_cert.pdf',
        status: CertificateStatus.verified,
        uploadedAt: now.subtract(const Duration(days: 58)),
        updatedAt: now.subtract(const Duration(days: 50)),
        uploadedBy: 'student-demo-uid-1',
        isVerified: true,
        verifiedBy: 'faculty-demo-uid-1',
        verifiedAt: now.subtract(const Duration(days: 50)),
      ),
      Certificate(
        id: 'cert-demo-2',
        studentId: 'student-demo-1',
        studentUid: 'student-demo-uid-1',
        studentName: 'Alex Johnson',
        collegeId: 'college-1',
        departmentId: 'dept-cs',
        title: 'National Hackathon 2024',
        type: CertificateType.achievement,
        issuer: 'Tech India Foundation',
        issueDate: now.subtract(const Duration(days: 120)),
        fileName: 'hackathon_certificate.jpg',
        fileType: 'jpg',
        fileSizeBytes: 1024 * 1024,
        storageFileId: 'mock-file-2',
        storagePath: 'mock/storage/cert-demo-2/hackathon_certificate.jpg',
        status: CertificateStatus.active,
        uploadedAt: now.subtract(const Duration(days: 118)),
        updatedAt: now.subtract(const Duration(days: 118)),
        uploadedBy: 'student-demo-uid-1',
        isVerified: false,
      ),
    ];

    for (final c in certs) {
      _store[c.id] = c;
    }
  }

  @override
  Future<List<Certificate>> getStudentCertificates(String studentUid) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _store.values
        .where((c) => c.studentUid == studentUid && c.status.isVisible)
        .toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  }

  @override
  Future<Certificate?> getCertificate(String certificateId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _store[certificateId];
  }

  @override
  Future<Certificate> createCertificate(Certificate certificate) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final id = certificate.id.isEmpty ? _uuid.v4() : certificate.id;
    final created = certificate.copyWith(id: id);
    _store[id] = created;
    return created;
  }

  @override
  Future<Certificate> updateCertificate(Certificate certificate) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!_store.containsKey(certificate.id)) {
      throw Exception('Certificate not found: ${certificate.id}');
    }
    _store[certificate.id] = certificate;
    return certificate;
  }

  @override
  Future<void> deleteCertificate(String certificateId, String requestingUid) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final cert = _store[certificateId];
    if (cert == null) throw Exception('Certificate not found: $certificateId');
    // Security: only owner can soft-delete their own certificate
    if (cert.studentUid != requestingUid) {
      throw Exception('Permission denied: you cannot delete this certificate.');
    }
    // Soft delete — preserves record for audit
    _store[certificateId] = cert.copyWith(
      status: CertificateStatus.removed,
      updatedAt: DateTime.now(),
      updatedBy: requestingUid,
    );
  }

  @override
  Future<List<Certificate>> searchCertificates(
    String query, {
    String? scopeStudentUid,
    String? scopeCollegeId,
    String? scopeDepartmentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final q = query.toLowerCase();
    return _store.values.where((c) {
      if (!c.status.isVisible) return false;
      if (scopeStudentUid != null && c.studentUid != scopeStudentUid) return false;
      if (scopeCollegeId != null && c.collegeId != scopeCollegeId) return false;
      if (scopeDepartmentId != null && c.departmentId != scopeDepartmentId) return false;
      return c.title.toLowerCase().contains(q) ||
          c.issuer.toLowerCase().contains(q) ||
          c.studentName.toLowerCase().contains(q) ||
          c.type.displayName.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  }

  @override
  Future<List<Certificate>> filterCertificates({
    String? studentUid,
    String? collegeId,
    String? departmentId,
    CertificateType? type,
    CertificateStatus? status,
    DateTime? issuedAfter,
    DateTime? issuedBefore,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _store.values.where((c) {
      if (studentUid != null && c.studentUid != studentUid) return false;
      if (collegeId != null && c.collegeId != collegeId) return false;
      if (departmentId != null && c.departmentId != departmentId) return false;
      if (type != null && c.type != type) return false;
      if (status != null && c.status != status) return false;
      if (issuedAfter != null && c.issueDate.isBefore(issuedAfter)) return false;
      if (issuedBefore != null && c.issueDate.isAfter(issuedBefore)) return false;
      return c.status.isVisible;
    }).toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  }

  @override
  Future<List<Certificate>> getFacultyStudentCertificates({
    required String facultyUid,
    required String collegeId,
    required String departmentId,
    String? sectionId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _store.values.where((c) {
      if (!c.status.isVisible) return false;
      // Scope: must match college AND department
      if (c.collegeId != collegeId) return false;
      if (c.departmentId != departmentId) return false;
      // Further scope if section provided
      if (sectionId != null && c.sectionId != sectionId) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  }

  @override
  Future<Certificate> verifyCertificate({
    required String certificateId,
    required String verifierUid,
    required String verifierName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final cert = _store[certificateId];
    if (cert == null) throw Exception('Certificate not found: $certificateId');
    // Security: student cannot verify their own certificate
    if (cert.studentUid == verifierUid) {
      throw Exception('Permission denied: students cannot verify their own certificates.');
    }
    final verified = cert.copyWith(
      isVerified: true,
      verifiedBy: verifierUid,
      verifiedAt: DateTime.now(),
      status: CertificateStatus.verified,
      updatedAt: DateTime.now(),
      updatedBy: verifierUid,
    );
    _store[certificateId] = verified;
    return verified;
  }

  @override
  Stream<List<Certificate>> watchStudentCertificates(String studentUid) async* {
    yield await getStudentCertificates(studentUid);
  }

  @override
  Stream<List<Certificate>> watchFacultyStudentCertificates({
    required String facultyUid,
    required String collegeId,
    required String departmentId,
    String? sectionId,
  }) async* {
    yield await getFacultyStudentCertificates(
      facultyUid: facultyUid,
      collegeId: collegeId,
      departmentId: departmentId,
      sectionId: sectionId,
    );
  }
}
