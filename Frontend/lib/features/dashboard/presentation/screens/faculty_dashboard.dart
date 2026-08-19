import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/domain/models/academic_models.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final statCols = AcadexLayout.statGridColumns(context);
        final firstName = user?.name.split(' ').first ?? 'Faculty';

        return AcadexPageContainer(
          particleSphereVariant: ParticleSphereVariant.dashboard,
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
                              style: AcadexTypography.heading2(color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(height: 6),
                          Text("Manage your assigned classes, attendance, lesson notes, and timetable.",
                              style: AcadexTypography.body(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted)),
                        ],
                      ),
                    ),
                    _RolePill(label: user?.role.displayName ?? 'Faculty'),
                  ],
                ),
                const SizedBox(height: 24),

                const SectionHeader(title: "Today's Schedule"),
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

                // My Assigned Subjects
                SectionHeader(
                  title: 'My Assigned Subjects',
                  actionLabel: 'View All Assignments',
                  onAction: () => context.push('/my-assignments'),
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          "No assigned subjects allocated yet.",
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                        ),
                      );
                    }

                    // Group assignments by subjectId
                    final Map<String, List<String>> subjectSections = {};
                    for (final a in myAssignments) {
                      subjectSections.putIfAbsent(a.subjectId, () => []).add(a.sectionId);
                    }

                    final subjectEntries = subjectSections.entries.toList();

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
                                        "${entry.value.length} Section${entry.value.length > 1 ? 's' : ''}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    sub?.name ?? 'Assigned Course',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AcadexTypography.title(color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Sections: $sectionNames",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AcadexTypography.caption(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                                  ),
                                ],
                              ),
                              const Divider(height: 1),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    tooltip: "Mark Attendance",
                                    icon: const Icon(LucideIcons.clipboardCheck, size: 16, color: AcadexColors.primary),
                                    onPressed: () => context.push('/attendance'),
                                  ),
                                  IconButton(
                                    tooltip: "Upload Notes",
                                    icon: const Icon(LucideIcons.filePlus, size: 16, color: AcadexColors.accentTeal),
                                    onPressed: () => context.push('/notes/new'),
                                  ),
                                  IconButton(
                                    tooltip: "View Timetable",
                                    icon: const Icon(LucideIcons.calendarDays, size: 16, color: AcadexColors.accentPurple),
                                    onPressed: () => context.push('/timetable'),
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

                const SectionHeader(title: 'Overview'),
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
                const SectionHeader(title: 'Quick Actions'),
                AcadexLayout.headerGap,
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: quickActions.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: width > 600 ? 4 : 2,
                    crossAxisSpacing: AcadexLayout.gridSpacing,
                    mainAxisSpacing: AcadexLayout.gridSpacing,
                    childAspectRatio: 1.2,
                  ),
                  itemBuilder: (_, i) => QuickActionCard(action: quickActions[i]),
                ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final firstAssign = assignments.isNotEmpty ? assignments.first : null;
    final dept = firstAssign != null ? deptMap[firstAssign.departmentId] : null;
    final course = firstAssign != null ? courseMap[firstAssign.courseId] : null;
    final semester = firstAssign != null ? semMap[firstAssign.semesterId] : null;

    showModalBottomSheet(
      context: context,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject?.name ?? subjectId,
                      style: AcadexTypography.heading3(color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code: ${subject?.code ?? "N/A"} • Type: ${subject?.type ?? "Theory"} • Credits: ${subject?.credits ?? 3}',
                      style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AcadexColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AcadexRadius.xs),
                  ),
                  child: Text(
                    "${assignments.length} Section${assignments.length > 1 ? 's' : ''}",
                    style: const TextStyle(color: AcadexColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Academic details grid
            Row(
              children: [
                Expanded(
                  child: _DetailTile(label: "Department", value: dept?.name ?? firstAssign?.departmentId ?? "N/A"),
                ),
                Expanded(
                  child: _DetailTile(label: "Course", value: course?.name ?? firstAssign?.courseId ?? "N/A"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DetailTile(label: "Semester", value: semester?.name ?? firstAssign?.semesterId ?? "N/A"),
                ),
                Expanded(
                  child: _DetailTile(
                    label: "Assigned Sections",
                    value: sectionIds.map((s) => secMap[s]?.name ?? s).join(', '),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action buttons
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
                    label: const Text("Take Attendance"),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/attendance');
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
                    label: const Text("Upload Notes"),
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
                    label: const Text("Timetable"),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/timetable');
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AcadexTypography.caption(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 2),
        Text(value, style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.w600)),
      ],
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
