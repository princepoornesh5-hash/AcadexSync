import '../../../auth/domain/models/role_enum.dart';

enum NotificationCategory {
  request,
  assignment,
  attendance,
  academic,
  system,
  profile,
  security,
  notes,
  certificates,
  timetable,
  announcement,
  practical,
  assessment,
  result,
  calendar,
  general,
}

enum NotificationPriority {
  low,
  normal,
  high,
  critical,
}

enum NotificationStatus {
  unread,
  read,
  archived,
  expired,
}

enum NotificationAudienceType {
  personal,
  role,
  department,
  college,
  platform,
  section,
}

enum NotificationType {
  requestReceived,
  requestUpdated,
  requestResponded,
  requestApproved,
  requestRejected,
  assignmentPublished,
  assignmentDueSoon,
  assignmentOverdue,
  assignmentGraded,
  gradePosted,
  submissionReceived,
  practicalSessionScheduled,
  practicalSessionCancelled,
  practicalSessionCompleted,
  assessmentPublished,
  assessmentMarkUpdated,
  academicResultPublished,
  academicResultReopened,
  academicRecordInitialized,
  academicProgressionUpdated,
  calendarHolidayDeclared,
  calendarEventCreated,
  calendarEventCancelled,
  calendarOverride,
  holiday,
  timetableChange,
  attendanceAlert,
  attendanceAbsent,
  attendanceLate,
  notePublished,
  noteUpdated,
  attendanceLow,
  attendanceMarked,
  timetablePublished,
  timetableUpdated,
  announcement,
  system,
  general,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.requestReceived:
        return 'REQUEST_RECEIVED';
      case NotificationType.requestUpdated:
        return 'REQUEST_UPDATED';
      case NotificationType.requestResponded:
        return 'REQUEST_RESPONDED';
      case NotificationType.requestApproved:
        return 'REQUEST_APPROVED';
      case NotificationType.requestRejected:
        return 'REQUEST_REJECTED';
      case NotificationType.assignmentPublished:
        return 'ASSIGNMENT_PUBLISHED';
      case NotificationType.assignmentDueSoon:
        return 'ASSIGNMENT_DUE_SOON';
      case NotificationType.assignmentOverdue:
        return 'ASSIGNMENT_OVERDUE';
      case NotificationType.assignmentGraded:
        return 'ASSIGNMENT_GRADED';
      case NotificationType.gradePosted:
        return 'GRADE_POSTED';
      case NotificationType.submissionReceived:
        return 'SUBMISSION_RECEIVED';
      case NotificationType.practicalSessionScheduled:
        return 'PRACTICAL_SESSION_SCHEDULED';
      case NotificationType.practicalSessionCancelled:
        return 'PRACTICAL_SESSION_CANCELLED';
      case NotificationType.practicalSessionCompleted:
        return 'PRACTICAL_SESSION_COMPLETED';
      case NotificationType.assessmentPublished:
        return 'ASSESSMENT_PUBLISHED';
      case NotificationType.assessmentMarkUpdated:
        return 'ASSESSMENT_MARK_UPDATED';
      case NotificationType.academicResultPublished:
        return 'ACADEMIC_RESULT_PUBLISHED';
      case NotificationType.academicResultReopened:
        return 'ACADEMIC_RESULT_REOPENED';
      case NotificationType.academicRecordInitialized:
        return 'ACADEMIC_RECORD_INITIALIZED';
      case NotificationType.academicProgressionUpdated:
        return 'ACADEMIC_PROGRESSION_UPDATED';
      case NotificationType.calendarHolidayDeclared:
        return 'CALENDAR_HOLIDAY_DECLARED';
      case NotificationType.calendarEventCreated:
        return 'CALENDAR_EVENT_CREATED';
      case NotificationType.calendarEventCancelled:
        return 'CALENDAR_EVENT_CANCELLED';
      case NotificationType.calendarOverride:
        return 'CALENDAR_OVERRIDE';
      case NotificationType.holiday:
        return 'HOLIDAY';
      case NotificationType.timetableChange:
        return 'TIMETABLE_CHANGE';
      case NotificationType.attendanceAlert:
        return 'ATTENDANCE_ALERT';
      case NotificationType.attendanceAbsent:
        return 'ATTENDANCE_ABSENT';
      case NotificationType.attendanceLate:
        return 'ATTENDANCE_LATE';
      case NotificationType.notePublished:
        return 'NOTE_PUBLISHED';
      case NotificationType.noteUpdated:
        return 'NOTE_UPDATED';
      case NotificationType.attendanceLow:
        return 'ATTENDANCE_LOW';
      case NotificationType.attendanceMarked:
        return 'ATTENDANCE_MARKED';
      case NotificationType.timetablePublished:
        return 'TIMETABLE_PUBLISHED';
      case NotificationType.timetableUpdated:
        return 'TIMETABLE_UPDATED';
      case NotificationType.announcement:
        return 'ANNOUNCEMENT';
      case NotificationType.system:
        return 'SYSTEM';
      case NotificationType.general:
        return 'GENERAL';
    }
  }

  static NotificationType fromString(String? val) {
    if (val == null) return NotificationType.general;
    final normalized = val.trim().toUpperCase();
    for (final t in NotificationType.values) {
      if (t.value == normalized) return t;
    }
    return NotificationType.general;
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType? notificationType;
  final NotificationCategory category;
  final NotificationPriority priority;
  final NotificationStatus status;
  final NotificationAudienceType audienceType;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? readAt;

  // Targeting fields
  final String? recipientUserId;
  final AppRole? recipientRole;
  final String? collegeId;
  final String? departmentId;
  final String? sectionId;

  // Context fields
  final String? relatedEntityId;
  final String? relatedEntityType;
  final String? navigationTarget;
  final Map<String, dynamic>? metadata;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.notificationType,
    required this.category,
    required this.priority,
    this.status = NotificationStatus.unread,
    required this.audienceType,
    required this.timestamp,
    this.isRead = false,
    this.readAt,
    this.recipientUserId,
    this.recipientRole,
    this.collegeId,
    this.departmentId,
    this.sectionId,
    this.relatedEntityId,
    this.relatedEntityType,
    this.navigationTarget,
    this.metadata,
  });

  /// Convenient alias for message
  String get body => message;

  /// Convenient alias for id
  String get notificationId => id;

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? notificationType,
    NotificationCategory? category,
    NotificationPriority? priority,
    NotificationStatus? status,
    NotificationAudienceType? audienceType,
    DateTime? timestamp,
    bool? isRead,
    DateTime? readAt,
    String? recipientUserId,
    AppRole? recipientRole,
    String? collegeId,
    String? departmentId,
    String? sectionId,
    String? relatedEntityId,
    String? relatedEntityType,
    String? navigationTarget,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationType: notificationType ?? this.notificationType,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      audienceType: audienceType ?? this.audienceType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      recipientRole: recipientRole ?? this.recipientRole,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      sectionId: sectionId ?? this.sectionId,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      navigationTarget: navigationTarget ?? this.navigationTarget,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['notificationId'] ?? json['_id'] ?? '';
    final rawTitle = json['title'] ?? '';
    final rawMessage = json['body'] ?? json['message'] ?? '';
    final rawCreatedAt = json['createdAt'] ?? json['timestamp'];
    final rawEntityType = json['entityType'] ?? json['relatedEntityType'];
    final rawEntityId = json['entityId'] ?? json['relatedEntityId'];
    
    // Resolve deep link or default to related entity route
    String? rawDeepLink = json['deepLink'] ?? json['navigationTarget'];
    if (rawDeepLink == null || rawDeepLink.isEmpty) {
      final entityUpper = rawEntityType?.toString().toUpperCase();
      if (entityUpper == 'REQUEST' && rawEntityId != null) {
        final internalId = (json['metadata'] is Map && json['metadata']['internalId'] != null)
            ? json['metadata']['internalId']
            : rawEntityId;
        rawDeepLink = '/requests/$internalId';
      } else if (entityUpper == 'ASSIGNMENT' && rawEntityId != null) {
        rawDeepLink = '/assignments/$rawEntityId';
      } else if (entityUpper == 'ASSESSMENT' && rawEntityId != null) {
        rawDeepLink = '/assessments/$rawEntityId';
      } else if ((entityUpper == 'PRACTICAL' || entityUpper == 'PRACTICALSESSION') && rawEntityId != null) {
        rawDeepLink = '/practicals/$rawEntityId';
      } else if ((entityUpper == 'CALENDAR' || entityUpper == 'CALENDAREVENT') && rawEntityId != null) {
        rawDeepLink = '/calendar/event/$rawEntityId';
      } else if (entityUpper == 'ACADEMICRESULT') {
        rawDeepLink = '/academic-results';
      } else if (entityUpper == 'ATTENDANCESESSION' ||
          json['category']?.toString().toLowerCase() == 'attendance') {
        final subjectId = (json['metadata'] is Map) ? json['metadata']['subjectId']?.toString() : null;
        if (subjectId != null && subjectId.isNotEmpty) {
          rawDeepLink = '/attendance/student/subject/$subjectId';
        } else {
          rawDeepLink = '/attendance/student';
        }
      }
    }

    final rawTypeStr = json['notificationType'] ?? json['type'];
    final rawStatusStr = json['status']?.toString().toLowerCase();
    final isReadVal = json['isRead'] ?? false;

    return NotificationModel(
      id: rawId.toString(),
      title: rawTitle.toString(),
      message: rawMessage.toString(),
      notificationType: rawTypeStr != null ? NotificationTypeExtension.fromString(rawTypeStr.toString()) : null,
      category: NotificationCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['category']?.toString().toLowerCase() ?? ''),
        orElse: () => NotificationCategory.general,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['priority']?.toString().toLowerCase() ?? ''),
        orElse: () => NotificationPriority.normal,
      ),
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == rawStatusStr,
        orElse: () => isReadVal ? NotificationStatus.read : NotificationStatus.unread,
      ),
      audienceType: NotificationAudienceType.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['audienceType']?.toString().toLowerCase() ?? ''),
        orElse: () => NotificationAudienceType.personal,
      ),
      timestamp: rawCreatedAt != null 
          ? DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now() 
          : DateTime.now(),
      isRead: isReadVal,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'].toString()) : null,
      recipientUserId: json['recipientUserId']?.toString(),
      recipientRole: json['recipientRole'] != null
          ? AppRole.values.firstWhere((e) => e.value == json['recipientRole'], orElse: () => AppRole.student)
          : null,
      collegeId: json['collegeId']?.toString(),
      departmentId: json['departmentId']?.toString(),
      sectionId: json['sectionId']?.toString(),
      relatedEntityId: rawEntityId?.toString(),
      relatedEntityType: rawEntityType?.toString(),
      navigationTarget: rawDeepLink?.toString(),
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notificationId': id,
      'title': title,
      'message': message,
      'body': message,
      if (notificationType != null) ...{
        'notificationType': notificationType!.value,
        'type': notificationType!.value,
      },
      'category': category.name,
      'priority': priority.name,
      'status': status.name,
      'audienceType': audienceType.name,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': timestamp.toIso8601String(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'recipientUserId': recipientUserId,
      'recipientRole': recipientRole?.value,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'sectionId': sectionId,
      'relatedEntityId': relatedEntityId,
      'entityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
      'entityType': relatedEntityType,
      'navigationTarget': navigationTarget,
      'deepLink': navigationTarget,
      if (metadata != null) 'metadata': metadata,
    };
  }
}
