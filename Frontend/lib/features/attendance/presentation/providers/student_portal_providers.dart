import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/attendance_alert.dart';
import '../../domain/models/attendance_analytics_models.dart';
import '../../domain/models/department_attendance_comparison.dart';
import '../../domain/models/student_attendance_models.dart';
import '../../domain/services/student_attendance_service.dart';
import '../../presentation/providers/attendance_providers.dart';
import '../../presentation/providers/attendance_alert_providers.dart';

/// Provider for domain service
final studentPortalServiceProvider = Provider<StudentAttendanceService>((ref) {
  return const StudentAttendanceService();
});

/// Current student ID with security enforcement
final authenticatedStudentIdProvider = Provider<String>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return authState.user.id;
  }
  return '';
});

/// Student Summary Analytics Provider
final studentPortalSummaryProvider = FutureProvider<StudentAttendanceAnalytics>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    return const StudentAttendanceAnalytics(
      studentId: '',
      attendancePercentage: 0.0,
      isLowAttendance: false,
    );
  }

  final repo = ref.watch(attendanceRepoProvider);
  return repo.getStudentAttendanceAnalytics(authState.user.id);
});

/// Detailed Subjects List Provider
final studentDetailedSubjectsProvider = FutureProvider<List<StudentDetailedSubjectAttendance>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];

  final repo = ref.watch(attendanceRepoProvider);
  final service = ref.watch(studentPortalServiceProvider);

  final subjects = await repo.getStudentSubjectAttendance(authState.user.id);
  return service.computeDetailedSubjects(subjects: subjects);
});

/// Selected Subject Filter state for Subject tab
final studentSelectedSubjectFilterProvider = StateProvider<String?>((ref) => null);

/// All attendance sessions for current student
final studentAllSessionsProvider = FutureProvider<List<StudentAttendanceSessionSummary>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];

  final repo = ref.watch(attendanceRepoProvider);
  final service = ref.watch(studentPortalServiceProvider);

  final sessions = await repo.getRecentSessions(authState.user.id);
  return service.extractStudentSessions(
    studentId: authState.user.id,
    sessions: sessions,
  );
});

/// Calendar Days Provider
final studentAttendanceCalendarProvider = FutureProvider<List<StudentAttendanceCalendarDay>>((ref) async {
  final service = ref.watch(studentPortalServiceProvider);
  final sessions = await ref.watch(studentAllSessionsProvider.future);
  return service.buildCalendarDays(sessions: sessions);
});

/// Selected date on calendar
final studentSelectedCalendarDateProvider = StateProvider<DateTime?>((ref) => null);

/// Sessions for the selected date on calendar
final studentSelectedDateSessionsProvider = Provider<List<StudentAttendanceSessionSummary>>((ref) {
  final selectedDate = ref.watch(studentSelectedCalendarDateProvider);
  final sessionsAsync = ref.watch(studentAllSessionsProvider);

  return sessionsAsync.maybeWhen(
    data: (sessions) {
      if (selectedDate == null) return sessions;
      return sessions.where((s) =>
        s.date.year == selectedDate.year &&
        s.date.month == selectedDate.month &&
        s.date.day == selectedDate.day
      ).toList();
    },
    orElse: () => [],
  );
});

/// Single session detail provider (Read-Only)
final studentSessionDetailProvider = FutureProvider.family<StudentAttendanceSessionSummary?, String>((ref, sessionId) async {
  final sessions = await ref.watch(studentAllSessionsProvider.future);
  return sessions.where((s) => s.sessionId == sessionId).firstOrNull;
});

/// Active student alerts
final studentPortalAlertsProvider = FutureProvider<List<AttendanceAlert>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];

  final alertRepo = ref.watch(attendanceAlertRepositoryProvider);
  return alertRepo.getAlerts(user: authState.user);
});

/// Comprehensive Student Insights Provider
final studentAttendanceInsightsProvider = FutureProvider<StudentAttendanceInsights>((ref) async {
  final service = ref.watch(studentPortalServiceProvider);
  final summary = await ref.watch(studentPortalSummaryProvider.future);
  final subjects = await ref.watch(studentDetailedSubjectsProvider.future);
  final alerts = await ref.watch(studentPortalAlertsProvider.future);

  return service.buildInsights(
    analytics: summary,
    subjects: subjects,
    alerts: alerts,
  );
});

// ---------------------------------------------------------------------------
// Phase 8G Explicit Provider Aliases & Specialized Feeds
// ---------------------------------------------------------------------------

/// Primary summary feed alias for student attendance
final studentAttendanceSummaryProvider = studentPortalSummaryProvider;

/// Subject-wise detailed attendance feed alias
final studentSubjectAttendanceProvider = studentDetailedSubjectsProvider;

/// Chronological attendance session history feed alias
final studentAttendanceHistoryProvider = studentAllSessionsProvider;

/// Filtered subjects below institutional threshold (Low Attendance Analysis)
final studentLowAttendanceProvider = Provider<AsyncValue<List<StudentDetailedSubjectAttendance>>>((ref) {
  final subjectsAsync = ref.watch(studentDetailedSubjectsProvider);
  return subjectsAsync.whenData((list) => list.where((s) => s.isBelowThreshold).toList());
});

/// Overall attendance trend direction feed
final studentAttendanceTrendProvider = Provider<AsyncValue<TrendDirection>>((ref) {
  final insightsAsync = ref.watch(studentAttendanceInsightsProvider);
  return insightsAsync.whenData((i) => i.trendDirection);
});

/// Chronological attendance sessions filtered by subject ID (Family Provider)
final studentSubjectHistoryProvider = FutureProvider.family<List<StudentAttendanceSessionSummary>, String>((ref, subjectId) async {
  final sessions = await ref.watch(studentAllSessionsProvider.future);
  return sessions.where((s) => s.subjectId == subjectId).toList();
});

