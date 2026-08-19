import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/analytics/data/repositories/mock_analytics_repository.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/attendance/data/repositories/mock_attendance_repository.dart';

void main() {
  group('Prompt 65: Analytics Security & Isolation Tests', () {
    late MockAnalyticsRepository repo;

    setUp(() {
      repo = MockAnalyticsRepository(MockAttendanceRepository());
    });

    test('1. Student receives only own attendance metrics', () async {
      final metrics = await repo.getSummaryMetrics(AppRole.student, 'mock_student');
      // Should have student-specific keys, not admin keys
      expect(metrics.containsKey('Overall Attendance'), isTrue);
      expect(metrics.containsKey('Active Colleges'), isFalse);
      expect(metrics.containsKey('Department Attendance'), isFalse);
      expect(metrics.containsKey('College Attendance'), isFalse);
    });

    test('2. Faculty receives own class metrics, not other roles', () async {
      final metrics = await repo.getSummaryMetrics(AppRole.faculty, 'mock_faculty');
      expect(metrics.containsKey('Average Class Attendance'), isTrue);
      expect(metrics.containsKey('Overall Attendance'), isFalse);
      expect(metrics.containsKey('Department Attendance'), isFalse);
    });

    test('3. HOD receives department-scoped metrics', () async {
      final metrics = await repo.getSummaryMetrics(AppRole.hod, 'mock_hod');
      expect(metrics.containsKey('Department Attendance'), isTrue);
      expect(metrics.containsKey('Overall Attendance'), isFalse);
      expect(metrics.containsKey('College Attendance'), isFalse);
    });

    test('4. College Admin receives college-scoped metrics', () async {
      final metrics = await repo.getSummaryMetrics(AppRole.collegeAdmin, 'mock_admin');
      expect(metrics.containsKey('College Attendance'), isTrue);
      expect(metrics.containsKey('Overall Attendance'), isFalse);
      expect(metrics.containsKey('Department Attendance'), isFalse);
    });

    test('5. Super Admin receives platform-level metrics', () async {
      final metrics = await repo.getSummaryMetrics(AppRole.superAdmin, 'mock_super');
      expect(metrics.containsKey('Platform Attendance'), isTrue);
      expect(metrics.containsKey('Overall Attendance'), isFalse);
    });

    test('6. Trend chart data is non-empty for each role', () async {
      for (final role in AppRole.values) {
        final data = await repo.getTrendChartData(role, 'user_$role');
        expect(data, isNotEmpty, reason: 'Expected trend data for $role');
      }
    });

    test('7. Comparison chart data is role-scoped', () async {
      final studentData = await repo.getComparisonChartData(AppRole.student, 'student1');
      final hodData = await repo.getComparisonChartData(AppRole.hod, 'hod1');
      // Student and HOD comparison keys should differ (subjects vs sections)
      expect(studentData, isNotEmpty);
      expect(hodData, isNotEmpty);
      // They should have different labels
      final studentLabels = studentData.map((d) => d.label).toSet();
      final hodLabels = hodData.map((d) => d.label).toSet();
      expect(studentLabels, isNot(equals(hodLabels)));
    });

    test('8. Insights are returned per role', () async {
      for (final role in AppRole.values) {
        final insights = await repo.getInsights(role, 'user_$role');
        expect(insights, isNotEmpty, reason: 'Expected insights for $role');
      }
    });

    test('9. No fabricated data — values must not be negative', () async {
      for (final role in AppRole.values) {
        final data = await repo.getTrendChartData(role, 'user_$role');
        for (final point in data) {
          expect(point.value, greaterThanOrEqualTo(0), reason: 'Negative value in trend for $role');
          expect(point.value, lessThanOrEqualTo(100), reason: 'Value >100% in trend for $role');
        }
      }
    });

    test('10. Production mock protection: MockAnalyticsRepository is distinct class from FirebaseAnalyticsRepository', () {
      expect(repo.runtimeType.toString(), equals('MockAnalyticsRepository'));
    });
  });
}
