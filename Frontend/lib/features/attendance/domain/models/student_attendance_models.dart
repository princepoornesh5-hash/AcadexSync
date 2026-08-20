import 'package:flutter/foundation.dart';
import 'attendance_analytics_models.dart';
import 'attendance_alert.dart';
import 'attendance_status.dart';
import 'department_attendance_comparison.dart';

/// Detailed subject attendance standing for student portal
@immutable
class StudentDetailedSubjectAttendance {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String facultyId;
  final String facultyName;
  final String? sectionId;
  final String? roomNumber;
  final int totalClasses;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final double attendancePercentage;
  final double requiredThreshold;
  final int marginClassesCanMiss;
  final int recoveryClassesNeeded;
  final AttendanceRiskLevel riskLevel;

  const StudentDetailedSubjectAttendance({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    this.facultyId = '',
    this.facultyName = 'Faculty Instructor',
    this.sectionId,
    this.roomNumber,
    required this.totalClasses,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.excusedCount,
    required this.attendancePercentage,
    this.requiredThreshold = AttendanceAnalyticsConstants.lowAttendanceThreshold,
    required this.marginClassesCanMiss,
    required this.recoveryClassesNeeded,
    required this.riskLevel,
  });

  /// Factory with automatic calculation of margin and recovery
  factory StudentDetailedSubjectAttendance.compute({
    required String subjectId,
    required String subjectName,
    required String subjectCode,
    String facultyId = '',
    String facultyName = 'Faculty Instructor',
    String? sectionId,
    String? roomNumber,
    required int totalClasses,
    required int presentCount,
    int absentCount = 0,
    int lateCount = 0,
    int excusedCount = 0,
    double requiredThreshold = AttendanceAnalyticsConstants.lowAttendanceThreshold,
  }) {
    final double percentage = totalClasses > 0
        ? (presentCount / totalClasses) * 100.0
        : 100.0;

    final risk = AttendanceAnalyticsConstants.evaluateRiskLevel(percentage);

    // Calculate how many classes can be missed before dropping below threshold:
    // (presentCount / (totalClasses + M)) >= threshold / 100
    // presentCount * 100 / threshold - totalClasses >= M
    int margin = 0;
    if (totalClasses > 0 && percentage >= requiredThreshold) {
      final double maxTotalAllowed = (presentCount * 100.0) / requiredThreshold;
      margin = (maxTotalAllowed - totalClasses).floor();
      if (margin < 0) margin = 0;
    }

    // Calculate recovery classes needed to reach threshold
    final int recovery = AttendanceAnalyticsConstants.calculateSessionsNeededToReachThreshold(
      presentCount: presentCount,
      totalSessions: totalClasses,
      targetThreshold: requiredThreshold,
    );

    return StudentDetailedSubjectAttendance(
      subjectId: subjectId,
      subjectName: subjectName,
      subjectCode: subjectCode,
      facultyId: facultyId,
      facultyName: facultyName,
      sectionId: sectionId,
      roomNumber: roomNumber,
      totalClasses: totalClasses,
      presentCount: presentCount,
      absentCount: absentCount,
      lateCount: lateCount,
      excusedCount: excusedCount,
      attendancePercentage: percentage,
      requiredThreshold: requiredThreshold,
      marginClassesCanMiss: margin,
      recoveryClassesNeeded: recovery,
      riskLevel: risk,
    );
  }

  bool get isBelowThreshold => attendancePercentage < requiredThreshold;
}

/// Student session summary representation for calendar and detail screens
@immutable
class StudentAttendanceSessionSummary {
  final String sessionId;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String facultyId;
  final String facultyName;
  final String sectionId;
  final String sectionName;
  final DateTime date;
  final String timeSlot;
  final String? roomNumber;
  final AttendanceStatus status;
  final int version;
  final String? remarks;

  const StudentAttendanceSessionSummary({
    required this.sessionId,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.facultyId,
    required this.facultyName,
    required this.sectionId,
    required this.sectionName,
    required this.date,
    required this.timeSlot,
    this.roomNumber,
    required this.status,
    this.version = 1,
    this.remarks,
  });
}

/// Calendar day aggregation of student attendance
@immutable
class StudentAttendanceCalendarDay {
  final DateTime date;
  final int totalClasses;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final double attendancePercentage;
  final List<StudentAttendanceSessionSummary> sessions;

  const StudentAttendanceCalendarDay({
    required this.date,
    required this.totalClasses,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.excusedCount,
    required this.attendancePercentage,
    required this.sessions,
  });

  bool get hasClasses => totalClasses > 0;
  bool get hasAbsence => absentCount > 0;
  bool get isFullAttendance => totalClasses > 0 && presentCount == totalClasses;
}

/// Comprehensive Student Attendance Insights Model
@immutable
class StudentAttendanceInsights {
  final double overallPercentage;
  final TrendDirection trendDirection;
  final AttendanceRiskLevel overallRiskLevel;
  final int totalConducted;
  final int totalAttended;
  final int totalAbsent;
  final int totalLate;
  final int totalExcused;
  final List<StudentDetailedSubjectAttendance> subjectRankings;
  final List<StudentDetailedSubjectAttendance> lowestAttendanceSubjects;
  final List<StudentDetailedSubjectAttendance> bestAttendanceSubjects;
  final List<AttendanceAlert> activeAlerts;
  final int thresholdWarningsCount;
  final bool isLowAttendance;
  final int totalRecoveryNeeded;

  const StudentAttendanceInsights({
    required this.overallPercentage,
    required this.trendDirection,
    required this.overallRiskLevel,
    required this.totalConducted,
    required this.totalAttended,
    required this.totalAbsent,
    required this.totalLate,
    required this.totalExcused,
    required this.subjectRankings,
    required this.lowestAttendanceSubjects,
    required this.bestAttendanceSubjects,
    required this.activeAlerts,
    required this.thresholdWarningsCount,
    required this.isLowAttendance,
    required this.totalRecoveryNeeded,
  });
}
