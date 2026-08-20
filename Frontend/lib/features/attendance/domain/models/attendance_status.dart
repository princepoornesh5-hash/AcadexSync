import 'package:flutter/material.dart';

enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
  medicalLeave, // Future support
  onDuty,       // Future support
  holiday;      // Future support

  String get displayName {
    switch (this) {
      case AttendanceStatus.present: return 'Present';
      case AttendanceStatus.absent: return 'Absent';
      case AttendanceStatus.late: return 'Late';
      case AttendanceStatus.excused: return 'Excused';
      case AttendanceStatus.medicalLeave: return 'Medical Leave';
      case AttendanceStatus.onDuty: return 'On Duty';
      case AttendanceStatus.holiday: return 'Holiday';
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.present: return const Color(0xFF22C55E); // Success
      case AttendanceStatus.absent: return const Color(0xFFEF4444);  // Error
      case AttendanceStatus.late: return const Color(0xFFF59E0B);    // Warning
      case AttendanceStatus.excused: return const Color(0xFF6366F1); // Indigo
      case AttendanceStatus.medicalLeave: return const Color(0xFF3B82F6); // Blue
      case AttendanceStatus.onDuty: return const Color(0xFF8B5CF6);  // Purple
      case AttendanceStatus.holiday: return const Color(0xFF9CA3AF); // Gray
    }
  }
}
