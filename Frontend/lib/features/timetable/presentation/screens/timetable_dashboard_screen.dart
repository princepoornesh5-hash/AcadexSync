import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_sliver_page_container.dart';
import '../../../../core/presentation/widgets/acadex_sliver_page_header.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/timetable_lookup_providers.dart';
import '../providers/timetable_providers.dart';
import '../widgets/acadex_timetable_calendar.dart';
import '../widgets/daily_timeline_view.dart';
import '../widgets/student_attendance_summary.dart';
import '../widgets/timetable_widgets.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/errors/acadex_error.dart';

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
      case AppRole.collegeAdmin:
        return 'College-wide timetable overview and schedule';
      default:
        return 'Your weekly academic schedule';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyTimetableProvider);
    final viewMode = ref.watch(timetableViewModeProvider);
    final selectedDay = ref.watch(timetableSelectedDayProvider);
    final selectedDate = ref.watch(timetableSelectedDateProvider);
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isStudent = user?.role == AppRole.student;
    final canManage =
        user?.role == AppRole.hod || user?.role == AppRole.collegeAdmin;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 640;

    return AcadexSliverPageContainer(
      onRefresh: () async {
        ref.invalidate(weeklyTimetableProvider);
      },
      header: AcadexSliverPageHeader(
        title: 'My Timetable',
        subtitle: _getSubtitleForRole(user?.role),
        actions: [
          if (canManage) ...[
            AcadexButton(
              label: 'Manage & Create',
              icon: LucideIcons.settings,
              variant: AcadexButtonVariant.secondary,
              size: AcadexButtonSize.sm,
              onPressed: () => context.go('/timetable/manage'),
            ),
            const SizedBox(width: 8),
          ],
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
              ref.read(timetableViewModeProvider.notifier).state =
                  newSelection.first;
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: AcadexRadius.borderRadiusMd,
                ),
              ),
            ),
          ),
        ],
      ),
      slivers: [
        if (viewMode == TimetableViewMode.day) ...[
          if (isStudent)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: StudentAttendanceCompactSummary(),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AcadexTimetableCalendar(role: user?.role),
            ),
          ),
          SliverToBoxAdapter(
            child: weeklyAsync.when(
              loading: () => DailyTimelineView(
                entries: const [],
                selectedDate: selectedDate,
                isLoading: true,
              ),
              error: (err, _) => DailyTimelineView(
                entries: const [],
                selectedDate: selectedDate,
                errorMessage: AcadexException.fromError(err).userMessage,
                onRetry: () => ref.refresh(weeklyTimetableProvider),
              ),
              data: (weeklyData) {
                final dayEntries = weeklyData[selectedDay] ?? [];
                return DailyTimelineView(
                  entries: dayEntries,
                  selectedDate: selectedDate,
                );
              },
            ),
          ),
        ] else if (viewMode == TimetableViewMode.week) ...[
          SliverToBoxAdapter(
            child: weeklyAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => AcadexErrorState.fromError(
                error: err,
                title: 'Unable to load weekly timetable',
                onRetry: () => ref.refresh(weeklyTimetableProvider),
              ),
              data: (weeklyData) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: isMobile ? 640 : width - 48,
                  ),
                  child: WeeklyTimetableGrid(weeklyData: weeklyData),
                ),
              ),
            ),
          ),
        ] else ...[
          SliverToBoxAdapter(
            child: weeklyAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => AcadexErrorState.fromError(
                error: err,
                title: 'Unable to load timetable list',
                onRetry: () => ref.refresh(weeklyTimetableProvider),
              ),
              data: (weeklyData) => TimetableListView(weeklyData: weeklyData),
            ),
          ),
        ],
      ],
    );
  }
}
