import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/role_enum.dart';

// --- Risk Classification ---

enum AttendanceRiskLevel {
  goodStanding,
  warning,
  critical
}

class AttendanceRiskProfile {
  final double attendancePercentage;
  final double threshold;
  final AttendanceRiskLevel level;

  const AttendanceRiskProfile({
    required this.attendancePercentage,
    required this.threshold,
    required this.level,
  });

  factory AttendanceRiskProfile.calculate(double percentage, double threshold) {
    if (percentage >= threshold) {
      return AttendanceRiskProfile(attendancePercentage: percentage, threshold: threshold, level: AttendanceRiskLevel.goodStanding);
    } else if (percentage >= threshold - 10) {
      // Configurable warning band. e.g. 65% - 75%
      return AttendanceRiskProfile(attendancePercentage: percentage, threshold: threshold, level: AttendanceRiskLevel.warning);
    } else {
      return AttendanceRiskProfile(attendancePercentage: percentage, threshold: threshold, level: AttendanceRiskLevel.critical);
    }
  }

  Color get color {
    switch (level) {
      case AttendanceRiskLevel.goodStanding: return DashboardColors.success;
      case AttendanceRiskLevel.warning: return DashboardColors.warning;
      case AttendanceRiskLevel.critical: return DashboardColors.error;
    }
  }

  String get label {
    switch (level) {
      case AttendanceRiskLevel.goodStanding: return 'Good Standing';
      case AttendanceRiskLevel.warning: return 'Warning';
      case AttendanceRiskLevel.critical: return 'Critical';
    }
  }
}

// --- Projections ---

class AttendanceProjection {
  final double currentPercentage;
  final double targetPercentage;
  final int totalClassesConducted;
  final int classesAttended;
  final int requiredConsecutiveClasses;
  final double projectedPercentageIfMissNext;

  const AttendanceProjection({
    required this.currentPercentage,
    required this.targetPercentage,
    required this.totalClassesConducted,
    required this.classesAttended,
    required this.requiredConsecutiveClasses,
    required this.projectedPercentageIfMissNext,
  });

  factory AttendanceProjection.calculate({
    required int totalClasses,
    required int attendedClasses,
    required double targetPercentage,
  }) {
    if (totalClasses == 0) {
      return AttendanceProjection(
        currentPercentage: 100,
        targetPercentage: targetPercentage,
        totalClassesConducted: 0,
        classesAttended: 0,
        requiredConsecutiveClasses: 0,
        projectedPercentageIfMissNext: 100,
      );
    }

    double current = (attendedClasses / totalClasses) * 100;
    
    // Formula for required consecutive classes (x):
    // (attended + x) / (total + x) = target / 100
    // 100 * (attended + x) = target * (total + x)
    // 100*attended + 100x = target*total + target*x
    // x(100 - target) = target*total - 100*attended
    // x = (target*total - 100*attended) / (100 - target)
    
    int requiredClasses = 0;
    if (current < targetPercentage && targetPercentage < 100) {
      double x = ((targetPercentage * totalClasses) - (100 * attendedClasses)) / (100 - targetPercentage);
      requiredClasses = x.ceil();
      if (requiredClasses < 0) requiredClasses = 0;
    }

    double ifMissNext = (attendedClasses / (totalClasses + 1)) * 100;

    return AttendanceProjection(
      currentPercentage: current,
      targetPercentage: targetPercentage,
      totalClassesConducted: totalClasses,
      classesAttended: attendedClasses,
      requiredConsecutiveClasses: requiredClasses,
      projectedPercentageIfMissNext: ifMissNext,
    );
  }
}

// --- Insights ---

enum InsightSeverity { positive, neutral, negative }

class AttendanceInsight {
  final String id;
  final String title;
  final String description;
  final InsightSeverity severity;
  final IconData icon;

  const AttendanceInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.icon,
  });
}

// --- Trends & Chart Data ---

class ChartDataPoint {
  final String label;
  final double value;
  final Color? color;

  const ChartDataPoint({
    required this.label,
    required this.value,
    this.color,
  });
}

// --- Reports ---

enum ReportType {
  daily,
  weekly,
  monthly,
  semester,
  department,
  faculty,
  student,
  section,
  subject,
  college
}

class AttendanceReport {
  final String id;
  final String title;
  final ReportType type;
  final DateTime generatedAt;
  final AppRole generatedBy;
  final Map<String, String> filtersApplied;
  final String summary;

  const AttendanceReport({
    required this.id,
    required this.title,
    required this.type,
    required this.generatedAt,
    required this.generatedBy,
    required this.filtersApplied,
    required this.summary,
  });
}
