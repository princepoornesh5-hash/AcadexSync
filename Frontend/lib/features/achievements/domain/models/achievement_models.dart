import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Categories for student-owned achievements.
enum AchievementCategory {
  academicMerit,
  achievement,
  prizeAward,
  competition,
  technical,
  skill,
  workshop,
  internship,
  hackathon,
  sports,
  cultural,
  leadership,
  certification,
  course,
  other;

  String get displayName {
    switch (this) {
      case AchievementCategory.academicMerit:
        return 'Academic Merit';
      case AchievementCategory.achievement:
        return 'Achievement';
      case AchievementCategory.prizeAward:
        return 'Prize / Award';
      case AchievementCategory.competition:
        return 'Competition';
      case AchievementCategory.technical:
        return 'Technical';
      case AchievementCategory.skill:
        return 'Skill';
      case AchievementCategory.workshop:
        return 'Workshop';
      case AchievementCategory.internship:
        return 'Internship';
      case AchievementCategory.hackathon:
        return 'Hackathon';
      case AchievementCategory.sports:
        return 'Sports';
      case AchievementCategory.cultural:
        return 'Cultural';
      case AchievementCategory.leadership:
        return 'Leadership';
      case AchievementCategory.certification:
        return 'Certification';
      case AchievementCategory.course:
        return 'Course';
      case AchievementCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case AchievementCategory.academicMerit:
        return LucideIcons.graduationCap;
      case AchievementCategory.achievement:
        return LucideIcons.trophy;
      case AchievementCategory.prizeAward:
        return LucideIcons.award;
      case AchievementCategory.competition:
        return LucideIcons.medal;
      case AchievementCategory.technical:
        return LucideIcons.cpu;
      case AchievementCategory.skill:
        return LucideIcons.zap;
      case AchievementCategory.workshop:
        return LucideIcons.presentation;
      case AchievementCategory.internship:
        return LucideIcons.briefcase;
      case AchievementCategory.hackathon:
        return LucideIcons.code;
      case AchievementCategory.sports:
        return LucideIcons.activity;
      case AchievementCategory.cultural:
        return LucideIcons.music;
      case AchievementCategory.leadership:
        return LucideIcons.users;
      case AchievementCategory.certification:
        return LucideIcons.fileBadge;
      case AchievementCategory.course:
        return LucideIcons.bookOpen;
      case AchievementCategory.other:
        return LucideIcons.sparkles;
    }
  }

  static AchievementCategory fromString(String val) {
    return AchievementCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.displayName.toLowerCase() == val.toLowerCase(),
      orElse: () => AchievementCategory.other,
    );
  }
}

/// Verification status for achievements submitted for review.
enum AchievementVerificationStatus {
  unverified,
  pending,
  verified,
  rejected;

  String get displayName {
    switch (this) {
      case AchievementVerificationStatus.unverified:
        return 'Unverified';
      case AchievementVerificationStatus.pending:
        return 'Pending Verification';
      case AchievementVerificationStatus.verified:
        return 'Verified';
      case AchievementVerificationStatus.rejected:
        return 'Rejected';
    }
  }

  static AchievementVerificationStatus fromString(String val) {
    return AchievementVerificationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => AchievementVerificationStatus.unverified,
    );
  }
}

/// Lifecycle status of an achievement.
enum AchievementStatus {
  active,
  archived;

  static AchievementStatus fromString(String val) {
    return AchievementStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => AchievementStatus.active,
    );
  }
}

/// Sort options for achievement listing.
enum AchievementSortOption {
  newest,
  oldest,
  alphabetical,
  verifiedFirst;

  String get displayName {
    switch (this) {
      case AchievementSortOption.newest:
        return 'Newest First';
      case AchievementSortOption.oldest:
        return 'Oldest First';
      case AchievementSortOption.alphabetical:
        return 'A-Z';
      case AchievementSortOption.verifiedFirst:
        return 'Verified First';
    }
  }
}

/// Core Achievement entity representing a student accomplishment or credential.
class Achievement {
  final String id;

  // Student Identity & Academic Context (Immutable post-creation)
  final String studentUid;
  final String studentId;
  final String studentName;
  final String collegeId;
  final String departmentId;
  final String courseId;
  final String semesterId;
  final String sectionId;
  final String academicYearId;

  // Content & Details
  final AchievementCategory category;
  final String title;
  final String description;
  final String issuer;
  final DateTime achievementDate;
  final List<String> skills; // Tags e.g. ['Flutter', 'Firebase']

  // Proof & Storage Asset
  final String? fileName;
  final String? fileType;
  final int fileSizeBytes;
  final String? storagePath;
  final String? fileUrl;

  // Lifecycle
  final AchievementStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;

  // Verification Engine
  final bool isVerificationRequested;
  final AchievementVerificationStatus verificationStatus;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? verificationNote;

  const Achievement({
    required this.id,
    required this.studentUid,
    required this.studentId,
    required this.studentName,
    required this.collegeId,
    required this.departmentId,
    this.courseId = '',
    this.semesterId = '',
    this.sectionId = '',
    this.academicYearId = '',
    required this.category,
    required this.title,
    this.description = '',
    required this.issuer,
    required this.achievementDate,
    this.skills = const [],
    this.fileName,
    this.fileType,
    this.fileSizeBytes = 0,
    this.storagePath,
    this.fileUrl,
    this.status = AchievementStatus.active,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    this.isVerificationRequested = false,
    this.verificationStatus = AchievementVerificationStatus.unverified,
    this.verifiedBy,
    this.verifiedAt,
    this.verificationNote,
  });

  bool get isVerified => verificationStatus == AchievementVerificationStatus.verified;
  bool get isPending => verificationStatus == AchievementVerificationStatus.pending;
  bool get isRejected => verificationStatus == AchievementVerificationStatus.rejected;
  bool get isUnverified => verificationStatus == AchievementVerificationStatus.unverified;
  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;
  int get year => achievementDate.year;

  String get fileSizeDisplay {
    if (fileSizeBytes <= 0) return '0 B';
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage {
    final type = fileType?.toLowerCase() ?? '';
    return type == 'jpg' || type == 'jpeg' || type == 'png';
  }

  bool get isPdf {
    final type = fileType?.toLowerCase() ?? '';
    return type == 'pdf';
  }

  Achievement copyWith({
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
    AchievementCategory? category,
    String? title,
    String? description,
    String? issuer,
    DateTime? achievementDate,
    List<String>? skills,
    String? fileName,
    String? fileType,
    int? fileSizeBytes,
    String? storagePath,
    String? fileUrl,
    AchievementStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isVerificationRequested,
    AchievementVerificationStatus? verificationStatus,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? verificationNote,
  }) {
    return Achievement(
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
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      issuer: issuer ?? this.issuer,
      achievementDate: achievementDate ?? this.achievementDate,
      skills: skills ?? this.skills,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      storagePath: storagePath ?? this.storagePath,
      fileUrl: fileUrl ?? this.fileUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isVerificationRequested: isVerificationRequested ?? this.isVerificationRequested,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verificationNote: verificationNote ?? this.verificationNote,
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
      'category': category.name,
      'title': title,
      'description': description,
      'issuer': issuer,
      'achievementDate': achievementDate.toIso8601String(),
      'skills': skills,
      'fileName': fileName,
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      'storagePath': storagePath,
      'fileUrl': fileUrl,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'isVerificationRequested': isVerificationRequested,
      'verificationStatus': verificationStatus.name,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verificationNote': verificationNote,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
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
      category: AchievementCategory.fromString(json['category'] as String? ?? 'other'),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      issuer: json['issuer'] as String? ?? '',
      achievementDate: json['achievementDate'] != null
          ? DateTime.tryParse(json['achievementDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      fileName: json['fileName'] as String?,
      fileType: json['fileType'] as String?,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      storagePath: json['storagePath'] as String?,
      fileUrl: json['fileUrl'] as String?,
      status: AchievementStatus.fromString(json['status'] as String? ?? 'active'),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      createdBy: json['createdBy'] as String? ?? '',
      isVerificationRequested: json['isVerificationRequested'] as bool? ?? false,
      verificationStatus: AchievementVerificationStatus.fromString(
        json['verificationStatus'] as String? ?? 'unverified',
      ),
      verifiedBy: json['verifiedBy'] as String?,
      verifiedAt: json['verifiedAt'] != null ? DateTime.tryParse(json['verifiedAt'] as String) : null,
      verificationNote: json['verificationNote'] as String?,
    );
  }
}

/// Aggregated metrics for student and administrative dashboards.
class AchievementMetrics {
  final int total;
  final int verified;
  final int pending;
  final int unverified;
  final int rejected;
  final int currentYearCount;

  const AchievementMetrics({
    this.total = 0,
    this.verified = 0,
    this.pending = 0,
    this.unverified = 0,
    this.rejected = 0,
    this.currentYearCount = 0,
  });
}

/// Filter state for querying and presentation.
class AchievementFilter {
  final String searchQuery;
  final AchievementCategory? category;
  final AchievementVerificationStatus? verificationStatus;
  final int? year;
  final AchievementSortOption sortOption;

  const AchievementFilter({
    this.searchQuery = '',
    this.category,
    this.verificationStatus,
    this.year,
    this.sortOption = AchievementSortOption.newest,
  });

  AchievementFilter copyWith({
    String? searchQuery,
    AchievementCategory? category,
    bool clearCategory = false,
    AchievementVerificationStatus? verificationStatus,
    bool clearVerificationStatus = false,
    int? year,
    bool clearYear = false,
    AchievementSortOption? sortOption,
  }) {
    return AchievementFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      category: clearCategory ? null : (category ?? this.category),
      verificationStatus: clearVerificationStatus ? null : (verificationStatus ?? this.verificationStatus),
      year: clearYear ? null : (year ?? this.year),
      sortOption: sortOption ?? this.sortOption,
    );
  }
}
