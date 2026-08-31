import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../domain/models/analytics_models.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../data/repositories/mock_analytics_repository.dart';
import '../../data/repositories/api_analytics_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../attendance/data/repositories/mock_attendance_repository.dart';

// --- Configuration ---

final analyticsThresholdProvider = Provider<double>((ref) => 75.0);

final apiAnalyticsRepositoryProvider = Provider<ApiAnalyticsRepository>((ref) {
  return ApiAnalyticsRepository();
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return MockAnalyticsRepository(MockAttendanceRepository());
  }
  return ref.watch(apiAnalyticsRepositoryProvider);
});

// --- Dashboard Data Providers ---

final analyticsSummaryProvider = FutureProvider<Map<String, String>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return {};
  
  final repo = ref.watch(analyticsRepositoryProvider);
  return await repo.getSummaryMetrics(authState.user.role, authState.user.id);
});

final trendChartProvider = FutureProvider<List<ChartDataPoint>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];
  
  final repo = ref.watch(analyticsRepositoryProvider);
  return await repo.getTrendChartData(authState.user.role, authState.user.id);
});

final comparisonChartProvider = FutureProvider<List<ChartDataPoint>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];
  
  final repo = ref.watch(analyticsRepositoryProvider);
  return await repo.getComparisonChartData(authState.user.role, authState.user.id);
});

final insightsProvider = FutureProvider<List<AttendanceInsight>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];
  
  final repo = ref.watch(analyticsRepositoryProvider);
  return await repo.getInsights(authState.user.role, authState.user.id);
});

final recentReportsProvider = FutureProvider<List<AttendanceReport>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];
  
  final repo = ref.watch(analyticsRepositoryProvider);
  return await repo.getRecentReports(authState.user.role);
});

// --- Student Projection: derived from real summary metrics ---

final studentAttendanceCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated || authState.user.role != AppRole.student) {
    return {'total': 0, 'attended': 0};
  }
  final summary = await ref.watch(analyticsSummaryProvider.future);
  // Parse real values from summary
  final classesStr = summary['Classes Attended'] ?? '0 / 0';
  final parts = classesStr.split('/');
  final attended = int.tryParse(parts[0].trim()) ?? 0;
  final total = parts.length > 1 ? int.tryParse(parts[1].trim()) ?? 0 : 0;
  return {'total': total, 'attended': attended};
});

final studentProjectionProvider = Provider<AttendanceProjection?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated || authState.user.role != AppRole.student) {
    return null;
  }
  final threshold = ref.watch(analyticsThresholdProvider);
  final countsAsync = ref.watch(studentAttendanceCountsProvider);

  return countsAsync.when(
    data: (counts) => AttendanceProjection.calculate(
      totalClasses: counts['total']!,
      attendedClasses: counts['attended']!,
      targetPercentage: threshold,
    ),
    loading: () => null,
    error: (_, _) => null,
  );
});

final studentRiskProvider = Provider<AttendanceRiskProfile?>((ref) {
  final projection = ref.watch(studentProjectionProvider);
  if (projection == null) return null;
  
  final threshold = ref.watch(analyticsThresholdProvider);
  return AttendanceRiskProfile.calculate(projection.currentPercentage, threshold);
});
