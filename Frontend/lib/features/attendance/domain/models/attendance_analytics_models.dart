import 'package:flutter/foundation.dart';

/// Preset date range options for attendance analytics
enum AttendanceDateRangePreset {
  today,
  thisWeek,
  thisMonth,
  custom,
}

/// Normalized date range abstraction for analytics queries
@immutable
class AttendanceDateRange {
  final DateTime startDate;
  final DateTime endDate;
  final AttendanceDateRangePreset preset;

  const AttendanceDateRange({
    required this.startDate,
    required this.endDate,
    this.preset = AttendanceDateRangePreset.custom,
  });

  /// Factory for Today (00:00:00.000 to 23:59:59.999)
  factory AttendanceDateRange.today([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 0, 0, 0, 0);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return AttendanceDateRange(
      startDate: start,
      endDate: end,
      preset: AttendanceDateRangePreset.today,
    );
  }

  /// Factory for This Week (Monday 00:00:00.000 to Sunday 23:59:59.999)
  factory AttendanceDateRange.thisWeek([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    // In Dart DateTime, weekday 1 = Monday, 7 = Sunday
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final start = DateTime(monday.year, monday.month, monday.day, 0, 0, 0, 0);
    final end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999);
    return AttendanceDateRange(
      startDate: start,
      endDate: end,
      preset: AttendanceDateRangePreset.thisWeek,
    );
  }

  /// Factory for This Month (1st day 00:00:00.000 to last day 23:59:59.999)
  factory AttendanceDateRange.thisMonth([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    final start = DateTime(now.year, now.month, 1, 0, 0, 0, 0);
    // Day 0 of next month is the last day of current month
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final end = DateTime(now.year, now.month, lastDay, 23, 59, 59, 999);
    return AttendanceDateRange(
      startDate: start,
      endDate: end,
      preset: AttendanceDateRangePreset.thisMonth,
    );
  }

  /// Factory for Custom inclusive date range
  factory AttendanceDateRange.custom({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0, 0);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
    return AttendanceDateRange(
      startDate: start,
      endDate: end,
      preset: AttendanceDateRangePreset.custom,
    );
  }

  /// Evaluates whether a given date falls within the inclusive normalized range
  bool contains(DateTime date) {
    // Normalization check: compare millisecondsSinceEpoch or isBefore / isAfter
    return !date.isBefore(startDate) && !date.isAfter(endDate);
  }

  AttendanceDateRange copyWith({
    DateTime? startDate,
    DateTime? endDate,
    AttendanceDateRangePreset? preset,
  }) {
    return AttendanceDateRange(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      preset: preset ?? this.preset,
    );
  }

  Map<String, dynamic> toJson() => {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'preset': preset.name,
      };

  factory AttendanceDateRange.fromJson(Map<String, dynamic> json) {
    return AttendanceDateRange(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      preset: AttendanceDateRangePreset.values.firstWhere(
        (e) => e.name == json['preset'],
        orElse: () => AttendanceDateRangePreset.custom,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceDateRange &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          preset == other.preset;

  @override
  int get hashCode => Object.hash(startDate, endDate, preset);

  @override
  String toString() =>
      'AttendanceDateRange(${startDate.toIso8601String().split('T').first} to ${endDate.toIso8601String().split('T').first}, preset: ${preset.name})';
}

/// Institutional Risk Levels for Attendance Classification
enum AttendanceRiskLevel {
  healthy, // >= 85.0%
  watch,   // 75.0% - 84.99%
  critical // < 75.0%
}

/// Centralized analytics calculations and configuration constants
class AttendanceAnalyticsConstants {
  AttendanceAnalyticsConstants._();

  /// Default regulatory low attendance threshold (75%)
  static const double lowAttendanceThreshold = 75.0;

  /// Healthy standing attendance threshold (85%)
  static const double healthyAttendanceThreshold = 85.0;

  /// Official Acadex Attendance Calculation Formula:
  /// attendancePercentage = presentCount / (presentCount + absentCount + lateCount + excusedCount) * 100
  /// Note: unmarkedCount MUST NOT be included in the denominator.
  /// If denominator is 0, safely returns 0.0 without divide-by-zero or NaN.
  static double calculatePercentage({
    required int presentCount,
    required int absentCount,
    required int lateCount,
    required int excusedCount,
    int unmarkedCount = 0,
  }) {
    final denominator = presentCount + absentCount + lateCount + excusedCount;
    if (denominator <= 0) return 0.0;
    final percentage = (presentCount / denominator) * 100.0;
    if (percentage.isNaN || percentage.isInfinite) return 0.0;
    return percentage;
  }

  /// Evaluates whether an attendance percentage strictly falls below the threshold (< 75.0)
  /// Boundary:
  /// 74.99% -> true (Low Attendance)
  /// 75.00% -> false (Adequate Attendance)
  /// 75.01% -> false (Adequate Attendance)
  static bool isLowAttendance(
    double percentage, [
    double threshold = lowAttendanceThreshold,
  ]) {
    return percentage < threshold;
  }

  /// Evaluates centralized risk level:
  /// >= 85.0% -> Healthy
  /// 75.0% - 84.99% -> Watch
  /// < 75.0% -> Critical
  static AttendanceRiskLevel evaluateRiskLevel(double percentage) {
    if (percentage >= healthyAttendanceThreshold) {
      return AttendanceRiskLevel.healthy;
    } else if (percentage >= lowAttendanceThreshold) {
      return AttendanceRiskLevel.watch;
    } else {
      return AttendanceRiskLevel.critical;
    }
  }

  /// Calculates the exact number of consecutive present sessions needed
  /// to reach or exceed a target threshold (default: 75.0%).
  /// Formula: (Present + P) / (Total + P) >= (Threshold / 100)
  /// -> P >= (Threshold * Total - 100 * Present) / (100 - Threshold)
  static int calculateSessionsNeededToReachThreshold({
    required int presentCount,
    required int totalSessions,
    double targetThreshold = lowAttendanceThreshold,
  }) {
    if (totalSessions <= 0) return 0;
    final currentPct = (presentCount / totalSessions) * 100.0;
    if (currentPct >= targetThreshold) return 0;

    final numerator = (targetThreshold * totalSessions) - (100.0 * presentCount);
    final denominator = 100.0 - targetThreshold;
    if (denominator <= 0) return 0;

    final required = (numerator / denominator).ceil();
    return required > 0 ? required : 0;
  }
}

/// Student Attendance Analytics Domain Model
@immutable
class StudentAttendanceAnalytics {
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String sectionId;
  final int totalSessions;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final int unmarkedCount;
  final double attendancePercentage;
  final bool isLowAttendance;
  final AttendanceDateRange? dateRange;

  const StudentAttendanceAnalytics({
    required this.studentId,
    this.studentName = '',
    this.rollNumber = '',
    this.sectionId = '',
    this.totalSessions = 0,
    this.presentCount = 0,
    this.absentCount = 0,
    this.lateCount = 0,
    this.excusedCount = 0,
    this.unmarkedCount = 0,
    required this.attendancePercentage,
    required this.isLowAttendance,
    this.dateRange,
  });

  /// Institutional Risk Level
  AttendanceRiskLevel get riskLevel =>
      AttendanceAnalyticsConstants.evaluateRiskLevel(attendancePercentage);

  /// Number of consecutive present sessions needed to reach 75%
  int get recoverySessionsNeeded =>
      AttendanceAnalyticsConstants.calculateSessionsNeededToReachThreshold(
        presentCount: presentCount,
        totalSessions: totalSessions,
      );

  /// Factory with automatic centralized calculation and boundary evaluation
  factory StudentAttendanceAnalytics.compute({
    required String studentId,
    String studentName = '',
    String rollNumber = '',
    String sectionId = '',
    int totalSessions = 0,
    int presentCount = 0,
    int absentCount = 0,
    int lateCount = 0,
    int excusedCount = 0,
    int unmarkedCount = 0,
    double threshold = AttendanceAnalyticsConstants.lowAttendanceThreshold,
    AttendanceDateRange? dateRange,
  }) {
    final percentage = AttendanceAnalyticsConstants.calculatePercentage(
      presentCount: presentCount,
      absentCount: absentCount,
      lateCount: lateCount,
      excusedCount: excusedCount,
      unmarkedCount: unmarkedCount,
    );
    final isLow = AttendanceAnalyticsConstants.isLowAttendance(percentage, threshold);

    return StudentAttendanceAnalytics(
      studentId: studentId,
      studentName: studentName,
      rollNumber: rollNumber,
      sectionId: sectionId,
      totalSessions: totalSessions,
      presentCount: presentCount,
      absentCount: absentCount,
      lateCount: lateCount,
      excusedCount: excusedCount,
      unmarkedCount: unmarkedCount,
      attendancePercentage: percentage,
      isLowAttendance: isLow,
      dateRange: dateRange,
    );
  }

  StudentAttendanceAnalytics copyWith({
    String? studentId,
    String? studentName,
    String? rollNumber,
    String? sectionId,
    int? totalSessions,
    int? presentCount,
    int? absentCount,
    int? lateCount,
    int? excusedCount,
    int? unmarkedCount,
    double? attendancePercentage,
    bool? isLowAttendance,
    AttendanceDateRange? dateRange,
  }) {
    return StudentAttendanceAnalytics(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      rollNumber: rollNumber ?? this.rollNumber,
      sectionId: sectionId ?? this.sectionId,
      totalSessions: totalSessions ?? this.totalSessions,
      presentCount: presentCount ?? this.presentCount,
      absentCount: absentCount ?? this.absentCount,
      lateCount: lateCount ?? this.lateCount,
      excusedCount: excusedCount ?? this.excusedCount,
      unmarkedCount: unmarkedCount ?? this.unmarkedCount,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      isLowAttendance: isLowAttendance ?? this.isLowAttendance,
      dateRange: dateRange ?? this.dateRange,
    );
  }

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'studentName': studentName,
        'rollNumber': rollNumber,
        'sectionId': sectionId,
        'totalSessions': totalSessions,
        'presentCount': presentCount,
        'absentCount': absentCount,
        'lateCount': lateCount,
        'excusedCount': excusedCount,
        'unmarkedCount': unmarkedCount,
        'attendancePercentage': attendancePercentage,
        'isLowAttendance': isLowAttendance,
        if (dateRange != null) 'dateRange': dateRange!.toJson(),
      };

  factory StudentAttendanceAnalytics.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceAnalytics(
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      rollNumber: json['rollNumber'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
      excusedCount: (json['excusedCount'] as num?)?.toInt() ?? 0,
      unmarkedCount: (json['unmarkedCount'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      isLowAttendance: json['isLowAttendance'] as bool? ?? false,
      dateRange: json['dateRange'] != null
          ? AttendanceDateRange.fromJson(json['dateRange'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentAttendanceAnalytics &&
          runtimeType == other.runtimeType &&
          studentId == other.studentId &&
          totalSessions == other.totalSessions &&
          presentCount == other.presentCount &&
          absentCount == other.absentCount &&
          lateCount == other.lateCount &&
          excusedCount == other.excusedCount &&
          unmarkedCount == other.unmarkedCount &&
          attendancePercentage == other.attendancePercentage &&
          isLowAttendance == other.isLowAttendance;

  @override
  int get hashCode => Object.hash(
        studentId,
        totalSessions,
        presentCount,
        absentCount,
        lateCount,
        excusedCount,
        unmarkedCount,
        attendancePercentage,
        isLowAttendance,
      );
}

/// Subject Attendance Analytics Domain Model
@immutable
class SubjectAttendanceAnalytics {
  final String subjectId;
  final String subjectName;
  final String? sectionId;
  final String? facultyId;
  final int totalSessions;
  final int totalStudentRecords;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final int unmarkedCount;
  final double attendancePercentage;
  final AttendanceDateRange? dateRange;

  const SubjectAttendanceAnalytics({
    required this.subjectId,
    this.subjectName = '',
    this.sectionId,
    this.facultyId,
    this.totalSessions = 0,
    this.totalStudentRecords = 0,
    this.presentCount = 0,
    this.absentCount = 0,
    this.lateCount = 0,
    this.excusedCount = 0,
    this.unmarkedCount = 0,
    required this.attendancePercentage,
    this.dateRange,
  });

  /// Institutional Risk Level
  AttendanceRiskLevel get riskLevel =>
      AttendanceAnalyticsConstants.evaluateRiskLevel(attendancePercentage);

  /// Factory with automatic centralized calculation
  factory SubjectAttendanceAnalytics.compute({
    required String subjectId,
    String subjectName = '',
    String? sectionId,
    String? facultyId,
    int totalSessions = 0,
    int totalStudentRecords = 0,
    int presentCount = 0,
    int absentCount = 0,
    int lateCount = 0,
    int excusedCount = 0,
    int unmarkedCount = 0,
    AttendanceDateRange? dateRange,
  }) {
    final percentage = AttendanceAnalyticsConstants.calculatePercentage(
      presentCount: presentCount,
      absentCount: absentCount,
      lateCount: lateCount,
      excusedCount: excusedCount,
      unmarkedCount: unmarkedCount,
    );

    return SubjectAttendanceAnalytics(
      subjectId: subjectId,
      subjectName: subjectName,
      sectionId: sectionId,
      facultyId: facultyId,
      totalSessions: totalSessions,
      totalStudentRecords: totalStudentRecords,
      presentCount: presentCount,
      absentCount: absentCount,
      lateCount: lateCount,
      excusedCount: excusedCount,
      unmarkedCount: unmarkedCount,
      attendancePercentage: percentage,
      dateRange: dateRange,
    );
  }

  SubjectAttendanceAnalytics copyWith({
    String? subjectId,
    String? subjectName,
    String? sectionId,
    String? facultyId,
    int? totalSessions,
    int? totalStudentRecords,
    int? presentCount,
    int? absentCount,
    int? lateCount,
    int? excusedCount,
    int? unmarkedCount,
    double? attendancePercentage,
    AttendanceDateRange? dateRange,
  }) {
    return SubjectAttendanceAnalytics(
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      sectionId: sectionId ?? this.sectionId,
      facultyId: facultyId ?? this.facultyId,
      totalSessions: totalSessions ?? this.totalSessions,
      totalStudentRecords: totalStudentRecords ?? this.totalStudentRecords,
      presentCount: presentCount ?? this.presentCount,
      absentCount: absentCount ?? this.absentCount,
      lateCount: lateCount ?? this.lateCount,
      excusedCount: excusedCount ?? this.excusedCount,
      unmarkedCount: unmarkedCount ?? this.unmarkedCount,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      dateRange: dateRange ?? this.dateRange,
    );
  }

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        'subjectName': subjectName,
        'sectionId': sectionId,
        'facultyId': facultyId,
        'totalSessions': totalSessions,
        'totalStudentRecords': totalStudentRecords,
        'presentCount': presentCount,
        'absentCount': absentCount,
        'lateCount': lateCount,
        'excusedCount': excusedCount,
        'unmarkedCount': unmarkedCount,
        'attendancePercentage': attendancePercentage,
        if (dateRange != null) 'dateRange': dateRange!.toJson(),
      };

  factory SubjectAttendanceAnalytics.fromJson(Map<String, dynamic> json) {
    return SubjectAttendanceAnalytics(
      subjectId: json['subjectId'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      sectionId: json['sectionId'] as String?,
      facultyId: json['facultyId'] as String?,
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      totalStudentRecords: (json['totalStudentRecords'] as num?)?.toInt() ?? 0,
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
      excusedCount: (json['excusedCount'] as num?)?.toInt() ?? 0,
      unmarkedCount: (json['unmarkedCount'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      dateRange: json['dateRange'] != null
          ? AttendanceDateRange.fromJson(json['dateRange'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectAttendanceAnalytics &&
          runtimeType == other.runtimeType &&
          subjectId == other.subjectId &&
          sectionId == other.sectionId &&
          facultyId == other.facultyId &&
          totalSessions == other.totalSessions &&
          totalStudentRecords == other.totalStudentRecords &&
          presentCount == other.presentCount &&
          absentCount == other.absentCount &&
          lateCount == other.lateCount &&
          excusedCount == other.excusedCount &&
          unmarkedCount == other.unmarkedCount &&
          attendancePercentage == other.attendancePercentage;

  @override
  int get hashCode => Object.hash(
        subjectId,
        sectionId,
        facultyId,
        totalSessions,
        totalStudentRecords,
        presentCount,
        absentCount,
        lateCount,
        excusedCount,
        unmarkedCount,
        attendancePercentage,
      );
}

/// Section Attendance Analytics Domain Model
@immutable
class SectionAttendanceAnalytics {
  final String sectionId;
  final String sectionName;
  final int totalSessions;
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final int unmarkedCount;
  final double attendancePercentage;
  final int lowAttendanceStudentCount;
  final List<StudentAttendanceAnalytics> studentAnalytics;
  final AttendanceDateRange? dateRange;

  const SectionAttendanceAnalytics({
    required this.sectionId,
    this.sectionName = '',
    this.totalSessions = 0,
    this.totalStudents = 0,
    this.presentCount = 0,
    this.absentCount = 0,
    this.lateCount = 0,
    this.excusedCount = 0,
    this.unmarkedCount = 0,
    required this.attendancePercentage,
    this.lowAttendanceStudentCount = 0,
    this.studentAnalytics = const [],
    this.dateRange,
  });

  /// Institutional Risk Level
  AttendanceRiskLevel get riskLevel =>
      AttendanceAnalyticsConstants.evaluateRiskLevel(attendancePercentage);

  /// Factory with automatic centralized calculation
  factory SectionAttendanceAnalytics.compute({
    required String sectionId,
    String sectionName = '',
    int totalSessions = 0,
    int totalStudents = 0,
    int presentCount = 0,
    int absentCount = 0,
    int lateCount = 0,
    int excusedCount = 0,
    int unmarkedCount = 0,
    int lowAttendanceStudentCount = 0,
    List<StudentAttendanceAnalytics> studentAnalytics = const [],
    AttendanceDateRange? dateRange,
  }) {
    final percentage = AttendanceAnalyticsConstants.calculatePercentage(
      presentCount: presentCount,
      absentCount: absentCount,
      lateCount: lateCount,
      excusedCount: excusedCount,
      unmarkedCount: unmarkedCount,
    );

    final lowCount = lowAttendanceStudentCount > 0
        ? lowAttendanceStudentCount
        : studentAnalytics.where((s) => s.isLowAttendance).length;

    return SectionAttendanceAnalytics(
      sectionId: sectionId,
      sectionName: sectionName,
      totalSessions: totalSessions,
      totalStudents: totalStudents > 0 ? totalStudents : studentAnalytics.length,
      presentCount: presentCount,
      absentCount: absentCount,
      lateCount: lateCount,
      excusedCount: excusedCount,
      unmarkedCount: unmarkedCount,
      attendancePercentage: percentage,
      lowAttendanceStudentCount: lowCount,
      studentAnalytics: studentAnalytics,
      dateRange: dateRange,
    );
  }

  SectionAttendanceAnalytics copyWith({
    String? sectionId,
    String? sectionName,
    int? totalSessions,
    int? totalStudents,
    int? presentCount,
    int? absentCount,
    int? lateCount,
    int? excusedCount,
    int? unmarkedCount,
    double? attendancePercentage,
    int? lowAttendanceStudentCount,
    List<StudentAttendanceAnalytics>? studentAnalytics,
    AttendanceDateRange? dateRange,
  }) {
    return SectionAttendanceAnalytics(
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      totalSessions: totalSessions ?? this.totalSessions,
      totalStudents: totalStudents ?? this.totalStudents,
      presentCount: presentCount ?? this.presentCount,
      absentCount: absentCount ?? this.absentCount,
      lateCount: lateCount ?? this.lateCount,
      excusedCount: excusedCount ?? this.excusedCount,
      unmarkedCount: unmarkedCount ?? this.unmarkedCount,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      lowAttendanceStudentCount: lowAttendanceStudentCount ?? this.lowAttendanceStudentCount,
      studentAnalytics: studentAnalytics ?? this.studentAnalytics,
      dateRange: dateRange ?? this.dateRange,
    );
  }

  Map<String, dynamic> toJson() => {
        'sectionId': sectionId,
        'sectionName': sectionName,
        'totalSessions': totalSessions,
        'totalStudents': totalStudents,
        'presentCount': presentCount,
        'absentCount': absentCount,
        'lateCount': lateCount,
        'excusedCount': excusedCount,
        'unmarkedCount': unmarkedCount,
        'attendancePercentage': attendancePercentage,
        'lowAttendanceStudentCount': lowAttendanceStudentCount,
        'studentAnalytics': studentAnalytics.map((s) => s.toJson()).toList(),
        if (dateRange != null) 'dateRange': dateRange!.toJson(),
      };

  factory SectionAttendanceAnalytics.fromJson(Map<String, dynamic> json) {
    return SectionAttendanceAnalytics(
      sectionId: json['sectionId'] as String? ?? '',
      sectionName: json['sectionName'] as String? ?? '',
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
      excusedCount: (json['excusedCount'] as num?)?.toInt() ?? 0,
      unmarkedCount: (json['unmarkedCount'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      lowAttendanceStudentCount: (json['lowAttendanceStudentCount'] as num?)?.toInt() ?? 0,
      studentAnalytics: (json['studentAnalytics'] as List<dynamic>?)
              ?.map((e) => StudentAttendanceAnalytics.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      dateRange: json['dateRange'] != null
          ? AttendanceDateRange.fromJson(json['dateRange'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionAttendanceAnalytics &&
          runtimeType == other.runtimeType &&
          sectionId == other.sectionId &&
          totalSessions == other.totalSessions &&
          totalStudents == other.totalStudents &&
          presentCount == other.presentCount &&
          absentCount == other.absentCount &&
          lateCount == other.lateCount &&
          excusedCount == other.excusedCount &&
          unmarkedCount == other.unmarkedCount &&
          attendancePercentage == other.attendancePercentage &&
          lowAttendanceStudentCount == other.lowAttendanceStudentCount &&
          listEquals(studentAnalytics, other.studentAnalytics);

  @override
  int get hashCode => Object.hash(
        sectionId,
        totalSessions,
        totalStudents,
        presentCount,
        absentCount,
        lateCount,
        excusedCount,
        unmarkedCount,
        attendancePercentage,
        lowAttendanceStudentCount,
        Object.hashAll(studentAnalytics),
      );
}

/// Faculty Attendance Activity Analytics Domain Model
@immutable
class FacultyAttendanceAnalytics {
  final String facultyId;
  final String facultyName;
  final int totalSessionsConducted;
  final int totalStudentRecords;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final int unmarkedCount;
  final double attendancePercentage;
  final AttendanceDateRange? dateRange;

  const FacultyAttendanceAnalytics({
    required this.facultyId,
    this.facultyName = '',
    this.totalSessionsConducted = 0,
    this.totalStudentRecords = 0,
    this.presentCount = 0,
    this.absentCount = 0,
    this.lateCount = 0,
    this.excusedCount = 0,
    this.unmarkedCount = 0,
    required this.attendancePercentage,
    this.dateRange,
  });

  /// Factory with automatic centralized calculation
  factory FacultyAttendanceAnalytics.compute({
    required String facultyId,
    String facultyName = '',
    int totalSessionsConducted = 0,
    int totalStudentRecords = 0,
    int presentCount = 0,
    int absentCount = 0,
    int lateCount = 0,
    int excusedCount = 0,
    int unmarkedCount = 0,
    AttendanceDateRange? dateRange,
  }) {
    final percentage = AttendanceAnalyticsConstants.calculatePercentage(
      presentCount: presentCount,
      absentCount: absentCount,
      lateCount: lateCount,
      excusedCount: excusedCount,
      unmarkedCount: unmarkedCount,
    );

    return FacultyAttendanceAnalytics(
      facultyId: facultyId,
      facultyName: facultyName,
      totalSessionsConducted: totalSessionsConducted,
      totalStudentRecords: totalStudentRecords,
      presentCount: presentCount,
      absentCount: absentCount,
      lateCount: lateCount,
      excusedCount: excusedCount,
      unmarkedCount: unmarkedCount,
      attendancePercentage: percentage,
      dateRange: dateRange,
    );
  }

  FacultyAttendanceAnalytics copyWith({
    String? facultyId,
    String? facultyName,
    int? totalSessionsConducted,
    int? totalStudentRecords,
    int? presentCount,
    int? absentCount,
    int? lateCount,
    int? excusedCount,
    int? unmarkedCount,
    double? attendancePercentage,
    AttendanceDateRange? dateRange,
  }) {
    return FacultyAttendanceAnalytics(
      facultyId: facultyId ?? this.facultyId,
      facultyName: facultyName ?? this.facultyName,
      totalSessionsConducted: totalSessionsConducted ?? this.totalSessionsConducted,
      totalStudentRecords: totalStudentRecords ?? this.totalStudentRecords,
      presentCount: presentCount ?? this.presentCount,
      absentCount: absentCount ?? this.absentCount,
      lateCount: lateCount ?? this.lateCount,
      excusedCount: excusedCount ?? this.excusedCount,
      unmarkedCount: unmarkedCount ?? this.unmarkedCount,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      dateRange: dateRange ?? this.dateRange,
    );
  }

  Map<String, dynamic> toJson() => {
        'facultyId': facultyId,
        'facultyName': facultyName,
        'totalSessionsConducted': totalSessionsConducted,
        'totalStudentRecords': totalStudentRecords,
        'presentCount': presentCount,
        'absentCount': absentCount,
        'lateCount': lateCount,
        'excusedCount': excusedCount,
        'unmarkedCount': unmarkedCount,
        'attendancePercentage': attendancePercentage,
        if (dateRange != null) 'dateRange': dateRange!.toJson(),
      };

  factory FacultyAttendanceAnalytics.fromJson(Map<String, dynamic> json) {
    return FacultyAttendanceAnalytics(
      facultyId: json['facultyId'] as String? ?? '',
      facultyName: json['facultyName'] as String? ?? '',
      totalSessionsConducted: (json['totalSessionsConducted'] as num?)?.toInt() ?? 0,
      totalStudentRecords: (json['totalStudentRecords'] as num?)?.toInt() ?? 0,
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
      excusedCount: (json['excusedCount'] as num?)?.toInt() ?? 0,
      unmarkedCount: (json['unmarkedCount'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      dateRange: json['dateRange'] != null
          ? AttendanceDateRange.fromJson(json['dateRange'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FacultyAttendanceAnalytics &&
          runtimeType == other.runtimeType &&
          facultyId == other.facultyId &&
          totalSessionsConducted == other.totalSessionsConducted &&
          totalStudentRecords == other.totalStudentRecords &&
          presentCount == other.presentCount &&
          absentCount == other.absentCount &&
          lateCount == other.lateCount &&
          excusedCount == other.excusedCount &&
          unmarkedCount == other.unmarkedCount &&
          attendancePercentage == other.attendancePercentage;

  @override
  int get hashCode => Object.hash(
        facultyId,
        totalSessionsConducted,
        totalStudentRecords,
        presentCount,
        absentCount,
        lateCount,
        excusedCount,
        unmarkedCount,
        attendancePercentage,
      );
}

/// Date Range Summary Domain Model
@immutable
class AttendanceDateRangeSummary {
  final DateTime startDate;
  final DateTime endDate;
  final int totalSessions;
  final int totalStudentRecords;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final int unmarkedCount;
  final double attendancePercentage;

  const AttendanceDateRangeSummary({
    required this.startDate,
    required this.endDate,
    this.totalSessions = 0,
    this.totalStudentRecords = 0,
    this.presentCount = 0,
    this.absentCount = 0,
    this.lateCount = 0,
    this.excusedCount = 0,
    this.unmarkedCount = 0,
    required this.attendancePercentage,
  });

  /// Factory with automatic centralized calculation
  factory AttendanceDateRangeSummary.compute({
    required DateTime startDate,
    required DateTime endDate,
    int totalSessions = 0,
    int totalStudentRecords = 0,
    int presentCount = 0,
    int absentCount = 0,
    int lateCount = 0,
    int excusedCount = 0,
    int unmarkedCount = 0,
  }) {
    final percentage = AttendanceAnalyticsConstants.calculatePercentage(
      presentCount: presentCount,
      absentCount: absentCount,
      lateCount: lateCount,
      excusedCount: excusedCount,
      unmarkedCount: unmarkedCount,
    );

    return AttendanceDateRangeSummary(
      startDate: startDate,
      endDate: endDate,
      totalSessions: totalSessions,
      totalStudentRecords: totalStudentRecords,
      presentCount: presentCount,
      absentCount: absentCount,
      lateCount: lateCount,
      excusedCount: excusedCount,
      unmarkedCount: unmarkedCount,
      attendancePercentage: percentage,
    );
  }

  AttendanceDateRangeSummary copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? totalSessions,
    int? totalStudentRecords,
    int? presentCount,
    int? absentCount,
    int? lateCount,
    int? excusedCount,
    int? unmarkedCount,
    double? attendancePercentage,
  }) {
    return AttendanceDateRangeSummary(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalSessions: totalSessions ?? this.totalSessions,
      totalStudentRecords: totalStudentRecords ?? this.totalStudentRecords,
      presentCount: presentCount ?? this.presentCount,
      absentCount: absentCount ?? this.absentCount,
      lateCount: lateCount ?? this.lateCount,
      excusedCount: excusedCount ?? this.excusedCount,
      unmarkedCount: unmarkedCount ?? this.unmarkedCount,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
    );
  }

  Map<String, dynamic> toJson() => {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'totalSessions': totalSessions,
        'totalStudentRecords': totalStudentRecords,
        'presentCount': presentCount,
        'absentCount': absentCount,
        'lateCount': lateCount,
        'excusedCount': excusedCount,
        'unmarkedCount': unmarkedCount,
        'attendancePercentage': attendancePercentage,
      };

  factory AttendanceDateRangeSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceDateRangeSummary(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      totalStudentRecords: (json['totalStudentRecords'] as num?)?.toInt() ?? 0,
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
      excusedCount: (json['excusedCount'] as num?)?.toInt() ?? 0,
      unmarkedCount: (json['unmarkedCount'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceDateRangeSummary &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          totalSessions == other.totalSessions &&
          totalStudentRecords == other.totalStudentRecords &&
          presentCount == other.presentCount &&
          absentCount == other.absentCount &&
          lateCount == other.lateCount &&
          excusedCount == other.excusedCount &&
          unmarkedCount == other.unmarkedCount &&
          attendancePercentage == other.attendancePercentage;

  @override
  int get hashCode => Object.hash(
        startDate,
        endDate,
        totalSessions,
        totalStudentRecords,
        presentCount,
        absentCount,
        lateCount,
        excusedCount,
        unmarkedCount,
        attendancePercentage,
      );
}
