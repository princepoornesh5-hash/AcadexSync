import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final statCols = AcadexLayout.statGridColumns(context);
        final firstName = user?.name.split(' ').first ?? 'Student';
        final classesToday = scheduleAsync.value?.length ?? 0;
        final profile = profileAsync.value;
        final attPercentage = profile?.overallAttendancePercentage ?? 85.0;

        return AcadexPageContainer(
          particleSphereVariant: ParticleSphereVariant.dashboard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Greeting
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hey, $firstName! 🎓',
                              style: AcadexTypography.heading2(color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(height: 6),
                          Text(
                            classesToday > 0 
                                ? 'You have $classesToday classes scheduled today. Keep it up!'
                                : 'No classes scheduled for today. Have a great day!',
                            style: AcadexTypography.body(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    _RolePill(label: user?.role.displayName ?? 'Student'),
                  ],
                ),
                const SizedBox(height: 16),

                // Academic Placement Banner
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
                            "${profile.course?.name ?? 'Course'} • ${profile.semester?.name ?? 'Semester'} • Section ${profile.section?.name ?? 'A'} (${profile.academicYear?.name ?? 'Current Academic Year'})",
                            style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AcadexColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AcadexRadius.xs),
                          ),
                          child: Text(
                            "Roll: ${profile.student.rollNumber}",
                            style: const TextStyle(color: AcadexColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

              // Attendance Warning Banner (conditional only if attendance < 75%)
              if (attPercentage < 75.0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AcadexColors.warning.withValues(alpha: 0.1),
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(color: AcadexColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, color: AcadexColors.warning, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Attendance Alert', style: AcadexTypography.bodySmall(color: AcadexColors.warning).copyWith(fontWeight: FontWeight.w700)),
                            Text('Your overall attendance is currently at ${attPercentage.toStringAsFixed(1)}% (below the required 75%). Please attend classes regularly.',
                                style: AcadexTypography.caption(color: AcadexColors.warning)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

                // Stats
                const SectionHeader(title: 'My Overview'),
                AcadexLayout.headerGap,
                stats.when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                  error: (err, stack) => Text('Error: $err'),
                  data: (data) => GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: data.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: statCols,
                      crossAxisSpacing: AcadexLayout.gridSpacing,
                      mainAxisSpacing: AcadexLayout.gridSpacing,
                      childAspectRatio: width > 600 ? 1.15 : 1.05,
                    ),
                    itemBuilder: (_, i) => StatCard(stat: data[i], animationDelay: i * 80),
                  ),
                ),
                AcadexLayout.sectionSpacer,

                // Today's timetable preview
                const SectionHeader(title: "Today's Timetable"),
                AcadexLayout.headerGap,
                Consumer(
                  builder: (context, ref, _) {
                    final todayAsync = ref.watch(todayScheduleProvider);
                    return todayAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Text('Error loading schedule: $err'),
                      data: (data) => TodayScheduleWidget(todayEntries: data),
                    );
                  },
                ),
                AcadexLayout.sectionSpacer,

                const SectionHeader(title: 'Quick Actions'),
                AcadexLayout.headerGap,
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: quickActions.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: width > 600 ? 6 : 3,
                    crossAxisSpacing: AcadexLayout.gridSpacing,
                    mainAxisSpacing: AcadexLayout.gridSpacing,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (_, i) => QuickActionCard(action: quickActions[i]),
                ),
                AcadexLayout.sectionSpacer,
                const NotificationPreviewList(),
                AcadexLayout.sectionSpacer,
                SectionHeader(title: 'Recent Activity', actionLabel: 'View All', onAction: () {}),
                AcadexLayout.headerGap,
                activity.when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                  error: (err, stack) => Text('Error: $err'),
                  data: (data) => ActivityFeed(items: data),
                ),
            ],
          ),
        );
      }),
    );
  }
}


class _RolePill extends StatelessWidget {
  final String label;
  const _RolePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: AcadexRadius.borderRadiusFull,
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AcadexColors.success, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: AcadexTypography.eyebrow(color: Theme.of(context).primaryColor)),
        ],
      ),
    );
  }
}
