import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/user_profile_model.dart';
import 'role_badge.dart';
import 'status_chip.dart';

class UserHeader extends StatelessWidget {
  final UserProfileModel user;

  const UserHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DashboardColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardColors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: DashboardColors.primaryLight,
            child: Text(
              user.name.substring(0, 1).toUpperCase(),
              style: GoogleFonts.inter(fontSize: 32, color: DashboardColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: GoogleFonts.inter(fontSize: 15, color: DashboardColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RoleBadge(role: user.role),
              const SizedBox(width: 12),
              StatusChip(status: user.status),
            ],
          ),
        ],
      ),
    );
  }
}
