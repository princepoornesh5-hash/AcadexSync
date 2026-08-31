import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/activity_feed.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import '../../../notifications/presentation/widgets/notification_preview_list.dart';
import '../../../timetable/presentation/providers/timetable_providers.dart';
import '../../../timetable/presentation/widgets/timetable_widgets.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(studentStatsProvider);
    final quickActions = ref.watch(studentQuickActionsProvider);
    final activity = ref.watch(studentActivityProvider);
    final authState = ref.watch(authProvider);

    UserModel? user;
    if (authState is AuthAuthenticated) user = authState.user;

    final profileAsync = ref.watch(currentStudentAcademicProfileProvider);
    final scheduleAsync = ref.watch(todayScheduleProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstName = user?.name.split(' ').first ?? 'Student';
    final classesToday = scheduleAsync.value?.length ?? 0;
    final profile = profileAsync.value;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final statCols = AcadexLayout.statGridColumns(context);

          return AcadexPageContainer(
            particleSphereVariant: ParticleSphereVariant.dashboard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Greeting & Role Badge
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hey, $firstName! 🎓',
                            style: AcadexTypography.heading1(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            classesToday > 0
                                ? 'You have $classesToday classes scheduled today. Stay on track!'
                                : 'No classes scheduled for today. Have a great day!',
                            style: AcadexTypography.body(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const AcadexBadge(
                      label: 'STUDENT',
                      variant: AcadexBadgeVariant.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Academic Placement & Enrolled Section Card
                if (profile != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AcadexColors.primary.withValues(alpha: 0.08),
                      borderRadius: AcadexRadius.borderRadiusMd,
                      border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.graduationCap, color: AcadexColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "${profile.course?.name ?? 'Course'} • ${profile.semester?.name ?? 'Semester'} • Section ${profile.section?.name ?? 'A'} (${profile.academicYear?.name ?? 'Current Year'})",
                            style: AcadexTypography.body(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AcadexColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AcadexRadius.xs),
                          ),
                          child: Text(
                            'Roll: ${profile.student.rollNumber}',
                            style: const TextStyle(
                              color: AcadexColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                AcadexLayout.sectionSpacer,

                // Overview Stat Cards (Attendance, Classes Missed, etc.)
                const SectionHeader(title: 'My Academic Overview'),
                AcadexLayout.headerGap,
                stats.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => AcadexCard(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Failed to load student metrics: $err',
                      style: AcadexTypography.caption(color: AcadexColors.error),
                    ),
                  ),
                  data: (data) => GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: data.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: statCols,
                      crossAxisSpacing: AcadexLayout.gridSpacing,
                      mainAxisSpacing: AcadexLayout.gridSpacing,
                      childAspectRatio: width > 600 ? 1.25 : 1.15,
                    ),
                    itemBuilder: (_, i) => StatCard(stat: data[i]),
                  ),
                ),
                AcadexLayout.sectionSpacer,

                // Today's Timetable Preview
                const SectionHeader(title: "Today's Schedule & Classes"),
                AcadexLayout.headerGap,
                Consumer(
                  builder: (context, ref, _) {
                    final todayAsync = ref.watch(todayScheduleProvider);
                    return todayAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error loading schedule: $err'),
                      data: (data) => TodayScheduleWidget(todayEntries: data),
                    );
                  },
                ),
                AcadexLayout.sectionSpacer,

                // Quick Navigation Actions
                const SectionHeader(title: 'Quick Operations'),
                AcadexLayout.headerGap,
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: quickActions.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: width > 900 ? 6 : (width > 600 ? 3 : 2),
                    crossAxisSpacing: AcadexLayout.gridSpacing,
                    mainAxisSpacing: AcadexLayout.gridSpacing,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder: (_, i) => QuickActionCard(action: quickActions[i]),
                ),
                AcadexLayout.sectionSpacer,

                // Notifications Preview Section
                const NotificationPreviewList(),
                AcadexLayout.sectionSpacer,

                // Recent Notifications / Activity Feed
                SectionHeader(
                  title: 'Recent Activity & Announcements',
                  actionLabel: 'View All',
                  onAction: () => context.go('/notifications'),
                ),
                AcadexLayout.headerGap,
                activity.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => AcadexCard(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Failed to load activity: $err',
                      style: AcadexTypography.caption(color: AcadexColors.error),
                    ),
                  ),
                  data: (data) => ActivityFeed(items: data),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
