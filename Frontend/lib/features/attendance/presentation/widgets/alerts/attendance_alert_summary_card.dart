import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/core/presentation/widgets/acadex_card.dart';
import 'package:campus_management/core/presentation/widgets/acadex_button.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_alert_providers.dart';
import 'package:campus_management/features/attendance/presentation/screens/attendance_alerts_screen.dart';

/// Reusable dashboard summary card displaying attendance early-warning metrics
class AttendanceAlertSummaryCard extends ConsumerWidget {
  final VoidCallback? onViewAlerts;

  const AttendanceAlertSummaryCard({
    super.key,
    this.onViewAlerts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);
    final summaryAsync = ref.watch(attendanceAlertSummaryProvider);

    return summaryAsync.when(
      loading: () => const AcadexCard(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      ),
      error: (err, _) => const SizedBox.shrink(),
      data: (summary) {
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
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: summary.criticalCount > 0
                                ? AcadexColors.error.withValues(alpha: 0.15)
                                : AcadexColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              summary.criticalCount > 0
                                  ? LucideIcons.alertOctagon
                                  : LucideIcons.shieldAlert,
                              size: 18,
                              color: summary.criticalCount > 0
                                  ? AcadexColors.error
                                  : AcadexColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance Early Warnings',
                                style: AcadexTypography.heading2(
                                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Automated risk monitoring & compliance alerts',
                                style: AcadexTypography.caption(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AcadexButton(
                    label: isMobile ? 'Alerts' : 'View All',
                    icon: LucideIcons.arrowRight,
                    variant: AcadexButtonVariant.secondary,
                    size: AcadexButtonSize.sm,
                    onPressed: onViewAlerts ?? () {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AttendanceAlertsScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Metrics Badges Row
              if (isMobile)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMetricPill(
                      label: '${summary.criticalCount} Critical',
                      count: summary.criticalCount,
                      color: AcadexColors.error,
                      icon: LucideIcons.alertTriangle,
                      isDark: isDark,
                    ),
                    _buildMetricPill(
                      label: '${summary.warningCount} Warnings',
                      count: summary.warningCount,
                      color: AcadexColors.warning,
                      icon: LucideIcons.alertCircle,
                      isDark: isDark,
                    ),
                    _buildMetricPill(
                      label: '${summary.unreadCount} Unread',
                      count: summary.unreadCount,
                      color: AcadexColors.info,
                      icon: LucideIcons.bell,
                      isDark: isDark,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Critical Risk',
                        count: summary.criticalCount,
                        color: AcadexColors.error,
                        icon: LucideIcons.alertTriangle,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Warnings',
                        count: summary.warningCount,
                        color: AcadexColors.warning,
                        icon: LucideIcons.alertCircle,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Unread Alerts',
                        count: summary.unreadCount,
                        color: AcadexColors.info,
                        icon: LucideIcons.bell,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricPill({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: AcadexRadius.borderRadiusSm,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AcadexTypography.caption(color: color).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: AcadexTypography.heading2(color: color).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
