import '../../domain/models/certificate_request_model.dart';

abstract class CertificateRequestRepository {
  /// Fetches the configured certificate types
  Future<List<ConfiguredCertificateType>> getCertificateTypes();

  /// Watch a specific student's certificate requests
  Stream<List<CertificateRequest>> watchStudentRequests(String studentUserId);

  /// Watch certificate requests for an administrator, scoped appropriately
  Stream<List<CertificateRequest>> watchAdminRequests({
    String? collegeId,
    String? departmentId,
  });

  /// Create a new certificate request
  Future<void> createRequest(CertificateRequest request);

  /// Update the status (and potentially other admin fields) of a request
  Future<void> updateRequestStatus({
    required String requestId,
    required CertificateRequestStatus status,
    String? rejectionReason,
    String? reviewedBy,
  });
}
