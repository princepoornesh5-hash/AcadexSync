import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsPlaceholderScreen extends ConsumerWidget {
  const SettingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: DashboardColors.textPrimary)),
        backgroundColor: DashboardColors.surface,
        iconTheme: const IconThemeData(color: DashboardColors.textPrimary),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsTile(Icons.color_lens, 'Theme', 'System Default'),
          _buildSettingsTile(Icons.language, 'Language', 'English'),
          _buildSettingsTile(Icons.notifications, 'Notifications', 'Enabled'),
          _buildSettingsTile(Icons.privacy_tip, 'Privacy', 'Manage Data'),
          _buildSettingsTile(Icons.security, 'Security', 'Change Password'),
          _buildSettingsTile(Icons.info, 'About', 'Version 1.0.0'),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.logout, color: DashboardColors.error),
            title: const Text('Logout', style: TextStyle(color: DashboardColors.error, fontWeight: FontWeight.bold)),
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: DashboardColors.surface,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DashboardColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: DashboardColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(color: DashboardColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right, color: DashboardColors.textMuted),
        onTap: () {},
      ),
    );
  }
}
