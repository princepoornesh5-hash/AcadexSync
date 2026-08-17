import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
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

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: DashboardColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final statCols = width > 1024 ? 4 : width > 600 ? 3 : 2;
          final firstName = user?.name.split(' ').first ?? 'Student';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
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
                              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
                          const SizedBox(height: 6),
                          Text('You have 4 classes today. Keep it up!',
                              style: GoogleFonts.inter(fontSize: 14, color: DashboardColors.textSecondary)),
                        ],
                      ),
                    ),
                    _RolePill(label: user?.role.displayName ?? 'Student'),
                  ],
                ),
                const SizedBox(height: 24),

                // Attendance Warning Banner (conditional example)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DashboardColors.warningLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DashboardColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, color: DashboardColors.warning, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Attendance Alert', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardColors.warning)),
                            Text('Your attendance in DBMS is below 75%. Please attend regularly.',
                                style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.warning)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stats
                const SectionHeader(title: 'My Overview'),
                const SizedBox(height: 12),
                stats.when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                  error: (err, stack) => Text('Error: $err'),
                  data: (data) => GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: data.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: statCols,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: width > 600 ? 1.15 : 1.05,
                    ),
                    itemBuilder: (_, i) => StatCard(stat: data[i], animationDelay: i * 80),
                  ),
                ),
                const SizedBox(height: 28),

                // Today's timetable preview
                const SectionHeader(title: "Today's Timetable"),
                const SizedBox(height: 12),
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
                const SizedBox(height: 28),

                const SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 12),
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: quickActions.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: width > 600 ? 6 : 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (_, i) => QuickActionCard(action: quickActions[i]),
                ),
                const SizedBox(height: 28),
                const NotificationPreviewList(),
                const SizedBox(height: 28),
                SectionHeader(title: 'Recent Activity', actionLabel: 'View All', onAction: () {}),
                const SizedBox(height: 12),
                activity.when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                  error: (err, stack) => Text('Error: $err'),
                  data: (data) => ActivityFeed(items: data),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}


class _RolePill extends StatelessWidget {
  final String label;
  const _RolePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: DashboardColors.primaryLight,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: DashboardColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: DashboardColors.success, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DashboardColors.primary)),
        ],
      ),
    );
  }
}
