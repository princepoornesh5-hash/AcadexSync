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
import '../../../academic_structure/domain/models/academic_models.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/acadex_hero_card.dart';
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstName = user?.name.split(' ').first ?? 'Faculty';

    return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final statCols = AcadexLayout.statGridColumns(context);
          final isMobile = AcadexBreakpoints.isMobile(context);

          final nextClassAsync = ref.watch(nextClassProvider);
          final nextClass = nextClassAsync.valueOrNull;
          final subMap = ref.watch(subjectMapProvider);
          final secMap = ref.watch(sectionMapProvider);

          final nextSub = nextClass != null ? subMap[nextClass.subjectId] : null;
          final nextSec = nextClass != null ? secMap[nextClass.sectionId] : null;
          final nextSubName = nextSub?.name ?? (nextClass != null && nextClass.subjectId.isNotEmpty ? nextClass.subjectId : null);
          final nextSecName = nextSec?.name ?? (nextClass != null && nextClass.sectionId.isNotEmpty ? nextClass.sectionId : null);

          return AcadexPageContainer(
            backgroundColor: Colors.transparent,
            topPadding: isMobile ? 16 : 24,
            onRefresh: () async {
              ref.invalidate(facultyStatsProvider);
              ref.invalidate(facultyActivityProvider);
              ref.invalidate(myFacultyAssignmentsProvider);
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
                          'Welcome, Prof. $firstName 👋',
                          style: AcadexTypography.heading2(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const AcadexBadge(
                        label: 'FACULTY',
                        variant: AcadexBadgeVariant.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AcadexAdaptiveGradientText(
                    nextClass != null
                        ? 'Next class: ${nextSubName ?? "Lecture"} at ${nextClass.startTime}'
                        : 'Manage your classes, student attendance, and schedule.',
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
                              'Good morning, Prof. $firstName 👋',
                              style: AcadexTypography.heading1(),
                            ),
                            const SizedBox(height: 4),
                            AcadexAdaptiveGradientText(
                              nextClass != null
                                  ? 'Next scheduled class: ${nextSubName ?? "Lecture"} at ${nextClass.startTime} in Room ${nextClass.roomNumber}.'
                                  : 'Manage your allocated classes, student attendance, lesson notes, and teaching schedule.',
                              style: AcadexTypography.body(),
                              isSecondary: true,
                            ),
                          ],
                        ),
                      ),
                      const AcadexBadge(
                        label: 'FACULTY',
                        variant: AcadexBadgeVariant.primary,
                      ),
                    ],
                  ),
                ],
                SizedBox(height: isMobile ? 14 : 20),

                // Teaching Operations Hero Card (Dynamic Next Class Action)
                if (nextClass != null)
                  AcadexHeroCard(
                    eyebrow: 'Next Scheduled Session',
                    badge: AcadexBadge(
                      label: '${nextClass.startTime} – ${nextClass.endTime}',

                      variant: AcadexBadgeVariant.success,
                    ),
                    icon: LucideIcons.sparkles,
                    title: nextSubName ?? 'Scheduled Lecture',
                    subtitle: '${nextClass.sessionType.displayName} • Section ${nextSecName ?? "—"}${nextClass.roomNumber.isNotEmpty ? " • Room ${nextClass.roomNumber}" : ""}',
                    primaryActionLabel: 'Mark Attendance',
                    primaryActionIcon: LucideIcons.clipboardCheck,
                    onPrimaryAction: () => context.go('/attendance'),
                    secondaryActionLabel: 'View Timetable',
                    onSecondaryAction: () => context.go('/timetable'),
                  )
                else
                  AcadexHeroCard(
                    eyebrow: 'Teaching Operations Workspace',
                    badge: const AcadexBadge(
                      label: 'FACULTY ON DUTY',
                      variant: AcadexBadgeVariant.primary,
                    ),
                    icon: LucideIcons.calendarCheck,
                    title: 'Daily Teaching & Attendance Portal',
                    subtitle: 'Quickly mark student attendance, review allocated sections, and manage study notes.',
                    primaryActionLabel: 'Mark Attendance',
                    primaryActionIcon: LucideIcons.clipboardCheck,
                    onPrimaryAction: () => context.go('/attendance'),
                    secondaryActionLabel: 'View Timetable',
                    onSecondaryAction: () => context.go('/timetable'),
                  ),
                AcadexLayout.sectionSpacer,

                // Overview Stat Cards
                const SectionHeader(title: 'Teaching Overview'),
                AcadexLayout.headerGap,
                stats.when(
                  loading: () => const AcadexLoadingState(message: 'Loading teaching metrics...'),
                  error: (err, _) => AcadexErrorState(
                    message: 'Failed to load teaching metrics: $err',
                    onRetry: () => ref.refresh(facultyStatsProvider),
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

                // Today's Timetable Schedule
                const SectionHeader(title: "Today's Teaching Schedule"),
                AcadexLayout.headerGap,
                Consumer(
                  builder: (context, ref, _) {
                    final todayAsync = ref.watch(todayScheduleProvider);
                    return todayAsync.when(
                      loading: () => const AcadexLoadingState(message: "Loading today's teaching schedule..."),
                      error: (err, _) => AcadexErrorState(
                        message: 'Error loading schedule: $err',
                        onRetry: () => ref.refresh(todayScheduleProvider),
                      ),
                      data: (data) => TodayScheduleWidget(todayEntries: data),
                    );
                  },
                ),
                AcadexLayout.sectionSpacer,

                // My Assigned Subjects Allocation Grid
                SectionHeader(
                  title: 'My Assigned Subjects & Sections',
                  actionLabel: 'View All Assignments',
                  onAction: () => context.go('/my-assignments'),
                ),
                AcadexLayout.headerGap,
                Consumer(
                  builder: (context, ref, _) {
                    final myAssignments = ref.watch(myFacultyAssignmentsProvider);
                    final subMap = ref.watch(subjectMapProvider);
                    final secMap = ref.watch(sectionMapProvider);
                    final courseMap = ref.watch(courseMapProvider);
                    final semMap = ref.watch(semesterMapProvider);

                    if (myAssignments.isEmpty) {
                      return const AcadexEmptyState(
                        title: 'No Assigned Subjects',
                        subtitle: 'No teaching assignments have been allocated to your profile yet.',
                        icon: LucideIcons.bookOpen,
                      );
                    }

                    // Group assignments by subjectId
                    final Map<String, List<String>> subjectSections = {};
                    for (final a in myAssignments) {
                      subjectSections.putIfAbsent(a.subjectId, () => []).add(a.sectionId);
                    }

                    final subjectEntries = subjectSections.entries.toList();

                    if (isMobile) {
                      return ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: subjectEntries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          final entry = subjectEntries[idx];
                          final sub = subMap[entry.key];
                          final sectionNames = entry.value
                              .map((secId) => secMap[secId]?.name ?? secId)
                              .join(', ');

                          return AcadexCard(
                            onTap: () => _showAssignmentDetailsModal(
                              context: context,
                              subject: sub,
                              subjectId: entry.key,
                              sectionIds: entry.value,
                              secMap: secMap,
                              courseMap: courseMap,
                              semMap: semMap,
                              deptMap: ref.read(departmentMapProvider),
                              assignments: myAssignments.where((a) => a.subjectId == entry.key).toList(),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AcadexColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(AcadexRadius.xs),
                                      ),
                                      child: Text(
                                        sub?.code ?? 'SUBJECT',
                                        style: const TextStyle(
                                          color: AcadexColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${entry.value.length} Section${entry.value.length > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  sub?.name ?? 'Assigned Course',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AcadexTypography.title(
                                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sections: $sectionNames',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AcadexTypography.caption(
                                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Divider(
                                  height: 1,
                                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      tooltip: 'Mark Attendance',
                                      icon: const Icon(LucideIcons.clipboardCheck, size: 16, color: AcadexColors.primary),
                                      onPressed: () => context.go('/attendance'),
                                    ),
                                    IconButton(
                                      tooltip: 'Upload Notes',
                                      icon: const Icon(LucideIcons.filePlus, size: 16, color: AcadexColors.accentTeal),
                                      onPressed: () => context.push('/notes/new'),
                                    ),
                                    IconButton(
                                      tooltip: 'View Timetable',
                                      icon: const Icon(LucideIcons.calendarDays, size: 16, color: AcadexColors.accentPurple),
                                      onPressed: () => context.go('/timetable'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: subjectEntries.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: width > 900 ? 3 : (width > 600 ? 2 : 1),
                        crossAxisSpacing: AcadexLayout.gridSpacing,
                        mainAxisSpacing: AcadexLayout.gridSpacing,
                        childAspectRatio: width > 600 ? 1.6 : 1.8,
                      ),
                      itemBuilder: (context, idx) {
                        final entry = subjectEntries[idx];
                        final sub = subMap[entry.key];
                        final sectionNames = entry.value
                            .map((secId) => secMap[secId]?.name ?? secId)
                            .join(', ');

                        return AcadexCard(
                          onTap: () => _showAssignmentDetailsModal(
                            context: context,
                            subject: sub,
                            subjectId: entry.key,
                            sectionIds: entry.value,
                            secMap: secMap,
                            courseMap: courseMap,
                            semMap: semMap,
                            deptMap: ref.read(departmentMapProvider),
                            assignments: myAssignments.where((a) => a.subjectId == entry.key).toList(),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AcadexColors.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(AcadexRadius.xs),
                                        ),
                                        child: Text(
                                          sub?.code ?? 'SUBJECT',
                                          style: const TextStyle(
                                            color: AcadexColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${entry.value.length} Section${entry.value.length > 1 ? 's' : ''}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    sub?.name ?? 'Assigned Course',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AcadexTypography.title(
                                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sections: $sectionNames',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AcadexTypography.caption(
                                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                              Divider(
                                height: 1,
                                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    tooltip: 'Mark Attendance',
                                    icon: const Icon(LucideIcons.clipboardCheck, size: 16, color: AcadexColors.primary),
                                    onPressed: () => context.go('/attendance'),
                                  ),
                                  IconButton(
                                    tooltip: 'Upload Notes',
                                    icon: const Icon(LucideIcons.filePlus, size: 16, color: AcadexColors.accentTeal),
                                    onPressed: () => context.push('/notes/new'),
                                  ),
                                  IconButton(
                                    tooltip: 'View Timetable',
                                    icon: const Icon(LucideIcons.calendarDays, size: 16, color: AcadexColors.accentPurple),
                                    onPressed: () => context.go('/timetable'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                AcadexLayout.sectionSpacer,

                // Quick Navigation Actions
                const SectionHeader(title: 'Quick Operations'),
                AcadexLayout.headerGap,
                QuickActionsRow(actions: quickActions),
                AcadexLayout.sectionSpacer,

                // Recent Activity / Announcements Feed
                SectionHeader(
                  title: 'Recent Activity & Notifications',
                  actionLabel: 'View All',
                  onAction: () => context.go('/notifications'),
                ),
                AcadexLayout.headerGap,
                activity.when(
                  loading: () => const AcadexLoadingState(message: 'Loading recent updates...'),
                  error: (err, _) => AcadexErrorState(
                    message: 'Failed to load activity: $err',
                    onRetry: () => ref.refresh(facultyActivityProvider),
                  ),
                  data: (data) => ActivityFeed(items: data),
                ),
              ],
            ),
          );
        },
      );
  }

  void _showAssignmentDetailsModal({
    required BuildContext context,
    required Subject? subject,
    required String subjectId,
    required List<String> sectionIds,
    required Map<String, Section> secMap,
    required Map<String, Course> courseMap,
    required Map<String, Semester> semMap,
    required Map<String, Department> deptMap,
    required List<FacultyAssignment> assignments,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);

    final firstAssign = assignments.isNotEmpty ? assignments.first : null;
    final dept = firstAssign != null ? deptMap[firstAssign.departmentId] : null;
    final course = firstAssign != null ? courseMap[firstAssign.courseId] : null;
    final semester = firstAssign != null ? semMap[firstAssign.semesterId] : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AcadexRadius.lg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject?.name ?? subjectId,
                        style: AcadexTypography.heading3(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: ${subject?.code ?? "N/A"} • Type: ${subject?.type ?? "Theory"} • Credits: ${subject?.credits ?? 3}',
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AcadexColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AcadexRadius.xs),
                  ),
                  child: Text(
                    '${assignments.length} Section${assignments.length > 1 ? 's' : ''}',
                    style: const TextStyle(color: AcadexColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
            const SizedBox(height: 16),

            // Academic details grid
            Row(
              children: [
                Expanded(
                  child: _DetailTile(label: 'Department', value: dept?.name ?? firstAssign?.departmentId ?? 'N/A'),
                ),
                Expanded(
                  child: _DetailTile(label: 'Course', value: course?.name ?? firstAssign?.courseId ?? 'N/A'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DetailTile(label: 'Semester', value: semester?.name ?? firstAssign?.semesterId ?? 'N/A'),
                ),
                Expanded(
                  child: _DetailTile(
                    label: 'Assigned Sections',
                    value: sectionIds.map((s) => secMap[s]?.name ?? s).join(', '),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action buttons
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcadexColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                    ),
                    icon: const Icon(LucideIcons.clipboardCheck, size: 18),
                    label: const Text('Take Attendance'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go('/attendance');
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AcadexColors.accentTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                          ),
                          icon: const Icon(LucideIcons.filePlus, size: 18),
                          label: const Text('Upload Notes'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push('/notes/new');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                          ),
                          icon: const Icon(LucideIcons.calendarDays, size: 18),
                          label: const Text('Timetable'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.go('/timetable');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AcadexColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                      ),
                      icon: const Icon(LucideIcons.clipboardCheck, size: 18),
                      label: const Text('Take Attendance'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go('/attendance');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AcadexColors.accentTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                      ),
                      icon: const Icon(LucideIcons.filePlus, size: 18),
                      label: const Text('Upload Notes'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/notes/new');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                      ),
                      icon: const Icon(LucideIcons.calendarDays, size: 18),
                      label: const Text('Timetable'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go('/timetable');
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;

  const _DetailTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AcadexTypography.caption(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AcadexTypography.body(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
