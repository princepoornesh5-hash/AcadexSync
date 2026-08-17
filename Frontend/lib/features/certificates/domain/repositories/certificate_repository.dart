import '../models/certificate.dart';
import '../models/certificate_status.dart';
import '../models/certificate_type.dart';

abstract class CertificateRepository {
  // Student operations — scoped to the student's own identity
  Future<List<Certificate>> getStudentCertificates(String studentUid);
  Future<Certificate?> getCertificate(String certificateId);
  Future<Certificate> createCertificate(Certificate certificate);
  Future<Certificate> updateCertificate(Certificate certificate);
  Future<void> deleteCertificate(String certificateId, String requestingUid);

  // Search & filter — within caller's authorized scope
  Future<List<Certificate>> searchCertificates(String query, {String? scopeStudentUid, String? scopeCollegeId, String? scopeDepartmentId});
  Future<List<Certificate>> filterCertificates({
    String? studentUid,
    String? collegeId,
    String? departmentId,
    CertificateType? type,
    CertificateStatus? status,
    DateTime? issuedAfter,
    DateTime? issuedBefore,
  });

  // Faculty operations — returns certificates for students in the authorized scope
  Future<List<Certificate>> getFacultyStudentCertificates({
    required String facultyUid,
    required String collegeId,
    required String departmentId,
    String? sectionId,
  });

  // Verification — only faculty/admin can verify
  Future<Certificate> verifyCertificate({
    required String certificateId,
    required String verifierUid,
    required String verifierName,
  });
}
