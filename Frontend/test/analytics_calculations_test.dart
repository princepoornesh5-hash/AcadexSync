import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/analytics/domain/models/analytics_models.dart';

void main() {
  group('Analytics Calculations Verification', () {
    test('Attendance Projection calculations match mathematical expected values', () {
      final projection = AttendanceProjection.calculate(
        totalClasses: 90,
        attendedClasses: 72,
        targetPercentage: 75.0,
      );

      expect(projection.currentPercentage, 80.0);
      expect(projection.requiredConsecutiveClasses, 0); // Already above target
    });

    test('Attendance Risk Profile classifies level correctly based on threshold', () {
      final riskGood = AttendanceRiskProfile.calculate(80.0, 75.0);
      expect(riskGood.level, AttendanceRiskLevel.goodStanding);

      final riskWarning = AttendanceRiskProfile.calculate(70.0, 75.0);
      expect(riskWarning.level, AttendanceRiskLevel.warning);

      final riskCritical = AttendanceRiskProfile.calculate(60.0, 75.0);
      expect(riskCritical.level, AttendanceRiskLevel.critical);
    });
  });
}
