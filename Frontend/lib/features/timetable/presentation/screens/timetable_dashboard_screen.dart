import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_providers.dart';
import '../providers/timetable_lookup_providers.dart';
import '../widgets/timetable_widgets.dart';

class TimetableDashboardScreen extends ConsumerWidget {
  const TimetableDashboardScreen({super.key});

  String _getSubtitleForRole(AppRole? role) {
    switch (role) {
      case AppRole.faculty:
        return 'Your teaching schedule and classroom allocations';
      case AppRole.student:
        return 'Your class schedule and lecture locations';
      case AppRole.hod:
        return 'Departmental timetable overview and schedule';
      default:
        return 'Your weekly academic schedule';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyTimetableProvider);
    final viewMode = ref.watch(timetableViewModeProvider);
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 640;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Page Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
                  child: AcadexPageHeader(
                    title: 'My Timetable',
                    subtitle: _getSubtitleForRole(user?.role),
                    actions: [
                      // View Mode Switcher with animated feedback
                      SegmentedButton<TimetableViewMode>(
                        segments: const [
                          ButtonSegment<TimetableViewMode>(
                            value: TimetableViewMode.day,
                            label: Text('Day'),
                            icon: Icon(LucideIcons.calendar, size: 16),
                          ),
                          ButtonSegment<TimetableViewMode>(
                            value: TimetableViewMode.week,
                            label: Text('Week'),
                            icon: Icon(LucideIcons.calendarDays, size: 16),
                          ),
                          ButtonSegment<TimetableViewMode>(
                            value: TimetableViewMode.list,
                            label: Text('List'),
                            icon: Icon(LucideIcons.list, size: 16),
                          ),
                        ],
                        selected: {viewMode},
                        onSelectionChanged: (newSelection) {
                          ref.read(timetableViewModeProvider.notifier).state = newSelection.first;
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Mobile Horizontal Day Bar if in Day View
                if (isMobile && viewMode == TimetableViewMode.day)
                  weeklyAsync.maybeWhen(
                    data: (weeklyData) => _buildMobileDayBar(context, ref, weeklyData),
                    orElse: () => const SizedBox.shrink(),
                  ),

                // Main Content with AnimatedSwitcher for smooth view transitions
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AcadexMotion.resolveDuration(context, AcadexMotion.normal),
                    switchInCurve: AcadexMotion.curveStandard,
                    switchOutCurve: AcadexMotion.curveStandard,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.015),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: weeklyAsync.when(
                      loading: () => const Center(
                        key: ValueKey('timetable_loading'),
                        child: CircularProgressIndicator(),
                      ),
                      error: (err, stack) => Center(
                        key: const ValueKey('timetable_error'),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.alertCircle, color: AcadexColors.error, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load timetable',
                                style: AcadexTypography.heading2(color: Theme.of(context).colorScheme.onSurface),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please check your network connection and try again.',
                                style: AcadexTypography.caption(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => ref.refresh(weeklyTimetableProvider),
                                icon: const Icon(LucideIcons.refreshCw, size: 16),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (weeklyData) {
                        final totalEntries = weeklyData.values.fold<int>(0, (sum, list) => sum + list.length);

                        if (totalEntries == 0) {
                          return Center(
                            key: const ValueKey('timetable_empty'),
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.calendarCheck,
                                    size: 64,
                                    color: (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted).withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No classes scheduled',
                                    style: AcadexTypography.heading2(color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your timetable will appear here once classes are assigned.',
                                    style: AcadexTypography.caption(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        switch (viewMode) {
                          case TimetableViewMode.day:
                            return TimetableDayView(key: const ValueKey('view_day'), weeklyData: weeklyData);
                          case TimetableViewMode.week:
                            return isMobile
                                ? TimetableDayView(key: const ValueKey('view_day_mobile'), weeklyData: weeklyData)
                                : WeeklyTimetableGrid(key: const ValueKey('view_week'), weeklyData: weeklyData);
                          case TimetableViewMode.list:
                            return TimetableListView(key: const ValueKey('view_list'), weeklyData: weeklyData);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDayBar(BuildContext context, WidgetRef ref, Map<TimetableDay, List<TimetableModel>> weeklyData) {
    final selectedDay = ref.watch(timetableSelectedDayProvider);

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: TimetableDay.values.length,
        itemBuilder: (context, index) {
          final day = TimetableDay.values[index];
          final isSelected = selectedDay == day;
          final count = (weeklyData[day] ?? []).length;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => ref.read(timetableSelectedDayProvider.notifier).state = day,
              borderRadius: AcadexRadius.borderRadiusLg,
              child: AnimatedContainer(
                duration: AcadexMotion.resolveDuration(context, AcadexMotion.fast),
                curve: AcadexMotion.curveStandard,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  borderRadius: AcadexRadius.borderRadiusLg,
                  border: Border.all(
                    color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      day.displayName.substring(0, 3),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      AnimatedContainer(
                        duration: AcadexMotion.resolveDuration(context, AcadexMotion.micro),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : Theme.of(context).dividerColor.withValues(alpha: 0.4),
                          borderRadius: AcadexRadius.borderRadiusXs,
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
