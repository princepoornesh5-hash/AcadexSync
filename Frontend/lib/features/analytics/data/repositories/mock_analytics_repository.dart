import 'dart:math';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/analytics_models.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../../attendance/data/repositories/mock_attendance_repository.dart';

class MockAnalyticsRepository implements AnalyticsRepository {
  final MockAttendanceRepository attendanceRepo;

  MockAnalyticsRepository(this.attendanceRepo);

  Future<void> _delay() async => await Future.delayed(const Duration(milliseconds: 600));

  // --- Summary Metrics ---

  @override
  Future<Map<String, String>> getSummaryMetrics(AppRole role, String userId) async {
    await _delay();
    
    switch (role) {
      case AppRole.student:
        return {
          'Overall Attendance': '78.5%',
          'Classes Attended': '145 / 185',
          'Classes Missed': '40',
          'Monthly Trend': '+2.1%',
        };
      case AppRole.faculty:
        return {
          'Average Class Attendance': '82.4%',
          'Students At Risk': '12',
          'Attendance Completion': '100%',
          'Classes Conducted': '48',
        };
      case AppRole.hod:
        return {
          'Department Attendance': '79.2%',
          'Students Below 75%': '45',
          'Faculty Completion': '94%',
          'Most Absent Subject': 'Compiler Design',
        };
      case AppRole.collegeAdmin:
        return {
          'College Attendance': '81.5%',
          'Total Students At Risk': '215',
          'Best Department': 'Computer Eng.',
          'Overall Completion': '92%',
        };
      case AppRole.superAdmin:
        return {
          'Platform Attendance': '80.1%',
          'Active Colleges': '4',
          'Total Records Today': '12.5K',
          'System Health': 'Optimal',
        };
    }
  }

  // --- Charts ---

  @override
  Future<List<ChartDataPoint>> getTrendChartData(AppRole role, String userId) async {
    await _delay();
    final random = Random(userId.hashCode); // deterministic based on user

    // Generate 6 months of trend data
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    double base = role == AppRole.student ? 75.0 : 80.0;
    
    return months.map((month) {
      base = base + (random.nextDouble() * 10 - 4);
      if (base > 100) base = 100;
      if (base < 50) base = 50;
      return ChartDataPoint(label: month, value: base);
    }).toList();
  }

  @override
  Future<List<ChartDataPoint>> getComparisonChartData(AppRole role, String userId) async {
    await _delay();
    
    if (role == AppRole.student || role == AppRole.faculty) {
      return [
        const ChartDataPoint(label: 'Math', value: 85),
        const ChartDataPoint(label: 'Physics', value: 72),
        const ChartDataPoint(label: 'CS', value: 91),
        const ChartDataPoint(label: 'English', value: 88),
      ];
    } else if (role == AppRole.hod) {
      return [
        const ChartDataPoint(label: 'Sec A', value: 82),
        const ChartDataPoint(label: 'Sec B', value: 76),
        const ChartDataPoint(label: 'Sec C', value: 89),
      ];
    } else {
      return [
        const ChartDataPoint(label: 'CSE', value: 84),
        const ChartDataPoint(label: 'ECE', value: 78),
        const ChartDataPoint(label: 'MECH', value: 71),
        const ChartDataPoint(label: 'CIVIL', value: 68),
      ];
    }
  }

  // --- Insights ---

  @override
  Future<List<AttendanceInsight>> getInsights(AppRole role, String userId) async {
    await _delay();
    
    List<AttendanceInsight> insights = [];

    if (role == AppRole.student) {
      insights.add(const AttendanceInsight(
        id: 'i1',
        title: 'Great Job!',
        description: 'Your attendance improved by 5% this month compared to last month.',
        severity: InsightSeverity.positive,
        icon: LucideIcons.trendingUp,
      ));
      insights.add(const AttendanceInsight(
        id: 'i2',
        title: 'Physics Warning',
        description: 'You missed the last 3 classes in Physics. You are close to the 75% threshold.',
        severity: InsightSeverity.negative,
        icon: LucideIcons.alertTriangle,
      ));
    } else if (role == AppRole.hod || role == AppRole.collegeAdmin) {
      insights.add(const AttendanceInsight(
        id: 'i3',
        title: 'Highest Attendance',
        description: 'Computer Engineering (Sec A) has the highest attendance this week at 92%.',
        severity: InsightSeverity.positive,
        icon: LucideIcons.award,
      ));
      insights.add(const AttendanceInsight(
        id: 'i4',
        title: 'Completion Alert',
        description: '3 faculty members have pending attendance submissions for today.',
        severity: InsightSeverity.negative,
        icon: LucideIcons.clock,
      ));
      insights.add(const AttendanceInsight(
        id: 'i5',
        title: 'Steady Trend',
        description: 'Overall attendance has remained stable above 80% for 4 consecutive weeks.',
        severity: InsightSeverity.neutral,
        icon: LucideIcons.activity,
      ));
    } else {
      insights.add(const AttendanceInsight(
        id: 'i6',
        title: 'Platform Stability',
        description: 'Attendance capture rate is operating normally across all institutions.',
        severity: InsightSeverity.positive,
        icon: LucideIcons.checkCircle2,
      ));
    }

    return insights;
  }

  // --- Reports ---

  @override
  Future<List<AttendanceReport>> getRecentReports(AppRole role) async {
    await _delay();
    return [
      AttendanceReport(
        id: 'rep_1',
        title: 'Monthly Department Summary - May',
        type: ReportType.monthly,
        generatedAt: DateTime.now().subtract(const Duration(days: 2)),
        generatedBy: AppRole.hod,
        filtersApplied: {'Month': 'May 2026', 'Department': 'CSE'},
        summary: 'Overall department attendance was 79%. 45 students fell below the 75% threshold.',
      ),
      AttendanceReport(
        id: 'rep_2',
        title: 'Weekly Risk Analysis',
        type: ReportType.weekly,
        generatedAt: DateTime.now().subtract(const Duration(days: 5)),
        generatedBy: AppRole.collegeAdmin,
        filtersApplied: {'Week': 'Week 24', 'Risk Level': 'Critical'},
        summary: '215 students across the college are currently in the critical attendance band.',
      ),
    ];
  }
}

final mockAnalyticsRepo = MockAnalyticsRepository(mockAttendanceRepo);
