import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/search_models.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';

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

  AcadexBadgeVariant _getBadgeVariantForType(SearchResultType type) {
    switch (type) {
      case SearchResultType.student:
        return AcadexBadgeVariant.info;
      case SearchResultType.faculty:
      case SearchResultType.hod:
        return AcadexBadgeVariant.purple;
      case SearchResultType.department:
        return AcadexBadgeVariant.warning;
      case SearchResultType.subject:
      case SearchResultType.course:
        return AcadexBadgeVariant.teal;
      default:
        return AcadexBadgeVariant.primary;
    }
  }

  String _getLabelForType(SearchResultType type) {
    switch (type) {
      case SearchResultType.collegeAdmin:
        return "College Admin";
      case SearchResultType.academicYear:
        return "Academic Year";
      default:
        final text = type.toString().split('.').last;
        return text[0].toUpperCase() + text.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeVariant = _getBadgeVariantForType(result.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AcadexRadius.borderRadiusLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AcadexRadius.borderRadiusLg,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.primaryHover.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                    borderRadius: AcadexRadius.borderRadiusMd,
                  ),
                  child: Icon(
                    _getIconForType(result.type),
                    color: isDark ? AcadexColors.primaryMuted : AcadexColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.title,
                        style: AcadexTypography.body(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.subtitle,
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AcadexBadge(
                  label: _getLabelForType(result.type),
                  variant: badgeVariant,
                ),
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.chevronRight,
                  color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
