import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/domain/models/auth_state.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import 'faculty_certificate_dashboard.dart';
import 'student_certificate_dashboard.dart';

class CertificateDashboardRouter extends ConsumerWidget {
  const CertificateDashboardRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = authState.user.role;

    switch (role) {
      case AppRole.student:
        return const StudentCertificateDashboard();
      case AppRole.faculty:
      case AppRole.hod:
        return const FacultyCertificateDashboard();
      case AppRole.collegeAdmin:
      case AppRole.superAdmin:
        // HOD and Admin get faculty-level overview (they can see all dept certs)
        return const FacultyCertificateDashboard();
    }
  }
}
