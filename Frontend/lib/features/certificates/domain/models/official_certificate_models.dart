import 'package:flutter/foundation.dart';

/// Applicability scope for an official certificate requirement.
enum RequirementApplicability {
  college,
  department,
  course,
  semester,
  section;

  String get value => name;

  static RequirementApplicability fromString(String val) {
    return RequirementApplicability.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => RequirementApplicability.college,
    );
  }

  String get displayName {
    switch (this) {
      case RequirementApplicability.college:
        return 'Entire College';
      case RequirementApplicability.department:
        return 'Department';
      case RequirementApplicability.course:
        return 'Course';
      case RequirementApplicability.semester:
        return 'Semester';
      case RequirementApplicability.section:
        return 'Section';
    }
  }
}

/// Status of an official certificate requirement.
enum RequirementStatus {
  active,
  inactive;

  String get value => name;

  static RequirementStatus fromString(String val) {
    return RequirementStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => RequirementStatus.active,
    );
  }
}

/// Verification status of a student's official certificate submission.
enum OfficialCertificateStatus {
  pending,
  verified,
  rejected,
  resubmissionRequired,
  archived;

  String get value => name;

  static OfficialCertificateStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'verified':
        return OfficialCertificateStatus.verified;
      case 'rejected':
        return OfficialCertificateStatus.rejected;
      case 'resubmissionrequired':
      case 'resubmission_required':
      case 'resubmit':
        return OfficialCertificateStatus.resubmissionRequired;
      case 'archived':
        return OfficialCertificateStatus.archived;
      case 'pending':
      default:
        return OfficialCertificateStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case OfficialCertificateStatus.pending:
        return 'Pending Verification';
      case OfficialCertificateStatus.verified:
        return 'Verified';
      case OfficialCertificateStatus.rejected:
        return 'Rejected';
      case OfficialCertificateStatus.resubmissionRequired:
        return 'Resubmission Required';
      case OfficialCertificateStatus.archived:
        return 'Archived';
    }
  }
}

/// Calculated overall state combining a requirement and its submission for a student.
enum RequirementSubmissionStatus {
  notSubmitted,
  pendingVerification,
  verified,
  rejected,
  resubmissionRequired,
  archived;

  String get displayName {
    switch (this) {
      case RequirementSubmissionStatus.notSubmitted:
        return 'Not Submitted';
      case RequirementSubmissionStatus.pendingVerification:
        return 'Pending Verification';
      case RequirementSubmissionStatus.verified:
        return 'Verified';
      case RequirementSubmissionStatus.rejected:
        return 'Rejected';
      case RequirementSubmissionStatus.resubmissionRequired:
        return 'Resubmission Required';
      case RequirementSubmissionStatus.archived:
        return 'Archived';
    }
  }
}

/// Model representing an official certificate/document requirement defined by College Admin or HOD.
@immutable
class OfficialCertificateRequirement {
  final String id;
  final String collegeId;
  final String? departmentId;
  final String? courseId;
  final String? semesterId;
  final String? sectionId;
  final String? academicYearId;

  final String name;
  final String description;
  final String category; // e.g. 'General', 'Academic', 'Admission', 'Disciplinary'

  final bool required;
  final bool verificationRequired;

  final List<String> allowedFileTypes; // e.g. ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx']
  final int maxFileSizeBytes; // default: 10 * 1024 * 1024 (10MB)

  final RequirementApplicability applicableTo;
  final RequirementStatus status;

  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const OfficialCertificateRequirement({
    required this.id,
    required this.collegeId,
    this.departmentId,
    this.courseId,
    this.semesterId,
    this.sectionId,
    this.academicYearId,
    required this.name,
    this.description = '',
    this.category = 'General',
    this.required = true,
    this.verificationRequired = true,
    this.allowedFileTypes = const ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    this.maxFileSizeBytes = 10 * 1024 * 1024,
    this.applicableTo = RequirementApplicability.college,
    this.status = RequirementStatus.active,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == RequirementStatus.active;
  bool get isCollegeWide => applicableTo == RequirementApplicability.college;

  String get targetScopeDisplay {
    switch (applicableTo) {
      case RequirementApplicability.college:
        return 'College-wide';
      case RequirementApplicability.department:
        return 'Department (${departmentId ?? 'All'})';
      case RequirementApplicability.course:
        return 'Course (${courseId ?? 'All'})';
      case RequirementApplicability.semester:
        return 'Semester (${semesterId ?? 'All'})';
      case RequirementApplicability.section:
        return 'Section (${sectionId ?? 'All'})';
    }
  }

  OfficialCertificateRequirement copyWith({
    String? id,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? academicYearId,
    String? name,
    String? description,
    String? category,
    bool? required,
    bool? verificationRequired,
    List<String>? allowedFileTypes,
    int? maxFileSizeBytes,
    RequirementApplicability? applicableTo,
    RequirementStatus? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OfficialCertificateRequirement(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      academicYearId: academicYearId ?? this.academicYearId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      required: required ?? this.required,
      verificationRequired: verificationRequired ?? this.verificationRequired,
      allowedFileTypes: allowedFileTypes ?? this.allowedFileTypes,
      maxFileSizeBytes: maxFileSizeBytes ?? this.maxFileSizeBytes,
      applicableTo: applicableTo ?? this.applicableTo,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory OfficialCertificateRequirement.fromJson(Map<String, dynamic> json) {
    return OfficialCertificateRequirement(
      id: json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      departmentId: json['departmentId'] as String?,
      courseId: json['courseId'] as String?,
      semesterId: json['semesterId'] as String?,
      sectionId: json['sectionId'] as String?,
      academicYearId: json['academicYearId'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      required: json['required'] as bool? ?? true,
      verificationRequired: json['verificationRequired'] as bool? ?? true,
      allowedFileTypes: (json['allowedFileTypes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      maxFileSizeBytes: (json['maxFileSizeBytes'] as num?)?.toInt() ?? 10 * 1024 * 1024,
      applicableTo: RequirementApplicability.fromString(json['applicableTo'] as String? ?? 'college'),
      status: RequirementStatus.fromString(json['status'] as String? ?? 'active'),
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'courseId': courseId,
      'semesterId': semesterId,
      'sectionId': sectionId,
      'academicYearId': academicYearId,
      'name': name,
      'description': description,
      'category': category,
      'required': required,
      'verificationRequired': verificationRequired,
      'allowedFileTypes': allowedFileTypes,
      'maxFileSizeBytes': maxFileSizeBytes,
      'applicableTo': applicableTo.value,
      'status': status.value,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

/// Model representing a student's official certificate submission against a requirement.
@immutable
class OfficialCertificate {
  final String id;

  final String studentUid;
  final String studentId;
  final String studentName;

  final String collegeId;
  final String departmentId;
  final String courseId;
  final String semesterId;
  final String sectionId;
  final String academicYearId;

  final String requirementId;
  final String certificateName;
  final String? description;

  final String fileName;
  final String fileType;
  final int fileSizeBytes;
  final String storagePath;
  final String fileUrl;

  final OfficialCertificateStatus status;

  final DateTime uploadedAt;
  final DateTime? updatedAt;

  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? rejectionReason;

  const OfficialCertificate({
    required this.id,
    required this.studentUid,
    required this.studentId,
    required this.studentName,
    required this.collegeId,
    required this.departmentId,
    required this.courseId,
    required this.semesterId,
    required this.sectionId,
    required this.academicYearId,
    required this.requirementId,
    required this.certificateName,
    this.description,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    required this.storagePath,
    required this.fileUrl,
    this.status = OfficialCertificateStatus.pending,
    required this.uploadedAt,
    this.updatedAt,
    this.verifiedBy,
    this.verifiedAt,
    this.rejectionReason,
  });

  bool get isVerified => status == OfficialCertificateStatus.verified;
  bool get isPending => status == OfficialCertificateStatus.pending;
  bool get isRejected => status == OfficialCertificateStatus.rejected;
  bool get needsResubmission => status == OfficialCertificateStatus.resubmissionRequired;

  String get fileSizeDisplay {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  OfficialCertificate copyWith({
    String? id,
    String? studentUid,
    String? studentId,
    String? studentName,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? academicYearId,
    String? requirementId,
    String? certificateName,
    String? description,
    String? fileName,
    String? fileType,
    int? fileSizeBytes,
    String? storagePath,
    String? fileUrl,
    OfficialCertificateStatus? status,
    DateTime? uploadedAt,
    DateTime? updatedAt,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? rejectionReason,
  }) {
    return OfficialCertificate(
      id: id ?? this.id,
      studentUid: studentUid ?? this.studentUid,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      academicYearId: academicYearId ?? this.academicYearId,
      requirementId: requirementId ?? this.requirementId,
      certificateName: certificateName ?? this.certificateName,
      description: description ?? this.description,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      storagePath: storagePath ?? this.storagePath,
      fileUrl: fileUrl ?? this.fileUrl,
      status: status ?? this.status,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  factory OfficialCertificate.fromJson(Map<String, dynamic> json) {
    return OfficialCertificate(
      id: json['id'] as String? ?? '',
      studentUid: json['studentUid'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      semesterId: json['semesterId'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      academicYearId: json['academicYearId'] as String? ?? '',
      requirementId: json['requirementId'] as String? ?? '',
      certificateName: json['certificateName'] as String? ?? '',
      description: json['description'] as String?,
      fileName: json['fileName'] as String? ?? '',
      fileType: json['fileType'] as String? ?? '',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      storagePath: json['storagePath'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      status: OfficialCertificateStatus.fromString(json['status'] as String? ?? 'pending'),
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      verifiedBy: json['verifiedBy'] as String?,
      verifiedAt: json['verifiedAt'] != null ? DateTime.tryParse(json['verifiedAt'] as String) : null,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentUid': studentUid,
      'studentId': studentId,
      'studentName': studentName,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'courseId': courseId,
      'semesterId': semesterId,
      'sectionId': sectionId,
      'academicYearId': academicYearId,
      'requirementId': requirementId,
      'certificateName': certificateName,
      'description': description,
      'fileName': fileName,
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      'storagePath': storagePath,
      'fileUrl': fileUrl,
      'status': status.value,
      'uploadedAt': uploadedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }
}

/// View model pairing a requirement with a student's submission.
@immutable
class RequirementWithSubmission {
  final OfficialCertificateRequirement requirement;
  final OfficialCertificate? submission;

  const RequirementWithSubmission({
    required this.requirement,
    this.submission,
  });

  RequirementSubmissionStatus get calculatedStatus {
    if (submission == null) return RequirementSubmissionStatus.notSubmitted;
    switch (submission!.status) {
      case OfficialCertificateStatus.pending:
        return RequirementSubmissionStatus.pendingVerification;
      case OfficialCertificateStatus.verified:
        return RequirementSubmissionStatus.verified;
      case OfficialCertificateStatus.rejected:
        return RequirementSubmissionStatus.rejected;
      case OfficialCertificateStatus.resubmissionRequired:
        return RequirementSubmissionStatus.resubmissionRequired;
      case OfficialCertificateStatus.archived:
        return RequirementSubmissionStatus.archived;
    }
  }

  bool get canUpload => submission == null;
  bool get canUploadAgain =>
      submission != null &&
      (submission!.status == OfficialCertificateStatus.resubmissionRequired ||
          submission!.status == OfficialCertificateStatus.rejected);
  bool get canViewDocument => submission != null && submission!.fileUrl.isNotEmpty;
}
