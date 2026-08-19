import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'student_official_certificates_screen.dart';
import 'official_certificates_admin_dashboard_screen.dart';

class OfficialCertificatesRouter extends ConsumerWidget {
  const OfficialCertificatesRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = authState.user.role;
    if (role == AppRole.student) {
      return const StudentOfficialCertificatesScreen();
    } else {
      return const OfficialCertificatesAdminDashboardScreen();
    }
  }
}
