import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../../features/auth/domain/models/auth_state.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/models/attendance_alert.dart';
import '../../domain/models/attendance_analytics_models.dart';
import '../../domain/models/attendance_session.dart';
import '../../domain/repositories/attendance_alert_repository.dart';
import '../../domain/services/attendance_risk_evaluator.dart';
import '../../data/repositories/firebase_attendance_alert_repository.dart';
import '../../data/repositories/mock_attendance_alert_repository.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';

/// Provider for AttendanceAlertRepository (supports Firestore and Mock)
final attendanceAlertRepositoryProvider = Provider<AttendanceAlertRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return MockAttendanceAlertRepository();
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FirebaseAttendanceAlertRepository(firestoreService);
});

/// Provider for AttendanceRiskEvaluator service
final attendanceRiskEvaluatorProvider = Provider<AttendanceRiskEvaluator>((ref) {
  return AttendanceRiskEvaluator();
});

/// StateProvider for current alert filter criteria
final attendanceAlertFilterProvider = StateProvider<AttendanceAlertFilter>((ref) {
  return const AttendanceAlertFilter();
});

/// StateProvider for search query across alerts
final attendanceAlertSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

/// Scoped alerts list provider reacting to auth user, filters, and search
final attendanceAlertsProvider = FutureProvider.autoDispose<List<AttendanceAlert>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    return [];
  }

  final repository = ref.watch(attendanceAlertRepositoryProvider);
  final filter = ref.watch(attendanceAlertFilterProvider);
  final searchQuery = ref.watch(attendanceAlertSearchQueryProvider);

  return repository.getAlerts(
    user: authState.user,
    filter: filter,
    searchQuery: searchQuery,
  );
});

/// Summary count provider for dashboard alert badges (Critical, Warning, Unread)
final attendanceAlertSummaryProvider = FutureProvider.autoDispose<AttendanceAlertSummary>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    return const AttendanceAlertSummary();
  }

  final repository = ref.watch(attendanceAlertRepositoryProvider);
  return repository.getAlertSummary(user: authState.user);
});

/// Single alert detail provider by alert ID
final attendanceAlertDetailProvider = FutureProvider.autoDispose.family<AttendanceAlert?, String>((ref, alertId) async {
  final repository = ref.watch(attendanceAlertRepositoryProvider);
  return repository.getAlertById(alertId);
});

/// Actions notifier for alert state transitions and evaluations
class AttendanceAlertActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AttendanceAlertActionNotifier(this._ref) : super(const AsyncValue.data(null));

  AttendanceAlertRepository get _repository => _ref.read(attendanceAlertRepositoryProvider);
  AttendanceRiskEvaluator get _evaluator => _ref.read(attendanceRiskEvaluatorProvider);

  void _invalidateAlertProviders() {
    _ref.invalidate(attendanceAlertsProvider);
    _ref.invalidate(attendanceAlertSummaryProvider);
  }

  /// Mark single alert as read
  Future<void> markAsRead(String alertId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.markAsRead(alertId);
      _ref.invalidate(attendanceAlertDetailProvider(alertId));
      _invalidateAlertProviders();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Mark all alerts visible to current user as read
  Future<void> markAllAsRead() async {
    final authState = _ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    state = const AsyncValue.loading();
    try {
      await _repository.markAllAsRead(user: authState.user);
      _invalidateAlertProviders();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Acknowledge an alert
  Future<void> acknowledgeAlert(String alertId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.acknowledgeAlert(alertId);
      _ref.invalidate(attendanceAlertDetailProvider(alertId));
      _invalidateAlertProviders();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Resolve an alert
  Future<void> resolveAlert(String alertId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.resolveAlert(alertId);
      _ref.invalidate(attendanceAlertDetailProvider(alertId));
      _invalidateAlertProviders();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Evaluates student attendance analytics and persists generated alerts
  Future<List<AttendanceAlert>> evaluateAndSyncStudentAlerts({
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
  }) async {
    final authState = _ref.read(authProvider);
    if (authState is! AuthAuthenticated) return [];

    final existingAlerts = await _repository.getAlerts(user: authState.user);

    final generatedAlerts = _evaluator.evaluateStudent(
      studentAnalytics: studentAnalytics,
      collegeId: collegeId,
      departmentId: departmentId,
      courseId: courseId,
      academicYearId: academicYearId,
      semesterId: semesterId,
      subjectAnalyticsList: subjectAnalyticsList,
      recentSessions: recentSessions,
      previousPercentagesBySubject: previousPercentagesBySubject,
      previousOverallPercentage: previousOverallPercentage,
      existingAlerts: existingAlerts,
    );

    if (generatedAlerts.isNotEmpty) {
      await _repository.saveAlerts(generatedAlerts);
      _invalidateAlertProviders();
      _ref.read(attendanceNotificationDispatcherProvider).safeDispatch(alerts: generatedAlerts);
    }

    return generatedAlerts;
  }
}

/// Provider for AttendanceAlertActionNotifier
final attendanceAlertActionProvider = StateNotifierProvider<AttendanceAlertActionNotifier, AsyncValue<void>>((ref) {
  return AttendanceAlertActionNotifier(ref);
});
