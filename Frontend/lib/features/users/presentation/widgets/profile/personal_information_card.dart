import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/user_profile_model.dart';
import 'edit_profile_dialog.dart';

class PersonalInformationCard extends StatelessWidget {
  final UserProfileModel profile;

  const PersonalInformationCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Information',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: DashboardColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.edit3, size: 18),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => EditProfileDialog(profile: profile),
                  );
                },
                tooltip: 'Edit Profile',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Full Name', profile.name, LucideIcons.user),
          const Divider(height: 24),
          _buildDetailRow('Email Address', profile.email, LucideIcons.mail, readOnly: true),
          const Divider(height: 24),
          _buildDetailRow(
            'Phone Number',
            profile.phone.isNotEmpty ? profile.phone : 'Not Added',
            LucideIcons.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {bool readOnly = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: DashboardColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: DashboardColors.textSecondary,
                    ),
                  ),
                  if (readOnly) ...[
                    const SizedBox(width: 6),
                    const Icon(LucideIcons.lock, size: 10, color: DashboardColors.textSecondary),
                  ]
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: DashboardColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
