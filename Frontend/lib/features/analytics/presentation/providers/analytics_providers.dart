import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../domain/models/analytics_models.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../data/repositories/firebase_analytics_repository.dart';
import '../../data/repositories/mock_analytics_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';

// --- Configuration ---

final analyticsThresholdProvider = Provider<double>((ref) => 75.0);

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return mockAnalyticsRepo;
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FirebaseAnalyticsRepository(firestoreService);
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

// --- Specific Calculators ---

final studentProjectionProvider = Provider<AttendanceProjection?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated || authState.user.role != AppRole.student) {
    return null;
  }
  final threshold = ref.watch(analyticsThresholdProvider);
  
  // Hardcoded for demo, normally this would come from a repository call giving total/attended classes
  return AttendanceProjection.calculate(
    totalClasses: 185,
    attendedClasses: 145,
    targetPercentage: threshold,
  );
});

final studentRiskProvider = Provider<AttendanceRiskProfile?>((ref) {
  final projection = ref.watch(studentProjectionProvider);
  if (projection == null) return null;
  
  final threshold = ref.watch(analyticsThresholdProvider);
  return AttendanceRiskProfile.calculate(projection.currentPercentage, threshold);
});
