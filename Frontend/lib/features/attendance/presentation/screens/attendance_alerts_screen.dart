import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/core/presentation/widgets/acadex_button.dart';
import 'package:campus_management/core/presentation/widgets/acadex_card.dart';
import 'package:campus_management/core/presentation/widgets/acadex_page_header.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_alert.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_alert_providers.dart';
import 'package:campus_management/features/attendance/presentation/widgets/alerts/attendance_alert_card.dart';
import 'package:campus_management/features/attendance/presentation/screens/attendance_alert_detail_screen.dart';

enum AlertFilterTab {
  all,
  critical,
  warning,
  unread,
  active,
  resolved,
}

/// Full screen interface for managing and acting on attendance alerts and early warnings
class AttendanceAlertsScreen extends ConsumerStatefulWidget {
  const AttendanceAlertsScreen({super.key});

  @override
  ConsumerState<AttendanceAlertsScreen> createState() => _AttendanceAlertsScreenState();
}

class _AttendanceAlertsScreenState extends ConsumerState<AttendanceAlertsScreen> {
  AlertFilterTab _activeTab = AlertFilterTab.all;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTabSelected(AlertFilterTab tab) {
    setState(() {
      _activeTab = tab;
    });

    final currentFilter = ref.read(attendanceAlertFilterProvider);
    switch (tab) {
      case AlertFilterTab.all:
        ref.read(attendanceAlertFilterProvider.notifier).state = const AttendanceAlertFilter();
        break;
      case AlertFilterTab.critical:
        ref.read(attendanceAlertFilterProvider.notifier).state = currentFilter.copyWith(
          severity: AttendanceAlertSeverity.critical,
          clearStatus: true,
          clearUnreadOnly: true,
        );
        break;
      case AlertFilterTab.warning:
        ref.read(attendanceAlertFilterProvider.notifier).state = currentFilter.copyWith(
          severity: AttendanceAlertSeverity.warning,
          clearStatus: true,
          clearUnreadOnly: true,
        );
        break;
      case AlertFilterTab.unread:
        ref.read(attendanceAlertFilterProvider.notifier).state = currentFilter.copyWith(
          unreadOnly: true,
          clearSeverity: true,
          clearStatus: true,
        );
        break;
      case AlertFilterTab.active:
        ref.read(attendanceAlertFilterProvider.notifier).state = currentFilter.copyWith(
          status: AttendanceAlertStatus.active,
          clearSeverity: true,
          clearUnreadOnly: true,
        );
        break;
      case AlertFilterTab.resolved:
        ref.read(attendanceAlertFilterProvider.notifier).state = currentFilter.copyWith(
          status: AttendanceAlertStatus.resolved,
          clearSeverity: true,
          clearUnreadOnly: true,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);
    final alertsAsync = ref.watch(attendanceAlertsProvider);
    final summaryAsync = ref.watch(attendanceAlertSummaryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
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
                  title: 'Attendance Early-Warning Center',
                  subtitle: 'Real-time shortage detection, sharp drops, and automated compliance alerts.',
                  onBack: () => Navigator.of(context).canPop()
                      ? Navigator.of(context).pop()
                      : context.go('/attendance/analytics'),
                  actions: [
                    summaryAsync.maybeWhen(
                      data: (summary) => summary.unreadCount > 0
                          ? AcadexButton(
                              label: 'Mark All Read',
                              icon: LucideIcons.checkCheck,
                              variant: AcadexButtonVariant.secondary,
                              size: AcadexButtonSize.sm,
                              onPressed: () {
                                ref.read(attendanceAlertActionProvider.notifier).markAllAsRead();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('All alerts marked as read.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            )
                          : const SizedBox.shrink(),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Search & Filter Toolbar
                AcadexCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          ref.read(attendanceAlertSearchQueryProvider.notifier).state = val;
                        },
                        decoration: InputDecoration(
                          hintText: 'Search alerts by student, roll no, subject, or section...',
                          prefixIcon: const Icon(LucideIcons.search, size: 16),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(LucideIcons.x, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(attendanceAlertSearchQueryProvider.notifier).state = '';
                                  },
                                )
                              : null,
                          isDense: true,
                          filled: true,
                          fillColor: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                          border: OutlineInputBorder(
                            borderRadius: AcadexRadius.borderRadiusSm,
                            borderSide: BorderSide(
                              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: 'All Alerts',
                              tab: AlertFilterTab.all,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              label: 'Critical',
                              tab: AlertFilterTab.critical,
                              color: AcadexColors.error,
                              icon: LucideIcons.alertTriangle,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              label: 'Warnings',
                              tab: AlertFilterTab.warning,
                              color: AcadexColors.warning,
                              icon: LucideIcons.alertCircle,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              label: 'Unread',
                              tab: AlertFilterTab.unread,
                              color: AcadexColors.info,
                              icon: LucideIcons.bell,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              label: 'Active',
                              tab: AlertFilterTab.active,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              label: 'Resolved',
                              tab: AlertFilterTab.resolved,
                              color: AcadexColors.success,
                              icon: LucideIcons.checkCircle2,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Alerts Stream / Async List
                alertsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) => AcadexCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Icon(LucideIcons.alertCircle, color: AcadexColors.error, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load attendance alerts',
                            style: AcadexTypography.heading2(color: AcadexColors.error),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            err.toString(),
                            style: AcadexTypography.caption(color: AcadexColors.inkMuted),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          AcadexButton(
                            label: 'Retry',
                            icon: LucideIcons.refreshCw,
                            onPressed: () => ref.refresh(attendanceAlertsProvider),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (alerts) {
                    if (alerts.isEmpty) {
                      final hasFilter = _activeTab != AlertFilterTab.all || _searchController.text.isNotEmpty;
                      return AcadexCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AcadexColors.success.withValues(alpha: isDark ? 0.15 : 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    LucideIcons.shieldCheck,
                                    size: 28,
                                    color: AcadexColors.success,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                hasFilter ? 'No Matching Alerts' : 'All Students Compliant',
                                style: AcadexTypography.heading2(
                                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                hasFilter
                                    ? 'No attendance alerts match the current filter or search criteria.'
                                    : 'No attendance alerts right now. All active attendance metrics meet institutional standards.',
                                style: AcadexTypography.caption(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (hasFilter) ...[
                                const SizedBox(height: 16),
                                AcadexButton(
                                  label: 'Clear Filters',
                                  icon: LucideIcons.rotateCcw,
                                  variant: AcadexButtonVariant.secondary,
                                  size: AcadexButtonSize.sm,
                                  onPressed: () {
                                    _searchController.clear();
                                    _onTabSelected(AlertFilterTab.all);
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (int i = 0; i < alerts.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          AttendanceAlertCard(
                            alert: alerts[i],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AttendanceAlertDetailScreen(alert: alerts[i]),
                                ),
                              );
                            },
                            onMarkAsRead: alerts[i].isRead
                                ? null
                                : () {
                                    ref.read(attendanceAlertActionProvider.notifier).markAsRead(alerts[i].id);
                                  },
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required AlertFilterTab tab,
    Color? color,
    IconData? icon,
    required bool isDark,
  }) {
    final isSelected = _activeTab == tab;
    final activeColor = color ?? AcadexColors.primary;

    return InkWell(
      onTap: () => _onTabSelected(tab),
      borderRadius: AcadexRadius.borderRadiusSm,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: isDark ? 0.25 : 0.15)
              : (isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft),
          borderRadius: AcadexRadius.borderRadiusSm,
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: isSelected ? activeColor : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AcadexTypography.caption(
                color: isSelected
                    ? activeColor
                    : (isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary),
              ).copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
