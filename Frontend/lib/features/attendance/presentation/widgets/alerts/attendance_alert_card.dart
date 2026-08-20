import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/core/presentation/widgets/acadex_badge.dart';
import 'package:campus_management/core/presentation/widgets/acadex_card.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_alert.dart';

/// Reusable Card widget for rendering a single attendance alert
class AttendanceAlertCard extends StatelessWidget {
  final AttendanceAlert alert;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onAcknowledge;

  const AttendanceAlertCard({
    super.key,
    required this.alert,
    this.onTap,
    this.onMarkAsRead,
    this.onAcknowledge,
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

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final severityColor = _getSeverityColor();
    final typeIcon = _getTypeIcon();

    return AcadexCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: AcadexRadius.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Severity, Badges, Time, Unread Indicator
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Type Icon Container
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(typeIcon, size: 16, color: severityColor),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Title & Timestamp
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (!alert.isRead) ...[
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: AcadexColors.info,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                            Flexible(
                              child: Text(
                                alert.title,
                                style: AcadexTypography.body(
                                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                ).copyWith(fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatDate(alert.createdAt),
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Severity & Status Badges
                  Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AcadexBadge(
                        label: alert.severity == AttendanceAlertSeverity.critical
                            ? 'Critical'
                            : (alert.severity == AttendanceAlertSeverity.warning ? 'Warning' : 'Info'),
                        variant: alert.severity == AttendanceAlertSeverity.critical
                            ? AcadexBadgeVariant.danger
                            : (alert.severity == AttendanceAlertSeverity.warning ? AcadexBadgeVariant.warning : AcadexBadgeVariant.info),
                      ),
                      if (alert.status == AttendanceAlertStatus.resolved)
                        const AcadexBadge(
                          label: 'Resolved',
                          variant: AcadexBadgeVariant.success,
                        )
                      else if (alert.status == AttendanceAlertStatus.acknowledged)
                        const AcadexBadge(
                          label: 'Acknowledged',
                          variant: AcadexBadgeVariant.neutral,
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Alert Message Explanation
              Text(
                alert.message,
                style: AcadexTypography.bodySmall(
                  color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 10),

              // Bottom Context Bar (Subject, Section, Recovery Chip, Actions)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (alert.studentName != null && alert.studentName!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                              borderRadius: AcadexRadius.borderRadiusSm,
                            ),
                            child: Text(
                              '${alert.studentName} (${alert.rollNumber ?? "--"})',
                              style: AcadexTypography.caption(
                                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                              ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        if (alert.subjectName != null && alert.subjectName!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                              borderRadius: AcadexRadius.borderRadiusSm,
                            ),
                            child: Text(
                              alert.subjectName!,
                              style: AcadexTypography.caption(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ).copyWith(fontSize: 11),
                            ),
                          ),
                        if (alert.recoverySessionsNeeded != null && alert.recoverySessionsNeeded! > 0)
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
                                  'Needs ${alert.recoverySessionsNeeded} consecutive classes',
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
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!alert.isRead && onMarkAsRead != null)
                        IconButton(
                          icon: const Icon(LucideIcons.checkCheck, size: 16),
                          tooltip: 'Mark as read',
                          onPressed: onMarkAsRead,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
