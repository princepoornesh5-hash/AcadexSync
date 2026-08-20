import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../domain/models/attendance_analytics_models.dart';

class AttendanceOverviewCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double percentage;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final int? unmarkedCount;
  final int totalSessions;
  final int? totalStudents;
  final bool isLowAttendance;
  final VoidCallback? onAction;

  const AttendanceOverviewCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.percentage,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.excusedCount,
    this.unmarkedCount,
    required this.totalSessions,
    this.totalStudents,
    required this.isLowAttendance,
    this.onAction,
  });

  Color _getPercentageColor() {
    if (percentage >= 85.0) return AcadexColors.success;
    if (percentage >= AttendanceAnalyticsConstants.lowAttendanceThreshold) return AcadexColors.warning;
    return AcadexColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pctColor = _getPercentageColor();

    return AcadexCard(
      child: LayoutBuilder(builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 450;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AcadexTypography.heading2(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AcadexBadge(
                  label: isLowAttendance ? 'Low Attendance (< 75%)' : 'Good Standing',
                  variant: isLowAttendance ? AcadexBadgeVariant.danger : AcadexBadgeVariant.success,
                  icon: isLowAttendance ? LucideIcons.alertTriangle : LucideIcons.checkCircle2,
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (isNarrow)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: pctColor.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(color: pctColor.withValues(alpha: 0.25)),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Attendance',
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ).copyWith(fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              percentage.toStringAsFixed(1),
                              style: AcadexTypography.heading1(color: pctColor).copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '%',
                              style: AcadexTypography.heading3(color: pctColor).copyWith(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sessions',
                              style: AcadexTypography.caption(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ).copyWith(fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$totalSessions',
                              style: AcadexTypography.heading2(
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ).copyWith(fontSize: 18),
                            ),
                          ],
                        ),
                        if (totalStudents != null) ...[
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Students',
                                style: AcadexTypography.caption(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ).copyWith(fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$totalStudents',
                                style: AcadexTypography.heading2(
                                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                ).copyWith(fontSize: 18),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: pctColor.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(color: pctColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Attendance',
                            style: AcadexTypography.caption(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ).copyWith(fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                percentage.toStringAsFixed(1),
                                style: AcadexTypography.heading1(color: pctColor).copyWith(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '%',
                                style: AcadexTypography.heading3(color: pctColor).copyWith(
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sessions',
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ).copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalSessions',
                          style: AcadexTypography.heading2(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ).copyWith(fontSize: 22),
                        ),
                      ],
                    ),
                    if (totalStudents != null) ...[
                      const SizedBox(width: 16),
                      Container(
                        height: 40,
                        width: 1,
                        color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Students',
                            style: AcadexTypography.caption(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ).copyWith(fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalStudents',
                            style: AcadexTypography.heading2(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ).copyWith(fontSize: 22),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 14),

            // 4 Status Metrics Breakdown Grid
            GridView.count(
              crossAxisCount: isNarrow ? 2 : 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: isNarrow ? 1.9 : 2.4,
              children: [
                _buildStatPill(
                  label: 'Present',
                  count: presentCount,
                  color: AcadexColors.success,
                  icon: LucideIcons.check,
                  isDark: isDark,
                  isNarrow: isNarrow,
                ),
                _buildStatPill(
                  label: 'Absent',
                  count: absentCount,
                  color: AcadexColors.error,
                  icon: LucideIcons.x,
                  isDark: isDark,
                  isNarrow: isNarrow,
                ),
                _buildStatPill(
                  label: 'Late',
                  count: lateCount,
                  color: AcadexColors.warning,
                  icon: LucideIcons.clock,
                  isDark: isDark,
                  isNarrow: isNarrow,
                ),
                _buildStatPill(
                  label: 'Excused',
                  count: excusedCount,
                  color: const Color(0xFF6366F1), // Indigo
                  icon: LucideIcons.shieldCheck,
                  isDark: isDark,
                  isNarrow: isNarrow,
                ),
              ],
            ),

            // Low Attendance Notice Alert Banner
            if (isLowAttendance) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AcadexColors.error.withValues(alpha: 0.1),
                  borderRadius: AcadexRadius.borderRadiusSm,
                  border: Border.all(color: AcadexColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, color: AcadexColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attendance is below the mandatory 75% minimum requirement.',
                        style: AcadexTypography.caption(color: AcadexColors.error).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildStatPill({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required bool isDark,
    required bool isNarrow,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
        borderRadius: AcadexRadius.borderRadiusSm,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: isNarrow ? 12 : 14, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ).copyWith(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$count',
                  style: AcadexTypography.body(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: isNarrow ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
