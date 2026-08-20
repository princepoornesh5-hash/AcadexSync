import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../domain/models/attendance_analytics_models.dart';

class LowAttendanceList extends StatelessWidget {
  final List<StudentAttendanceAnalytics> students;
  final String title;

  const LowAttendanceList({
    super.key,
    required this.students,
    this.title = 'Students Below Mandatory Threshold (< 75%)',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Strict regulatory threshold filter (< 75.0%)
    final lowStudents = students.where((s) => AttendanceAnalyticsConstants.isLowAttendance(s.attendancePercentage)).toList();
    // Sort lowest attendance first
    lowStudents.sort((a, b) => a.attendancePercentage.compareTo(b.attendancePercentage));

    return AcadexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertTriangle, size: 18, color: AcadexColors.error),
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
              ),
              if (lowStudents.isNotEmpty) ...[
                const SizedBox(width: 8),
                AcadexBadge(
                  label: '${lowStudents.length} Students',
                  variant: AcadexBadgeVariant.danger,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (lowStudents.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AcadexColors.success.withValues(alpha: isDark ? 0.12 : 0.06),
                borderRadius: AcadexRadius.borderRadiusMd,
                border: Border.all(color: AcadexColors.success.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.checkCircle2, color: AcadexColors.success, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Students in Critical Shortage',
                          style: AcadexTypography.body(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'All students currently meet or exceed the 75% regulatory requirement.',
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lowStudents.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final student = lowStudents[index];
                final displayName = student.studentName.isNotEmpty ? student.studentName : student.studentId;
                final rollNumber = student.rollNumber.isNotEmpty ? student.rollNumber : 'Roll: --';

                return Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AcadexColors.error.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: AcadexTypography.caption(color: AcadexColors.error).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: AcadexTypography.body(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$rollNumber • Section: ${student.sectionId.isNotEmpty ? student.sectionId : '--'} • ${student.presentCount}/${student.totalSessions} present',
                            style: AcadexTypography.caption(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${student.attendancePercentage.toStringAsFixed(1)}%',
                          style: AcadexTypography.body(color: AcadexColors.error).copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const AcadexBadge(
                          label: 'Shortage',
                          variant: AcadexBadgeVariant.danger,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
