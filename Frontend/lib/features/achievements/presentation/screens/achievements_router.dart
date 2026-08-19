import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'achievement_admin_screen.dart';
import 'student_achievements_screen.dart';

/// Role-aware router screen for `/achievements`.
/// Dispatches students to their personal portfolio dashboard and reviewers
/// (Faculty, HOD, College Admin) to the administrative verification screen.
class AchievementsRouter extends ConsumerWidget {
  const AchievementsRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return const StudentAchievementsScreen();
    }

    final role = authState.user.role;

    switch (role) {
      case AppRole.student:
        return const StudentAchievementsScreen();
      case AppRole.faculty:
      case AppRole.hod:
      case AppRole.collegeAdmin:
      case AppRole.superAdmin:
        return const AchievementAdminScreen();
    }
  }
}
