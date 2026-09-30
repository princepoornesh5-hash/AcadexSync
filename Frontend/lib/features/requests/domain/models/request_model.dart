import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/role_enum.dart';

enum RequestStatus {
  draft,
  submitted,
  received,
  inReview,
  approved,
  rejected,
  resolved,
  cancelled,
  closed,
}

extension RequestStatusExtension on RequestStatus {
  String get value {
    switch (this) {
      case RequestStatus.draft:
        return 'DRAFT';
      case RequestStatus.submitted:
        return 'SUBMITTED';
      case RequestStatus.received:
        return 'RECEIVED';
      case RequestStatus.inReview:
        return 'IN_REVIEW';
      case RequestStatus.approved:
        return 'APPROVED';
      case RequestStatus.rejected:
        return 'REJECTED';
      case RequestStatus.resolved:
        return 'RESOLVED';
      case RequestStatus.cancelled:
        return 'CANCELLED';
      case RequestStatus.closed:
        return 'CLOSED';
    }
  }

  String get displayName {
    switch (this) {
      case RequestStatus.draft:
        return 'Draft';
      case RequestStatus.submitted:
        return 'Submitted';
      case RequestStatus.received:
        return 'Received';
      case RequestStatus.inReview:
        return 'Under Review';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.rejected:
        return 'Rejected';
      case RequestStatus.resolved:
        return 'Resolved';
      case RequestStatus.cancelled:
        return 'Cancelled';
      case RequestStatus.closed:
        return 'Closed';
    }
  }

  Color get color {
    switch (this) {
      case RequestStatus.draft:
        return const Color(0xFF6B7280); // gray-500
      case RequestStatus.submitted:
        return AcadexColors.inkSecondary;
      case RequestStatus.received:
        return AcadexColors.primary;
      case RequestStatus.inReview:
        return const Color(0xFFD97706); // amber-600
      case RequestStatus.approved:
        return const Color(0xFF059669); // emerald-600
      case RequestStatus.rejected:
        return const Color(0xFFDC2626); // red-600
      case RequestStatus.resolved:
        return const Color(0xFF0D9488); // teal-600
      case RequestStatus.cancelled:
        return const Color(0xFF9CA3AF); // gray-400
      case RequestStatus.closed:
        return const Color(0xFF64748B); // slate-500
    }
  }

  Color get backgroundColor {
    switch (this) {
      case RequestStatus.draft:
        return const Color(0xFFF3F4F6); // gray-100
      case RequestStatus.submitted:
        return AcadexColors.surfaceHover;
      case RequestStatus.received:
        return AcadexColors.primaryLight;
      case RequestStatus.inReview:
        return const Color(0xFFFEF3C7); // amber-100
      case RequestStatus.approved:
        return const Color(0xFFD1FAE5); // emerald-100
      case RequestStatus.rejected:
        return const Color(0xFFFEE2E2); // red-100
      case RequestStatus.resolved:
        return const Color(0xFFCCFBF1); // teal-100
      case RequestStatus.cancelled:
        return const Color(0xFFF3F4F6); // gray-100
      case RequestStatus.closed:
        return const Color(0xFFF1F5F9); // slate-100
    }
  }

  IconData get icon {
    switch (this) {
      case RequestStatus.draft:
        return LucideIcons.fileEdit;
      case RequestStatus.submitted:
        return LucideIcons.send;
      case RequestStatus.received:
        return LucideIcons.inbox;
      case RequestStatus.inReview:
        return LucideIcons.clock;
      case RequestStatus.approved:
        return LucideIcons.checkCircle;
      case RequestStatus.rejected:
        return LucideIcons.xCircle;
      case RequestStatus.resolved:
        return LucideIcons.checkCheck;
      case RequestStatus.cancelled:
        return LucideIcons.ban;
      case RequestStatus.closed:
        return LucideIcons.archive;
    }
  }

  static RequestStatus fromString(String val) {
    final clean = val.toUpperCase().trim();
    switch (clean) {
      case 'DRAFT':
        return RequestStatus.draft;
      case 'SUBMITTED':
        return RequestStatus.submitted;
      case 'RECEIVED':
        return RequestStatus.received;
      case 'IN_REVIEW':
      case 'INREVIEW':
      case 'UNDER_REVIEW':
      case 'REVIEW':
        return RequestStatus.inReview;
      case 'APPROVED':
        return RequestStatus.approved;
      case 'REJECTED':
        return RequestStatus.rejected;
      case 'RESOLVED':
        return RequestStatus.resolved;
      case 'CANCELLED':
        return RequestStatus.cancelled;
      case 'CLOSED':
        return RequestStatus.closed;
      default:
        return RequestStatus.submitted;
    }
  }
}

enum RequestType {
  leave,
  attendanceCorrection,
  academicIssue,
  generalRequest,
  complaintIssue,
  documentRequest,
  onDuty,
  permission,
  timetableChange,
  resourceRequest,
  classroomLabIssue,
  workloadConcern,
  facultyRequirement,
  infrastructureIssue,
  academicApproval,
  eventWorkshopApproval,
  generalAdminRequest,
}

extension RequestTypeExtension on RequestType {
  String get value {
    switch (this) {
      case RequestType.leave:
        return 'LEAVE';
      case RequestType.attendanceCorrection:
        return 'ATTENDANCE_CORRECTION';
      case RequestType.academicIssue:
        return 'ACADEMIC_ISSUE';
      case RequestType.generalRequest:
        return 'GENERAL_REQUEST';
      case RequestType.complaintIssue:
        return 'COMPLAINT_ISSUE';
      case RequestType.documentRequest:
        return 'DOCUMENT_REQUEST';
      case RequestType.onDuty:
        return 'ON_DUTY';
      case RequestType.permission:
        return 'PERMISSION';
      case RequestType.timetableChange:
        return 'TIMETABLE_CHANGE';
      case RequestType.resourceRequest:
        return 'RESOURCE_REQUEST';
      case RequestType.classroomLabIssue:
        return 'CLASSROOM_LAB_ISSUE';
      case RequestType.workloadConcern:
        return 'WORKLOAD_CONCERN';
      case RequestType.facultyRequirement:
        return 'FACULTY_REQUIREMENT';
      case RequestType.infrastructureIssue:
        return 'INFRASTRUCTURE_ISSUE';
      case RequestType.academicApproval:
        return 'ACADEMIC_APPROVAL';
      case RequestType.eventWorkshopApproval:
        return 'EVENT_WORKSHOP_APPROVAL';
      case RequestType.generalAdminRequest:
        return 'GENERAL_ADMIN_REQUEST';
    }
  }

  String get displayName {
    switch (this) {
      case RequestType.leave:
        return 'Leave Request';
      case RequestType.attendanceCorrection:
        return 'Attendance Correction';
      case RequestType.academicIssue:
        return 'Academic Issue';
      case RequestType.generalRequest:
        return 'General Request';
      case RequestType.complaintIssue:
        return 'Complaint / Issue';
      case RequestType.documentRequest:
        return 'Document / Certificate';
      case RequestType.onDuty:
        return 'On-Duty Request';
      case RequestType.permission:
        return 'Permission Request';
      case RequestType.timetableChange:
        return 'Timetable Change';
      case RequestType.resourceRequest:
        return 'Resource Request';
      case RequestType.classroomLabIssue:
        return 'Classroom / Lab Issue';
      case RequestType.workloadConcern:
        return 'Workload Concern';
      case RequestType.facultyRequirement:
        return 'Faculty Requirement';
      case RequestType.infrastructureIssue:
        return 'Infrastructure Issue';
      case RequestType.academicApproval:
        return 'Academic Approval';
      case RequestType.eventWorkshopApproval:
        return 'Event / Workshop Approval';
      case RequestType.generalAdminRequest:
        return 'General Admin Request';
    }
  }

  IconData get icon {
    switch (this) {
      case RequestType.leave:
        return LucideIcons.calendarX2;
      case RequestType.attendanceCorrection:
        return LucideIcons.clipboardEdit;
      case RequestType.academicIssue:
        return LucideIcons.bookAlert;
      case RequestType.generalRequest:
        return LucideIcons.messageSquare;
      case RequestType.complaintIssue:
        return LucideIcons.alertTriangle;
      case RequestType.documentRequest:
        return LucideIcons.fileCheck;
      case RequestType.onDuty:
        return LucideIcons.briefcase;
      case RequestType.permission:
        return LucideIcons.shieldCheck;
      case RequestType.timetableChange:
        return LucideIcons.calendarDays;
      case RequestType.resourceRequest:
        return LucideIcons.packagePlus;
      case RequestType.classroomLabIssue:
        return LucideIcons.monitorX;
      case RequestType.workloadConcern:
        return LucideIcons.scale;
      case RequestType.facultyRequirement:
        return LucideIcons.userPlus;
      case RequestType.infrastructureIssue:
        return LucideIcons.wrench;
      case RequestType.academicApproval:
        return LucideIcons.fileSignature;
      case RequestType.eventWorkshopApproval:
        return LucideIcons.sparkles;
      case RequestType.generalAdminRequest:
        return LucideIcons.landmark;
    }
  }

  static RequestType fromString(String val) {
    final clean = val.toUpperCase().trim();
    switch (clean) {
      case 'LEAVE':
        return RequestType.leave;
      case 'ATTENDANCE_CORRECTION':
        return RequestType.attendanceCorrection;
      case 'ACADEMIC_ISSUE':
        return RequestType.academicIssue;
      case 'GENERAL_REQUEST':
        return RequestType.generalRequest;
      case 'COMPLAINT_ISSUE':
        return RequestType.complaintIssue;
      case 'DOCUMENT_REQUEST':
        return RequestType.documentRequest;
      case 'ON_DUTY':
        return RequestType.onDuty;
      case 'PERMISSION':
        return RequestType.permission;
      case 'TIMETABLE_CHANGE':
        return RequestType.timetableChange;
      case 'RESOURCE_REQUEST':
        return RequestType.resourceRequest;
      case 'CLASSROOM_LAB_ISSUE':
        return RequestType.classroomLabIssue;
      case 'WORKLOAD_CONCERN':
        return RequestType.workloadConcern;
      case 'FACULTY_REQUIREMENT':
        return RequestType.facultyRequirement;
      case 'INFRASTRUCTURE_ISSUE':
        return RequestType.infrastructureIssue;
      case 'ACADEMIC_APPROVAL':
        return RequestType.academicApproval;
      case 'EVENT_WORKSHOP_APPROVAL':
        return RequestType.eventWorkshopApproval;
      case 'GENERAL_ADMIN_REQUEST':
        return RequestType.generalAdminRequest;
      default:
        return RequestType.generalRequest;
    }
  }

  static List<RequestType> allowedTypesForRole(AppRole role) {
    switch (role) {
      case AppRole.student:
        return [
          RequestType.leave,
          RequestType.attendanceCorrection,
          RequestType.academicIssue,
          RequestType.generalRequest,
          RequestType.complaintIssue,
          RequestType.documentRequest,
        ];
      case AppRole.faculty:
        return [
          RequestType.leave,
          RequestType.onDuty,
          RequestType.permission,
          RequestType.timetableChange,
          RequestType.resourceRequest,
          RequestType.classroomLabIssue,
          RequestType.workloadConcern,
          RequestType.generalRequest,
        ];
      case AppRole.hod:
        return [
          RequestType.leave,
          RequestType.facultyRequirement,
          RequestType.resourceRequest,
          RequestType.infrastructureIssue,
          RequestType.academicApproval,
          RequestType.eventWorkshopApproval,
          RequestType.timetableChange,
          RequestType.generalAdminRequest,
        ];
      case AppRole.collegeAdmin:
      case AppRole.superAdmin:
        return [
          RequestType.generalRequest,
          RequestType.resourceRequest,
          RequestType.infrastructureIssue,
        ];
    }
  }
}

class AcademicContextModel {
  final String? courseId;
  final String? academicYearId;
  final String? semesterId;
  final String? sectionId;
  final String? subjectId;
  final String? facultyAssignmentId;
  final String? courseName;
  final String? sectionName;
  final String? subjectName;

  const AcademicContextModel({
    this.courseId,
    this.academicYearId,
    this.semesterId,
    this.sectionId,
    this.subjectId,
    this.facultyAssignmentId,
    this.courseName,
    this.sectionName,
    this.subjectName,
  });

  factory AcademicContextModel.fromJson(Map<String, dynamic> json) {
    return AcademicContextModel(
      courseId: json['courseId']?.toString(),
      academicYearId: json['academicYearId']?.toString(),
      semesterId: json['semesterId']?.toString(),
      sectionId: json['sectionId']?.toString(),
      subjectId: json['subjectId']?.toString(),
      facultyAssignmentId: json['facultyAssignmentId']?.toString(),
      courseName: json['courseName']?.toString(),
      sectionName: json['sectionName']?.toString(),
      subjectName: json['subjectName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (courseId != null) 'courseId': courseId,
      if (academicYearId != null) 'academicYearId': academicYearId,
      if (semesterId != null) 'semesterId': semesterId,
      if (sectionId != null) 'sectionId': sectionId,
      if (subjectId != null) 'subjectId': subjectId,
      if (facultyAssignmentId != null) 'facultyAssignmentId': facultyAssignmentId,
      if (courseName != null) 'courseName': courseName,
      if (sectionName != null) 'sectionName': sectionName,
      if (subjectName != null) 'subjectName': subjectName,
    };
  }
}

class RequestDetailsModel {
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? date;
  final String? resourceName;
  final String? requestedChange;
  final String? documentType;
  final String? reason;
  final Map<String, dynamic>? metadata;

  const RequestDetailsModel({
    this.startDate,
    this.endDate,
    this.date,
    this.resourceName,
    this.requestedChange,
    this.documentType,
    this.reason,
    this.metadata,
  });

  factory RequestDetailsModel.fromJson(Map<String, dynamic> json) {
    return RequestDetailsModel(
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      resourceName: json['resourceName']?.toString(),
      requestedChange: json['requestedChange']?.toString(),
      documentType: json['documentType']?.toString(),
      reason: json['reason']?.toString(),
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (date != null) 'date': date!.toIso8601String(),
      if (resourceName != null) 'resourceName': resourceName,
      if (requestedChange != null) 'requestedChange': requestedChange,
      if (documentType != null) 'documentType': documentType,
      if (reason != null) 'reason': reason,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

class RequestAuditEntryModel {
  final RequestStatus status;
  final String? changedBy;
  final String? changedByName;
  final String? note;
  final DateTime timestamp;

  const RequestAuditEntryModel({
    required this.status,
    this.changedBy,
    this.changedByName,
    this.note,
    required this.timestamp,
  });

  factory RequestAuditEntryModel.fromJson(Map<String, dynamic> json) {
    return RequestAuditEntryModel(
      status: RequestStatusExtension.fromString(json['status']?.toString() ?? 'SUBMITTED'),
      changedBy: json['changedBy']?.toString(),
      changedByName: json['changedByName']?.toString(),
      note: json['note']?.toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.value,
      'changedBy': changedBy,
      'changedByName': changedByName,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class RequestModel {
  final String id;
  final String requestId;
  final String collegeId;
  final String? departmentId;
  final String requesterUserId;
  final String requesterName;
  final AppRole requesterRole;
  final AppRole targetRole;
  final String? targetUserId;
  final String? targetName;
  final RequestType requestType;
  final String title;
  final String description;
  final AcademicContextModel? academicContext;
  final RequestDetailsModel? details;
  final RequestStatus status;
  final DateTime? respondedAt;
  final String? respondedBy;
  final String? respondedByName;
  final String? responseMessage;
  final List<RequestAuditEntryModel> history;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RequestModel({
    required this.id,
    required this.requestId,
    required this.collegeId,
    this.departmentId,
    required this.requesterUserId,
    required this.requesterName,
    required this.requesterRole,
    required this.targetRole,
    this.targetUserId,
    this.targetName,
    required this.requestType,
    required this.title,
    required this.description,
    this.academicContext,
    this.details,
    required this.status,
    this.respondedAt,
    this.respondedBy,
    this.respondedByName,
    this.responseMessage,
    this.history = const [],
    this.relatedEntityType,
    this.relatedEntityId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      requestId: json['requestId']?.toString() ?? '',
      collegeId: json['collegeId']?.toString() ?? '',
      departmentId: json['departmentId']?.toString(),
      requesterUserId: json['requesterUserId']?.toString() ?? '',
      requesterName: json['requesterName']?.toString() ?? 'Requester',
      requesterRole: AppRoleExtension.fromValue(json['requesterRole']?.toString() ?? 'STUDENT'),
      targetRole: AppRoleExtension.fromValue(json['targetRole']?.toString() ?? 'FACULTY'),
      targetUserId: json['targetUserId']?.toString(),
      targetName: json['targetName']?.toString(),
      requestType: RequestTypeExtension.fromString(json['requestType']?.toString() ?? 'GENERAL_REQUEST'),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      academicContext: json['academicContext'] is Map<String, dynamic>
          ? AcademicContextModel.fromJson(json['academicContext'] as Map<String, dynamic>)
          : null,
      details: json['details'] is Map<String, dynamic>
          ? RequestDetailsModel.fromJson(json['details'] as Map<String, dynamic>)
          : null,
      status: RequestStatusExtension.fromString(json['status']?.toString() ?? 'SUBMITTED'),
      respondedAt: json['respondedAt'] != null ? DateTime.tryParse(json['respondedAt'].toString()) : null,
      respondedBy: json['respondedBy']?.toString(),
      respondedByName: json['respondedByName']?.toString(),
      responseMessage: json['responseMessage']?.toString(),
      history: json['history'] is List
          ? (json['history'] as List)
              .map((h) => RequestAuditEntryModel.fromJson(Map<String, dynamic>.from(h as Map)))
              .toList()
          : const [],
      relatedEntityType: json['relatedEntityType']?.toString(),
      relatedEntityId: json['relatedEntityId']?.toString(),
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
      'requestId': requestId,
      'collegeId': collegeId,
      if (departmentId != null) 'departmentId': departmentId,
      'requesterUserId': requesterUserId,
      'requesterName': requesterName,
      'requesterRole': requesterRole.value,
      'targetRole': targetRole.value,
      if (targetUserId != null) 'targetUserId': targetUserId,
      if (targetName != null) 'targetName': targetName,
      'requestType': requestType.value,
      'title': title,
      'description': description,
      if (academicContext != null) 'academicContext': academicContext!.toJson(),
      if (details != null) 'details': details!.toJson(),
      'status': status.value,
      if (respondedAt != null) 'respondedAt': respondedAt!.toIso8601String(),
      if (respondedBy != null) 'respondedBy': respondedBy,
      if (respondedByName != null) 'respondedByName': respondedByName,
      if (responseMessage != null) 'responseMessage': responseMessage,
      'history': history.map((h) => h.toJson()).toList(),
      if (relatedEntityType != null) 'relatedEntityType': relatedEntityType,
      if (relatedEntityId != null) 'relatedEntityId': relatedEntityId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class RequestSummaryCounts {
  final int myPendingCount;
  final int incomingCount;

  const RequestSummaryCounts({
    this.myPendingCount = 0,
    this.incomingCount = 0,
  });

  factory RequestSummaryCounts.fromJson(Map<String, dynamic> json) {
    return RequestSummaryCounts(
      myPendingCount: json['myPendingCount'] is int
          ? json['myPendingCount'] as int
          : (int.tryParse(json['myPendingCount']?.toString() ?? '0') ?? 0),
      incomingCount: json['incomingCount'] is int
          ? json['incomingCount'] as int
          : (int.tryParse(json['incomingCount']?.toString() ?? '0') ?? 0),
    );
  }
}
