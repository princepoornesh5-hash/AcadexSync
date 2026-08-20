import 'package:flutter/foundation.dart';

enum DateRangePreset {
  today,
  thisWeek,
  thisMonth,
  currentSemester,
  custom,
}

extension DateRangePresetExtension on DateRangePreset {
  String toApiValue() {
    switch (this) {
      case DateRangePreset.today:
        return 'today';
      case DateRangePreset.thisWeek:
        return 'this_week';
      case DateRangePreset.thisMonth:
        return 'this_month';
      case DateRangePreset.currentSemester:
        return 'current_semester';
      case DateRangePreset.custom:
        return 'custom';
    }
  }

  static DateRangePreset fromString(String? val) {
    switch (val) {
      case 'today':
        return DateRangePreset.today;
      case 'this_week':
        return DateRangePreset.thisWeek;
      case 'this_month':
        return DateRangePreset.thisMonth;
      case 'current_semester':
        return DateRangePreset.currentSemester;
      default:
        return DateRangePreset.custom;
    }
  }
}

/// Student Info in Report
@immutable
class ReportStudentInfo {
  final String id;
  final String name;
  final String rollNumber;
  final String studentIdNumber;
  final String? sectionId;
  final String? semesterId;
  final String? courseId;
  final String? departmentId;

  const ReportStudentInfo({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.studentIdNumber,
    this.sectionId,
    this.semesterId,
    this.courseId,
    this.departmentId,
  });

  factory ReportStudentInfo.fromJson(Map<String, dynamic> json) {
    return ReportStudentInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rollNumber: json['rollNumber'] as String? ?? '',
      studentIdNumber: json['studentIdNumber'] as String? ?? '',
      sectionId: json['sectionId'] as String?,
      semesterId: json['semesterId'] as String?,
      courseId: json['courseId'] as String?,
      departmentId: json['departmentId'] as String?,
    );
  }
}

/// Generic Attendance Summary
@immutable
class ReportAttendanceSummary {
  final int totalClasses;
  final int present;
  final int late;
  final int absent;
  final int excused;
  final double percentage;
  final int? totalSessions;

  const ReportAttendanceSummary({
    required this.totalClasses,
    required this.present,
    required this.late,
    required this.absent,
    required this.excused,
    required this.percentage,
    this.totalSessions,
  });

  factory ReportAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return ReportAttendanceSummary(
      totalClasses: (json['totalClasses'] as num?)?.toInt() ?? 0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      excused: (json['excused'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      totalSessions: (json['totalSessions'] as num?)?.toInt(),
    );
  }
}

/// Subject Attendance Item
@immutable
class ReportSubjectAttendanceItem {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final int totalClasses;
  final int present;
  final int late;
  final int absent;
  final int excused;
  final double percentage;
  final bool lowAttendanceAlert;

  const ReportSubjectAttendanceItem({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.totalClasses,
    required this.present,
    required this.late,
    required this.absent,
    required this.excused,
    required this.percentage,
    required this.lowAttendanceAlert,
  });

  factory ReportSubjectAttendanceItem.fromJson(Map<String, dynamic> json) {
    return ReportSubjectAttendanceItem(
      subjectId: json['subjectId'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? '',
      totalClasses: (json['totalClasses'] as num?)?.toInt() ?? 0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      excused: (json['excused'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      lowAttendanceAlert: json['lowAttendanceAlert'] as bool? ?? false,
    );
  }
}

/// Attendance Risk Profile
@immutable
class ReportRiskProfile {
  final double percentage;
  final double threshold;
  final bool isLowAttendance;
  final String status;

  const ReportRiskProfile({
    required this.percentage,
    required this.threshold,
    required this.isLowAttendance,
    required this.status,
  });

  factory ReportRiskProfile.fromJson(Map<String, dynamic> json) {
    return ReportRiskProfile(
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 75.0,
      isLowAttendance: json['isLowAttendance'] as bool? ?? false,
      status: json['status'] as String? ?? 'NORMAL',
    );
  }
}

/// Attendance Trend Record
@immutable
class ReportAttendanceTrendItem {
  final String date;
  final String status;
  final String subjectName;
  final String timeSlot;

  const ReportAttendanceTrendItem({
    required this.date,
    required this.status,
    required this.subjectName,
    required this.timeSlot,
  });

  factory ReportAttendanceTrendItem.fromJson(Map<String, dynamic> json) {
    return ReportAttendanceTrendItem(
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      timeSlot: json['timeSlot'] as String? ?? '',
    );
  }
}

/// Student Attendance Report
@immutable
class StudentAttendanceReportModel {
  final ReportStudentInfo student;
  final ReportAttendanceSummary summary;
  final List<ReportSubjectAttendanceItem> subjects;
  final ReportRiskProfile riskProfile;
  final List<ReportAttendanceTrendItem> recentTrends;

  const StudentAttendanceReportModel({
    required this.student,
    required this.summary,
    required this.subjects,
    required this.riskProfile,
    required this.recentTrends,
  });

  factory StudentAttendanceReportModel.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceReportModel(
      student: ReportStudentInfo.fromJson(json['student'] as Map<String, dynamic>? ?? {}),
      summary: ReportAttendanceSummary.fromJson(json['summary'] as Map<String, dynamic>? ?? {}),
      subjects: (json['subjects'] as List<dynamic>? ?? [])
          .map((e) => ReportSubjectAttendanceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      riskProfile: ReportRiskProfile.fromJson(json['riskProfile'] as Map<String, dynamic>? ?? {}),
      recentTrends: (json['recentTrends'] as List<dynamic>? ?? [])
          .map((e) => ReportAttendanceTrendItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Section Attendance Student Ranking
@immutable
class ReportStudentRankingItem {
  final String studentId;
  final String studentName;
  final String rollNumber;
  final int totalClasses;
  final int attendedClasses;
  final double attendancePercentage;
  final bool isLowAttendance;
  final int rank;

  const ReportStudentRankingItem({
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.totalClasses,
    required this.attendedClasses,
    required this.attendancePercentage,
    required this.isLowAttendance,
    required this.rank,
  });

  factory ReportStudentRankingItem.fromJson(Map<String, dynamic> json) {
    return ReportStudentRankingItem(
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      rollNumber: json['rollNumber'] as String? ?? '',
      totalClasses: (json['totalClasses'] as num?)?.toInt() ?? 0,
      attendedClasses: (json['attendedClasses'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      isLowAttendance: json['isLowAttendance'] as bool? ?? false,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Section Subject Breakdown Item
@immutable
class ReportSectionSubjectBreakdownItem {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final int totalSessions;
  final double attendancePercentage;

  const ReportSectionSubjectBreakdownItem({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.totalSessions,
    required this.attendancePercentage,
  });

  factory ReportSectionSubjectBreakdownItem.fromJson(Map<String, dynamic> json) {
    return ReportSectionSubjectBreakdownItem(
      subjectId: json['subjectId'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? '',
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Section Attendance Report
@immutable
class SectionAttendanceReportModel {
  final Map<String, dynamic> section;
  final ReportAttendanceSummary summary;
  final List<ReportSectionSubjectBreakdownItem> subjectBreakdown;
  final List<ReportStudentRankingItem> students;
  final int lowAttendanceCount;

  const SectionAttendanceReportModel({
    required this.section,
    required this.summary,
    required this.subjectBreakdown,
    required this.students,
    required this.lowAttendanceCount,
  });

  factory SectionAttendanceReportModel.fromJson(Map<String, dynamic> json) {
    return SectionAttendanceReportModel(
      section: json['section'] as Map<String, dynamic>? ?? {},
      summary: ReportAttendanceSummary.fromJson(json['summary'] as Map<String, dynamic>? ?? {}),
      subjectBreakdown: (json['subjectBreakdown'] as List<dynamic>? ?? [])
          .map((e) => ReportSectionSubjectBreakdownItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      students: (json['students'] as List<dynamic>? ?? [])
          .map((e) => ReportStudentRankingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      lowAttendanceCount: (json['lowAttendanceCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Department Section Comparison Item
@immutable
class ReportDepartmentSectionItem {
  final String sectionId;
  final String sectionName;
  final int totalStudents;
  final double attendancePercentage;

  const ReportDepartmentSectionItem({
    required this.sectionId,
    required this.sectionName,
    required this.totalStudents,
    required this.attendancePercentage,
  });

  factory ReportDepartmentSectionItem.fromJson(Map<String, dynamic> json) {
    return ReportDepartmentSectionItem(
      sectionId: json['sectionId'] as String? ?? '',
      sectionName: json['sectionName'] as String? ?? '',
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Department Subject Comparison Item
@immutable
class ReportDepartmentSubjectItem {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final double attendancePercentage;

  const ReportDepartmentSubjectItem({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.attendancePercentage,
  });

  factory ReportDepartmentSubjectItem.fromJson(Map<String, dynamic> json) {
    return ReportDepartmentSubjectItem(
      subjectId: json['subjectId'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? '',
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Department Attendance Report
@immutable
class DepartmentAttendanceReportModel {
  final Map<String, dynamic> department;
  final ReportAttendanceSummary summary;
  final List<ReportDepartmentSectionItem> sectionsComparison;
  final List<ReportDepartmentSubjectItem> subjectsComparison;
  final int lowAttendanceStudentsCount;

  const DepartmentAttendanceReportModel({
    required this.department,
    required this.summary,
    required this.sectionsComparison,
    required this.subjectsComparison,
    required this.lowAttendanceStudentsCount,
  });

  factory DepartmentAttendanceReportModel.fromJson(Map<String, dynamic> json) {
    return DepartmentAttendanceReportModel(
      department: json['department'] as Map<String, dynamic>? ?? {},
      summary: ReportAttendanceSummary.fromJson(json['summary'] as Map<String, dynamic>? ?? {}),
      sectionsComparison: (json['sectionsComparison'] as List<dynamic>? ?? [])
          .map((e) => ReportDepartmentSectionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subjectsComparison: (json['subjectsComparison'] as List<dynamic>? ?? [])
          .map((e) => ReportDepartmentSubjectItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      lowAttendanceStudentsCount: (json['lowAttendanceStudentsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// College Department Comparison Item
@immutable
class ReportCollegeDepartmentItem {
  final String departmentId;
  final String departmentName;
  final String departmentCode;
  final int totalStudents;
  final double attendancePercentage;

  const ReportCollegeDepartmentItem({
    required this.departmentId,
    required this.departmentName,
    required this.departmentCode,
    required this.totalStudents,
    required this.attendancePercentage,
  });

  factory ReportCollegeDepartmentItem.fromJson(Map<String, dynamic> json) {
    return ReportCollegeDepartmentItem(
      departmentId: json['departmentId'] as String? ?? '',
      departmentName: json['departmentName'] as String? ?? '',
      departmentCode: json['departmentCode'] as String? ?? '',
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// College Attendance Report
@immutable
class CollegeAttendanceReportModel {
  final Map<String, dynamic> college;
  final ReportAttendanceSummary summary;
  final List<ReportCollegeDepartmentItem> departmentComparison;
  final List<String> lowAttendanceDepartments;

  const CollegeAttendanceReportModel({
    required this.college,
    required this.summary,
    required this.departmentComparison,
    required this.lowAttendanceDepartments,
  });

  factory CollegeAttendanceReportModel.fromJson(Map<String, dynamic> json) {
    return CollegeAttendanceReportModel(
      college: json['college'] as Map<String, dynamic>? ?? {},
      summary: ReportAttendanceSummary.fromJson(json['summary'] as Map<String, dynamic>? ?? {}),
      departmentComparison: (json['departmentComparison'] as List<dynamic>? ?? [])
          .map((e) => ReportCollegeDepartmentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      lowAttendanceDepartments: (json['lowAttendanceDepartments'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// Academic Hierarchy & Timetable Coverage Report
@immutable
class AcademicHierarchyReportModel {
  final String? collegeId;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> enrollmentCapacity;
  final Map<String, dynamic> timetableCoverage;

  const AcademicHierarchyReportModel({
    this.collegeId,
    required this.summary,
    required this.enrollmentCapacity,
    required this.timetableCoverage,
  });

  factory AcademicHierarchyReportModel.fromJson(Map<String, dynamic> json) {
    return AcademicHierarchyReportModel(
      collegeId: json['collegeId'] as String?,
      summary: json['summary'] as Map<String, dynamic>? ?? {},
      enrollmentCapacity: json['enrollmentCapacity'] as Map<String, dynamic>? ?? {},
      timetableCoverage: json['timetableCoverage'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Notes Analytics Report
@immutable
class NotesAnalyticsReportModel {
  final String? collegeId;
  final int totalNotes;
  final int publishedNotes;
  final int totalSizeBytes;
  final double totalSizeMB;
  final List<dynamic> departmentDistribution;
  final List<dynamic> subjectDistribution;

  const NotesAnalyticsReportModel({
    this.collegeId,
    required this.totalNotes,
    required this.publishedNotes,
    required this.totalSizeBytes,
    required this.totalSizeMB,
    required this.departmentDistribution,
    required this.subjectDistribution,
  });

  factory NotesAnalyticsReportModel.fromJson(Map<String, dynamic> json) {
    return NotesAnalyticsReportModel(
      collegeId: json['collegeId'] as String?,
      totalNotes: (json['totalNotes'] as num?)?.toInt() ?? 0,
      publishedNotes: (json['publishedNotes'] as num?)?.toInt() ?? 0,
      totalSizeBytes: (json['totalSizeBytes'] as num?)?.toInt() ?? 0,
      totalSizeMB: (json['totalSizeMB'] as num?)?.toDouble() ?? 0.0,
      departmentDistribution: json['departmentDistribution'] as List<dynamic>? ?? [],
      subjectDistribution: json['subjectDistribution'] as List<dynamic>? ?? [],
    );
  }
}

/// Role-Based Dynamic Dashboard Report
@immutable
class RoleDashboardReportModel {
  final String role;
  final Map<String, dynamic> metrics;
  final Map<String, dynamic> quickStats;
  final List<dynamic> recentActivity;

  const RoleDashboardReportModel({
    required this.role,
    required this.metrics,
    required this.quickStats,
    required this.recentActivity,
  });

  factory RoleDashboardReportModel.fromJson(Map<String, dynamic> json) {
    return RoleDashboardReportModel(
      role: json['role'] as String? ?? '',
      metrics: json['metrics'] as Map<String, dynamic>? ?? {},
      quickStats: json['quickStats'] as Map<String, dynamic>? ?? {},
      recentActivity: json['recentActivity'] as List<dynamic>? ?? [],
    );
  }
}
