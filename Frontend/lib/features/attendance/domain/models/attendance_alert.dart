import 'package:flutter/foundation.dart';
import 'attendance_analytics_models.dart';

/// Alert types supported by the ACADEX Early-Warning System
enum AttendanceAlertType {
  lowAttendance,       // Attendance percentage below regulatory threshold (< 75%)
  attendanceDrop,      // Sudden significant drop in attendance percentage (e.g. >= 5% or >= 10%)
  repeatedAbsence,     // Repeated consecutive absences (e.g. >= 3 consecutive missed classes)
  unmarkedAttendance,  // Scheduled timetable class slot has passed with no recorded session
  attendanceRecovery,  // Attendance improved back above threshold (>= 75%)
  sessionCorrection,   // Session attendance record was updated or corrected
}

/// Centralized Alert Severity Levels
enum AttendanceAlertSeverity {
  info,
  warning,
  critical,
}

/// Lifecycle states of an attendance alert
enum AttendanceAlertStatus {
  active,
  acknowledged,
  resolved,
}

/// Filter criteria for querying alerts
@immutable
class AttendanceAlertFilter {
  final AttendanceAlertSeverity? severity;
  final AttendanceAlertStatus? status;
  final bool? unreadOnly;
  final AttendanceAlertType? alertType;
  final String? sectionId;
  final String? subjectId;

  const AttendanceAlertFilter({
    this.severity,
    this.status,
    this.unreadOnly,
    this.alertType,
    this.sectionId,
    this.subjectId,
  });

  AttendanceAlertFilter copyWith({
    AttendanceAlertSeverity? severity,
    AttendanceAlertStatus? status,
    bool? unreadOnly,
    AttendanceAlertType? alertType,
    String? sectionId,
    String? subjectId,
    bool clearSeverity = false,
    bool clearStatus = false,
    bool clearUnreadOnly = false,
  }) {
    return AttendanceAlertFilter(
      severity: clearSeverity ? null : (severity ?? this.severity),
      status: clearStatus ? null : (status ?? this.status),
      unreadOnly: clearUnreadOnly ? null : (unreadOnly ?? this.unreadOnly),
      alertType: alertType ?? this.alertType,
      sectionId: sectionId ?? this.sectionId,
      subjectId: subjectId ?? this.subjectId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceAlertFilter &&
          runtimeType == other.runtimeType &&
          severity == other.severity &&
          status == other.status &&
          unreadOnly == other.unreadOnly &&
          alertType == other.alertType &&
          sectionId == other.sectionId &&
          subjectId == other.subjectId;

  @override
  int get hashCode => Object.hash(severity, status, unreadOnly, alertType, sectionId, subjectId);
}

/// Aggregate summary counts of alerts for dashboard widgets
@immutable
class AttendanceAlertSummary {
  final int totalAlerts;
  final int criticalCount;
  final int warningCount;
  final int infoCount;
  final int unreadCount;
  final int activeCount;
  final int acknowledgedCount;
  final int resolvedCount;

  const AttendanceAlertSummary({
    this.totalAlerts = 0,
    this.criticalCount = 0,
    this.warningCount = 0,
    this.infoCount = 0,
    this.unreadCount = 0,
    this.activeCount = 0,
    this.acknowledgedCount = 0,
    this.resolvedCount = 0,
  });

  factory AttendanceAlertSummary.fromAlerts(List<AttendanceAlert> alerts) {
    int critical = 0;
    int warning = 0;
    int info = 0;
    int unread = 0;
    int active = 0;
    int acknowledged = 0;
    int resolved = 0;

    for (final a in alerts) {
      if (a.isRead == false) unread++;
      switch (a.severity) {
        case AttendanceAlertSeverity.critical:
          critical++;
          break;
        case AttendanceAlertSeverity.warning:
          warning++;
          break;
        case AttendanceAlertSeverity.info:
          info++;
          break;
      }
      switch (a.status) {
        case AttendanceAlertStatus.active:
          active++;
          break;
        case AttendanceAlertStatus.acknowledged:
          acknowledged++;
          break;
        case AttendanceAlertStatus.resolved:
          resolved++;
          break;
      }
    }

    return AttendanceAlertSummary(
      totalAlerts: alerts.length,
      criticalCount: critical,
      warningCount: warning,
      infoCount: info,
      unreadCount: unread,
      activeCount: active,
      acknowledgedCount: acknowledged,
      resolvedCount: resolved,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceAlertSummary &&
          runtimeType == other.runtimeType &&
          totalAlerts == other.totalAlerts &&
          criticalCount == other.criticalCount &&
          warningCount == other.warningCount &&
          infoCount == other.infoCount &&
          unreadCount == other.unreadCount &&
          activeCount == other.activeCount &&
          acknowledgedCount == other.acknowledgedCount &&
          resolvedCount == other.resolvedCount;

  @override
  int get hashCode => Object.hash(
        totalAlerts,
        criticalCount,
        warningCount,
        infoCount,
        unreadCount,
        activeCount,
        acknowledgedCount,
        resolvedCount,
      );
}

/// Core Attendance Alert Domain Model
@immutable
class AttendanceAlert {
  final String id;
  final String collegeId;
  final String departmentId;
  final String? courseId;
  final String? academicYearId;
  final String? semesterId;
  final String? sectionId;
  final String? studentId;
  final String? studentName;
  final String? rollNumber;
  final String? subjectId;
  final String? subjectName;
  final String? facultyId;
  final AttendanceAlertType alertType;
  final AttendanceAlertSeverity severity;
  final AttendanceAlertStatus status;
  final String title;
  final String message;
  final double? attendancePercentage;
  final double? previousPercentage;
  final double? dropPercentage;
  final double threshold;
  final int? consecutiveAbsences;
  final int? recoverySessionsNeeded;
  final String? relatedSessionId;
  final String? relatedTimetableEntryId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String deduplicationKey;

  const AttendanceAlert({
    required this.id,
    required this.collegeId,
    required this.departmentId,
    this.courseId,
    this.academicYearId,
    this.semesterId,
    this.sectionId,
    this.studentId,
    this.studentName,
    this.rollNumber,
    this.subjectId,
    this.subjectName,
    this.facultyId,
    required this.alertType,
    required this.severity,
    this.status = AttendanceAlertStatus.active,
    required this.title,
    required this.message,
    this.attendancePercentage,
    this.previousPercentage,
    this.dropPercentage,
    this.threshold = AttendanceAnalyticsConstants.lowAttendanceThreshold,
    this.consecutiveAbsences,
    this.recoverySessionsNeeded,
    this.relatedSessionId,
    this.relatedTimetableEntryId,
    required this.createdAt,
    this.updatedAt,
    this.isRead = false,
    this.readAt,
    this.acknowledgedAt,
    this.resolvedAt,
    required this.deduplicationKey,
  });

  /// Factory helper for creating low attendance alert
  factory AttendanceAlert.createLowAttendance({
    required String id,
    required String collegeId,
    required String departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    required String studentId,
    required String studentName,
    required String rollNumber,
    String? subjectId,
    String? subjectName,
    String? facultyId,
    required double attendancePercentage,
    required int presentCount,
    required int totalSessions,
    double threshold = AttendanceAnalyticsConstants.lowAttendanceThreshold,
    DateTime? createdAt,
  }) {
    final severity = attendancePercentage < 70.0
        ? AttendanceAlertSeverity.critical
        : AttendanceAlertSeverity.warning;

    final recoveryNeeded = AttendanceAnalyticsConstants.calculateSessionsNeededToReachThreshold(
      presentCount: presentCount,
      totalSessions: totalSessions,
      targetThreshold: threshold,
    );

    final subjectContext = subjectName != null && subjectName.isNotEmpty
        ? 'in $subjectName'
        : (sectionId != null && sectionId.isNotEmpty ? 'in Section $sectionId' : '');

    final dedupKey = 'low_att_${studentId}_${subjectId ?? "overall"}_${sectionId ?? "none"}';

    return AttendanceAlert(
      id: id,
      collegeId: collegeId,
      departmentId: departmentId,
      courseId: courseId,
      academicYearId: academicYearId,
      semesterId: semesterId,
      sectionId: sectionId,
      studentId: studentId,
      studentName: studentName,
      rollNumber: rollNumber,
      subjectId: subjectId,
      subjectName: subjectName,
      facultyId: facultyId,
      alertType: AttendanceAlertType.lowAttendance,
      severity: severity,
      status: AttendanceAlertStatus.active,
      title: 'Low Attendance Alert: $studentName (${attendancePercentage.toStringAsFixed(1)}%)',
      message: 'Attendance $subjectContext has dropped to ${attendancePercentage.toStringAsFixed(1)}%, which is below the mandatory ${threshold.toStringAsFixed(0)}% institutional requirement. $recoveryNeeded consecutive attended sessions are required to restore compliance.',
      attendancePercentage: attendancePercentage,
      threshold: threshold,
      recoverySessionsNeeded: recoveryNeeded,
      createdAt: createdAt ?? DateTime.now(),
      deduplicationKey: dedupKey,
    );
  }

  /// Factory helper for creating attendance drop alert
  factory AttendanceAlert.createAttendanceDrop({
    required String id,
    required String collegeId,
    required String departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    required String studentId,
    required String studentName,
    required String rollNumber,
    String? subjectId,
    String? subjectName,
    String? facultyId,
    required double previousPercentage,
    required double currentPercentage,
    double threshold = AttendanceAnalyticsConstants.lowAttendanceThreshold,
    DateTime? createdAt,
  }) {
    final drop = (previousPercentage - currentPercentage).clamp(0.0, 100.0);
    final severity = drop >= 10.0
        ? AttendanceAlertSeverity.critical
        : AttendanceAlertSeverity.warning;

    final subjectContext = subjectName != null && subjectName.isNotEmpty
        ? 'in $subjectName'
        : '';

    final dedupKey = 'drop_${studentId}_${subjectId ?? "overall"}';

    return AttendanceAlert(
      id: id,
      collegeId: collegeId,
      departmentId: departmentId,
      courseId: courseId,
      academicYearId: academicYearId,
      semesterId: semesterId,
      sectionId: sectionId,
      studentId: studentId,
      studentName: studentName,
      rollNumber: rollNumber,
      subjectId: subjectId,
      subjectName: subjectName,
      facultyId: facultyId,
      alertType: AttendanceAlertType.attendanceDrop,
      severity: severity,
      status: AttendanceAlertStatus.active,
      title: 'Sharp Attendance Drop: $studentName (-${drop.toStringAsFixed(1)}%)',
      message: 'Attendance $subjectContext dropped sharply from ${previousPercentage.toStringAsFixed(1)}% to ${currentPercentage.toStringAsFixed(1)}% (-${drop.toStringAsFixed(1)} percentage points).',
      attendancePercentage: currentPercentage,
      previousPercentage: previousPercentage,
      dropPercentage: drop,
      threshold: threshold,
      createdAt: createdAt ?? DateTime.now(),
      deduplicationKey: dedupKey,
    );
  }

  /// Factory helper for creating repeated absence alert
  factory AttendanceAlert.createRepeatedAbsence({
    required String id,
    required String collegeId,
    required String departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    required String studentId,
    required String studentName,
    required String rollNumber,
    String? subjectId,
    String? subjectName,
    String? facultyId,
    required int consecutiveAbsences,
    double? currentPercentage,
    DateTime? createdAt,
  }) {
    final severity = consecutiveAbsences >= 3
        ? AttendanceAlertSeverity.critical
        : AttendanceAlertSeverity.warning;

    final subjectContext = subjectName != null && subjectName.isNotEmpty
        ? 'in $subjectName'
        : '';

    final dedupKey = 'repeat_abs_${studentId}_${subjectId ?? "overall"}';

    return AttendanceAlert(
      id: id,
      collegeId: collegeId,
      departmentId: departmentId,
      courseId: courseId,
      academicYearId: academicYearId,
      semesterId: semesterId,
      sectionId: sectionId,
      studentId: studentId,
      studentName: studentName,
      rollNumber: rollNumber,
      subjectId: subjectId,
      subjectName: subjectName,
      facultyId: facultyId,
      alertType: AttendanceAlertType.repeatedAbsence,
      severity: severity,
      status: AttendanceAlertStatus.active,
      title: 'Repeated Absence: $studentName ($consecutiveAbsences missed classes)',
      message: 'Student has been consecutively absent for $consecutiveAbsences scheduled sessions $subjectContext.',
      attendancePercentage: currentPercentage,
      consecutiveAbsences: consecutiveAbsences,
      createdAt: createdAt ?? DateTime.now(),
      deduplicationKey: dedupKey,
    );
  }

  /// Factory helper for creating unmarked attendance alert
  factory AttendanceAlert.createUnmarkedAttendance({
    required String id,
    required String collegeId,
    required String departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    required String sectionId,
    required String subjectId,
    required String subjectName,
    required String facultyId,
    required String relatedTimetableEntryId,
    required DateTime slotDate,
    required String timeSlot,
    DateTime? createdAt,
  }) {
    final dedupKey = 'unmarked_${relatedTimetableEntryId}_${slotDate.year}_${slotDate.month}_${slotDate.day}';

    return AttendanceAlert(
      id: id,
      collegeId: collegeId,
      departmentId: departmentId,
      courseId: courseId,
      academicYearId: academicYearId,
      semesterId: semesterId,
      sectionId: sectionId,
      subjectId: subjectId,
      subjectName: subjectName,
      facultyId: facultyId,
      relatedTimetableEntryId: relatedTimetableEntryId,
      alertType: AttendanceAlertType.unmarkedAttendance,
      severity: AttendanceAlertSeverity.warning,
      status: AttendanceAlertStatus.active,
      title: 'Missing Attendance: $subjectName (Section $sectionId)',
      message: 'Attendance was not submitted for scheduled timetable slot ($timeSlot) on ${slotDate.day}/${slotDate.month}/${slotDate.year}.',
      createdAt: createdAt ?? DateTime.now(),
      deduplicationKey: dedupKey,
    );
  }

  AttendanceAlert copyWith({
    String? id,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    String? studentId,
    String? studentName,
    String? rollNumber,
    String? subjectId,
    String? subjectName,
    String? facultyId,
    AttendanceAlertType? alertType,
    AttendanceAlertSeverity? severity,
    AttendanceAlertStatus? status,
    String? title,
    String? message,
    double? attendancePercentage,
    double? previousPercentage,
    double? dropPercentage,
    double? threshold,
    int? consecutiveAbsences,
    int? recoverySessionsNeeded,
    String? relatedSessionId,
    String? relatedTimetableEntryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRead,
    DateTime? readAt,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    String? deduplicationKey,
  }) {
    return AttendanceAlert(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      academicYearId: academicYearId ?? this.academicYearId,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      rollNumber: rollNumber ?? this.rollNumber,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      facultyId: facultyId ?? this.facultyId,
      alertType: alertType ?? this.alertType,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      title: title ?? this.title,
      message: message ?? this.message,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      previousPercentage: previousPercentage ?? this.previousPercentage,
      dropPercentage: dropPercentage ?? this.dropPercentage,
      threshold: threshold ?? this.threshold,
      consecutiveAbsences: consecutiveAbsences ?? this.consecutiveAbsences,
      recoverySessionsNeeded: recoverySessionsNeeded ?? this.recoverySessionsNeeded,
      relatedSessionId: relatedSessionId ?? this.relatedSessionId,
      relatedTimetableEntryId: relatedTimetableEntryId ?? this.relatedTimetableEntryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      deduplicationKey: deduplicationKey ?? this.deduplicationKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'collegeId': collegeId,
        'departmentId': departmentId,
        'courseId': courseId,
        'academicYearId': academicYearId,
        'semesterId': semesterId,
        'sectionId': sectionId,
        'studentId': studentId,
        'studentName': studentName,
        'rollNumber': rollNumber,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'facultyId': facultyId,
        'alertType': alertType.name,
        'severity': severity.name,
        'status': status.name,
        'title': title,
        'message': message,
        'attendancePercentage': attendancePercentage,
        'previousPercentage': previousPercentage,
        'dropPercentage': dropPercentage,
        'threshold': threshold,
        'consecutiveAbsences': consecutiveAbsences,
        'recoverySessionsNeeded': recoverySessionsNeeded,
        'relatedSessionId': relatedSessionId,
        'relatedTimetableEntryId': relatedTimetableEntryId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'isRead': isRead,
        'readAt': readAt?.toIso8601String(),
        'acknowledgedAt': acknowledgedAt?.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'deduplicationKey': deduplicationKey,
      };

  factory AttendanceAlert.fromJson(Map<String, dynamic> json) {
    return AttendanceAlert(
      id: json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      courseId: json['courseId'] as String?,
      academicYearId: json['academicYearId'] as String?,
      semesterId: json['semesterId'] as String?,
      sectionId: json['sectionId'] as String?,
      studentId: json['studentId'] as String?,
      studentName: json['studentName'] as String?,
      rollNumber: json['rollNumber'] as String?,
      subjectId: json['subjectId'] as String?,
      subjectName: json['subjectName'] as String?,
      facultyId: json['facultyId'] as String?,
      alertType: AttendanceAlertType.values.firstWhere(
        (e) => e.name == json['alertType'],
        orElse: () => AttendanceAlertType.lowAttendance,
      ),
      severity: AttendanceAlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AttendanceAlertSeverity.warning,
      ),
      status: AttendanceAlertStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AttendanceAlertStatus.active,
      ),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble(),
      previousPercentage: (json['previousPercentage'] as num?)?.toDouble(),
      dropPercentage: (json['dropPercentage'] as num?)?.toDouble(),
      threshold: (json['threshold'] as num?)?.toDouble() ?? AttendanceAnalyticsConstants.lowAttendanceThreshold,
      consecutiveAbsences: json['consecutiveAbsences'] as int?,
      recoverySessionsNeeded: json['recoverySessionsNeeded'] as int?,
      relatedSessionId: json['relatedSessionId'] as String?,
      relatedTimetableEntryId: json['relatedTimetableEntryId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
      acknowledgedAt: json['acknowledgedAt'] != null
          ? DateTime.tryParse(json['acknowledgedAt'] as String)
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'] as String)
          : null,
      deduplicationKey: json['deduplicationKey'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceAlert &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status &&
          isRead == other.isRead &&
          deduplicationKey == other.deduplicationKey;

  @override
  int get hashCode => Object.hash(id, status, isRead, deduplicationKey);
}
