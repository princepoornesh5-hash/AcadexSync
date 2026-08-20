import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/presentation/widgets/acadex_card.dart';
import '../../../domain/models/attendance_analytics_models.dart';

class SubjectAttendanceChart extends StatelessWidget {
  final List<SubjectAttendanceAnalytics> subjects;
  final String title;
  final ValueChanged<SubjectAttendanceAnalytics>? onSubjectSelected;

  const SubjectAttendanceChart({
    super.key,
    required this.subjects,
    this.title = 'Subject-Wise Attendance',
    this.onSubjectSelected,
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
              const Icon(LucideIcons.bookOpen, size: 18, color: AcadexColors.primary),
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
          if (subjects.isEmpty)
            SizedBox(
              height: 140,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.bookOpen,
                      size: 36,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No subject attendance records found',
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
                for (int index = 0; index < subjects.length; index++) ...[
                  if (index > 0) const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final item = subjects[index];
                      final barColor = _getBarColor(item.attendancePercentage);
                      final displayName = item.subjectName.isNotEmpty ? item.subjectName : item.subjectId;

                      return InkWell(
                        onTap: onSubjectSelected != null ? () => onSubjectSelected!(item) : null,
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
                                        Flexible(
                                          child: Text(
                                            displayName,
                                            style: AcadexTypography.body(
                                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                            ).copyWith(fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                                            borderRadius: AcadexRadius.borderRadiusSm,
                                            border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                                          ),
                                          child: Text(
                                            '${item.totalSessions} classes',
                                            style: AcadexTypography.caption(
                                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                            ).copyWith(fontSize: 10),
                                          ),
                                        ),
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
                                      if (onSubjectSelected != null) ...[
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
