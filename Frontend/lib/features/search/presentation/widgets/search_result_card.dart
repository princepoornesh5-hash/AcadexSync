import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/search_models.dart';

class SearchResultCard extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.result,
    required this.onTap,
  });

  IconData _getIconForType(SearchResultType type) {
    switch (type) {
      case SearchResultType.student:
        return LucideIcons.user;
      case SearchResultType.faculty:
      case SearchResultType.hod:
      case SearchResultType.collegeAdmin:
        return LucideIcons.briefcase;
      case SearchResultType.college:
        return LucideIcons.building2;
      case SearchResultType.department:
        return LucideIcons.building;
      case SearchResultType.course:
      case SearchResultType.subject:
        return LucideIcons.bookOpen;
      case SearchResultType.section:
        return LucideIcons.users;
      case SearchResultType.academicYear:
      case SearchResultType.semester:
        return LucideIcons.calendar;
      case SearchResultType.attendance:
        return LucideIcons.clipboardCheck;
    }
  }

  Color _getColorForType(SearchResultType type) {
    switch (type) {
      case SearchResultType.student:
        return Colors.blue;
      case SearchResultType.faculty:
        return Colors.indigo;
      case SearchResultType.department:
        return Colors.orange;
      case SearchResultType.subject:
        return Colors.green;
      default:
        return DashboardColors.primary;
    }
  }

  String _getLabelForType(SearchResultType type) {
    switch (type) {
      case SearchResultType.collegeAdmin:
        return "College Admin";
      case SearchResultType.academicYear:
        return "Academic Year";
      default:
        // simple capitalization for others
        final text = type.toString().split('.').last;
        return text[0].toUpperCase() + text.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForType(result.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairlineDark),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForType(result.type),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDarkElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.hairlineDark),
                ),
                child: Text(
                  _getLabelForType(result.type),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(LucideIcons.chevronRight, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
