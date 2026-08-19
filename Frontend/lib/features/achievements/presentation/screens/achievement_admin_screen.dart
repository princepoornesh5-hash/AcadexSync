import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/achievement_providers.dart';
import '../widgets/achievement_widgets.dart';

class AchievementAdminScreen extends ConsumerStatefulWidget {
  const AchievementAdminScreen({super.key});

  @override
  ConsumerState<AchievementAdminScreen> createState() => _AchievementAdminScreenState();
}

class _AchievementAdminScreenState extends ConsumerState<AchievementAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final metrics = ref.watch(adminAchievementMetricsProvider);
    final authState = ref.watch(authProvider);
    final isHod = authState is AuthAuthenticated && authState.user.role == AppRole.hod;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        maxWidth: 1600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            AcadexPageHeader(
              title: 'Student Achievements Review',
              subtitle: isHod
                  ? 'Review and verify departmental student achievements and credentials.'
                  : 'Review and verify student achievements across authorized academic scopes.',
            ),
            const SizedBox(height: AcadexSpacing.space16),

            // Summary Metrics
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 900;
                if (isNarrow) {
                  return Wrap(
                    spacing: AcadexSpacing.space16,
                    runSpacing: AcadexSpacing.space16,
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth - AcadexSpacing.space16) / 2,
                        child: AchievementMetricCard(
                          label: 'Total Achievements',
                          value: '${metrics.total}',
                          icon: LucideIcons.trophy,
                          color: AcadexColors.primary,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - AcadexSpacing.space16) / 2,
                        child: AchievementMetricCard(
                          label: 'Pending Verification',
                          value: '${metrics.pending}',
                          icon: LucideIcons.clock,
                          color: AcadexColors.warning,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - AcadexSpacing.space16) / 2,
                        child: AchievementMetricCard(
                          label: 'Verified',
                          value: '${metrics.verified}',
                          icon: LucideIcons.checkCircle2,
                          color: AcadexColors.success,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - AcadexSpacing.space16) / 2,
                        child: AchievementMetricCard(
                          label: 'Rejected',
                          value: '${metrics.rejected}',
                          icon: LucideIcons.xCircle,
                          color: AcadexColors.error,
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: AchievementMetricCard(
                        label: 'Total Achievements',
                        value: '${metrics.total}',
                        icon: LucideIcons.trophy,
                        color: AcadexColors.primary,
                      ),
                    ),
                    const SizedBox(width: AcadexSpacing.space16),
                    Expanded(
                      child: AchievementMetricCard(
                        label: 'Pending Verification',
                        value: '${metrics.pending}',
                        icon: LucideIcons.clock,
                        color: AcadexColors.warning,
                      ),
                    ),
                    const SizedBox(width: AcadexSpacing.space16),
                    Expanded(
                      child: AchievementMetricCard(
                        label: 'Verified',
                        value: '${metrics.verified}',
                        icon: LucideIcons.checkCircle2,
                        color: AcadexColors.success,
                      ),
                    ),
                    const SizedBox(width: AcadexSpacing.space16),
                    Expanded(
                      child: AchievementMetricCard(
                        label: 'Rejected',
                        value: '${metrics.rejected}',
                        icon: LucideIcons.xCircle,
                        color: AcadexColors.error,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AcadexSpacing.space24),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AcadexColors.primary,
                labelColor: AcadexColors.primary,
                unselectedLabelColor: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                tabs: const [
                  Tab(text: 'Pending Verification Queue'),
                  Tab(text: 'All Achievements'),
                ],
              ),
            ),
            const SizedBox(height: AcadexSpacing.space16),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingQueueTab(context),
                  _buildAllAchievementsTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingQueueTab(BuildContext context) {
    final asyncList = ref.watch(scopedAchievementsProvider);

    return asyncList.when(
      loading: () => const Center(child: AcadexLoadingState()),
      error: (err, _) => Center(
        child: AcadexErrorState(
          title: 'Error loading verification queue',
          message: err.toString(),
          onRetry: () => ref.invalidate(scopedAchievementsProvider),
        ),
      ),
      data: (list) {
        final pending = list.where((a) => a.isPending).toList();

        if (pending.isEmpty) {
          return const Center(
            child: AcadexEmptyState(
              title: 'Verification Queue Clean',
              subtitle: 'There are no student achievements currently awaiting verification.',
              icon: LucideIcons.checkCheck,
            ),
          );
        }

        return AcadexDataTable(
          columns: const [
            'Student',
            'Department',
            'Category',
            'Achievement Title',
            'Issuer',
            'Date',
            'Action',
          ],
          rows: pending.map((a) {
            return DataRow(
              cells: [
                DataCell(Text(a.studentName, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(a.departmentId.toUpperCase())),
                DataCell(AchievementCategoryBadge(category: a.category)),
                DataCell(Text(a.title)),
                DataCell(Text(a.issuer)),
                DataCell(Text('${a.achievementDate.day}/${a.achievementDate.month}/${a.achievementDate.year}')),
                DataCell(
                  AcadexButton(
                    label: 'Review',
                    icon: LucideIcons.eye,
                    variant: AcadexButtonVariant.primary,
                    size: AcadexButtonSize.sm,
                    onPressed: () => context.push('/achievements/${a.id}', extra: a),
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAllAchievementsTab(BuildContext context) {
    final filtered = ref.watch(filteredScopedAchievementsProvider);
    final filter = ref.watch(achievementFilterProvider);

    return Column(
      children: [
        // Search & Filter
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by student name, title, issuer, or skills...',
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                ),
                onChanged: (val) {
                  ref.read(achievementFilterProvider.notifier).state = filter.copyWith(searchQuery: val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AcadexSpacing.space16),

        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: AcadexEmptyState(
                    title: 'No Achievements Found',
                    subtitle: 'No achievements match the search query.',
                    icon: LucideIcons.inbox,
                  ),
                )
              : AcadexDataTable(
                  columns: const [
                    'Student',
                    'Department',
                    'Category',
                    'Title',
                    'Status',
                    'Date',
                    'Action',
                  ],
                  rows: filtered.map((a) {
                    return DataRow(
                      cells: [
                        DataCell(Text(a.studentName, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(a.departmentId.toUpperCase())),
                        DataCell(AchievementCategoryBadge(category: a.category)),
                        DataCell(Text(a.title)),
                        DataCell(AchievementStatusBadge(status: a.verificationStatus)),
                        DataCell(Text('${a.achievementDate.day}/${a.achievementDate.month}/${a.achievementDate.year}')),
                        DataCell(
                          AcadexButton(
                            label: 'Details',
                            icon: LucideIcons.eye,
                            variant: AcadexButtonVariant.secondary,
                            size: AcadexButtonSize.sm,
                            onPressed: () => context.push('/achievements/${a.id}', extra: a),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
