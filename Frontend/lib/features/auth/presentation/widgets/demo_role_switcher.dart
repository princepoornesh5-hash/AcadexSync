import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';

class DemoRoleSwitcher extends StatelessWidget {
  final Function(String email, String password) onFillCredentials;

  const DemoRoleSwitcher({super.key, required this.onFillCredentials});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Development Fast Login",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildRoleButton("Super Admin", "superadmin.test@acadex.com", LucideIcons.shieldCheck),
            _buildRoleButton("College Admin", "admin.test@acadex.com", LucideIcons.building),
            _buildRoleButton("HOD", "hod.test@acadex.com", LucideIcons.bookOpen),
            _buildRoleButton("Faculty", "faculty.test@acadex.com", LucideIcons.userCheck),
            _buildRoleButton("Student", "student.test@acadex.com", LucideIcons.user),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleButton(String role, String email, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () => onFillCredentials(email, "acadex123"),
      icon: Icon(icon, size: 14, color: AppColors.primary),
      label: Text(role, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
      ),
    );
  }
}
