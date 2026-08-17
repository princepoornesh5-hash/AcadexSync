import 'certificate_type.dart';
import 'certificate_status.dart';

class Certificate {
  final String id;

  // Permanent student identity — remains valid even after graduation
  final String studentId;
  final String studentUid;
  final String studentName;

  // Academic context at time of upload (informational only — not used for access control)
  final String? collegeId;
  final String? departmentId;
  final String? courseId;
  final String? academicYearId;
  final String? semesterId;
  final String? sectionId;

  // Certificate metadata
  final String title;
  final CertificateType type;
  final String? description;
  final String issuer;
  final DateTime issueDate;

  // File reference (NOT the binary data — just references to the storage layer)
  final String fileName;
  final String fileType; // e.g., 'pdf', 'jpg'
  final int fileSizeBytes;
  final String storageFileId;
  final String storagePath;

  // Lifecycle
  final CertificateStatus status;
  final DateTime uploadedAt;
  final DateTime updatedAt;
  final String uploadedBy;    // uid of the uploader (student)
  final String? updatedBy;

  // Verification
  final bool isVerified;
  final String? verifiedBy;   // uid of faculty/admin who verified
  final DateTime? verifiedAt;

  const Certificate({
    required this.id,
    required this.studentId,
    required this.studentUid,
    required this.studentName,
    this.collegeId,
    this.departmentId,
    this.courseId,
    this.academicYearId,
    this.semesterId,
    this.sectionId,
    required this.title,
    required this.type,
    this.description,
    required this.issuer,
    required this.issueDate,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    required this.storageFileId,
    required this.storagePath,
    this.status = CertificateStatus.active,
    required this.uploadedAt,
    required this.updatedAt,
    required this.uploadedBy,
    this.updatedBy,
    this.isVerified = false,
    this.verifiedBy,
    this.verifiedAt,
  });

  Certificate copyWith({
    String? id,
    String? studentId,
    String? studentUid,
    String? studentName,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    String? title,
    CertificateType? type,
    String? description,
    String? issuer,
    DateTime? issueDate,
    String? fileName,
    String? fileType,
    int? fileSizeBytes,
    String? storageFileId,
    String? storagePath,
    CertificateStatus? status,
    DateTime? uploadedAt,
    DateTime? updatedAt,
    String? uploadedBy,
    String? updatedBy,
    bool? isVerified,
    String? verifiedBy,
    DateTime? verifiedAt,
  }) {
    return Certificate(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      academicYearId: academicYearId ?? this.academicYearId,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      title: title ?? this.title,
      type: type ?? this.type,
      description: description ?? this.description,
      issuer: issuer ?? this.issuer,
      issueDate: issueDate ?? this.issueDate,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      storageFileId: storageFileId ?? this.storageFileId,
      storagePath: storagePath ?? this.storagePath,
      status: status ?? this.status,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isVerified: isVerified ?? this.isVerified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      studentUid: json['studentUid'] as String,
      studentName: json['studentName'] as String? ?? '',
      collegeId: json['collegeId'] as String?,
      departmentId: json['departmentId'] as String?,
      courseId: json['courseId'] as String?,
      academicYearId: json['academicYearId'] as String?,
      semesterId: json['semesterId'] as String?,
      sectionId: json['sectionId'] as String?,
      title: json['title'] as String,
      type: CertificateTypeExtension.fromValue(json['type'] as String? ?? 'other'),
      description: json['description'] as String?,
      issuer: json['issuer'] as String,
      issueDate: DateTime.parse(json['issueDate'] as String),
      fileName: json['fileName'] as String,
      fileType: json['fileType'] as String? ?? 'pdf',
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      storageFileId: json['storageFileId'] as String,
      storagePath: json['storagePath'] as String,
      status: CertificateStatusExtension.fromValue(json['status'] as String? ?? 'active'),
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      uploadedBy: json['uploadedBy'] as String,
      updatedBy: json['updatedBy'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      verifiedBy: json['verifiedBy'] as String?,
      verifiedAt: json['verifiedAt'] != null ? DateTime.parse(json['verifiedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentUid': studentUid,
    'studentName': studentName,
    'collegeId': collegeId,
    'departmentId': departmentId,
    'courseId': courseId,
    'academicYearId': academicYearId,
    'semesterId': semesterId,
    'sectionId': sectionId,
    'title': title,
    'type': type.value,
    'description': description,
    'issuer': issuer,
    'issueDate': issueDate.toIso8601String(),
    'fileName': fileName,
    'fileType': fileType,
    'fileSizeBytes': fileSizeBytes,
    'storageFileId': storageFileId,
    'storagePath': storagePath,
    'status': status.value,
    'uploadedAt': uploadedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'uploadedBy': uploadedBy,
    'updatedBy': updatedBy,
    'isVerified': isVerified,
    'verifiedBy': verifiedBy,
    'verifiedAt': verifiedAt?.toIso8601String(),
  };

  String get fileSizeDisplay {
    if (fileSizeBytes < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
