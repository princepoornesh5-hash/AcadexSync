import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_motion.dart';

/// Reusable, compact, mobile-first academic context card (Prompt 3 Phase 3).
///
/// Clearly answers:
/// 1. Where am I?
/// 2. What academic context am I viewing?
/// 3. How can I change context?
///
/// Implements progressive disclosure:
/// - Compact dot-separated breadcrumbs instead of multiple giant cards
/// - Constraint-driven adaptive layout (stacks vertically on narrow screens, horizontal on wide screens)
/// - Semantic ACADEX color palette and typography
class AcadexAcademicContextCard extends StatelessWidget {
  final String? departmentName;
  final String? departmentCode;
  final String? programName;
  final String? programCode;
  final String? semesterName;
  final String? sectionName;
  final String? academicYearName;
  final String? cohort;
  final String? title;
  final VoidCallback? onChangeContext;
  final Widget? trailing;
  final bool isFlat;

  const AcadexAcademicContextCard({
    super.key,
    this.departmentName,
    this.departmentCode,
    this.programName,
    this.programCode,
    this.semesterName,
    this.sectionName,
    this.academicYearName,
    this.cohort,
    this.title,
    this.onChangeContext,
    this.trailing,
    this.isFlat = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Build breadcrumb segments cleanly
    final segments = <String>[];
    if (departmentCode != null && departmentCode!.isNotEmpty) {
      segments.add(departmentCode!);
    } else if (departmentName != null && departmentName!.isNotEmpty) {
      segments.add(departmentName!);
    }

    if (semesterName != null && semesterName!.isNotEmpty) {
      segments.add(semesterName!);
    }

    if (sectionName != null && sectionName!.isNotEmpty) {
      segments.add(sectionName!.toLowerCase().startsWith('sec') ? sectionName! : 'Section $sectionName');
    }

    if (academicYearName != null && academicYearName!.isNotEmpty) {
      segments.add(academicYearName!);
    } else if (cohort != null && cohort!.isNotEmpty) {
      segments.add('Cohort $cohort');
    }

    final breadcrumbsText = segments.join(' · ');
    final primaryName = programName ?? departmentName ?? 'All Departments';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 440;

        return AcadexCard(
          isFlat: isFlat,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Eyebrow row with context label & change action
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AcadexColors.primary.withValues(alpha: 0.2)
                                : AcadexColors.primaryLight,
                            borderRadius: AcadexRadius.borderRadiusSm,
                          ),
                          child: const Icon(
                            LucideIcons.graduationCap,
                            size: 14,
                            color: AcadexColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (title ?? 'Academic Context').toUpperCase(),
                            style: AcadexTypography.eyebrow(
                              color: isDark ? AcadexColors.primaryMuted : AcadexColors.primary,
                            ).copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onChangeContext != null)
                          _buildChangeButton(context, isDark)
                        else if (trailing != null)
                          trailing!,
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Primary context name
                    Text(
                      primaryName,
                      style: AcadexTypography.title(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (breadcrumbsText.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        breadcrumbsText,
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ).copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AcadexColors.primary.withValues(alpha: 0.2)
                            : AcadexColors.primaryLight,
                        borderRadius: AcadexRadius.borderRadiusSm,
                      ),
                      child: const Icon(
                        LucideIcons.graduationCap,
                        size: 18,
                        color: AcadexColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                (title ?? 'Academic Context').toUpperCase(),
                                style: AcadexTypography.eyebrow(
                                  color: isDark ? AcadexColors.primaryMuted : AcadexColors.primary,
                                ).copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              if (departmentCode != null && departmentCode!.isNotEmpty) ...[
                                Text(
                                  ' • $departmentCode',
                                  style: AcadexTypography.caption(
                                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                  ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            primaryName,
                            style: AcadexTypography.title(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ).copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (breadcrumbsText.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              breadcrumbsText,
                              style: AcadexTypography.caption(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ).copyWith(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onChangeContext != null) ...[
                      const SizedBox(width: 12),
                      _buildChangeButton(context, isDark),
                    ] else if (trailing != null) ...[
                      const SizedBox(width: 12),
                      trailing!,
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildChangeButton(BuildContext context, bool isDark) {
    return AcadexPressable(
      onTap: onChangeContext,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32, minWidth: 44),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? AcadexColors.primary.withValues(alpha: 0.15) : AcadexColors.primaryLight,
          borderRadius: AcadexRadius.borderRadiusSm,
          border: Border.all(
            color: AcadexColors.primary.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.slidersHorizontal, size: 12, color: AcadexColors.primary),
            const SizedBox(width: 5),
            Text(
              'Change',
              style: AcadexTypography.button.copyWith(
                color: AcadexColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
