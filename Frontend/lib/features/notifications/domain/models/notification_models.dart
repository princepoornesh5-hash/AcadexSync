import '../../../auth/domain/models/role_enum.dart';

enum NotificationCategory {
  attendance,
  academic,
  system,
  profile,
  security,
  notes,
  certificates,
  timetable,
  general,
}

enum NotificationPriority {
  low,
  normal,
  high,
  critical,
}

enum NotificationAudienceType {
  personal,
  role,
  department,
  college,
  platform,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationCategory category;
  final NotificationPriority priority;
  final NotificationAudienceType audienceType;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? readAt;

  // Targeting fields
  final String? recipientUserId;
  final AppRole? recipientRole;
  final String? collegeId;
  final String? departmentId;

  // Context fields
  final String? relatedEntityId;
  final String? relatedEntityType;
  final String? navigationTarget;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.priority,
    required this.audienceType,
    required this.timestamp,
    this.isRead = false,
    this.readAt,
    this.recipientUserId,
    this.recipientRole,
    this.collegeId,
    this.departmentId,
    this.relatedEntityId,
    this.relatedEntityType,
    this.navigationTarget,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationCategory? category,
    NotificationPriority? priority,
    NotificationAudienceType? audienceType,
    DateTime? timestamp,
    bool? isRead,
    DateTime? readAt,
    String? recipientUserId,
    AppRole? recipientRole,
    String? collegeId,
    String? departmentId,
    String? relatedEntityId,
    String? relatedEntityType,
    String? navigationTarget,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      audienceType: audienceType ?? this.audienceType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      recipientRole: recipientRole ?? this.recipientRole,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      navigationTarget: navigationTarget ?? this.navigationTarget,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      category: NotificationCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => NotificationCategory.general,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      audienceType: NotificationAudienceType.values.firstWhere(
        (e) => e.name == json['audienceType'],
        orElse: () => NotificationAudienceType.personal,
      ),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      recipientUserId: json['recipientUserId'],
      recipientRole: json['recipientRole'] != null
          ? AppRole.values.firstWhere((e) => e.value == json['recipientRole'], orElse: () => AppRole.student)
          : null,
      collegeId: json['collegeId'],
      departmentId: json['departmentId'],
      relatedEntityId: json['relatedEntityId'],
      relatedEntityType: json['relatedEntityType'],
      navigationTarget: json['navigationTarget'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'category': category.name,
      'priority': priority.name,
      'audienceType': audienceType.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'recipientUserId': recipientUserId,
      'recipientRole': recipientRole?.value,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
      'navigationTarget': navigationTarget,
    };
  }
}
