enum CalendarOverrideType {
  holiday,
  cancelled;

  static CalendarOverrideType fromString(String val) {
    final lower = val.toLowerCase();
    if (lower == 'cancelled') return CalendarOverrideType.cancelled;
    return CalendarOverrideType.holiday;
  }

  String toServerString() {
    switch (this) {
      case CalendarOverrideType.cancelled:
        return 'CANCELLED';
      case CalendarOverrideType.holiday:
        return 'HOLIDAY';
    }
  }
}

enum CalendarOverrideScope {
  college,
  department,
  section,
  entry;

  static CalendarOverrideScope fromString(String val) {
    switch (val.toUpperCase()) {
      case 'DEPARTMENT':
        return CalendarOverrideScope.department;
      case 'SECTION':
        return CalendarOverrideScope.section;
      case 'ENTRY':
        return CalendarOverrideScope.entry;
      default:
        return CalendarOverrideScope.college;
    }
  }

  String toServerString() => name.toUpperCase();
}

class CalendarOverride {
  final String id;
  final String collegeId;
  final String? departmentId;
  final String? sectionId;
  final String? timetableId;
  final String? timetableEntryId;
  final String date; // YYYY-MM-DD
  final CalendarOverrideType type;
  final CalendarOverrideScope scope;
  final String reason;
  final String? createdBy;
  final DateTime? createdAt;

  const CalendarOverride({
    required this.id,
    required this.collegeId,
    this.departmentId,
    this.sectionId,
    this.timetableId,
    this.timetableEntryId,
    required this.date,
    required this.type,
    required this.scope,
    required this.reason,
    this.createdBy,
    this.createdAt,
  });

  factory CalendarOverride.fromJson(Map<String, dynamic> json) {
    return CalendarOverride(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      collegeId: (json['collegeId'] ?? '').toString(),
      departmentId: json['departmentId']?.toString(),
      sectionId: json['sectionId']?.toString(),
      timetableId: json['timetableId']?.toString(),
      timetableEntryId: json['timetableEntryId']?.toString(),
      date: (json['date'] ?? '').toString(),
      type: CalendarOverrideType.fromString((json['type'] ?? 'HOLIDAY').toString()),
      scope: CalendarOverrideScope.fromString((json['scope'] ?? 'COLLEGE').toString()),
      reason: (json['reason'] ?? '').toString(),
      createdBy: json['createdBy']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collegeId': collegeId,
      if (departmentId != null) 'departmentId': departmentId,
      if (sectionId != null) 'sectionId': sectionId,
      if (timetableId != null) 'timetableId': timetableId,
      if (timetableEntryId != null) 'timetableEntryId': timetableEntryId,
      'date': date,
      'type': type.toServerString(),
      'scope': scope.toServerString(),
      'reason': reason,
    };
  }
}
