import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/core/presentation/widgets/acadex_badge.dart';
import 'package:campus_management/core/presentation/widgets/acadex_button.dart';
import 'package:campus_management/core/presentation/widgets/acadex_card.dart';
import 'package:campus_management/core/presentation/widgets/acadex_page_header.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_alert.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_alert_providers.dart';
import 'package:campus_management/features/attendance/presentation/screens/student_attendance_detail_screen.dart';
import 'package:campus_management/features/attendance/presentation/screens/subject_attendance_detail_screen.dart';
import 'package:campus_management/features/attendance/presentation/screens/section_attendance_detail_screen.dart';

/// Full screen displaying in-depth alert context, mathematical recovery projections, and actions
class AttendanceAlertDetailScreen extends ConsumerWidget {
  final AttendanceAlert alert;

  const AttendanceAlertDetailScreen({
    super.key,
    required this.alert,
  });

  Color _getSeverityColor() {
    switch (alert.severity) {
      case AttendanceAlertSeverity.critical:
        return AcadexColors.error;
      case AttendanceAlertSeverity.warning:
        return AcadexColors.warning;
      case AttendanceAlertSeverity.info:
        return AcadexColors.info;
    }
  }

  IconData _getTypeIcon() {
    switch (alert.alertType) {
      case AttendanceAlertType.lowAttendance:
        return LucideIcons.alertOctagon;
      case AttendanceAlertType.attendanceDrop:
        return LucideIcons.trendingDown;
      case AttendanceAlertType.repeatedAbsence:
        return LucideIcons.userX;
      case AttendanceAlertType.unmarkedAttendance:
        return LucideIcons.calendarX;
      case AttendanceAlertType.attendanceRecovery:
        return LucideIcons.checkCircle2;
      case AttendanceAlertType.sessionCorrection:
        return LucideIcons.fileEdit;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);
    final severityColor = _getSeverityColor();
    final typeIcon = _getTypeIcon();

    // Watch updated single alert if available in provider
    final updatedAlertAsync = ref.watch(attendanceAlertDetailProvider(alert.id));
    final effectiveAlert = updatedAlertAsync.value ?? alert;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Bar
                AcadexPageHeader(
                  title: 'Attendance Alert Details',
                  subtitle: 'Early-warning diagnosis, severity classification, and remediation.',
                  onBack: () => Navigator.of(context).canPop()
                      ? Navigator.of(context).pop()
                      : context.go('/attendance/alerts'),
                ),

                const SizedBox(height: 16),

                // Severity & Status Alert Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(color: severityColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: severityColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(typeIcon, size: 22, color: severityColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    effectiveAlert.title,
                                    style: AcadexTypography.heading2(
                                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                    ),
                                  ),
                                ),
                                Wrap(
                                  spacing: 4,
                                  children: [
                                    AcadexBadge(
                                      label: effectiveAlert.severity == AttendanceAlertSeverity.critical
                                          ? 'Critical'
                                          : (effectiveAlert.severity == AttendanceAlertSeverity.warning ? 'Warning' : 'Info'),
                                      variant: effectiveAlert.severity == AttendanceAlertSeverity.critical
                                          ? AcadexBadgeVariant.danger
                                          : (effectiveAlert.severity == AttendanceAlertSeverity.warning ? AcadexBadgeVariant.warning : AcadexBadgeVariant.info),
                                    ),
                                    if (effectiveAlert.status == AttendanceAlertStatus.resolved)
                                      const AcadexBadge(label: 'Resolved', variant: AcadexBadgeVariant.success)
                                    else if (effectiveAlert.status == AttendanceAlertStatus.acknowledged)
                                      const AcadexBadge(label: 'Acknowledged', variant: AcadexBadgeVariant.neutral),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              effectiveAlert.message,
                              style: AcadexTypography.body(
                                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Metrics Breakdown Card
                AcadexCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alert Metrics & Key Indicators',
                        style: AcadexTypography.heading2(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          if (effectiveAlert.attendancePercentage != null) ...[
                            Expanded(
                              child: _buildMetricTile(
                                title: 'Current Attendance',
                                value: '${effectiveAlert.attendancePercentage!.toStringAsFixed(1)}%',
                                color: severityColor,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Threshold',
                              value: '${effectiveAlert.threshold.toStringAsFixed(0)}%',
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              isDark: isDark,
                            ),
                          ),
                          if (effectiveAlert.dropPercentage != null) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricTile(
                                title: 'Percentage Drop',
                                value: '-${effectiveAlert.dropPercentage!.toStringAsFixed(1)}%',
                                color: AcadexColors.error,
                                isDark: isDark,
                              ),
                            ),
                          ],
                          if (effectiveAlert.consecutiveAbsences != null) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricTile(
                                title: 'Missed Sessions',
                                value: '${effectiveAlert.consecutiveAbsences}',
                                color: AcadexColors.error,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Mathematical Recovery Projection Banner (if applicable)
                if (effectiveAlert.recoverySessionsNeeded != null && effectiveAlert.recoverySessionsNeeded! > 0) ...[
                  const SizedBox(height: 16),
                  AcadexCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.target, color: AcadexColors.warning, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Attendance Recovery Projection',
                              style: AcadexTypography.heading2(
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Student requires ${effectiveAlert.recoverySessionsNeeded} consecutive attended class sessions (with 0 absences) to reach the mandatory ${effectiveAlert.threshold.toStringAsFixed(0)}% attendance threshold.',
                          style: AcadexTypography.body(
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Calculated via institutional formula: ⌈(75 × Total - 100 × Present) / 25⌉',
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Entity Context Details Card
                AcadexCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Academic Scope & Identity Context',
                        style: AcadexTypography.heading2(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (effectiveAlert.studentName != null && effectiveAlert.studentName!.isNotEmpty)
                        _buildDetailRow('Student Name', effectiveAlert.studentName!, isDark),
                      if (effectiveAlert.rollNumber != null && effectiveAlert.rollNumber!.isNotEmpty)
                        _buildDetailRow('Roll Number', effectiveAlert.rollNumber!, isDark),
                      if (effectiveAlert.subjectName != null && effectiveAlert.subjectName!.isNotEmpty)
                        _buildDetailRow('Subject', effectiveAlert.subjectName!, isDark),
                      if (effectiveAlert.sectionId != null && effectiveAlert.sectionId!.isNotEmpty)
                        _buildDetailRow('Section ID', effectiveAlert.sectionId!, isDark),
                      if (effectiveAlert.departmentId.isNotEmpty)
                        _buildDetailRow('Department', effectiveAlert.departmentId, isDark),
                      _buildDetailRow('Created On', '${effectiveAlert.createdAt.day}/${effectiveAlert.createdAt.month}/${effectiveAlert.createdAt.year} at ${effectiveAlert.createdAt.hour.toString().padLeft(2, "0")}:${effectiveAlert.createdAt.minute.toString().padLeft(2, "0")}', isDark),
                      _buildDetailRow('Deduplication Key', effectiveAlert.deduplicationKey, isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action Controls Bar
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    // Drill-down CTA button
                    AcadexButton(
                      label: 'View Attendance Details',
                      icon: LucideIcons.externalLink,
                      onPressed: () {
                        if (effectiveAlert.studentId != null && effectiveAlert.studentId!.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentAttendanceDetailScreen(
                                studentId: effectiveAlert.studentId!,
                              ),
                            ),
                          );
                        } else if (effectiveAlert.subjectId != null && effectiveAlert.subjectId!.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SubjectAttendanceDetailScreen(
                                subjectId: effectiveAlert.subjectId!,
                                sectionId: effectiveAlert.sectionId,
                              ),
                            ),
                          );
                        } else if (effectiveAlert.sectionId != null && effectiveAlert.sectionId!.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SectionAttendanceDetailScreen(
                                sectionId: effectiveAlert.sectionId!,
                              ),
                            ),
                          );
                        }
                      },
                    ),

                    // Acknowledge Action
                    if (effectiveAlert.status == AttendanceAlertStatus.active)
                      AcadexButton(
                        label: 'Acknowledge Alert',
                        icon: LucideIcons.check,
                        variant: AcadexButtonVariant.secondary,
                        onPressed: () {
                          ref.read(attendanceAlertActionProvider.notifier).acknowledgeAlert(effectiveAlert.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Alert marked as acknowledged.')),
                          );
                        },
                      ),

                    // Resolve Action
                    if (effectiveAlert.status != AttendanceAlertStatus.resolved)
                      AcadexButton(
                        label: 'Resolve Alert',
                        icon: LucideIcons.checkCircle2,
                        variant: AcadexButtonVariant.secondary,
                        onPressed: () {
                          ref.read(attendanceAlertActionProvider.notifier).resolveAlert(effectiveAlert.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Alert marked as resolved.')),
                          );
                        },
                      ),

                    // Mark as Read Action
                    if (!effectiveAlert.isRead)
                      AcadexButton(
                        label: 'Mark as Read',
                        icon: LucideIcons.eye,
                        variant: AcadexButtonVariant.secondary,
                        onPressed: () {
                          ref.read(attendanceAlertActionProvider.notifier).markAsRead(effectiveAlert.id);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
        borderRadius: AcadexRadius.borderRadiusSm,
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ).copyWith(fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AcadexTypography.heading2(color: color).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AcadexTypography.bodySmall(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ).copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
