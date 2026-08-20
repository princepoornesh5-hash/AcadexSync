import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../../core/presentation/widgets/acadex_button.dart';
import '../../../domain/models/attendance_analytics_models.dart';
import '../../../domain/services/attendance_report_exporter.dart';

class LowAttendanceActionPanel extends StatelessWidget {
  final List<StudentAttendanceAnalytics> students;
  final String title;
  final ValueChanged<StudentAttendanceAnalytics>? onStudentSelected;
  final ValueChanged<String>? onExportCsv;

  const LowAttendanceActionPanel({
    super.key,
    required this.students,
    this.title = 'Low Attendance Action Center',
    this.onStudentSelected,
    this.onExportCsv,
  });

  void _handleExport(BuildContext context) {
    final lowStudents = students
        .where((s) => AttendanceAnalyticsConstants.isLowAttendance(s.attendancePercentage))
        .toList();
    final csv = AttendanceReportExporter.generateLowAttendanceReportCsv(
      lowAttendanceStudents: lowStudents,
      scopeTitle: title,
    );
    if (onExportCsv != null) {
      onExportCsv!(csv);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${lowStudents.length} shortage records to CSV'),
          backgroundColor: AcadexColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lowStudents = students
        .where((s) => AttendanceAnalyticsConstants.isLowAttendance(s.attendancePercentage))
        .toList()
      ..sort((a, b) => a.attendancePercentage.compareTo(b.attendancePercentage));

    return AcadexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertOctagon, size: 20, color: AcadexColors.error),
                    const SizedBox(width: 10),
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
                          Text(
                            'Students requiring urgent attendance intervention (< 75%)',
                            style: AcadexTypography.caption(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (lowStudents.isNotEmpty) ...[
                    AcadexBadge(
                      label: '${lowStudents.length} Critical',
                      variant: AcadexBadgeVariant.danger,
                    ),
                    const SizedBox(width: 8),
                    AcadexButton(
                      label: 'Export CSV',
                      icon: LucideIcons.download,
                      variant: AcadexButtonVariant.secondary,
                      size: AcadexButtonSize.sm,
                      onPressed: () => _handleExport(context),
                    ),
                  ],
                ],
              ),
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
                  const Icon(LucideIcons.shieldCheck, color: AcadexColors.success, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Students Compliant',
                          style: AcadexTypography.body(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'No students are currently in critical shortage below the 75% requirement.',
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
            Column(
              children: [
                for (int index = 0; index < lowStudents.length; index++) ...[
                  if (index > 0) const Divider(height: 20),
                  Builder(
                    builder: (context) {
                      final student = lowStudents[index];
                      final displayName = student.studentName.isNotEmpty ? student.studentName : student.studentId;
                      final rollNumber = student.rollNumber.isNotEmpty ? student.rollNumber : 'Roll: --';
                      final recoveryNeeded = student.recoverySessionsNeeded;

                      return InkWell(
                        onTap: onStudentSelected != null ? () => onStudentSelected!(student) : null,
                        borderRadius: AcadexRadius.borderRadiusSm,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Priority Badge
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AcadexColors.error.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '#${index + 1}',
                                    style: AcadexTypography.caption(color: AcadexColors.error).copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Student Info & Recovery Projection
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            displayName,
                                            style: AcadexTypography.body(
                                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                            ).copyWith(fontWeight: FontWeight.w700),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '($rollNumber)',
                                          style: AcadexTypography.caption(
                                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        if (student.sectionId.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                                              borderRadius: AcadexRadius.borderRadiusSm,
                                            ),
                                            child: Text(
                                              'Sec: ${student.sectionId}',
                                              style: AcadexTypography.caption(
                                                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                                              ).copyWith(fontSize: 10),
                                            ),
                                          ),
                                        // Recovery Projection Chip
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AcadexColors.warning.withValues(alpha: 0.15),
                                            borderRadius: AcadexRadius.borderRadiusSm,
                                            border: Border.all(color: AcadexColors.warning.withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(LucideIcons.target, size: 10, color: AcadexColors.warning),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Needs $recoveryNeeded consecutive classes for 75%',
                                                style: AcadexTypography.caption(color: AcadexColors.warning).copyWith(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Percentage & Action
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
                                  Text(
                                    '${student.presentCount}/${student.totalSessions} present',
                                    style: AcadexTypography.caption(
                                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                    ).copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                              if (onStudentSelected != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  LucideIcons.chevronRight,
                                  size: 16,
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ),
                              ],
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
