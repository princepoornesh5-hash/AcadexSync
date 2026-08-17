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
import '../../../timetable/presentation/providers/timetable_providers.dart';
import '../../../timetable/presentation/widgets/timetable_widgets.dart';

class FacultyDashboard extends ConsumerWidget {
  const FacultyDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(facultyStatsProvider);
    final quickActions = ref.watch(facultyQuickActionsProvider);
    final activity = ref.watch(facultyActivityProvider);
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
          final firstName = user?.name.split(' ').first ?? 'Faculty';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting + role
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Good morning, Prof. $firstName!',
                              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
                          const SizedBox(height: 6),
                          Text("You have 3 classes today. Stay on track!",
                              style: GoogleFonts.inter(fontSize: 14, color: DashboardColors.textSecondary)),
                        ],
                      ),
                    ),
                    _RolePill(label: user?.role.displayName ?? 'Faculty'),
                  ],
                ),
                const SizedBox(height: 24),

                const SectionHeader(title: "Today's Schedule"),
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

                const SectionHeader(title: 'Overview'),
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
                const SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 12),
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: quickActions.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: width > 600 ? 4 : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.2,
                  ),
                  itemBuilder: (_, i) => QuickActionCard(action: quickActions[i]),
                ),
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
