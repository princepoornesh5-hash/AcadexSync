import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/attendance_admin_providers.dart';
import '../providers/attendance_analytics_providers.dart';
import '../providers/attendance_alert_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';

class AttendanceAdminDashboardScreen extends ConsumerWidget {
  const AttendanceAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final deptId = user?.departmentId;

    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final alertSummaryAsync = ref.watch(attendanceAlertSummaryProvider);
    final reconciliationAsync = ref.watch(
      attendanceReconciliationProvider((departmentId: deptId, sectionId: null, dateRange: null)),
    );
    final dateRangeSummaryAsync = ref.watch(
      attendanceDateRangeSummaryProvider(DateRangeSummaryQuery(departmentId: deptId, dateRange: null)),
    );

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        title: Text(
          user?.role == AppRole.hod
              ? 'Department Attendance Administration'
              : (user?.role == AppRole.superAdmin ? 'Super Admin Attendance System' : 'College Attendance Administration'),
          style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
        ),
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.fileSpreadsheet),
            tooltip: 'Report Center',
            onPressed: () => context.go('/attendance/reports'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.history),
            tooltip: 'Session Admin & Audit',
            onPressed: () => context.go('/attendance/sessions/admin'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.bell),
            tooltip: 'Notifications',
            onPressed: () => context.go('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Executive Metrics Grid
            _buildExecutiveGrid(
              context,
              dateRangeSummaryAsync,
              alertSummaryAsync,
              reconciliationAsync,
              unreadCount,
              isDark,
            ),
            const SizedBox(height: 24),

            // Operational Quick Access Actions
            _buildActionShortcuts(context, isDark),
            const SizedBox(height: 24),

            // Summary & Breakdown Cards
            dateRangeSummaryAsync.when(
              loading: () => const AcadexLoadingState(message: 'Loading institutional attendance data...'),
              error: (err, _) => AcadexErrorState(
                message: 'Failed to load attendance metrics: $err',
                onRetry: () => ref.refresh(
                  attendanceDateRangeSummaryProvider(DateRangeSummaryQuery(departmentId: deptId, dateRange: null)),
                ),
              ),
              data: (summary) => _buildBreakdownSections(context, summary, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveGrid(
    BuildContext context,
    AsyncValue<dynamic> summaryAsync,
    AsyncValue<dynamic> alertAsync,
    AsyncValue<dynamic> reconciliationAsync,
    int unreadCount,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.0,
          children: [
            _buildStatCard(
              'Overall Attendance',
              summaryAsync.maybeWhen(
                data: (s) => '${s.attendancePercentage.toStringAsFixed(1)}%',
                orElse: () => '--%',
              ),
              LucideIcons.percent,
              AcadexColors.primary,
              isDark,
            ),
            _buildStatCard(
              'Critical Students (<70%)',
              alertAsync.maybeWhen(
                data: (a) => '${a.criticalCount}',
                orElse: () => '0',
              ),
              LucideIcons.shieldAlert,
              AcadexColors.error,
              isDark,
              onTap: () => context.go('/attendance/alerts'),
            ),
            _buildStatCard(
              'Scheduled Classes Conducted',
              reconciliationAsync.maybeWhen(
                data: (r) => '${r.recordedSessions} / ${r.expectedSessions}',
                orElse: () => '-- / --',
              ),
              LucideIcons.calendarCheck,
              AcadexColors.success,
              isDark,
              onTap: () => context.go('/attendance/sessions/admin'),
            ),
            _buildStatCard(
              'Unread Alerts & Notifications',
              '$unreadCount',
              LucideIcons.bellRing,
              unreadCount > 0 ? AcadexColors.warning : AcadexColors.inkMuted,
              isDark,
              onTap: () => context.go('/notifications'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const Spacer(),
                if (onTap != null)
                  Icon(LucideIcons.arrowUpRight, size: 14, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AcadexTypography.heading2(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                ),
                Text(
                  title,
                  style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionShortcuts(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.go('/attendance/reports'),
            icon: const Icon(LucideIcons.fileSpreadsheet, size: 18, color: Colors.white),
            label: const Text('Open Report Center', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.go('/attendance/sessions/admin'),
            icon: const Icon(LucideIcons.slidersHorizontal, size: 18),
            label: const Text('Manage Sessions & Audit'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownSections(BuildContext context, dynamic summary, bool isDark) {
    return Material(
      color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.barChart3, size: 18, color: AcadexColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Department & Section Overview',
                  style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Institutional target is 75.0%. Interventions are flagged for any student or class falling below standard.',
              style: AcadexTypography.bodySmall(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: AcadexColors.primary, child: const Icon(LucideIcons.users, color: Colors.white, size: 16)),
              title: const Text('Interactive Student & Section Drill-Down'),
              subtitle: const Text('View ranked rosters, recovery trajectories, and detailed attendance analytics.'),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => context.go('/attendance/analytics'),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: AcadexColors.error, child: const Icon(LucideIcons.alertOctagon, color: Colors.white, size: 16)),
              title: const Text('Early-Warning Attendance Alerts'),
              subtitle: const Text('Automated tracking of drop alerts, shortage risks, and recovery resolutions.'),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => context.go('/attendance/alerts'),
            ),
          ],
        ),
      ),
    );
  }
}
