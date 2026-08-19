import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../domain/models/achievement_models.dart';
import '../providers/achievement_providers.dart';
import '../widgets/achievement_widgets.dart';

class StudentAchievementsScreen extends ConsumerWidget {
  const StudentAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final asyncAchievements = ref.watch(studentAchievementsProvider);
    final filteredAchievements = ref.watch(filteredStudentAchievementsProvider);
    final metrics = ref.watch(studentAchievementMetricsProvider);
    final filter = ref.watch(achievementFilterProvider);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        maxWidth: 1600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            AcadexPageHeader(
              title: 'Achievements',
              subtitle: 'Showcase your accomplishments, skills and recognitions.',
              actions: [
                AcadexButton(
                  label: 'Add Achievement',
                  icon: LucideIcons.plus,
                  variant: AcadexButtonVariant.primary,
                  onPressed: () => context.push('/achievements/new'),
                ),
              ],
            ),
            const SizedBox(height: AcadexSpacing.space16),

            // Summary Metrics Strip
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
                          label: 'Verified',
                          value: '${metrics.verified}',
                          icon: LucideIcons.checkCircle2,
                          color: AcadexColors.success,
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
                          label: '${DateTime.now().year} Achievements',
                          value: '${metrics.currentYearCount}',
                          icon: LucideIcons.calendar,
                          color: AcadexColors.info,
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
                        label: 'Verified',
                        value: '${metrics.verified}',
                        icon: LucideIcons.checkCircle2,
                        color: AcadexColors.success,
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
                        label: '${DateTime.now().year} Achievements',
                        value: '${metrics.currentYearCount}',
                        icon: LucideIcons.calendar,
                        color: AcadexColors.info,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AcadexSpacing.space24),

            // Search & Sort Toolbar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search achievements by title, issuer, skills, description...',
                      prefixIcon: const Icon(LucideIcons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                    ),
                    onChanged: (val) {
                      ref.read(achievementFilterProvider.notifier).state = filter.copyWith(searchQuery: val);
                    },
                  ),
                ),
                const SizedBox(width: AcadexSpacing.space16),
                _statusDropdown(context, ref, filter, isDark),
                const SizedBox(width: AcadexSpacing.space12),
                _sortDropdown(context, ref, filter, isDark),
              ],
            ),
            const SizedBox(height: AcadexSpacing.space16),

            // Horizontally Scrollable Category Pills
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _categoryPill(
                    label: 'All Categories',
                    icon: LucideIcons.layers,
                    isSelected: filter.category == null,
                    onTap: () {
                      ref.read(achievementFilterProvider.notifier).state = filter.copyWith(clearCategory: true);
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  ...AchievementCategory.values.map((cat) {
                    final isSelected = filter.category == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _categoryPill(
                        label: cat.displayName,
                        icon: cat.icon,
                        isSelected: isSelected,
                        onTap: () {
                          ref.read(achievementFilterProvider.notifier).state = isSelected
                              ? filter.copyWith(clearCategory: true)
                              : filter.copyWith(category: cat);
                        },
                        isDark: isDark,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AcadexSpacing.space24),

            // Achievements Grid / List Content
            Expanded(
              child: asyncAchievements.when(
                loading: () => const Center(child: AcadexLoadingState()),
                error: (err, _) => Center(
                  child: AcadexErrorState(
                    title: 'Error loading achievements',
                    message: err.toString(),
                    onRetry: () => ref.invalidate(studentAchievementsProvider),
                  ),
                ),
                data: (allAchievements) {
                  if (allAchievements.isEmpty) {
                    return Center(
                      child: AcadexEmptyState(
                        title: 'No achievements yet',
                        subtitle: 'Your accomplishments deserve a place here. Add your first achievement to build your portfolio.',
                        icon: LucideIcons.trophy,
                        actionLabel: 'Add Achievement',
                        onActionTap: () => context.push('/achievements/new'),
                      ),
                    );
                  }

                  if (filteredAchievements.isEmpty) {
                    return Center(
                      child: AcadexEmptyState(
                        title: 'No Matching Achievements',
                        subtitle: 'No achievements match your current search and filter criteria.',
                        icon: LucideIcons.searchX,
                        actionLabel: 'Clear Filters',
                        onActionTap: () {
                          ref.read(achievementFilterProvider.notifier).state = const AchievementFilter();
                        },
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isSingleCol = constraints.maxWidth < 900;
                      final crossAxisCount = isSingleCol ? 1 : 2;

                      return GridView.builder(
                        padding: const EdgeInsets.only(bottom: AcadexSpacing.space48),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisExtent: 310,
                          crossAxisSpacing: AcadexSpacing.space16,
                          mainAxisSpacing: AcadexSpacing.space16,
                        ),
                        itemCount: filteredAchievements.length,
                        itemBuilder: (context, index) {
                          final a = filteredAchievements[index];
                          return AchievementCard(
                            achievement: a,
                            onView: () => context.push('/achievements/${a.id}', extra: a),
                            onEdit: () => context.push('/achievements/${a.id}/edit', extra: a),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AcadexRadius.full),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AcadexColors.primary
              : (isDark ? AcadexColors.darkSurface : AcadexColors.surface),
          borderRadius: BorderRadius.circular(AcadexRadius.full),
          border: Border.all(
            color: isSelected
                ? AcadexColors.primary
                : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AcadexColors.darkInk : AcadexColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusDropdown(BuildContext context, WidgetRef ref, AchievementFilter filter, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AcadexSpacing.space16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AchievementVerificationStatus?>(
          value: filter.verificationStatus,
          hint: const Text('All Statuses'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Statuses')),
            ...AchievementVerificationStatus.values.map((s) {
              return DropdownMenuItem(value: s, child: Text(s.displayName));
            }),
          ],
          onChanged: (val) {
            ref.read(achievementFilterProvider.notifier).state =
                val == null ? filter.copyWith(clearVerificationStatus: true) : filter.copyWith(verificationStatus: val);
          },
        ),
      ),
    );
  }

  Widget _sortDropdown(BuildContext context, WidgetRef ref, AchievementFilter filter, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AcadexSpacing.space16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AchievementSortOption>(
          value: filter.sortOption,
          items: AchievementSortOption.values.map((opt) {
            return DropdownMenuItem(value: opt, child: Text(opt.displayName));
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              ref.read(achievementFilterProvider.notifier).state = filter.copyWith(sortOption: val);
            }
          },
        ),
      ),
    );
  }
}
