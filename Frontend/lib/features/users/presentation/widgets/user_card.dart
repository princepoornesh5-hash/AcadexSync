import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/user_profile_model.dart';
import 'role_badge.dart';
import 'status_chip.dart';

class UserCard extends StatelessWidget {
  final UserProfileModel user;
  final VoidCallback onTap;

  const UserCard({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DashboardColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DashboardColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: DashboardColors.primaryLight,
                  child: Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.inter(color: DashboardColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: GoogleFonts.inter(fontSize: 13, color: DashboardColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RoleBadge(role: user.role),
                StatusChip(status: user.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(LucideIcons.building, size: 14, color: DashboardColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    user.departmentId != null ? 'Dept: ${user.departmentId}' : 'No Department',
                    style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 16, color: DashboardColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
