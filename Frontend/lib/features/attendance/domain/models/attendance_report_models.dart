import '../models/attendance_analytics_models.dart';
import '../models/attendance_status.dart';

/// Supported types of attendance administrative reports
enum AttendanceReportType {
  student,
  subject,
  section,
  faculty,
  department,
  college,
  session,
  lowAttendance;

  String get displayName {
    switch (this) {
      case AttendanceReportType.student:
        return 'Student Attendance Report';
      case AttendanceReportType.subject:
        return 'Subject Attendance Report';
      case AttendanceReportType.section:
        return 'Section Attendance Report';
      case AttendanceReportType.faculty:
        return 'Faculty Attendance Report';
      case AttendanceReportType.department:
        return 'Department Attendance Report';
      case AttendanceReportType.college:
        return 'College Attendance Report';
      case AttendanceReportType.session:
        return 'Attendance Session Report';
      case AttendanceReportType.lowAttendance:
        return 'Low Attendance Intervention Report';
    }
  }
}

/// Filter criteria for generating structured attendance reports
class AttendanceReportFilter {
  final AttendanceReportType reportType;
  final AttendanceDateRange? dateRange;
  final String? collegeId;
  final String? departmentId;
  final String? courseId;
  final String? academicYearId;
  final String? semesterId;
  final String? sectionId;
  final String? subjectId;
  final String? facultyId;
  final String? studentId;
  final double threshold;
  final AttendanceStatus? statusFilter;
  final String? searchQuery;

  const AttendanceReportFilter({
    required this.reportType,
    this.dateRange,
    this.collegeId,
    this.departmentId,
    this.courseId,
    this.academicYearId,
    this.semesterId,
    this.sectionId,
    this.subjectId,
    this.facultyId,
    this.studentId,
    this.threshold = 75.0,
    this.statusFilter,
    this.searchQuery,
  });

  AttendanceReportFilter copyWith({
    AttendanceReportType? reportType,
    AttendanceDateRange? dateRange,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    String? subjectId,
    String? facultyId,
    String? studentId,
    double? threshold,
    AttendanceStatus? statusFilter,
    String? searchQuery,
  }) {
    return AttendanceReportFilter(
      reportType: reportType ?? this.reportType,
      dateRange: dateRange ?? this.dateRange,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      academicYearId: academicYearId ?? this.academicYearId,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      subjectId: subjectId ?? this.subjectId,
      facultyId: facultyId ?? this.facultyId,
      studentId: studentId ?? this.studentId,
      threshold: threshold ?? this.threshold,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Encapsulates the output of a generated attendance report
class AttendanceReportResult {
  final AttendanceReportType reportType;
  final String title;
  final String scopeDescription;
  final DateTime generatedAt;
  final String generatedBy;
  final AttendanceDateRange? dateRange;
  final int totalRecords;
  final Map<String, dynamic> summaryStatistics;
  final List<String> headers;
  final List<List<dynamic>> rows;

  const AttendanceReportResult({
    required this.reportType,
    required this.title,
    required this.scopeDescription,
    required this.generatedAt,
    required this.generatedBy,
    this.dateRange,
    required this.totalRecords,
    required this.summaryStatistics,
    required this.headers,
    required this.rows,
  });
}

/// Result of reconciling expected timetable classes vs recorded attendance sessions
class AttendanceReconciliationResult {
  final int expectedSessions;
  final int recordedSessions;
  final int missingSessions;
  final double compliancePercentage;
  final List<MissingSessionInfo> missingDetails;

  const AttendanceReconciliationResult({
    required this.expectedSessions,
    required this.recordedSessions,
    required this.missingSessions,
    required this.compliancePercentage,
    this.missingDetails = const [],
  });

  bool get isFullyReconciled => missingSessions == 0;
}

class MissingSessionInfo {
  final String timetableEntryId;
  final String subjectId;
  final String subjectName;
  final String sectionId;
  final String facultyId;
  final String facultyName;
  final String timeSlot;
  final DateTime scheduledDate;

  const MissingSessionInfo({
    required this.timetableEntryId,
    required this.subjectId,
    required this.subjectName,
    required this.sectionId,
    required this.facultyId,
    required this.facultyName,
    required this.timeSlot,
    required this.scheduledDate,
  });
}

/// Consistency and data integrity issue types
enum AttendanceConsistencyType {
  missingTimetableRef,
  orphanSection,
  duplicateSession,
  invalidPercentage,
  mismatchedCounts,
  unmarkedInSubmitted;

  String get displayName {
    switch (this) {
      case AttendanceConsistencyType.missingTimetableRef:
        return 'Session Missing Timetable Reference';
      case AttendanceConsistencyType.orphanSection:
        return 'Session References Nonexistent Section';
      case AttendanceConsistencyType.duplicateSession:
        return 'Duplicate Session Record';
      case AttendanceConsistencyType.invalidPercentage:
        return 'Invalid Attendance Percentage (>100% or <0%)';
      case AttendanceConsistencyType.mismatchedCounts:
        return 'Mismatched Student Counts';
      case AttendanceConsistencyType.unmarkedInSubmitted:
        return 'Unmarked Records in Submitted Session';
    }
  }
}

/// Details of a single data consistency anomaly
class AttendanceConsistencyIssue {
  final String sessionId;
  final AttendanceConsistencyType issueType;
  final String description;
  final String severity; // 'critical', 'warning', 'info'
  final DateTime detectedAt;

  const AttendanceConsistencyIssue({
    required this.sessionId,
    required this.issueType,
    required this.description,
    required this.severity,
    required this.detectedAt,
  });
}

/// Represents an audit log entry when an attendance session is modified
class AttendanceAuditEntry {
  final String sessionId;
  final int fromVersion;
  final int toVersion;
  final String modifiedBy;
  final DateTime modifiedAt;
  final String subjectName;
  final String sectionName;
  final int recordsChangedCount;
  final String details;

  const AttendanceAuditEntry({
    required this.sessionId,
    required this.fromVersion,
    required this.toVersion,
    required this.modifiedBy,
    required this.modifiedAt,
    required this.subjectName,
    required this.sectionName,
    required this.recordsChangedCount,
    required this.details,
  });
}
