import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'assigned_classes_screen.dart';
import 'student_attendance_portal_screen.dart';
import 'package:campus_management/features/analytics/presentation/screens/department_analytics_screen.dart';
import 'college_attendance_dashboard_screen.dart';
import 'super_admin_attendance_dashboard_screen.dart';

class AttendanceDashboardRouter extends ConsumerWidget {
  const AttendanceDashboardRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is AuthAuthenticated) {
      if (authState.user.role == AppRole.student) {
        return const StudentAttendancePortalScreen();
      } else if (authState.user.role == AppRole.hod) {
        return const DepartmentAnalyticsScreen();
      } else if (authState.user.role == AppRole.collegeAdmin) {
        return const CollegeAttendanceDashboardScreen();
      } else if (authState.user.role == AppRole.superAdmin) {
        return const SuperAdminAttendanceDashboardScreen();
      } else {
        // Faculty and others
        return const AssignedClassesScreen();
      }
    }

    return const Center(child: CircularProgressIndicator());
  }
}
