import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import 'faculty_assignments_list_screen.dart';
import 'student_assignments_screen.dart';

class AssignmentsScreen extends ConsumerWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is AuthAuthenticated && authState.user.role == AppRole.student) {
      return const StudentAssignmentsScreen();
    }

    return const FacultyAssignmentsListScreen();
  }
}
