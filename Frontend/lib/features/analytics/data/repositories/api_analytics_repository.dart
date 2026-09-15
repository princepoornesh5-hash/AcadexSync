import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/analytics_models.dart';
import '../../domain/models/department_analytics_models.dart';
import '../../domain/repositories/analytics_repository.dart';

class ApiAnalyticsRepository implements AnalyticsRepository {
  final ApiClient _client;

  ApiAnalyticsRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<Map<String, String>> getSummaryMetrics(AppRole role, String userId) async {
    try {
      final response = await _client.dio.get('/reports/dashboard');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : null;

      if (data is Map<String, dynamic>) {
        final metrics = (data['metrics'] as Map<String, dynamic>?) ??
            (data['kpis'] as Map<String, dynamic>?) ??
            data;

        switch (role) {
          case AppRole.student:
            final attended = (metrics['attendedClasses'] as num?)?.toInt() ?? 0;
            final total = (metrics['totalClasses'] as num?)?.toInt() ?? 0;
            final missed = (metrics['absentClasses'] as num?)?.toInt() ?? 0;
            final pct = (metrics['attendancePercentage'] as num?)?.toDouble() ?? 0.0;
            return {
              'Overall Attendance': total > 0 ? '${pct.toStringAsFixed(1)}%' : '0.0%',
              'Classes Attended': '$attended / $total',
              'Classes Missed': '$missed',
              'Monthly Trend': total > 0 ? '${pct.toStringAsFixed(1)}%' : '0.0%',
            };
          case AppRole.faculty:
            final avgPct = (metrics['avgAttendance'] as num?)?.toDouble() ?? 0.0;
            final conducted = (metrics['totalSessionsConducted'] as num?)?.toInt() ?? 0;
            final atRisk = (metrics['studentsAtRiskCount'] as num?)?.toInt() ?? 0;
            final completion = (metrics['completionRate'] as num?)?.toDouble() ?? 0.0;
            return {
              'Average Class Attendance': conducted > 0 ? '${avgPct.toStringAsFixed(1)}%' : '0.0%',
              'Students At Risk': '$atRisk',
              'Attendance Completion': conducted > 0 ? '${completion.toStringAsFixed(1)}%' : '0.0%',
              'Classes Conducted': '$conducted',
            };
          case AppRole.hod:
            final deptPct = (metrics['departmentAttendancePercentage'] as num?)?.toDouble() ??
                (metrics['avgAttendance'] as num?)?.toDouble() ?? 0.0;
            final lowAtt = (metrics['studentsBelowThresholdCount'] as num?)?.toInt() ?? 0;
            final facComp = (metrics['facultyCompletionRate'] as num?)?.toDouble() ?? 0.0;
            return {
              'Department Attendance': deptPct > 0 ? '${deptPct.toStringAsFixed(1)}%' : '0.0%',
              'Students Below 75%': '$lowAtt',
              'Faculty Completion': facComp > 0 ? '${facComp.toStringAsFixed(1)}%' : '0.0%',
              'Most Absent Subject': (metrics['mostAbsentSubject'] as String?) ?? 'None',
            };
          case AppRole.collegeAdmin:
            final colPct = (metrics['collegeAttendancePercentage'] as num?)?.toDouble() ??
                (metrics['avgAttendance'] as num?)?.toDouble() ?? 0.0;
            final totalRisk = (metrics['totalStudentsAtRisk'] as num?)?.toInt() ?? 0;
            final overallComp = (metrics['overallCompletionRate'] as num?)?.toDouble() ?? 0.0;
            return {
              'College Attendance': colPct > 0 ? '${colPct.toStringAsFixed(1)}%' : '0.0%',
              'Total Students At Risk': '$totalRisk',
              'Best Department': (metrics['topDepartmentName'] as String?) ?? 'None',
              'Overall Completion': overallComp > 0 ? '${overallComp.toStringAsFixed(1)}%' : '0.0%',
            };
          case AppRole.superAdmin:
            final sysPct = (metrics['systemAttendancePercentage'] as num?)?.toDouble() ?? 0.0;
            final activeCols = (metrics['activeCollegesCount'] as num?)?.toInt() ??
                (metrics['totalColleges'] as num?)?.toInt() ?? 0;
            final todayRecs = (metrics['totalRecordsToday'] as num?)?.toInt() ?? 0;
            return {
              'Platform Attendance': sysPct > 0 ? '${sysPct.toStringAsFixed(1)}%' : '0.0%',
              'Active Colleges': '$activeCols',
              'Total Records Today': '$todayRecs',
              'System Health': 'Healthy',
            };
        }
      }
    } catch (_) {
      // Fall through to empty semantics
    }

    return getEmptyMetricsForRole(role);
  }

  Map<String, String> getEmptyMetricsForRole(AppRole role) {
    switch (role) {
      case AppRole.student:
        return {
          'Overall Attendance': '0.0%',
          'Classes Attended': '0 / 0',
          'Classes Missed': '0',
          'Monthly Trend': '0.0%',
        };
      case AppRole.faculty:
        return {
          'Average Class Attendance': '0.0%',
          'Students At Risk': '0',
          'Attendance Completion': '0.0%',
          'Classes Conducted': '0',
        };
      case AppRole.hod:
        return {
          'Department Attendance': '0.0%',
          'Students Below 75%': '0',
          'Faculty Completion': '0.0%',
          'Most Absent Subject': 'None',
        };
      case AppRole.collegeAdmin:
        return {
          'College Attendance': '0.0%',
          'Total Students At Risk': '0',
          'Best Department': 'None',
          'Overall Completion': '0.0%',
        };
      case AppRole.superAdmin:
        return {
          'Platform Attendance': '0.0%',
          'Active Colleges': '0',
          'Total Records Today': '0',
          'System Health': 'Healthy',
        };
    }
  }

  @override
  Future<List<ChartDataPoint>> getTrendChartData(AppRole role, String userId) async {
    try {
      final response = await _client.dio.get('/reports/dashboard');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : null;
      if (data is Map<String, dynamic>) {
        final trends = data['dailyTrend'] as List<dynamic>? ?? data['trends'] as List<dynamic>?;
        if (trends != null && trends.isNotEmpty) {
          return trends.map((item) {
            final m = item as Map<String, dynamic>;
            final dateStr = (m['date'] as String?) ?? '';
            final label = dateStr.isNotEmpty && dateStr.length >= 10 ? dateStr.substring(5, 10) : (m['day'] ?? 'Day');
            final val = (m['percentage'] as num?)?.toDouble() ?? (m['value'] as num?)?.toDouble() ?? 0.0;
            return ChartDataPoint(label: label.toString(), value: val);
          }).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<ChartDataPoint>> getComparisonChartData(AppRole role, String userId) async {
    try {
      final response = await _client.dio.get('/reports/dashboard');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : null;
      if (data is Map<String, dynamic>) {
        final comps = data['departmentComparison'] as List<dynamic>? ??
            data['collegeComparison'] as List<dynamic>? ??
            data['comparisons'] as List<dynamic>?;
        if (comps != null && comps.isNotEmpty) {
          return comps.map((item) {
            final m = item as Map<String, dynamic>;
            final label = (m['name'] as String?) ?? (m['code'] as String?) ?? 'Unit';
            final val = (m['attendancePercentage'] as num?)?.toDouble() ?? (m['percentage'] as num?)?.toDouble() ?? 0.0;
            return ChartDataPoint(label: label, value: val);
          }).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<AttendanceInsight>> getInsights(AppRole role, String userId) async {
    try {
      final response = await _client.dio.get('/reports/dashboard');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : null;
      if (data is Map<String, dynamic>) {
        final insights = data['insights'] as List<dynamic>?;
        if (insights != null && insights.isNotEmpty) {
          return insights.map((item) {
            final m = item as Map<String, dynamic>;
            final sevStr = (m['severity'] as String?) ?? 'positive';
            final sev = sevStr == 'negative'
                ? InsightSeverity.negative
                : (sevStr == 'warning' ? InsightSeverity.neutral : InsightSeverity.positive);
            return AttendanceInsight(
              id: (m['id'] as String?) ?? UniqueKey().toString(),
              title: (m['title'] as String?) ?? 'Insight',
              description: (m['description'] as String?) ?? '',
              severity: sev,
              icon: sev == InsightSeverity.positive ? LucideIcons.trendingUp : LucideIcons.alertTriangle,
            );
          }).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<AttendanceReport>> getRecentReports(AppRole role) async {
    return [];
  }

  // =========================================================================
  // DEPARTMENT ANALYTICS (Prompt 6 of 6)
  // =========================================================================

  Future<DepartmentOverviewModel> getDepartmentOverview({DepartmentAnalyticsFilter? filter}) async {
    final response = await _client.dio.get(
      '/analytics/department/overview',
      queryParameters: filter?.toQueryParameters(),
    );
    final body = response.data;
    final data = body is Map<String, dynamic> ? (body['data'] ?? body) : <String, dynamic>{};
    return DepartmentOverviewModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<CourseAnalyticsModel>> getDepartmentCourses({DepartmentAnalyticsFilter? filter}) async {
    final response = await _client.dio.get(
      '/analytics/department/courses',
      queryParameters: filter?.toQueryParameters(),
    );
    final body = response.data;
    final list = body is Map<String, dynamic> && body['data'] is List ? (body['data'] as List) : (body is List ? body : []);
    return list.map((e) => CourseAnalyticsModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SectionAnalyticsModel>> getDepartmentSections({DepartmentAnalyticsFilter? filter}) async {
    final response = await _client.dio.get(
      '/analytics/department/sections',
      queryParameters: filter?.toQueryParameters(),
    );
    final body = response.data;
    final list = body is Map<String, dynamic> && body['data'] is List ? (body['data'] as List) : (body is List ? body : []);
    return list.map((e) => SectionAnalyticsModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SubjectAnalyticsModel>> getDepartmentSubjects({DepartmentAnalyticsFilter? filter}) async {
    final response = await _client.dio.get(
      '/analytics/department/subjects',
      queryParameters: filter?.toQueryParameters(),
    );
    final body = response.data;
    final list = body is Map<String, dynamic> && body['data'] is List ? (body['data'] as List) : (body is List ? body : []);
    return list.map((e) => SubjectAnalyticsModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DepartmentStudentsResult> getDepartmentStudents({DepartmentAnalyticsFilter? filter}) async {
    final response = await _client.dio.get(
      '/analytics/department/students',
      queryParameters: filter?.toQueryParameters(),
    );
    final body = response.data;
    final data = body is Map<String, dynamic> ? (body['data'] ?? body) : <String, dynamic>{};
    return DepartmentStudentsResult.fromJson(data as Map<String, dynamic>);
  }

  Future<List<TrendAnalyticsModel>> getDepartmentTrends({DepartmentAnalyticsFilter? filter}) async {
    final response = await _client.dio.get(
      '/analytics/department/trends',
      queryParameters: filter?.toQueryParameters(),
    );
    final body = response.data;
    final data = body is Map<String, dynamic> ? (body['data'] ?? body) : null;
    final list = data is Map<String, dynamic> && data['trends'] is List ? (data['trends'] as List) : (data is List ? data : []);
    return list.map((e) => TrendAnalyticsModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
