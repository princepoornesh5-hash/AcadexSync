import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../auth/domain/models/role_enum.dart';
import '../../../domain/models/user_profile_model.dart';

class AcademicInformationCard extends StatelessWidget {
  final UserProfileModel profile;
  final String collegeName;
  final String departmentName;
  final String courseName;
  final String semesterName;
  final String sectionName;
  final String rollNumber;
  final String employeeId;

  const AcademicInformationCard({
    super.key,
    required this.profile,
    required this.collegeName,
    required this.departmentName,
    required this.courseName,
    required this.semesterName,
    required this.sectionName,
    required this.rollNumber,
    required this.employeeId,
  });

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
          Text(
            'Academic Details',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('College / Institution', collegeName, LucideIcons.school),
          if (profile.role != AppRole.superAdmin) ...[
            const Divider(height: 24),
            _buildDetailRow('Department', departmentName, LucideIcons.building),
          ],
          if (profile.role == AppRole.student) ...[
            const Divider(height: 24),
            _buildDetailRow('Course', courseName, LucideIcons.book),
            const Divider(height: 24),
            _buildDetailRow('Semester', semesterName, LucideIcons.calendar),
            const Divider(height: 24),
            _buildDetailRow('Section', sectionName, LucideIcons.users),
            const Divider(height: 24),
            _buildDetailRow('Student ID / Roll Number', rollNumber, LucideIcons.hash),
          ],
          if (profile.role == AppRole.faculty || profile.role == AppRole.hod) ...[
            const Divider(height: 24),
            _buildDetailRow('Employee / Faculty ID', employeeId, LucideIcons.creditCard),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: DashboardColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: DashboardColors.textSecondary,
                ),
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
