import '../../../auth/domain/models/role_enum.dart';
import '../models/analytics_models.dart';

abstract class AnalyticsRepository {
  Future<Map<String, String>> getSummaryMetrics(AppRole role, String userId);
  Future<List<ChartDataPoint>> getTrendChartData(AppRole role, String userId);
  Future<List<ChartDataPoint>> getComparisonChartData(AppRole role, String userId);
  Future<List<AttendanceInsight>> getInsights(AppRole role, String userId);
  Future<List<AttendanceReport>> getRecentReports(AppRole role);
}
