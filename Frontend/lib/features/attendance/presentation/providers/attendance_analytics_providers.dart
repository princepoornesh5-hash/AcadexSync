import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/attendance_analytics_models.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/domain/models/auth_state.dart';
import 'attendance_providers.dart';

/// Parameter object for student analytics queries
@immutable
class StudentAnalyticsQuery {
  final String studentId;
  final AttendanceDateRange? dateRange;

  const StudentAnalyticsQuery({
    required this.studentId,
    this.dateRange,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentAnalyticsQuery &&
          runtimeType == other.runtimeType &&
          studentId == other.studentId &&
          dateRange == other.dateRange;

  @override
  int get hashCode => Object.hash(studentId, dateRange);
}

/// Parameter object for subject analytics queries
@immutable
class SubjectAnalyticsQuery {
  final String subjectId;
  final String? sectionId;
  final AttendanceDateRange? dateRange;

  const SubjectAnalyticsQuery({
    required this.subjectId,
    this.sectionId,
    this.dateRange,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectAnalyticsQuery &&
          runtimeType == other.runtimeType &&
          subjectId == other.subjectId &&
          sectionId == other.sectionId &&
          dateRange == other.dateRange;

  @override
  int get hashCode => Object.hash(subjectId, sectionId, dateRange);
}

/// Parameter object for section analytics queries
@immutable
class SectionAnalyticsQuery {
  final String sectionId;
  final AttendanceDateRange? dateRange;

  const SectionAnalyticsQuery({
    required this.sectionId,
    this.dateRange,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionAnalyticsQuery &&
          runtimeType == other.runtimeType &&
          sectionId == other.sectionId &&
          dateRange == other.dateRange;

  @override
  int get hashCode => Object.hash(sectionId, dateRange);
}

/// Parameter object for faculty analytics queries
@immutable
class FacultyAnalyticsQuery {
  final String facultyId;
  final AttendanceDateRange? dateRange;

  const FacultyAnalyticsQuery({
    required this.facultyId,
    this.dateRange,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FacultyAnalyticsQuery &&
          runtimeType == other.runtimeType &&
          facultyId == other.facultyId &&
          dateRange == other.dateRange;

  @override
  int get hashCode => Object.hash(facultyId, dateRange);
}

/// Parameter object for date-range summaries
@immutable
class DateRangeSummaryQuery {
  final AttendanceDateRange? dateRange;
  final String? departmentId;
  final String? sectionId;

  const DateRangeSummaryQuery({
    this.dateRange,
    this.departmentId,
    this.sectionId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRangeSummaryQuery &&
          runtimeType == other.runtimeType &&
          dateRange == other.dateRange &&
          departmentId == other.departmentId &&
          sectionId == other.sectionId;

  @override
  int get hashCode => Object.hash(dateRange, departmentId, sectionId);
}

/// Student Attendance Analytics Provider (Family)
final studentAttendanceAnalyticsProvider =
    FutureProvider.autoDispose.family<StudentAttendanceAnalytics, StudentAnalyticsQuery>((ref, query) async {
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getStudentAttendanceAnalytics(
    query.studentId,
    dateRange: query.dateRange,
  );
});

/// Subject Attendance Analytics Provider (Family)
final subjectAttendanceAnalyticsProvider =
    FutureProvider.autoDispose.family<SubjectAttendanceAnalytics, SubjectAnalyticsQuery>((ref, query) async {
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getSubjectAttendanceAnalytics(
    query.subjectId,
    sectionId: query.sectionId,
    dateRange: query.dateRange,
  );
});

/// Section Attendance Analytics Provider (Family)
final sectionAttendanceAnalyticsProvider =
    FutureProvider.autoDispose.family<SectionAttendanceAnalytics, SectionAnalyticsQuery>((ref, query) async {
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getSectionAttendanceAnalytics(
    query.sectionId,
    dateRange: query.dateRange,
  );
});

/// Faculty Attendance Analytics Provider (Family)
final facultyAttendanceAnalyticsProvider =
    FutureProvider.autoDispose.family<FacultyAttendanceAnalytics, FacultyAnalyticsQuery>((ref, query) async {
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getFacultyAttendanceAnalytics(
    query.facultyId,
    dateRange: query.dateRange,
  );
});

/// Date Range Summary Analytics Provider (Family)
final attendanceDateRangeSummaryProvider =
    FutureProvider.autoDispose.family<AttendanceDateRangeSummary, DateRangeSummaryQuery>((ref, query) async {
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getAttendanceDateRangeSummary(
    dateRange: query.dateRange,
    departmentId: query.departmentId,
    sectionId: query.sectionId,
  );
});

/// Contextual Provider for Currently Logged-in Student
final currentStudentAnalyticsProvider =
    FutureProvider.autoDispose.family<StudentAttendanceAnalytics, AttendanceDateRange?>((ref, dateRange) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    return const StudentAttendanceAnalytics(
      studentId: '',
      attendancePercentage: 0.0,
      isLowAttendance: false,
    );
  }

  final repo = ref.watch(attendanceRepoProvider);
  return repo.getStudentAttendanceAnalytics(
    authState.user.id,
    dateRange: dateRange,
  );
});

/// Contextual Provider for Currently Logged-in Faculty
final currentFacultyAnalyticsProvider =
    FutureProvider.autoDispose.family<FacultyAttendanceAnalytics, AttendanceDateRange?>((ref, dateRange) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    return const FacultyAttendanceAnalytics(
      facultyId: '',
      attendancePercentage: 0.0,
    );
  }

  final repo = ref.watch(attendanceRepoProvider);
  return repo.getFacultyAttendanceAnalytics(
    authState.user.id,
    dateRange: dateRange,
  );
});
