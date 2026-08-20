import 'package:uuid/uuid.dart';
import '../models/attendance_alert.dart';
import '../models/attendance_analytics_models.dart';
import '../models/attendance_record.dart';
import '../models/attendance_session.dart';
import '../models/attendance_status.dart';
import '../../../../features/timetable/domain/models/timetable_models.dart';

/// Centralized domain evaluator for generating early-warning attendance alerts.
class AttendanceRiskEvaluator {
  final String Function() _idGenerator;

  AttendanceRiskEvaluator({String Function()? idGenerator})
      : _idGenerator = idGenerator ?? (() => const Uuid().v4());

  /// Evaluates student attendance analytics and history to produce actionable alerts.
  List<AttendanceAlert> evaluateStudent({
    required StudentAttendanceAnalytics studentAnalytics,
    required String collegeId,
    required String departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    List<SubjectAttendanceAnalytics>? subjectAnalyticsList,
    List<AttendanceSession>? recentSessions,
    Map<String, double>? previousPercentagesBySubject,
    double? previousOverallPercentage,
    List<AttendanceAlert>? existingAlerts,
    double threshold = AttendanceAnalyticsConstants.lowAttendanceThreshold,
  }) {
    final alerts = <AttendanceAlert>[];
    final existingMap = <String, AttendanceAlert>{};
    if (existingAlerts != null) {
      for (final a in existingAlerts) {
        existingMap[a.deduplicationKey] = a;
      }
    }

    // 1. Evaluate Overall Student Attendance Shortage
    if (studentAnalytics.totalSessions > 0) {
      final overallKey = 'low_att_${studentAnalytics.studentId}_overall_${studentAnalytics.sectionId}';
      final existingOverall = existingMap[overallKey];

      if (studentAnalytics.attendancePercentage < threshold) {
        // Generate or update active alert
        final alert = AttendanceAlert.createLowAttendance(
          id: existingOverall?.id ?? _idGenerator(),
          collegeId: collegeId,
          departmentId: departmentId,
          courseId: courseId,
          academicYearId: academicYearId,
          semesterId: semesterId,
          sectionId: studentAnalytics.sectionId,
          studentId: studentAnalytics.studentId,
          studentName: studentAnalytics.studentName.isNotEmpty
              ? studentAnalytics.studentName
              : studentAnalytics.studentId,
          rollNumber: studentAnalytics.rollNumber,
          attendancePercentage: studentAnalytics.attendancePercentage,
          presentCount: studentAnalytics.presentCount,
          totalSessions: studentAnalytics.totalSessions,
          threshold: threshold,
          createdAt: existingOverall?.createdAt,
        );
        // Preserve read/acknowledged status if still active
        alerts.add(alert.copyWith(
          isRead: existingOverall?.isRead ?? false,
          status: existingOverall?.status == AttendanceAlertStatus.acknowledged
              ? AttendanceAlertStatus.acknowledged
              : AttendanceAlertStatus.active,
        ));
      } else if (existingOverall != null && existingOverall.status != AttendanceAlertStatus.resolved) {
        // Resolve previous shortage
        alerts.add(existingOverall.copyWith(
          status: AttendanceAlertStatus.resolved,
          resolvedAt: DateTime.now(),
          title: 'Attendance Recovered: ${studentAnalytics.studentName} (${studentAnalytics.attendancePercentage.toStringAsFixed(1)}%)',
          message: 'Attendance has improved to ${studentAnalytics.attendancePercentage.toStringAsFixed(1)}%, successfully restoring compliance with the ${threshold.toStringAsFixed(0)}% requirement.',
        ));
      }

      // Check Overall Attendance Drop
      if (previousOverallPercentage != null && previousOverallPercentage > studentAnalytics.attendancePercentage) {
        final drop = previousOverallPercentage - studentAnalytics.attendancePercentage;
        if (drop >= 5.0) {
          final dropKey = 'drop_${studentAnalytics.studentId}_overall';
          final existingDrop = existingMap[dropKey];
          alerts.add(AttendanceAlert.createAttendanceDrop(
            id: existingDrop?.id ?? _idGenerator(),
            collegeId: collegeId,
            departmentId: departmentId,
            courseId: courseId,
            academicYearId: academicYearId,
            semesterId: semesterId,
            sectionId: studentAnalytics.sectionId,
            studentId: studentAnalytics.studentId,
            studentName: studentAnalytics.studentName,
            rollNumber: studentAnalytics.rollNumber,
            previousPercentage: previousOverallPercentage,
            currentPercentage: studentAnalytics.attendancePercentage,
            threshold: threshold,
            createdAt: existingDrop?.createdAt,
          ));
        }
      }
    }

    // 2. Evaluate Subject-Level Analytics
    if (subjectAnalyticsList != null) {
      for (final sub in subjectAnalyticsList) {
        if (sub.totalSessions <= 0) continue;

        final subKey = 'low_att_${studentAnalytics.studentId}_${sub.subjectId}_${studentAnalytics.sectionId}';
        final existingSubAlert = existingMap[subKey];

        if (sub.attendancePercentage < threshold) {
          final alert = AttendanceAlert.createLowAttendance(
            id: existingSubAlert?.id ?? _idGenerator(),
            collegeId: collegeId,
            departmentId: departmentId,
            courseId: courseId,
            academicYearId: academicYearId,
            semesterId: semesterId,
            sectionId: studentAnalytics.sectionId,
            studentId: studentAnalytics.studentId,
            studentName: studentAnalytics.studentName,
            rollNumber: studentAnalytics.rollNumber,
            subjectId: sub.subjectId,
            subjectName: sub.subjectName,
            attendancePercentage: sub.attendancePercentage,
            presentCount: sub.presentCount,
            totalSessions: sub.totalSessions,
            threshold: threshold,
            createdAt: existingSubAlert?.createdAt,
          );
          alerts.add(alert.copyWith(
            isRead: existingSubAlert?.isRead ?? false,
            status: existingSubAlert?.status == AttendanceAlertStatus.acknowledged
                ? AttendanceAlertStatus.acknowledged
                : AttendanceAlertStatus.active,
          ));
        } else if (existingSubAlert != null && existingSubAlert.status != AttendanceAlertStatus.resolved) {
          alerts.add(existingSubAlert.copyWith(
            status: AttendanceAlertStatus.resolved,
            resolvedAt: DateTime.now(),
            title: 'Attendance Recovered: ${studentAnalytics.studentName} in ${sub.subjectName} (${sub.attendancePercentage.toStringAsFixed(1)}%)',
            message: 'Attendance in ${sub.subjectName} has recovered to ${sub.attendancePercentage.toStringAsFixed(1)}%.',
          ));
        }

        // Check Subject Drop
        if (previousPercentagesBySubject != null && previousPercentagesBySubject.containsKey(sub.subjectId)) {
          final prev = previousPercentagesBySubject[sub.subjectId]!;
          if (prev > sub.attendancePercentage) {
            final drop = prev - sub.attendancePercentage;
            if (drop >= 5.0) {
              final dropSubKey = 'drop_${studentAnalytics.studentId}_${sub.subjectId}';
              final existingSubDrop = existingMap[dropSubKey];
              alerts.add(AttendanceAlert.createAttendanceDrop(
                id: existingSubDrop?.id ?? _idGenerator(),
                collegeId: collegeId,
                departmentId: departmentId,
                courseId: courseId,
                academicYearId: academicYearId,
                semesterId: semesterId,
                sectionId: studentAnalytics.sectionId,
                studentId: studentAnalytics.studentId,
                studentName: studentAnalytics.studentName,
                rollNumber: studentAnalytics.rollNumber,
                subjectId: sub.subjectId,
                subjectName: sub.subjectName,
                previousPercentage: prev,
                currentPercentage: sub.attendancePercentage,
                threshold: threshold,
                createdAt: existingSubDrop?.createdAt,
              ));
            }
          }
        }
      }
    }

    // 3. Evaluate Repeated Absences from recent sessions
    if (recentSessions != null && recentSessions.isNotEmpty) {
      final sessionsBySubject = <String, List<AttendanceSession>>{};
      for (final s in recentSessions) {
        sessionsBySubject.putIfAbsent(s.subjectId, () => []).add(s);
      }

      for (final entry in sessionsBySubject.entries) {
        final subjectId = entry.key;
        final list = entry.value;
        list.sort((a, b) => b.date.compareTo(a.date));

        int consecutiveAbsences = 0;
        String subjectName = '';
        for (final s in list) {
          subjectName = s.subjectName;
          final studentRecord = s.records.cast<AttendanceRecord?>().firstWhere(
            (r) => r?.studentId == studentAnalytics.studentId,
            orElse: () => null,
          );
          if (studentRecord != null && studentRecord.status == AttendanceStatus.absent) {
            consecutiveAbsences++;
          } else {
            break;
          }
        }

        if (consecutiveAbsences >= 2) {
          final repKey = 'repeat_abs_${studentAnalytics.studentId}_$subjectId';
          final existingRep = existingMap[repKey];
          alerts.add(AttendanceAlert.createRepeatedAbsence(
            id: existingRep?.id ?? _idGenerator(),
            collegeId: collegeId,
            departmentId: departmentId,
            courseId: courseId,
            academicYearId: academicYearId,
            semesterId: semesterId,
            sectionId: studentAnalytics.sectionId,
            studentId: studentAnalytics.studentId,
            studentName: studentAnalytics.studentName,
            rollNumber: studentAnalytics.rollNumber,
            subjectId: subjectId,
            subjectName: subjectName,
            consecutiveAbsences: consecutiveAbsences,
            currentPercentage: studentAnalytics.attendancePercentage,
            createdAt: existingRep?.createdAt,
          ));
        }
      }
    }

    return alerts;
  }

  /// Evaluates unmarked attendance for scheduled classes that have ended
  List<AttendanceAlert> evaluateUnmarkedClasses({
    required List<TimetableModel> scheduledEntries,
    required List<String> conductedSessionTimetableIds,
    required DateTime referenceDate,
    required String collegeId,
    required String departmentId,
    List<AttendanceAlert>? existingAlerts,
  }) {
    final alerts = <AttendanceAlert>[];
    final existingMap = <String, AttendanceAlert>{};
    if (existingAlerts != null) {
      for (final a in existingAlerts) {
        existingMap[a.deduplicationKey] = a;
      }
    }

    for (final entry in scheduledEntries) {
      // Check if session was already conducted
      if (conductedSessionTimetableIds.contains(entry.id)) {
        continue;
      }

      final dedupKey = 'unmarked_${entry.id}_${referenceDate.year}_${referenceDate.month}_${referenceDate.day}';
      final existingAlert = existingMap[dedupKey];

      alerts.add(AttendanceAlert.createUnmarkedAttendance(
        id: existingAlert?.id ?? _idGenerator(),
        collegeId: collegeId,
        departmentId: departmentId,
        sectionId: entry.sectionId,
        subjectId: entry.subjectId,
        subjectName: entry.subjectId,
        facultyId: entry.facultyId,
        relatedTimetableEntryId: entry.id,
        slotDate: referenceDate,
        timeSlot: '${entry.startTime} - ${entry.endTime}',
        createdAt: existingAlert?.createdAt,
      ));
    }

    return alerts;
  }
}
