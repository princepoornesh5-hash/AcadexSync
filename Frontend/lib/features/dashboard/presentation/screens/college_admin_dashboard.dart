import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_adaptive_gradient_text.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/acadex_hero_card.dart';
import '../widgets/activity_feed.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import '../../../timetable/presentation/providers/timetable_providers.dart';
import '../../../timetable/presentation/widgets/timetable_widgets.dart';
import '../../../academic_structure/presentation/widgets/academic_structure_summary_widget.dart';
import '../../../reports/presentation/providers/reports_providers.dart';

class CollegeAdminDashboard extends ConsumerWidget {
  const CollegeAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(collegeAdminStatsProvider);
    final quickActions = ref.watch(collegeAdminQuickActionsProvider);
    final activity = ref.watch(collegeAdminActivityProvider);
    final authState = ref.watch(authProvider);

    UserModel? user;
    if (authState is AuthAuthenticated) user = authState.user;

    final isMobile = AcadexBreakpoints.isMobile(context);
    final firstName = user?.name.split(' ').first ?? 'College Admin';

    return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final statCols = AcadexLayout.statGridColumns(context);

          return AcadexPageContainer(
            backgroundColor: Colors.transparent,
            topPadding: isMobile ? 16 : 24,
            onRefresh: () async {
              ref.invalidate(collegeAdminStatsProvider);
              ref.invalidate(collegeAdminActivityProvider);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Top Greeting (Unboxed Adaptive Gradient Text) ──────
                _buildGreeting(context, isMobile, firstName),
                SizedBox(height: isMobile ? 14 : 20),

                // ── 2. College Status Hero Card (Solid White Surface) ─────
                AcadexHeroCard(
                  eyebrow: 'Institutional Command',
                  badge: const AcadexBadge(
                    label: 'ACTIVE ACADEMIC SESSION',
                    variant: AcadexBadgeVariant.primary,
                  ),
                  icon: LucideIcons.building2,
                  title: 'Academic Structure & Operations',
                  subtitle: 'Manage departments, courses, faculty allocations, and timetable across campus.',
                  primaryActionLabel: 'Academic Structure',
                  primaryActionIcon: LucideIcons.layers,
                  onPrimaryAction: () => context.go('/academics'),
                  secondaryActionLabel: 'Manage Timetable',
                  onSecondaryAction: () => context.go('/timetable/manage'),
                ),
                SizedBox(height: isMobile ? 18 : 24),

                // ── 3. Key Institutional Stat Cards ───────────────────────
                SectionHeader(
                  title: 'College Overview',
                  actionLabel: 'View Analytics →',
                  showAccent: true,
                  onAction: () => context.go('/analytics'),
                ),
                const SizedBox(height: 12),
                stats.when(
                  loading: () => const AcadexLoadingState(message: 'Loading institutional metrics...'),
                  error: (err, _) => AcadexErrorState(
                    message: 'Failed to load metrics: $err',
                    onRetry: () => ref.refresh(collegeAdminStatsProvider),
                  ),
                  data: (data) => GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: data.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: statCols,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: isMobile
                          ? (width >= 375 ? 1.05 : 0.98)
                          : (width > 600 ? 1.25 : 1.1),
                    ),
                    itemBuilder: (_, i) => StatCard(stat: data[i]),
                  ),
                ),
                SizedBox(height: isMobile ? 18 : 24),

                // ── 4. Today's Campus Timetable Schedule ───────────────────
                const SectionHeader(
                  title: "Today's Schedule & Sessions",
                  showAccent: true,
                ),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, _) {
                    final todayAsync = ref.watch(todayScheduleProvider);
                    return todayAsync.when(
                      loading: () => const AcadexLoadingState(message: 'Loading today\'s sessions...'),
                      error: (err, _) => AcadexErrorState(
                        message: 'Error loading schedule: $err',
                        onRetry: () => ref.refresh(todayScheduleProvider),
                      ),
                      data: (data) => TodayScheduleWidget(todayEntries: data),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ── 5. Academic Hierarchy Summary Deck ─────────────────────
                const AcademicStructureSummaryWidget(),
                const SizedBox(height: 24),

                // ── 6. Department Breakdown (Live from /reports/dashboard) ──
                Consumer(
                  builder: (context, ref, _) {
                    final reportAsync = ref.watch(roleDashboardReportProvider);
                    return reportAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (report) {
                        if (report == null || report.recentActivity.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final depts = report.recentActivity;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(
                              title: 'Department Performance Breakdown',
                              actionLabel: 'View Departments →',
                              showAccent: true,
                              onAction: () => context.go('/academics/departments'),
                            ),
                            const SizedBox(height: 12),
                            AcadexCard(
                              padding: const EdgeInsets.all(16),
                              child: ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: depts.length > 6 ? 6 : depts.length,
                                separatorBuilder: (_, _) => const Divider(
                                  height: 1,
                                  color: AcadexColors.hairline,
                                ),
                                itemBuilder: (context, idx) {
                                  final dept = depts[idx];
                                  final name = dept['name']?.toString() ?? 'Department';
                                  final code = dept['code']?.toString() ?? '';
                                  final students = dept['studentsCount']?.toString() ?? '0';
                                  final faculty = dept['facultyCount']?.toString() ?? '0';
                                  final attPct = dept['attendancePercentage'] != null
                                      ? '${(dept['attendancePercentage'] as num).toStringAsFixed(1)}%'
                                      : 'N/A';

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    leading: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: AcadexColors.primaryLight,
                                        borderRadius: AcadexRadius.borderRadiusMd,
                                      ),
                                      child: const Icon(LucideIcons.layoutGrid, color: AcadexColors.primary, size: 18),
                                    ),
                                    title: Text(
                                      name,
                                      style: AcadexTypography.body(
                                        color: AcadexColors.ink,
                                      ).copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      'Code: $code • $students Students • $faculty Faculty',
                                      style: AcadexTypography.caption(
                                        color: AcadexColors.inkMuted,
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AcadexColors.canvasSoft,
                                        borderRadius: AcadexRadius.borderRadiusSm,
                                      ),
                                      child: Text(
                                        'Att: $attPct',
                                        style: AcadexTypography.caption(
                                          color: AcadexColors.inkSecondary,
                                        ).copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    );
                  },
                ),

                // ── 7. Quick Operations Grid ───────────────────────────────
                SectionHeader(
                  title: 'Quick Operations',
                  actionLabel: 'More Actions →',
                  showAccent: true,
                  onAction: () => context.go('/academics'),
                ),
                const SizedBox(height: 12),
                QuickActionsRow(actions: quickActions),
                const SizedBox(height: 24),

                // ── 8. Recent Notifications & Activity ─────────────────────
                SectionHeader(
                  title: 'Recent Activity & Notifications',
                  actionLabel: 'View All →',
                  showAccent: true,
                  onAction: () => context.go('/notifications'),
                ),
                const SizedBox(height: 12),
                activity.when(
                  loading: () => const AcadexLoadingState(message: 'Loading recent activity...'),
                  error: (err, _) => AcadexErrorState(
                    message: 'Failed to load activity: $err',
                    onRetry: () => ref.refresh(collegeAdminActivityProvider),
                  ),
                  data: (data) => ActivityFeed(items: data),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      );
  }

  Widget _buildGreeting(BuildContext context, bool isMobile, String firstName) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AcadexAdaptiveGradientText(
                  'Hello, $firstName 👋',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const AcadexBadge(
                label: 'COLLEGE ADMIN',
                variant: AcadexBadgeVariant.primary,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const AcadexAdaptiveGradientText(
            'Institutional command center for academic operations, scheduling, and faculty management.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            isSecondary: true,
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AcadexAdaptiveGradientText(
                  'Hello, $firstName 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const AcadexAdaptiveGradientText(
                  'Institutional command center for academic operations, scheduling, and faculty management.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  isSecondary: true,
                ),
              ],
            ),
          ),
          const AcadexBadge(
            label: 'COLLEGE ADMIN',
            variant: AcadexBadgeVariant.primary,
          ),
        ],
      );
    }
  }
}
