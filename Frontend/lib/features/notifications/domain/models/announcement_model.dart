import '../../../auth/domain/models/role_enum.dart';
import 'notification_models.dart';

enum AnnouncementAudienceScope {
  college,
  department,
  course,
  semester,
  section,
  role,
  individual;

  String get label {
    switch (this) {
      case AnnouncementAudienceScope.college:
        return 'College-wide';
      case AnnouncementAudienceScope.department:
        return 'Department';
      case AnnouncementAudienceScope.course:
        return 'Course';
      case AnnouncementAudienceScope.semester:
        return 'Semester';
      case AnnouncementAudienceScope.section:
        return 'Section';
      case AnnouncementAudienceScope.role:
        return 'Role-based';
      case AnnouncementAudienceScope.individual:
        return 'Individual';
    }
  }

  String get apiValue => name.toUpperCase();
  String get displayName => label;

  static AnnouncementAudienceScope fromString(String? val) {
    if (val == null) return AnnouncementAudienceScope.college;
    final lower = val.toLowerCase();
    return AnnouncementAudienceScope.values.firstWhere(
      (e) => e.name.toLowerCase() == lower,
      orElse: () => AnnouncementAudienceScope.college,
    );
  }
}

enum AnnouncementStatus {
  draft,
  published,
  archived;

  String get label {
    switch (this) {
      case AnnouncementStatus.draft:
        return 'Draft';
      case AnnouncementStatus.published:
        return 'Published';
      case AnnouncementStatus.archived:
        return 'Archived';
    }
  }

  String get apiValue => name.toUpperCase();
  String get displayName => label;

  static AnnouncementStatus fromString(String? val) {
    if (val == null) return AnnouncementStatus.draft;
    final lower = val.toLowerCase();
    return AnnouncementStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == lower,
      orElse: () => AnnouncementStatus.draft,
    );
  }
}

class AnnouncementModel {
  final String id;
  final String collegeId;
  final String? departmentId;
  final String title;
  final String body;
  final String category;
  final AnnouncementAudienceScope audienceScope;
  final AppRole? targetRole;
  final String? targetCourseId;
  final String? targetSemesterId;
  final String? targetSectionId;
  final String? targetUserId;
  final DateTime publishAt;
  final DateTime? expiresAt;
  final NotificationPriority priority;
  final bool isPinned;
  final AnnouncementStatus status;
  final String createdBy;
  final DateTime? publishedAt;
  final int recipientCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AnnouncementModel({
    required this.id,
    required this.collegeId,
    this.departmentId,
    required this.title,
    required this.body,
    this.category = 'announcement',
    required this.audienceScope,
    this.targetRole,
    this.targetCourseId,
    this.targetSemesterId,
    this.targetSectionId,
    this.targetUserId,
    required this.publishAt,
    this.expiresAt,
    this.priority = NotificationPriority.normal,
    this.isPinned = false,
    this.status = AnnouncementStatus.draft,
    required this.createdBy,
    this.publishedAt,
    this.recipientCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPublished => status == AnnouncementStatus.published;
  bool get isDraft => status == AnnouncementStatus.draft;
  bool get isArchived => status == AnnouncementStatus.archived;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'] ?? '';
    final rawCollegeId = json['collegeId'] ?? '';
    final rawCreatedBy = json['createdBy'] ?? '';

    return AnnouncementModel(
      id: rawId.toString(),
      collegeId: rawCollegeId.toString(),
      departmentId: json['departmentId']?.toString(),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      category: json['category']?.toString() ?? 'announcement',
      audienceScope: AnnouncementAudienceScope.fromString(json['audienceScope']?.toString()),
      targetRole: json['targetRole'] != null
          ? AppRole.values.firstWhere(
              (e) => e.value.toLowerCase() == json['targetRole'].toString().toLowerCase(),
              orElse: () => AppRole.student,
            )
          : null,
      targetCourseId: json['targetCourseId']?.toString(),
      targetSemesterId: json['targetSemesterId']?.toString(),
      targetSectionId: json['targetSectionId']?.toString(),
      targetUserId: json['targetUserId']?.toString(),
      publishAt: json['publishAt'] != null
          ? DateTime.tryParse(json['publishAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'].toString()) : null,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['priority']?.toString().toLowerCase() ?? ''),
        orElse: () => NotificationPriority.normal,
      ),
      isPinned: json['isPinned'] == true,
      status: AnnouncementStatus.fromString(json['status']?.toString()),
      createdBy: rawCreatedBy.toString(),
      publishedAt: json['publishedAt'] != null ? DateTime.tryParse(json['publishedAt'].toString()) : null,
      recipientCount: (json['recipientCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'title': title,
      'body': body,
      'category': category,
      'audienceScope': audienceScope.apiValue,
      'targetRole': targetRole?.value,
      'targetCourseId': targetCourseId,
      'targetSemesterId': targetSemesterId,
      'targetSectionId': targetSectionId,
      'targetUserId': targetUserId,
      'publishAt': publishAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'priority': priority.name,
      'isPinned': isPinned,
      'status': status.apiValue,
      'createdBy': createdBy,
      'publishedAt': publishedAt?.toIso8601String(),
      'recipientCount': recipientCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AnnouncementModel copyWith({
    String? id,
    String? collegeId,
    String? departmentId,
    String? title,
    String? body,
    String? category,
    AnnouncementAudienceScope? audienceScope,
    AppRole? targetRole,
    String? targetCourseId,
    String? targetSemesterId,
    String? targetSectionId,
    String? targetUserId,
    DateTime? publishAt,
    DateTime? expiresAt,
    NotificationPriority? priority,
    bool? isPinned,
    AnnouncementStatus? status,
    String? createdBy,
    DateTime? publishedAt,
    int? recipientCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      audienceScope: audienceScope ?? this.audienceScope,
      targetRole: targetRole ?? this.targetRole,
      targetCourseId: targetCourseId ?? this.targetCourseId,
      targetSemesterId: targetSemesterId ?? this.targetSemesterId,
      targetSectionId: targetSectionId ?? this.targetSectionId,
      targetUserId: targetUserId ?? this.targetUserId,
      publishAt: publishAt ?? this.publishAt,
      expiresAt: expiresAt ?? this.expiresAt,
      priority: priority ?? this.priority,
      isPinned: isPinned ?? this.isPinned,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      publishedAt: publishedAt ?? this.publishedAt,
      recipientCount: recipientCount ?? this.recipientCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
