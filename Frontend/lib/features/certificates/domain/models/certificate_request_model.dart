import 'package:cloud_firestore/cloud_firestore.dart';

enum CertificateRequestStatus {
  pending,
  underReview,
  approved,
  rejected,
  ready,
  completed,
  cancelled
}

extension CertificateRequestStatusExtension on CertificateRequestStatus {
  String get value => name;

  String get displayName {
    switch (this) {
      case CertificateRequestStatus.pending: return 'Pending';
      case CertificateRequestStatus.underReview: return 'Under Review';
      case CertificateRequestStatus.approved: return 'Approved';
      case CertificateRequestStatus.rejected: return 'Rejected';
      case CertificateRequestStatus.ready: return 'Ready';
      case CertificateRequestStatus.completed: return 'Completed';
      case CertificateRequestStatus.cancelled: return 'Cancelled';
    }
  }

  static CertificateRequestStatus fromString(String val) {
    return CertificateRequestStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => CertificateRequestStatus.pending,
    );
  }
}

class ConfiguredCertificateType {
  final String id;
  final String name;
  final String description;
  final bool requiresReason;
  final bool requiresPurpose;
  final bool isActive;

  const ConfiguredCertificateType({
    required this.id,
    required this.name,
    required this.description,
    this.requiresReason = false,
    this.requiresPurpose = false,
    this.isActive = true,
  });

  factory ConfiguredCertificateType.fromJson(Map<String, dynamic> json) {
    return ConfiguredCertificateType(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      requiresReason: json['requiresReason'] as bool? ?? false,
      requiresPurpose: json['requiresPurpose'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'requiresReason': requiresReason,
    'requiresPurpose': requiresPurpose,
    'isActive': isActive,
  };
}

class CertificateRequest {
  final String id;
  
  // Student Context
  final String studentId;
  final String studentUserId;
  
  // Academic Context
  final String collegeId;
  final String departmentId;
  final String courseId;
  final String academicYearId;
  
  // Certificate Info
  final String certificateTypeId;
  final String certificateTypeName;
  final String? reason;
  final String? purpose;
  
  // State
  final CertificateRequestStatus status;
  final String? rejectionReason;
  final String? documentUrl;
  
  // Timestamps & Audit
  final DateTime requestedAt;
  final DateTime updatedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final DateTime createdAt;

  const CertificateRequest({
    required this.id,
    required this.studentId,
    required this.studentUserId,
    required this.collegeId,
    required this.departmentId,
    required this.courseId,
    required this.academicYearId,
    required this.certificateTypeId,
    required this.certificateTypeName,
    this.reason,
    this.purpose,
    this.status = CertificateRequestStatus.pending,
    this.rejectionReason,
    this.documentUrl,
    required this.requestedAt,
    required this.updatedAt,
    this.reviewedAt,
    this.reviewedBy,
    required this.createdAt,
  });

  factory CertificateRequest.fromJson(Map<String, dynamic> json) {
    return CertificateRequest(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      studentUserId: json['studentUserId'] as String,
      collegeId: json['collegeId'] as String,
      departmentId: json['departmentId'] as String,
      courseId: json['courseId'] as String,
      academicYearId: json['academicYearId'] as String,
      certificateTypeId: json['certificateTypeId'] as String,
      certificateTypeName: json['certificateTypeName'] as String,
      reason: json['reason'] as String?,
      purpose: json['purpose'] as String?,
      status: json['status'] != null 
          ? CertificateRequestStatusExtension.fromString(json['status'] as String) 
          : CertificateRequestStatus.pending,
      rejectionReason: json['rejectionReason'] as String?,
      documentUrl: json['documentUrl'] as String?,
      requestedAt: _parseDate(json['requestedAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
      reviewedAt: json['reviewedAt'] != null ? _parseDate(json['reviewedAt']) : null,
      reviewedBy: json['reviewedBy'] as String?,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentUserId': studentUserId,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'courseId': courseId,
      'academicYearId': academicYearId,
      'certificateTypeId': certificateTypeId,
      'certificateTypeName': certificateTypeName,
      'reason': reason,
      'purpose': purpose,
      'status': status.value,
      'rejectionReason': rejectionReason,
      'documentUrl': documentUrl,
      'requestedAt': requestedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.parse(date);
    return null;
  }

  CertificateRequest copyWith({
    String? id,
    String? studentId,
    String? studentUserId,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? academicYearId,
    String? certificateTypeId,
    String? certificateTypeName,
    String? reason,
    String? purpose,
    CertificateRequestStatus? status,
    String? rejectionReason,
    String? documentUrl,
    DateTime? requestedAt,
    DateTime? updatedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    DateTime? createdAt,
  }) {
    return CertificateRequest(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentUserId: studentUserId ?? this.studentUserId,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      academicYearId: academicYearId ?? this.academicYearId,
      certificateTypeId: certificateTypeId ?? this.certificateTypeId,
      certificateTypeName: certificateTypeName ?? this.certificateTypeName,
      reason: reason ?? this.reason,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      documentUrl: documentUrl ?? this.documentUrl,
      requestedAt: requestedAt ?? this.requestedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
