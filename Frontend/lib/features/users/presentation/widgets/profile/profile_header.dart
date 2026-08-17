import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../auth/domain/models/role_enum.dart';
import '../../../domain/models/user_profile_model.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfileModel profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DashboardColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: DashboardColors.primary.withValues(alpha: 0.2),
            foregroundImage: profile.profilePictureUrl != null
                ? NetworkImage(profile.profilePictureUrl!)
                : null,
            child: Text(
              profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: DashboardColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.name,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          _buildRoleBadge(profile.role),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: DashboardColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              profile.status.name.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: DashboardColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(AppRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: DashboardColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.displayName.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: DashboardColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
