import 'package:flutter/foundation.dart';

enum AcademicProgressionStatus {
  active,
  completed,
  promoted,
  retained,
  withdrawn,
  discontinued;

  String get value => name.toUpperCase();

  static AcademicProgressionStatus fromString(String? val) {
    if (val == null) return AcademicProgressionStatus.active;
    final normalized = val.toUpperCase().trim();
    switch (normalized) {
      case 'COMPLETED':
        return AcademicProgressionStatus.completed;
      case 'PROMOTED':
        return AcademicProgressionStatus.promoted;
      case 'RETAINED':
        return AcademicProgressionStatus.retained;
      case 'WITHDRAWN':
        return AcademicProgressionStatus.withdrawn;
      case 'DISCONTINUED':
        return AcademicProgressionStatus.discontinued;
      case 'ACTIVE':
      default:
        return AcademicProgressionStatus.active;
    }
  }

  String get displayName {
    switch (this) {
      case AcademicProgressionStatus.active:
        return 'Active';
      case AcademicProgressionStatus.completed:
        return 'Completed';
      case AcademicProgressionStatus.promoted:
        return 'Promoted';
      case AcademicProgressionStatus.retained:
        return 'Retained';
      case AcademicProgressionStatus.withdrawn:
        return 'Withdrawn';
      case AcademicProgressionStatus.discontinued:
        return 'Discontinued';
    }
  }
}

enum SubjectAcademicStatus {
  enrolled,
  inProgress,
  completed,
  withdrawn,
  exempted;

  String get value {
    switch (this) {
      case SubjectAcademicStatus.enrolled:
        return 'ENROLLED';
      case SubjectAcademicStatus.inProgress:
        return 'IN_PROGRESS';
      case SubjectAcademicStatus.completed:
        return 'COMPLETED';
      case SubjectAcademicStatus.withdrawn:
        return 'WITHDRAWN';
      case SubjectAcademicStatus.exempted:
        return 'EXEMPTED';
    }
  }

  static SubjectAcademicStatus fromString(String? val) {
    if (val == null) return SubjectAcademicStatus.enrolled;
    final normalized = val.toUpperCase().trim();
    switch (normalized) {
      case 'IN_PROGRESS':
        return SubjectAcademicStatus.inProgress;
      case 'COMPLETED':
        return SubjectAcademicStatus.completed;
      case 'WITHDRAWN':
        return SubjectAcademicStatus.withdrawn;
      case 'EXEMPTED':
        return SubjectAcademicStatus.exempted;
      case 'ENROLLED':
      default:
        return SubjectAcademicStatus.enrolled;
    }
  }

  String get displayName {
    switch (this) {
      case SubjectAcademicStatus.enrolled:
        return 'Enrolled';
      case SubjectAcademicStatus.inProgress:
        return 'In Progress';
      case SubjectAcademicStatus.completed:
        return 'Completed';
      case SubjectAcademicStatus.withdrawn:
        return 'Withdrawn';
      case SubjectAcademicStatus.exempted:
        return 'Exempted';
    }
  }
}

@immutable
class AttendanceAggregationSummary {
  final int totalClasses;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final int percentage;

  const AttendanceAggregationSummary({
    this.totalClasses = 0,
    this.presentCount = 0,
    this.absentCount = 0,
    this.lateCount = 0,
    this.excusedCount = 0,
    this.percentage = 0,
  });

  factory AttendanceAggregationSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AttendanceAggregationSummary();
    return AttendanceAggregationSummary(
      totalClasses: (json['totalClasses'] as num?)?.toInt() ?? 0,
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
      excusedCount: (json['excusedCount'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalClasses': totalClasses,
        'presentCount': presentCount,
        'absentCount': absentCount,
        'lateCount': lateCount,
        'excusedCount': excusedCount,
        'percentage': percentage,
      };
}

@immutable
class PracticalAggregationSummary {
  final int totalSessions;
  final int completedCount;
  final int inProgressCount;
  final int absentCount;
  final int excusedCount;
  final int completionRate;

  const PracticalAggregationSummary({
    this.totalSessions = 0,
    this.completedCount = 0,
    this.inProgressCount = 0,
    this.absentCount = 0,
    this.excusedCount = 0,
    this.completionRate = 0,
  });

  factory PracticalAggregationSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PracticalAggregationSummary();
    return PracticalAggregationSummary(
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      inProgressCount: (json['inProgressCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      excusedCount: (json['excusedCount'] as num?)?.toInt() ?? 0,
      completionRate: (json['completionRate'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalSessions': totalSessions,
        'completedCount': completedCount,
        'inProgressCount': inProgressCount,
        'absentCount': absentCount,
        'excusedCount': excusedCount,
        'completionRate': completionRate,
      };
}

@immutable
class AssignmentAggregationSummary {
  final int totalAssignments;
  final int submittedCount;
  final int completedCount;
  final int lateCount;
  final int completionRate;

  const AssignmentAggregationSummary({
    this.totalAssignments = 0,
    this.submittedCount = 0,
    this.completedCount = 0,
    this.lateCount = 0,
    this.completionRate = 0,
  });

  factory AssignmentAggregationSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AssignmentAggregationSummary();
    return AssignmentAggregationSummary(
      totalAssignments: (json['totalAssignments'] as num?)?.toInt() ?? 0,
      submittedCount: (json['submittedCount'] as num?)?.toInt() ?? 0,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
      completionRate: (json['completionRate'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalAssignments': totalAssignments,
        'submittedCount': submittedCount,
        'completedCount': completedCount,
        'lateCount': lateCount,
        'completionRate': completionRate,
      };
}

@immutable
class AssessmentSummaryEntry {
  final String title;
  final num? totalMarks;
  final bool isPublished;

  const AssessmentSummaryEntry({
    required this.title,
    this.totalMarks,
    this.isPublished = false,
  });

  factory AssessmentSummaryEntry.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AssessmentSummaryEntry(title: '');
    return AssessmentSummaryEntry(
      title: json['title'] as String? ?? '',
      totalMarks: json['totalMarks'] as num?,
      isPublished: json['isPublished'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        if (totalMarks != null) 'totalMarks': totalMarks,
        'isPublished': isPublished,
      };
}

@immutable
class SubjectRecordSummary {
  final String id;
  final String subjectId;
  final String name;
  final String code;
  final String type;
  final int credits;
  final SubjectAcademicStatus status;
  final String? facultyName;
  final AttendanceAggregationSummary? attendance;
  final PracticalAggregationSummary? practical;
  final AssignmentAggregationSummary? assignment;
  final AssessmentSummaryEntry? assessment;

  const SubjectRecordSummary({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.code,
    required this.type,
    this.credits = 0,
    this.status = SubjectAcademicStatus.enrolled,
    this.facultyName,
    this.attendance,
    this.practical,
    this.assignment,
    this.assessment,
  });

  factory SubjectRecordSummary.fromJson(Map<String, dynamic> json) {
    return SubjectRecordSummary(
      id: json['id'] as String? ?? (json['_id'] as String? ?? ''),
      subjectId: json['subjectId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      type: json['type'] as String? ?? 'Theory',
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      status: SubjectAcademicStatus.fromString(json['status'] as String?),
      facultyName: json['facultyName'] as String?,
      attendance: json['attendance'] != null
          ? AttendanceAggregationSummary.fromJson(json['attendance'] as Map<String, dynamic>)
          : null,
      practical: json['practical'] != null
          ? PracticalAggregationSummary.fromJson(json['practical'] as Map<String, dynamic>)
          : null,
      assignment: json['assignment'] != null
          ? AssignmentAggregationSummary.fromJson(json['assignment'] as Map<String, dynamic>)
          : null,
      assessment: json['assessment'] != null
          ? AssessmentSummaryEntry.fromJson(json['assessment'] as Map<String, dynamic>)
          : null,
    );
  }
}

@immutable
class AcademicRecordModel {
  final String id;
  final String collegeId;
  final String studentId;
  final String? studentName;
  final String? rollNumber;
  final String studentEnrollmentId;
  final String courseId;
  final String departmentId;
  final String academicYearId;
  final String semesterId;
  final String? sectionId;
  final String academicStage;
  final String cohort;
  final AcademicProgressionStatus progressionStatus;
  final String? remarks;
  final DateTime? promotedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AcademicRecordModel({
    required this.id,
    required this.collegeId,
    required this.studentId,
    this.studentName,
    this.rollNumber,
    required this.studentEnrollmentId,
    required this.courseId,
    required this.departmentId,
    required this.academicYearId,
    required this.semesterId,
    this.sectionId,
    required this.academicStage,
    required this.cohort,
    this.progressionStatus = AcademicProgressionStatus.active,
    this.remarks,
    this.promotedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory AcademicRecordModel.fromJson(Map<String, dynamic> json) {
    // Resolve nested student if populated
    String? sName;
    String? rNum;
    String resolvedStudentId = '';
    if (json['studentId'] is Map<String, dynamic>) {
      final sMap = json['studentId'] as Map<String, dynamic>;
      resolvedStudentId = sMap['_id'] as String? ?? '';
      sName = sMap['name'] as String?;
      rNum = sMap['rollNumber'] as String?;
    } else {
      resolvedStudentId = json['studentId'] as String? ?? '';
    }

    String resolveId(dynamic field) {
      if (field is Map<String, dynamic>) return field['_id'] as String? ?? '';
      return field as String? ?? '';
    }

    return AcademicRecordModel(
      id: json['id'] as String? ?? (json['_id'] as String? ?? ''),
      collegeId: resolveId(json['collegeId']),
      studentId: resolvedStudentId,
      studentName: sName,
      rollNumber: rNum,
      studentEnrollmentId: resolveId(json['studentEnrollmentId']),
      courseId: resolveId(json['courseId']),
      departmentId: resolveId(json['departmentId']),
      academicYearId: resolveId(json['academicYearId']),
      semesterId: resolveId(json['semesterId']),
      sectionId: json['sectionId'] != null ? resolveId(json['sectionId']) : null,
      academicStage: json['academicStage'] as String? ?? '',
      cohort: json['cohort'] as String? ?? '',
      progressionStatus: AcademicProgressionStatus.fromString(json['progressionStatus'] as String?),
      remarks: json['remarks'] as String?,
      promotedAt: json['promotedAt'] != null ? DateTime.tryParse(json['promotedAt'] as String) : null,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'] as String) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }
}

@immutable
class AcademicHistoryItemModel {
  final AcademicRecordModel record;
  final String courseName;
  final String departmentName;
  final String academicYearName;
  final int semesterNumber;
  final String? sectionName;
  final int subjectCount;
  final AttendanceAggregationSummary attendance;
  final PracticalAggregationSummary practical;
  final AssignmentAggregationSummary assignment;

  const AcademicHistoryItemModel({
    required this.record,
    required this.courseName,
    required this.departmentName,
    required this.academicYearName,
    required this.semesterNumber,
    this.sectionName,
    this.subjectCount = 0,
    required this.attendance,
    required this.practical,
    required this.assignment,
  });

  factory AcademicHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return AcademicHistoryItemModel(
      record: AcademicRecordModel.fromJson(json['record'] as Map<String, dynamic>),
      courseName: json['courseName'] as String? ?? 'Course',
      departmentName: json['departmentName'] as String? ?? 'Department',
      academicYearName: json['academicYearName'] as String? ?? 'Academic Year',
      semesterNumber: (json['semesterNumber'] as num?)?.toInt() ?? 1,
      sectionName: json['sectionName'] as String?,
      subjectCount: (json['subjectCount'] as num?)?.toInt() ?? 0,
      attendance: AttendanceAggregationSummary.fromJson(json['attendance'] as Map<String, dynamic>?),
      practical: PracticalAggregationSummary.fromJson(json['practical'] as Map<String, dynamic>?),
      assignment: AssignmentAggregationSummary.fromJson(json['assignment'] as Map<String, dynamic>?),
    );
  }
}

@immutable
class AcademicRecordDetailModel {
  final AcademicRecordModel record;
  final String courseName;
  final String departmentName;
  final String academicYearName;
  final int semesterNumber;
  final String? sectionName;
  final AttendanceAggregationSummary overallAttendance;
  final PracticalAggregationSummary overallPractical;
  final AssignmentAggregationSummary overallAssignment;
  final List<SubjectRecordSummary> subjects;

  const AcademicRecordDetailModel({
    required this.record,
    required this.courseName,
    required this.departmentName,
    required this.academicYearName,
    required this.semesterNumber,
    this.sectionName,
    required this.overallAttendance,
    required this.overallPractical,
    required this.overallAssignment,
    this.subjects = const [],
  });

  factory AcademicRecordDetailModel.fromJson(Map<String, dynamic> json) {
    final ctx = json['academicContext'] as Map<String, dynamic>? ?? {};
    final subsRaw = json['subjects'] as List<dynamic>? ?? [];

    return AcademicRecordDetailModel(
      record: AcademicRecordModel.fromJson(json['record'] as Map<String, dynamic>),
      courseName: ctx['courseName'] as String? ?? 'Course',
      departmentName: ctx['departmentName'] as String? ?? 'Department',
      academicYearName: ctx['academicYearName'] as String? ?? 'Academic Year',
      semesterNumber: (ctx['semesterNumber'] as num?)?.toInt() ?? 1,
      sectionName: ctx['sectionName'] as String?,
      overallAttendance: AttendanceAggregationSummary.fromJson(
        json['overallAttendance'] as Map<String, dynamic>?,
      ),
      overallPractical: PracticalAggregationSummary.fromJson(
        json['overallPractical'] as Map<String, dynamic>?,
      ),
      overallAssignment: AssignmentAggregationSummary.fromJson(
        json['overallAssignment'] as Map<String, dynamic>?,
      ),
      subjects: subsRaw
          .map((s) => SubjectRecordSummary.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

@immutable
class PaginatedAcademicRecordsModel {
  final List<AcademicRecordModel> records;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PaginatedAcademicRecordsModel({
    this.records = const [],
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 1,
  });

  factory PaginatedAcademicRecordsModel.fromJson(Map<String, dynamic> json) {
    final listRaw = json['records'] as List<dynamic>? ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? {};

    return PaginatedAcademicRecordsModel(
      records: listRaw
          .map((r) => AcademicRecordModel.fromJson(r as Map<String, dynamic>))
          .toList(),
      page: (meta['page'] as num?)?.toInt() ?? 1,
      limit: (meta['limit'] as num?)?.toInt() ?? 20,
      total: (meta['total'] as num?)?.toInt() ?? 0,
      totalPages: (meta['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
