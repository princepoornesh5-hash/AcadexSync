import 'package:flutter/material.dart';
import 'student_attendance_portal_screen.dart';

/// Dedicated Student Attendance Calendar screen
class StudentAttendanceCalendarScreen extends StatelessWidget {
  const StudentAttendanceCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudentAttendancePortalScreen(initialTab: 2);
  }
}
