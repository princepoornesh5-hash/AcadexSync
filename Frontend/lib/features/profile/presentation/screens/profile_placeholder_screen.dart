import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfilePlaceholderScreen extends ConsumerWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    
    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: DashboardColors.textPrimary)),
        backgroundColor: DashboardColors.surface,
        iconTheme: const IconThemeData(color: DashboardColors.textPrimary),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: DashboardColors.primaryLight,
              ),
              child: const Icon(Icons.person, size: 50, color: DashboardColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              user?.name ?? 'User Name',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? 'user@example.com',
              style: const TextStyle(fontSize: 16, color: DashboardColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: DashboardColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user?.role.displayName ?? 'Role',
                style: const TextStyle(color: DashboardColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Profile Module Coming Soon",
              style: TextStyle(color: DashboardColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
