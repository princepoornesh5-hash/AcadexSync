import 'dart:typed_data';
import '../../../auth/domain/models/user_model.dart';
import '../models/official_certificate_models.dart';

abstract class OfficialCertificateRepository {
  // --- Requirement Management ---
  Future<List<OfficialCertificateRequirement>> getRequirements({
    required String collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    bool activeOnly = true,
  });

  Future<OfficialCertificateRequirement?> getRequirementById(String id);

  Future<void> createRequirement(OfficialCertificateRequirement requirement);

  Future<void> updateRequirement(OfficialCertificateRequirement requirement);

  Future<void> deleteRequirement(String id);

  Stream<List<OfficialCertificateRequirement>> watchRequirements(
    String collegeId, {
    String? departmentId,
  });

  // --- Student Submissions ---
  Future<List<OfficialCertificate>> getSubmissions({
    required String collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? studentUid,
    String? requirementId,
    OfficialCertificateStatus? status,
  });

  Future<OfficialCertificate?> getSubmissionById(String id);

  Future<void> submitCertificate({
    required OfficialCertificate certificate,
    Uint8List? fileBytes,
    String? oldStoragePath,
  });

  Future<void> verifySubmission({
    required String submissionId,
    required String verifiedBy,
    required OfficialCertificateStatus status,
    String? rejectionReason,
  });

  Future<void> deleteSubmission({
    required String submissionId,
    required String storagePath,
  });

  Stream<List<OfficialCertificate>> watchStudentSubmissions(String studentUid);

  Stream<List<OfficialCertificate>> watchCollegeSubmissions(
    String collegeId, {
    String? departmentId,
  });

  // --- Student Requirement Resolution ---
  Future<List<RequirementWithSubmission>> getRequirementsWithSubmissionsForStudent({
    required UserModel student,
  });

  Stream<List<RequirementWithSubmission>> watchRequirementsWithSubmissionsForStudent({
    required UserModel student,
  });
}
