import 'dart:async';
import 'dart:typed_data';
import '../../../../core/firebase/firebase_exceptions.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/official_certificate_models.dart';
import '../../domain/repositories/official_certificate_repository.dart';

class MockOfficialCertificateRepository implements OfficialCertificateRepository {
  final UserModel? currentUser;

  final List<OfficialCertificateRequirement> _requirements = [];
  final List<OfficialCertificate> _submissions = [];
  final Set<String> _simulatedStorageFiles = {};

  final _requirementsController = StreamController<List<OfficialCertificateRequirement>>.broadcast();
  final _submissionsController = StreamController<List<OfficialCertificate>>.broadcast();

  bool _initialized = false;

  MockOfficialCertificateRepository({
    this.currentUser,
    List<OfficialCertificateRequirement>? initialRequirements,
    List<OfficialCertificate>? initialSubmissions,
  }) {
    if (initialRequirements != null) {
      _requirements.addAll(initialRequirements);
      _initialized = true;
    }
    if (initialSubmissions != null) {
      _submissions.addAll(initialSubmissions);
      _initialized = true;
    }
    _initData();
  }

  Future<void> _delay() async => await Future.delayed(const Duration(milliseconds: 10));

  void _emitRequirements() {
    if (!_requirementsController.isClosed) {
      _requirementsController.add(List.from(_requirements));
    }
  }

  void _emitSubmissions() {
    if (!_submissionsController.isClosed) {
      _submissionsController.add(List.from(_submissions));
    }
  }

  void _initData() {
    if (_initialized || _requirements.isNotEmpty) {
      _initialized = true;
      return;
    }

    final now = DateTime.now();

    // Default college-wide requirements for 'c1'
    _requirements.addAll([
      OfficialCertificateRequirement(
        id: 'req_tc',
        collegeId: 'c1',
        name: 'Transfer Certificate (TC)',
        description: 'Original Transfer Certificate from previous institution.',
        category: 'Admission',
        required: true,
        verificationRequired: true,
        allowedFileTypes: const ['pdf', 'jpg', 'jpeg', 'png'],
        maxFileSizeBytes: 10 * 1024 * 1024,
        applicableTo: RequirementApplicability.college,
        status: RequirementStatus.active,
        createdBy: 'admin_1',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      OfficialCertificateRequirement(
        id: 'req_birth',
        collegeId: 'c1',
        name: 'Birth Certificate',
        description: 'Official government-issued birth certificate for age verification.',
        category: 'General',
        required: true,
        verificationRequired: true,
        allowedFileTypes: const ['pdf', 'jpg', 'jpeg', 'png'],
        maxFileSizeBytes: 10 * 1024 * 1024,
        applicableTo: RequirementApplicability.college,
        status: RequirementStatus.active,
        createdBy: 'admin_1',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      OfficialCertificateRequirement(
        id: 'req_study',
        collegeId: 'c1',
        departmentId: 'd1',
        name: 'Study Certificate',
        description: 'Study Certificate for DCME department verification.',
        category: 'Academic',
        required: true,
        verificationRequired: true,
        allowedFileTypes: const ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        maxFileSizeBytes: 10 * 1024 * 1024,
        applicableTo: RequirementApplicability.department,
        status: RequirementStatus.active,
        createdBy: 'hod_1',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      OfficialCertificateRequirement(
        id: 'req_conduct',
        collegeId: 'c1',
        departmentId: 'd1',
        name: 'Conduct Certificate',
        description: 'Character and Conduct Certificate issued by head of institution.',
        category: 'General',
        required: false,
        verificationRequired: true,
        allowedFileTypes: const ['pdf', 'jpg', 'jpeg', 'png'],
        maxFileSizeBytes: 10 * 1024 * 1024,
        applicableTo: RequirementApplicability.department,
        status: RequirementStatus.active,
        createdBy: 'hod_1',
        createdAt: now.subtract(const Duration(days: 15)),
      ),
    ]);

    // Sample student submission for student 's1'
    final samplePath = '/colleges/c1/students/s1/official-certificates/birth_cert.pdf';
    _simulatedStorageFiles.add(samplePath);

    _submissions.add(
      OfficialCertificate(
        id: 'sub_1',
        studentUid: 's1',
        studentId: 's1',
        studentName: 'John Doe',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        academicYearId: 'ay1',
        requirementId: 'req_birth',
        certificateName: 'Birth Certificate',
        description: 'Uploaded government certificate',
        fileName: 'birth_cert.pdf',
        fileType: 'pdf',
        fileSizeBytes: 1024 * 1024 * 2,
        storagePath: samplePath,
        fileUrl: 'mock://storage$samplePath',
        status: OfficialCertificateStatus.verified,
        uploadedAt: now.subtract(const Duration(days: 10)),
        verifiedBy: 'admin_1',
        verifiedAt: now.subtract(const Duration(days: 8)),
      ),
    );

    _initialized = true;
  }

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
    await _delay();
    return _requirements.where((r) {
      if (r.collegeId != collegeId) return false;
      if (activeOnly && !r.isActive) return false;
      if (departmentId != null && r.departmentId != null && r.departmentId != departmentId) return false;
      if (courseId != null && r.courseId != null && r.courseId != courseId) return false;
      if (semesterId != null && r.semesterId != null && r.semesterId != semesterId) return false;
      if (sectionId != null && r.sectionId != null && r.sectionId != sectionId) return false;
      return true;
    }).toList();
  }

  @override
  Future<OfficialCertificateRequirement?> getRequirementById(String id) async {
    await _delay();
    return _requirements.where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<void> createRequirement(OfficialCertificateRequirement requirement) async {
    await _delay();
    if (currentUser != null) {
      if (currentUser!.role == AppRole.student) {
        throw const BackendPermissionException('Students cannot create certificate requirements');
      }
      if (currentUser!.role == AppRole.faculty) {
        throw const BackendPermissionException('Faculty cannot create certificate requirements');
      }
      if (currentUser!.role == AppRole.superAdmin) {
        throw const BackendPermissionException('Super Admin does not create routine college requirements');
      }
      if (currentUser!.role == AppRole.hod) {
        if (requirement.applicableTo == RequirementApplicability.college) {
          throw const BackendPermissionException('HOD cannot create college-wide requirements');
        }
        if (requirement.departmentId != null && requirement.departmentId != currentUser!.departmentId) {
          throw const BackendPermissionException('HOD can only create requirements for their own department');
        }
      }
      if (currentUser!.collegeId != null && currentUser!.collegeId != requirement.collegeId) {
        throw const BackendPermissionException('Access denied to other college');
      }
    }

    _requirements.add(requirement);
    _emitRequirements();
  }

  @override
  Future<void> updateRequirement(OfficialCertificateRequirement requirement) async {
    await _delay();
    if (currentUser != null) {
      if (currentUser!.role == AppRole.student || currentUser!.role == AppRole.faculty) {
        throw const BackendPermissionException('Unauthorized to modify requirements');
      }
      if (currentUser!.role == AppRole.hod && requirement.departmentId != currentUser!.departmentId) {
        throw const BackendPermissionException('HOD cannot modify requirements outside their department');
      }
    }

    final index = _requirements.indexWhere((r) => r.id == requirement.id);
    if (index == -1) throw Exception('Requirement not found');
    _requirements[index] = requirement.copyWith(updatedAt: DateTime.now());
    _emitRequirements();
  }

  @override
  Future<void> deleteRequirement(String id) async {
    await _delay();
    final req = _requirements.where((r) => r.id == id).firstOrNull;
    if (req == null) return;

    if (currentUser != null) {
      if (currentUser!.role == AppRole.student || currentUser!.role == AppRole.faculty) {
        throw const BackendPermissionException('Unauthorized to delete requirements');
      }
      if (currentUser!.role == AppRole.hod && req.departmentId != currentUser!.departmentId) {
        throw const BackendPermissionException('HOD cannot delete requirements outside their department');
      }
    }

    _requirements.removeWhere((r) => r.id == id);
    _emitRequirements();
  }

  @override
  Stream<List<OfficialCertificateRequirement>> watchRequirements(
    String collegeId, {
    String? departmentId,
  }) {
    Future.microtask(() => _emitRequirements());
    return _requirementsController.stream.map((list) {
      return list.where((r) {
        if (r.collegeId != collegeId) return false;
        if (departmentId != null && r.departmentId != null && r.departmentId != departmentId) return false;
        return true;
      }).toList();
    });
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
    await _delay();
    return _submissions.where((s) {
      if (s.collegeId != collegeId) return false;
      if (departmentId != null && s.departmentId != departmentId) return false;
      if (courseId != null && s.courseId != courseId) return false;
      if (semesterId != null && s.semesterId != semesterId) return false;
      if (sectionId != null && s.sectionId != sectionId) return false;
      if (studentUid != null && s.studentUid != studentUid) return false;
      if (requirementId != null && s.requirementId != requirementId) return false;
      if (status != null && s.status != status) return false;
      return true;
    }).toList();
  }

  @override
  Future<OfficialCertificate?> getSubmissionById(String id) async {
    await _delay();
    return _submissions.where((s) => s.id == id).firstOrNull;
  }

  @override
  Future<void> submitCertificate({
    required OfficialCertificate certificate,
    Uint8List? fileBytes,
    String? oldStoragePath,
  }) async {
    await _delay();

    // 1. File size validation (10MB)
    if (certificate.fileSizeBytes > 10 * 1024 * 1024) {
      throw const BackendValidationException('File size exceeds the 10MB limit');
    }

    // 2. File type validation
    final ext = certificate.fileType.toLowerCase().replaceAll('.', '');
    final allowed = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];
    if (!allowed.contains(ext)) {
      throw const BackendValidationException('Unsupported file format. Allowed: PDF, JPG, JPEG, PNG, DOC, DOCX');
    }

    // 3. Ownership / context enforcement
    if (currentUser != null && currentUser!.role == AppRole.student) {
      if (currentUser!.id != certificate.studentUid && currentUser!.firebaseUid != certificate.studentUid) {
        throw const BackendPermissionException('Students can only submit documents for themselves');
      }
      if (currentUser!.collegeId != null && currentUser!.collegeId != certificate.collegeId) {
        throw const BackendPermissionException('Invalid college scope');
      }
    }

    // 4. Clean up old physical file if replacing
    if (oldStoragePath != null && oldStoragePath.isNotEmpty) {
      _simulatedStorageFiles.remove(oldStoragePath);
    }

    _simulatedStorageFiles.add(certificate.storagePath);

    // 5. Update or insert submission
    final existingIdx = _submissions.indexWhere((s) =>
        s.id == certificate.id ||
        (s.studentUid == certificate.studentUid && s.requirementId == certificate.requirementId));

    if (existingIdx != -1) {
      _submissions[existingIdx] = certificate.copyWith(
        updatedAt: DateTime.now(),
        status: OfficialCertificateStatus.pending,
      );
    } else {
      _submissions.add(certificate);
    }

    _emitSubmissions();
  }

  @override
  Future<void> verifySubmission({
    required String submissionId,
    required String verifiedBy,
    required OfficialCertificateStatus status,
    String? rejectionReason,
  }) async {
    await _delay();
    final index = _submissions.indexWhere((s) => s.id == submissionId);
    if (index == -1) throw Exception('Submission not found');
    final sub = _submissions[index];

    if (currentUser != null) {
      if (currentUser!.role == AppRole.student) {
        throw const BackendPermissionException('Students cannot verify documents');
      }
      if (currentUser!.role == AppRole.hod && currentUser!.departmentId != sub.departmentId) {
        throw const BackendPermissionException('HOD can only verify submissions for their department');
      }
      if (currentUser!.role == AppRole.collegeAdmin && currentUser!.collegeId != sub.collegeId) {
        throw const BackendPermissionException('College Admin can only verify submissions in their college');
      }
    }

    if ((status == OfficialCertificateStatus.rejected || status == OfficialCertificateStatus.resubmissionRequired) &&
        (rejectionReason == null || rejectionReason.trim().isEmpty)) {
      throw const BackendValidationException('A reason is required when rejecting or requesting re-upload');
    }

    _submissions[index] = sub.copyWith(
      status: status,
      verifiedBy: verifiedBy,
      verifiedAt: DateTime.now(),
      rejectionReason: rejectionReason,
      updatedAt: DateTime.now(),
    );

    _emitSubmissions();
  }

  @override
  Future<void> deleteSubmission({
    required String submissionId,
    required String storagePath,
  }) async {
    await _delay();
    final sub = _submissions.where((s) => s.id == submissionId).firstOrNull;
    if (sub == null) return;

    if (currentUser != null && currentUser!.role == AppRole.student) {
      if (currentUser!.id != sub.studentUid && currentUser!.firebaseUid != sub.studentUid) {
        throw const BackendPermissionException('Cannot delete submissions of other students');
      }
    }

    _submissions.removeWhere((s) => s.id == submissionId);
    _simulatedStorageFiles.remove(storagePath);
    _emitSubmissions();
  }

  @override
  Stream<List<OfficialCertificate>> watchStudentSubmissions(String studentUid) {
    Future.microtask(() => _emitSubmissions());
    return _submissionsController.stream.map((list) {
      return list.where((s) => s.studentUid == studentUid).toList();
    });
  }

  @override
  Stream<List<OfficialCertificate>> watchCollegeSubmissions(
    String collegeId, {
    String? departmentId,
  }) {
    Future.microtask(() => _emitSubmissions());
    return _submissionsController.stream.map((list) {
      return list.where((s) {
        if (s.collegeId != collegeId) return false;
        if (departmentId != null && s.departmentId != departmentId) return false;
        return true;
      }).toList();
    });
  }

  // --- Student Resolution ---

  @override
  Future<List<RequirementWithSubmission>> getRequirementsWithSubmissionsForStudent({
    required UserModel student,
  }) async {
    await _delay();
    final collegeId = student.collegeId ?? '';
    final deptId = student.departmentId;
    final semId = student.semesterId;
    final secId = student.sectionId;

    // 1. Resolve applicable requirements
    final applicableRequirements = _requirements.where((r) {
      if (r.collegeId != collegeId || !r.isActive) return false;

      switch (r.applicableTo) {
        case RequirementApplicability.college:
          return true;
        case RequirementApplicability.department:
          return deptId != null && r.departmentId == deptId;
        case RequirementApplicability.course:
          return true; // course resolution if present
        case RequirementApplicability.semester:
          return semId != null && r.semesterId == semId;
        case RequirementApplicability.section:
          return secId != null && r.sectionId == secId;
      }
    }).toList();

    // 2. Fetch student's submissions
    final studentSubmissions = _submissions.where((s) =>
        s.studentUid == student.id || (student.firebaseUid != null && s.studentUid == student.firebaseUid));
    final subMap = {for (final s in studentSubmissions) s.requirementId: s};

    // 3. Map to RequirementWithSubmission
    return applicableRequirements.map((req) {
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
    Future.microtask(() {
      _emitRequirements();
      _emitSubmissions();
    });

    return _requirementsController.stream.asyncMap((_) async {
      return getRequirementsWithSubmissionsForStudent(student: student);
    });
  }

  bool isStorageFilePresent(String path) => _simulatedStorageFiles.contains(path);
}

final mockOfficialCertificateRepo = MockOfficialCertificateRepository();
