import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/presentation/widgets/acadex_card.dart';
import '../../../domain/models/attendance_analytics_models.dart';

class SectionAttendanceChart extends StatelessWidget {
  final List<SectionAttendanceAnalytics> sections;
  final String title;
  final ValueChanged<SectionAttendanceAnalytics>? onSectionSelected;

  const SectionAttendanceChart({
    super.key,
    required this.sections,
    this.title = 'Section-Wise Attendance Comparison',
    this.onSectionSelected,
  });

  Color _getBarColor(double pct) {
    if (pct >= 85.0) return AcadexColors.success;
    if (pct >= AttendanceAnalyticsConstants.lowAttendanceThreshold) return AcadexColors.warning;
    return AcadexColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AcadexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.layoutGrid, size: 18, color: AcadexColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AcadexTypography.heading2(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sections.isEmpty)
            SizedBox(
              height: 140,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.layoutGrid,
                      size: 36,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No section attendance records available',
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                for (int index = 0; index < sections.length; index++) ...[
                  if (index > 0) const SizedBox(height: 14),
                  Builder(
                    builder: (context) {
                      final item = sections[index];
                      final barColor = _getBarColor(item.attendancePercentage);
                      final displayName = item.sectionName.isNotEmpty ? item.sectionName : item.sectionId;

                      return InkWell(
                        onTap: onSectionSelected != null ? () => onSectionSelected!(item) : null,
                        borderRadius: AcadexRadius.borderRadiusSm,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          displayName,
                                          style: AcadexTypography.body(
                                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                          ).copyWith(fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                                            borderRadius: AcadexRadius.borderRadiusSm,
                                          ),
                                          child: Text(
                                            '${item.totalStudents} students',
                                            style: AcadexTypography.caption(
                                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                            ).copyWith(fontSize: 10),
                                          ),
                                        ),
                                        if (item.lowAttendanceStudentCount > 0) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AcadexColors.error.withValues(alpha: 0.12),
                                              borderRadius: AcadexRadius.borderRadiusSm,
                                              border: Border.all(color: AcadexColors.error.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              '${item.lowAttendanceStudentCount} below 75%',
                                              style: AcadexTypography.caption(color: AcadexColors.error).copyWith(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${item.attendancePercentage.toStringAsFixed(1)}%',
                                        style: AcadexTypography.body(color: barColor).copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (onSectionSelected != null) ...[
                                        const SizedBox(width: 6),
                                        Icon(
                                          LucideIcons.chevronRight,
                                          size: 14,
                                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: AcadexRadius.borderRadiusSm,
                                child: LinearProgressIndicator(
                                  value: (item.attendancePercentage / 100).clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
