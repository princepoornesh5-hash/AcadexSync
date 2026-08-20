import 'package:flutter/material.dart';
import 'student_attendance_portal_screen.dart';

/// Dedicated Student Attendance Dashboard screen
class StudentAttendanceDashboardScreen extends StatelessWidget {
  const StudentAttendanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudentAttendancePortalScreen(initialTab: 0);
  }
}
