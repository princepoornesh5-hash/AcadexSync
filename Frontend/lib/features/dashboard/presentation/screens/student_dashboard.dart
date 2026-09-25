import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
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

    final firstName = user?.name.split(' ').first ?? 'Student';
    final classesToday = scheduleAsync.valueOrNull?.length ?? 0;
    final profile = profileAsync.valueOrNull;

    return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final statCols = AcadexLayout.statGridColumns(context);

          final isMobile = AcadexBreakpoints.isMobile(context);

          return AcadexPageContainer(
            backgroundColor: Colors.transparent,
            topPadding: isMobile ? 16 : 24,
            onRefresh: () async {
              ref.invalidate(studentStatsProvider);
              ref.invalidate(studentActivityProvider);
              ref.invalidate(currentStudentAcademicProfileProvider);
              ref.invalidate(todayScheduleProvider);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Greeting & Role Badge
                if (isMobile) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: AcadexAdaptiveGradientText(
                          'Hey, $firstName! 🎓',
                          style: AcadexTypography.heading2(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const AcadexBadge(
                        label: 'STUDENT',
                        variant: AcadexBadgeVariant.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AcadexAdaptiveGradientText(
                    classesToday > 0
                        ? 'You have $classesToday classes scheduled today.'
                        : 'No classes scheduled for today.',
                    style: AcadexTypography.caption(),
                    isSecondary: true,
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AcadexAdaptiveGradientText(
                              'Hey, $firstName! 🎓',
                              style: AcadexTypography.heading1(),
                            ),
                            const SizedBox(height: 4),
                            AcadexAdaptiveGradientText(
                              classesToday > 0
                                  ? 'You have $classesToday classes scheduled today. Stay on track!'
                                  : 'No classes scheduled for today. Have a great day!',
                              style: AcadexTypography.body(),
                              isSecondary: true,
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
                ],
                SizedBox(height: isMobile ? 14 : 20),

                // Student Academic Portal Hero Card
                AcadexHeroCard(
                  eyebrow: 'Student Academic Portal',
                  badge: profile != null
                      ? AcadexBadge(
                          label: 'ROLL: ${profile.student.rollNumber}',
                          variant: AcadexBadgeVariant.primary,
                        )
                      : const AcadexBadge(
                          label: 'STUDENT ENROLLED',
                          variant: AcadexBadgeVariant.success,
                        ),
                  icon: LucideIcons.graduationCap,
                  title: profile != null
                      ? '${profile.course?.name ?? "Enrolled Program"} • ${profile.semester?.name ?? "Semester"}'
                      : 'My Academic Program',
                  subtitle: profile != null
                      ? 'Section ${profile.section?.name ?? "A"} • Academic Year ${profile.academicYear?.name ?? "2025-2026"}'
                      : 'View your course syllabus, lecture schedule, and attendance standing.',
                  primaryActionLabel: 'My Attendance',
                  primaryActionIcon: LucideIcons.clipboardCheck,
                  onPrimaryAction: () => context.go('/attendance'),
                  secondaryActionLabel: 'Full Timetable',
                  onSecondaryAction: () => context.go('/timetable'),
                ),
                AcadexLayout.sectionSpacer,

                // Overview Stat Cards (Attendance, Classes Missed, etc.)
                const SectionHeader(title: 'My Academic Overview'),
                AcadexLayout.headerGap,
                stats.when(
                  loading: () => const AcadexLoadingState(message: 'Loading academic metrics...'),
                  error: (err, _) => AcadexErrorState(
                    message: 'Failed to load student metrics: $err',
                    onRetry: () => ref.refresh(studentStatsProvider),
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
                          : (width > 600 ? 1.25 : 1.15),
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
                      loading: () => const AcadexLoadingState(message: "Loading today's classes..."),
                      error: (err, _) => AcadexErrorState(
                        message: 'Error loading schedule: $err',
                        onRetry: () => ref.refresh(todayScheduleProvider),
                      ),
                      data: (data) => TodayScheduleWidget(todayEntries: data),
                    );
                  },
                ),
                AcadexLayout.sectionSpacer,

                // Quick Navigation Actions
                const SectionHeader(title: 'Quick Operations'),
                AcadexLayout.headerGap,
                QuickActionsRow(actions: quickActions),
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
                  loading: () => const AcadexLoadingState(message: 'Loading announcements...'),
                  error: (err, _) => AcadexErrorState(
                    message: 'Failed to load activity: $err',
                    onRetry: () => ref.refresh(studentActivityProvider),
                  ),
                  data: (data) => ActivityFeed(items: data),
                ),
              ],
            ),
          );
        },
      );
  }
}
