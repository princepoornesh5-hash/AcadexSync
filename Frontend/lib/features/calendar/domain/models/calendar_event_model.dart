import 'package:flutter/material.dart';
import '../../../auth/domain/models/role_enum.dart';

enum CalendarSourceType {
  manual('MANUAL'),
  derived('DERIVED'),
  system('SYSTEM');

  final String value;
  const CalendarSourceType(this.value);

  static CalendarSourceType fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'DERIVED':
        return CalendarSourceType.derived;
      case 'SYSTEM':
        return CalendarSourceType.system;
      default:
        return CalendarSourceType.manual;
    }
  }
}

enum CalendarEventType {
  event('EVENT'),
  holiday('HOLIDAY'),
  publicHoliday('PUBLIC_HOLIDAY'),
  institutionHoliday('INSTITUTION_HOLIDAY'),
  exam('EXAM'),
  seminar('SEMINAR'),
  workshop('WORKSHOP'),
  labViva('LAB_VIVA'),
  classTest('CLASS_TEST'),
  deadline('DEADLINE'),
  other('OTHER');

  final String value;
  const CalendarEventType(this.value);

  static CalendarEventType fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'HOLIDAY':
        return CalendarEventType.holiday;
      case 'PUBLIC_HOLIDAY':
        return CalendarEventType.publicHoliday;
      case 'INSTITUTION_HOLIDAY':
        return CalendarEventType.institutionHoliday;
      case 'EXAM':
        return CalendarEventType.exam;
      case 'SEMINAR':
        return CalendarEventType.seminar;
      case 'WORKSHOP':
        return CalendarEventType.workshop;
      case 'LAB_VIVA':
        return CalendarEventType.labViva;
      case 'CLASS_TEST':
        return CalendarEventType.classTest;
      case 'DEADLINE':
        return CalendarEventType.deadline;
      case 'OTHER':
        return CalendarEventType.other;
      default:
        return CalendarEventType.event;
    }
  }

  String get displayName {
    switch (this) {
      case CalendarEventType.holiday:
        return 'Holiday';
      case CalendarEventType.publicHoliday:
        return 'Public Holiday';
      case CalendarEventType.institutionHoliday:
        return 'Institution Holiday';
      case CalendarEventType.exam:
        return 'Examination';
      case CalendarEventType.seminar:
        return 'Seminar';
      case CalendarEventType.workshop:
        return 'Workshop';
      case CalendarEventType.labViva:
        return 'Lab Viva';
      case CalendarEventType.classTest:
        return 'Class Test';
      case CalendarEventType.deadline:
        return 'Assignment Deadline';
      case CalendarEventType.other:
        return 'Academic Activity';
      case CalendarEventType.event:
        return 'College Event';
    }
  }
}

enum CalendarEventScope {
  college('COLLEGE'),
  department('DEPARTMENT'),
  section('SECTION'),
  classScope('CLASS');

  final String value;
  const CalendarEventScope(this.value);

  static CalendarEventScope fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'DEPARTMENT':
        return CalendarEventScope.department;
      case 'SECTION':
        return CalendarEventScope.section;
      case 'CLASS':
        return CalendarEventScope.classScope;
      default:
        return CalendarEventScope.college;
    }
  }
}

enum CalendarEventStatus {
  draft('DRAFT'),
  published('PUBLISHED'),
  cancelled('CANCELLED'),
  archived('ARCHIVED');

  final String value;
  const CalendarEventStatus(this.value);

  static CalendarEventStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'DRAFT':
        return CalendarEventStatus.draft;
      case 'CANCELLED':
        return CalendarEventStatus.cancelled;
      case 'ARCHIVED':
        return CalendarEventStatus.archived;
      default:
        return CalendarEventStatus.published;
    }
  }
}

enum CalendarRecurrence {
  none('NONE'),
  annual('ANNUAL');

  final String value;
  const CalendarRecurrence(this.value);

  static CalendarRecurrence fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'ANNUAL':
        return CalendarRecurrence.annual;
      default:
        return CalendarRecurrence.none;
    }
  }
}

@immutable
class CalendarEventModel {
  final String id;
  final String title;
  final String description;
  final CalendarSourceType sourceType;
  final String? sourceId;
  final CalendarEventType eventType;
  final CalendarEventScope scope;
  final String startDate; // YYYY-MM-DD
  final String endDate; // YYYY-MM-DD
  final String? startTime; // HH:mm
  final String? endTime; // HH:mm
  final bool allDay;
  final String? departmentId;
  final String? courseId;
  final String? academicYearId;
  final String? semesterId;
  final String? sectionId;
  final String? subjectId;
  final String? academicContext;
  final String? location;
  final bool isRecurring;
  final CalendarRecurrence recurrence;
  final CalendarEventStatus status;
  final String createdBy;
  final AppRole creatorRole;
  final String creatorName;
  final String? navigationTarget;
  final bool canEdit;
  final bool canCancel;

  const CalendarEventModel({
    required this.id,
    required this.title,
    this.description = '',
    this.sourceType = CalendarSourceType.manual,
    this.sourceId,
    required this.eventType,
    this.scope = CalendarEventScope.college,
    required this.startDate,
    required this.endDate,
    this.startTime,
    this.endTime,
    this.allDay = false,
    this.departmentId,
    this.courseId,
    this.academicYearId,
    this.semesterId,
    this.sectionId,
    this.subjectId,
    this.academicContext,
    this.location,
    this.isRecurring = false,
    this.recurrence = CalendarRecurrence.none,
    this.status = CalendarEventStatus.published,
    this.createdBy = '',
    this.creatorRole = AppRole.collegeAdmin,
    this.creatorName = 'Staff',
    this.navigationTarget,
    this.canEdit = false,
    this.canCancel = false,
  });

  DateTime get startDateTime {
    final parts = startDate.split('-').map(int.parse).toList();
    if (startTime != null && startTime!.contains(':')) {
      final tParts = startTime!.split(':').map(int.parse).toList();
      return DateTime(parts[0], parts[1], parts[2], tParts[0], tParts[1]);
    }
    return DateTime(parts[0], parts[1], parts[2]);
  }

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    AppRole cRole = AppRole.collegeAdmin;
    final rStr = (json['creatorRole'] as String?)?.toUpperCase() ?? '';
    if (rStr.contains('HOD')) {
      cRole = AppRole.hod;
    } else if (rStr.contains('FACULTY')) {
      cRole = AppRole.faculty;
    } else if (rStr.contains('STUDENT')) {
      cRole = AppRole.student;
    }

    return CalendarEventModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      title: json['title'] as String? ?? 'Untitled Event',
      description: json['description'] as String? ?? '',
      sourceType: CalendarSourceType.fromString(json['sourceType'] as String?),
      sourceId: json['sourceId']?.toString(),
      eventType: CalendarEventType.fromString(json['eventType'] as String?),
      scope: CalendarEventScope.fromString(json['scope'] as String?),
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? (json['startDate'] as String? ?? ''),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      allDay: json['allDay'] as bool? ?? false,
      departmentId: json['departmentId']?.toString(),
      courseId: json['courseId']?.toString(),
      academicYearId: json['academicYearId']?.toString(),
      semesterId: json['semesterId']?.toString(),
      sectionId: json['sectionId']?.toString(),
      subjectId: json['subjectId']?.toString(),
      academicContext: json['academicContext'] as String?,
      location: json['location'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurrence: CalendarRecurrence.fromString(json['recurrence'] as String?),
      status: CalendarEventStatus.fromString(json['status'] as String?),
      createdBy: json['createdBy']?.toString() ?? '',
      creatorRole: cRole,
      creatorName: json['creatorName'] as String? ?? 'Staff Member',
      navigationTarget: json['navigationTarget'] as String?,
      canEdit: json['canEdit'] as bool? ?? false,
      canCancel: json['canCancel'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'sourceType': sourceType.value,
      'sourceId': sourceId,
      'eventType': eventType.value,
      'scope': scope.value,
      'startDate': startDate,
      'endDate': endDate,
      'startTime': startTime,
      'endTime': endTime,
      'allDay': allDay,
      'departmentId': departmentId,
      'courseId': courseId,
      'academicYearId': academicYearId,
      'semesterId': semesterId,
      'sectionId': sectionId,
      'subjectId': subjectId,
      'academicContext': academicContext,
      'location': location,
      'isRecurring': isRecurring,
      'recurrence': recurrence.value,
      'status': status.value,
      'createdBy': createdBy,
      'creatorRole': creatorRole.name,
      'creatorName': creatorName,
      'navigationTarget': navigationTarget,
      'canEdit': canEdit,
      'canCancel': canCancel,
    };
  }

  CalendarEventModel copyWith({
    String? id,
    String? title,
    String? description,
    CalendarSourceType? sourceType,
    String? sourceId,
    CalendarEventType? eventType,
    CalendarEventScope? scope,
    String? startDate,
    String? endDate,
    String? startTime,
    String? endTime,
    bool? allDay,
    String? departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    String? subjectId,
    String? academicContext,
    String? location,
    bool? isRecurring,
    CalendarRecurrence? recurrence,
    CalendarEventStatus? status,
    String? createdBy,
    AppRole? creatorRole,
    String? creatorName,
    String? navigationTarget,
    bool? canEdit,
    bool? canCancel,
  }) {
    return CalendarEventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      eventType: eventType ?? this.eventType,
      scope: scope ?? this.scope,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      allDay: allDay ?? this.allDay,
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      academicYearId: academicYearId ?? this.academicYearId,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      subjectId: subjectId ?? this.subjectId,
      academicContext: academicContext ?? this.academicContext,
      location: location ?? this.location,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrence: recurrence ?? this.recurrence,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      creatorRole: creatorRole ?? this.creatorRole,
      creatorName: creatorName ?? this.creatorName,
      navigationTarget: navigationTarget ?? this.navigationTarget,
      canEdit: canEdit ?? this.canEdit,
      canCancel: canCancel ?? this.canCancel,
    );
  }
}
