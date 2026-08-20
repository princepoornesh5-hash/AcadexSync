import '../models/attendance_alert.dart';
import '../models/attendance_analytics_models.dart';
import '../models/attendance_session.dart';
import '../models/attendance_status.dart';
import '../models/department_attendance_comparison.dart';
import '../models/student_attendance_models.dart';
import '../models/subject_attendance.dart';

/// Centralized domain service for student attendance processing
class StudentAttendanceService {
  const StudentAttendanceService();

  /// Converts standard SubjectAttendance records to rich detailed student subject models
  List<StudentDetailedSubjectAttendance> computeDetailedSubjects({
    required List<SubjectAttendance> subjects,
    double threshold = AttendanceAnalyticsConstants.lowAttendanceThreshold,
  }) {
    return subjects.map((s) {
      return StudentDetailedSubjectAttendance.compute(
        subjectId: s.subjectId,
        subjectName: s.subjectName,
        subjectCode: s.subjectCode,
        facultyName: s.facultyName,
        totalClasses: s.totalClasses,
        presentCount: s.attendedClasses,
        absentCount: s.missedClasses,
        requiredThreshold: threshold,
      );
    }).toList();
  }

  /// Extracts student-specific session summaries from live attendance sessions
  List<StudentAttendanceSessionSummary> extractStudentSessions({
    required String studentId,
    required List<AttendanceSession> sessions,
  }) {
    final List<StudentAttendanceSessionSummary> result = [];

    for (final session in sessions) {
      // Find record for this student
      final record = session.records.where((r) => r.studentId == studentId).firstOrNull;
      if (record != null && record.status != null) {
        result.add(
          StudentAttendanceSessionSummary(
            sessionId: session.id,
            subjectId: session.subjectId,
            subjectName: session.subjectName.isNotEmpty ? session.subjectName : session.subjectId,
            subjectCode: session.subjectId,
            facultyId: session.facultyId,
            facultyName: session.facultyId,
            sectionId: session.sectionId,
            sectionName: session.sectionName.isNotEmpty ? session.sectionName : session.sectionId,
            date: session.date,
            timeSlot: session.timeSlot,
            status: record.status!,
            version: session.version,
          ),
        );
      }
    }

    // Sort newest session first
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  /// Groups student session records by date into calendar days
  List<StudentAttendanceCalendarDay> buildCalendarDays({
    required List<StudentAttendanceSessionSummary> sessions,
  }) {
    final Map<String, List<StudentAttendanceSessionSummary>> grouped = {};

    for (final s in sessions) {
      final key = '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(s);
    }

    final List<StudentAttendanceCalendarDay> days = [];

    for (final entry in grouped.entries) {
      final list = entry.value;
      final date = list.first.date;
      final normalizedDate = DateTime(date.year, date.month, date.day);

      int present = 0;
      int absent = 0;
      int late = 0;
      int excused = 0;

      for (final item in list) {
        switch (item.status) {
          case AttendanceStatus.present:
            present++;
            break;
          case AttendanceStatus.absent:
            absent++;
            break;
          case AttendanceStatus.late:
            late++;
            break;
          case AttendanceStatus.excused:
          case AttendanceStatus.medicalLeave:
          case AttendanceStatus.onDuty:
          case AttendanceStatus.holiday:
            excused++;
            break;
        }
      }

      final total = present + absent + late + excused;
      final percentage = total > 0 ? (present / total) * 100.0 : 0.0;

      days.add(
        StudentAttendanceCalendarDay(
          date: normalizedDate,
          totalClasses: total,
          presentCount: present,
          absentCount: absent,
          lateCount: late,
          excusedCount: excused,
          attendancePercentage: percentage,
          sessions: list,
        ),
      );
    }

    days.sort((a, b) => b.date.compareTo(a.date));
    return days;
  }

  /// Builds comprehensive insights from student analytics, subjects, and alerts
  StudentAttendanceInsights buildInsights({
    required StudentAttendanceAnalytics analytics,
    required List<StudentDetailedSubjectAttendance> subjects,
    required List<AttendanceAlert> alerts,
  }) {
    final sortedSubjects = List<StudentDetailedSubjectAttendance>.from(subjects)
      ..sort((a, b) => b.attendancePercentage.compareTo(a.attendancePercentage));

    final bestSubjects = sortedSubjects.where((s) => s.attendancePercentage >= 85.0).toList();
    final lowestSubjects = sortedSubjects.where((s) => s.attendancePercentage < 75.0).toList();

    int totalRecovery = 0;
    for (final s in subjects) {
      totalRecovery += s.recoveryClassesNeeded;
    }

    final warningsCount = subjects.where((s) => s.riskLevel != AttendanceRiskLevel.healthy).length;

    // Evaluate overall trend
    final trend = analytics.attendancePercentage >= 80.0
        ? TrendDirection.up
        : (analytics.attendancePercentage >= 75.0 ? TrendDirection.neutral : TrendDirection.down);

    return StudentAttendanceInsights(
      overallPercentage: analytics.attendancePercentage,
      trendDirection: trend,
      overallRiskLevel: analytics.riskLevel,
      totalConducted: analytics.totalSessions,
      totalAttended: analytics.presentCount,
      totalAbsent: analytics.absentCount,
      totalLate: analytics.lateCount,
      totalExcused: analytics.excusedCount,
      subjectRankings: sortedSubjects,
      lowestAttendanceSubjects: lowestSubjects.isNotEmpty ? lowestSubjects : (sortedSubjects.length > 2 ? [sortedSubjects.last] : []),
      bestAttendanceSubjects: bestSubjects.isNotEmpty ? bestSubjects : (sortedSubjects.isNotEmpty ? [sortedSubjects.first] : []),
      activeAlerts: alerts,
      thresholdWarningsCount: warningsCount,
      isLowAttendance: analytics.isLowAttendance,
      totalRecoveryNeeded: totalRecovery,
    );
  }
}
