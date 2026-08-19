import 'dart:async';
import 'dart:typed_data';
import '../../../../core/firebase/firebase_exceptions.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../../../features/storage/domain/models/file_category.dart';
import '../../../../features/storage/domain/repositories/file_storage_repository.dart';
import '../../domain/models/official_certificate_models.dart';
import '../../domain/repositories/official_certificate_repository.dart';

class FirebaseOfficialCertificateRepository implements OfficialCertificateRepository {
  final FirestoreService _firestoreService;
  final FileStorageRepository? _fileStorageRepository;

  static const String _requirementsCollection = 'officialCertificateRequirements';
  static const String _certificatesCollection = 'officialCertificates';

  FirebaseOfficialCertificateRepository(
    this._firestoreService, {
    FileStorageRepository? fileStorageRepository,
  }) : _fileStorageRepository = fileStorageRepository;

  // --- Requirements ---

  @override
  Future<List<OfficialCertificateRequirement>> getRequirements({
    required String collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    bool activeOnly = true,
  }) async {
    final filters = <String, dynamic>{'collegeId': collegeId};
    if (departmentId != null) {
      filters['departmentId'] = departmentId;
    }
    if (activeOnly) {
      filters['status'] = RequirementStatus.active.name;
    }
    if (courseId != null) {
      filters['courseId'] = courseId;
    }
    if (semesterId != null) {
      filters['semesterId'] = semesterId;
    }
    if (sectionId != null) {
      filters['sectionId'] = sectionId;
    }

    final result = await _firestoreService.queryCollectionPaginated(
      _requirementsCollection,
      filters,
      limit: 100,
    );
    return result.data.map((d) => OfficialCertificateRequirement.fromJson(d)).toList();
  }

  @override
  Future<OfficialCertificateRequirement?> getRequirementById(String id) async {
    final doc = await _firestoreService.getDocument(_requirementsCollection, id);
    if (doc == null) return null;
    return OfficialCertificateRequirement.fromJson(doc);
  }

  @override
  Future<void> createRequirement(OfficialCertificateRequirement requirement) async {
    await _firestoreService.setDocument(
      _requirementsCollection,
      requirement.id,
      requirement.toJson(),
    );
  }

  @override
  Future<void> updateRequirement(OfficialCertificateRequirement requirement) async {
    await _firestoreService.setDocument(
      _requirementsCollection,
      requirement.id,
      requirement.toJson(),
    );
  }

  @override
  Future<void> deleteRequirement(String id) async {
    await _firestoreService.deleteDocument(_requirementsCollection, id);
  }

  @override
  Stream<List<OfficialCertificateRequirement>> watchRequirements(
    String collegeId, {
    String? departmentId,
  }) {
    final filters = <String, dynamic>{'collegeId': collegeId};
    if (departmentId != null) {
      filters['departmentId'] = departmentId;
    }
    return _firestoreService.watchQuery(_requirementsCollection, filters).map(
          (docs) => docs.map((d) => OfficialCertificateRequirement.fromJson(d)).toList(),
        );
  }

  // --- Submissions ---

  @override
  Future<List<OfficialCertificate>> getSubmissions({
    required String collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? studentUid,
    String? requirementId,
    OfficialCertificateStatus? status,
  }) async {
    final filters = <String, dynamic>{'collegeId': collegeId};
    if (departmentId != null) filters['departmentId'] = departmentId;
    if (courseId != null) filters['courseId'] = courseId;
    if (semesterId != null) filters['semesterId'] = semesterId;
    if (sectionId != null) filters['sectionId'] = sectionId;
    if (studentUid != null) filters['studentUid'] = studentUid;
    if (requirementId != null) filters['requirementId'] = requirementId;
    if (status != null) filters['status'] = status.value;

    final result = await _firestoreService.queryCollectionPaginated(
      _certificatesCollection,
      filters,
      limit: 100,
    );
    return result.data.map((d) => OfficialCertificate.fromJson(d)).toList();
  }

  @override
  Future<OfficialCertificate?> getSubmissionById(String id) async {
    final doc = await _firestoreService.getDocument(_certificatesCollection, id);
    if (doc == null) return null;
    return OfficialCertificate.fromJson(doc);
  }

  @override
  Future<void> submitCertificate({
    required OfficialCertificate certificate,
    Uint8List? fileBytes,
    String? oldStoragePath,
  }) async {
    // 1. Validation
    if (certificate.fileSizeBytes > 10 * 1024 * 1024) {
      throw const BackendValidationException('File size exceeds the 10MB limit');
    }

    String finalFileUrl = certificate.fileUrl;
    String finalStoragePath = certificate.storagePath;

    // 2. Storage upload if bytes provided
    if (fileBytes != null && _fileStorageRepository != null) {
      try {
        final stored = await _fileStorageRepository.uploadFile(
          bytes: fileBytes,
          fileName: certificate.fileName,
          contentType: _mapContentType(certificate.fileType),
          category: FileCategory.certificate,
          ownerUid: certificate.studentUid,
          collegeId: certificate.collegeId,
          departmentId: certificate.departmentId,
          studentId: certificate.studentId,
          customMetadata: {
            'requirementId': certificate.requirementId,
            'certificateName': certificate.certificateName,
          },
        );
        finalFileUrl = stored.downloadUrl;
        finalStoragePath = stored.storagePath;
      } catch (e) {
        throw BackendStorageException('Storage upload failed: $e');
      }
    }

    // 3. Firestore write with Rollback on error
    final updatedCert = certificate.copyWith(
      fileUrl: finalFileUrl,
      storagePath: finalStoragePath,
    );

    try {
      await _firestoreService.setDocument(
        _certificatesCollection,
        updatedCert.id,
        updatedCert.toJson(),
      );
    } catch (e) {
      // Rollback newly uploaded file on Firestore failure
      if (fileBytes != null && _fileStorageRepository != null) {
        try {
          await _fileStorageRepository.deleteFile(finalStoragePath);
        } catch (_) {}
      }
      throw BackendDatabaseException('Failed to save certificate metadata: $e');
    }

    // 4. Cleanup old storage file on successful replacement
    if (oldStoragePath != null &&
        oldStoragePath.isNotEmpty &&
        oldStoragePath != finalStoragePath &&
        _fileStorageRepository != null) {
      try {
        await _fileStorageRepository.deleteFile(oldStoragePath);
      } catch (_) {}
    }
  }

  @override
  Future<void> verifySubmission({
    required String submissionId,
    required String verifiedBy,
    required OfficialCertificateStatus status,
    String? rejectionReason,
  }) async {
    if (status == OfficialCertificateStatus.rejected ||
        status == OfficialCertificateStatus.resubmissionRequired) {
      if (rejectionReason == null || rejectionReason.trim().isEmpty) {
        throw const BackendValidationException(
          'Rejection reason is required when rejecting or requesting resubmission.',
        );
      }
    }

    final existing = await getSubmissionById(submissionId);
    if (existing == null) {
      throw const BackendDatabaseException('Certificate submission not found');
    }

    final updated = existing.copyWith(
      status: status,
      verifiedBy: verifiedBy,
      verifiedAt: DateTime.now(),
      rejectionReason: rejectionReason,
      updatedAt: DateTime.now(),
    );

    await _firestoreService.setDocument(
      _certificatesCollection,
      submissionId,
      updated.toJson(),
    );
  }

  @override
  Future<void> deleteSubmission({
    required String submissionId,
    required String storagePath,
  }) async {
    await _firestoreService.deleteDocument(_certificatesCollection, submissionId);

    if (storagePath.isNotEmpty && _fileStorageRepository != null) {
      try {
        await _fileStorageRepository.deleteFile(storagePath);
      } catch (_) {}
    }
  }

  @override
  Stream<List<OfficialCertificate>> watchStudentSubmissions(String studentUid) {
    return _firestoreService.watchQuery(_certificatesCollection, {'studentUid': studentUid}).map(
          (docs) => docs.map((d) => OfficialCertificate.fromJson(d)).toList(),
        );
  }

  @override
  Stream<List<OfficialCertificate>> watchCollegeSubmissions(
    String collegeId, {
    String? departmentId,
  }) {
    final filters = <String, dynamic>{'collegeId': collegeId};
    if (departmentId != null) filters['departmentId'] = departmentId;

    return _firestoreService.watchQuery(_certificatesCollection, filters).map(
          (docs) => docs.map((d) => OfficialCertificate.fromJson(d)).toList(),
        );
  }

  @override
  Future<List<RequirementWithSubmission>> getRequirementsWithSubmissionsForStudent({
    required UserModel student,
  }) async {
    final collegeId = student.collegeId ?? '';
    final allRequirements = await getRequirements(
      collegeId: collegeId,
      activeOnly: true,
    );

    final applicableReqs = allRequirements.where((r) {
      switch (r.applicableTo) {
        case RequirementApplicability.college:
          return true;
        case RequirementApplicability.department:
          return student.departmentId != null && r.departmentId == student.departmentId;
        case RequirementApplicability.course:
          return true;
        case RequirementApplicability.semester:
          return student.semesterId != null && r.semesterId == student.semesterId;
        case RequirementApplicability.section:
          return student.sectionId != null && r.sectionId == student.sectionId;
      }
    }).toList();

    final submissions = await getSubmissions(
      collegeId: collegeId,
      studentUid: student.id,
    );
    final subMap = {for (final s in submissions) s.requirementId: s};

    return applicableReqs.map((req) {
      return RequirementWithSubmission(
        requirement: req,
        submission: subMap[req.id],
      );
    }).toList();
  }

  @override
  Stream<List<RequirementWithSubmission>> watchRequirementsWithSubmissionsForStudent({
    required UserModel student,
  }) {
    late StreamController<List<RequirementWithSubmission>> controller;
    StreamSubscription? reqsSub;
    StreamSubscription? subsSub;

    List<OfficialCertificateRequirement>? latestReqs;
    List<OfficialCertificate>? latestSubs;

    void emitIfReady() {
      if (latestReqs == null || latestSubs == null || controller.isClosed) return;

      final applicableReqs = latestReqs!.where((r) {
        if (!r.isActive) return false;
        switch (r.applicableTo) {
          case RequirementApplicability.college:
            return true;
          case RequirementApplicability.department:
            return student.departmentId != null && r.departmentId == student.departmentId;
          case RequirementApplicability.course:
            return true;
          case RequirementApplicability.semester:
            return student.semesterId != null && r.semesterId == student.semesterId;
          case RequirementApplicability.section:
            return student.sectionId != null && r.sectionId == student.sectionId;
        }
      }).toList();

      final subMap = {for (final s in latestSubs!) s.requirementId: s};

      final result = applicableReqs.map((req) {
        return RequirementWithSubmission(
          requirement: req,
          submission: subMap[req.id],
        );
      }).toList();

      controller.add(result);
    }

    controller = StreamController<List<RequirementWithSubmission>>.broadcast(
      onListen: () {
        reqsSub = watchRequirements(student.collegeId ?? '').listen(
          (reqs) {
            latestReqs = reqs;
            emitIfReady();
          },
          onError: controller.addError,
        );

        subsSub = watchStudentSubmissions(student.id).listen(
          (subs) {
            latestSubs = subs;
            emitIfReady();
          },
          onError: controller.addError,
        );
      },
      onCancel: () {
        reqsSub?.cancel();
        subsSub?.cancel();
      },
    );

    return controller.stream;
  }

  String _mapContentType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
