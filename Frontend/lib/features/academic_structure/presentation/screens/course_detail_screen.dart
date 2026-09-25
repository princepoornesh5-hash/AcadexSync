import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../../../../features/auth/domain/models/auth_state.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/academic_providers.dart';
import '../../domain/models/academic_models.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  int _selectedTabIndex = 0; // 0: Semesters, 1: Sections, 2: Subjects

  void _confirmStatusToggle(
    BuildContext context,
    String courseName,
    bool isCurrentlyActive,
  ) {
    final action = isCurrentlyActive ? 'Deactivate' : 'Activate';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Course?'),
        content: Text(
          isCurrentlyActive
              ? 'Are you sure you want to deactivate $courseName? Students and semesters associated with this course may be impacted.'
              : 'Are you sure you want to activate $courseName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyActive ? AcadexColors.error : AcadexColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(coursesProvider.notifier).toggleCourseStatus(widget.courseId, !isCurrentlyActive);
                ref.invalidate(courseByIdProvider(widget.courseId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Course $action successful!'),
                      backgroundColor: AcadexColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update status: $e'),
                      backgroundColor: AcadexColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);
    final courseAsync = ref.watch(courseByIdProvider(widget.courseId));
    final deptMap = ref.watch(departmentMapProvider);
    final semesterMap = ref.watch(semesterMapProvider);
    final semesters = ref.watch(semestersByCourseProvider(widget.courseId));
    final sections = ref.watch(sectionsByCourseProvider(widget.courseId));
    final subjects = ref.watch(subjectsByCourseProvider(widget.courseId));
    final hasEnclosingScaffold = Scaffold.maybeOf(context) != null;

    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final canManage = user?.role == AppRole.superAdmin ||
        user?.role == AppRole.collegeAdmin ||
        user?.role == AppRole.hod;

    final bodyContent = courseAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.circleAlert, color: AcadexColors.error, size: 36),
            const SizedBox(height: 12),
            Text('Error loading course: $err', style: const TextStyle(color: AcadexColors.error)),
            const SizedBox(height: 12),
            AcadexButton(
              label: 'Retry',
              onPressed: () => ref.invalidate(courseByIdProvider(widget.courseId)),
            ),
          ],
        ),
      ),
      data: (course) {
        final dept = deptMap[course.departmentId];
        final deptName = dept?.name ?? (course.departmentId.isNotEmpty ? course.departmentId : 'Unassigned Department');
        final deptCode = dept?.code ?? '';

        return AcadexPageContainer(
          backgroundColor: Colors.transparent,
          maxWidth: 1080,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Header Card ──────────────────────────────────────
              _buildHeroCard(context, isDark, isMobile, course, canManage),
              const SizedBox(height: 20),

              // ── Course & Department Cards ─────────────────────────────
              if (isMobile) ...[
                _buildDetailsCard(context, isDark, course),
                const SizedBox(height: 20),
                _buildDepartmentCard(context, isDark, deptName, deptCode, dept?.id),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildDetailsCard(context, isDark, course)),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _buildDepartmentCard(context, isDark, deptName, deptCode, dept?.id)),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // ── Summary Metrics ───────────────────────────────────────
              _buildSummaryMetrics(isDark, isMobile, semesters.length, sections.length, subjects.length),
              const SizedBox(height: 24),

              // ── Downstream Curriculum Tabs ────────────────────────────
              _buildCurriculumTabs(context, isDark, isMobile, canManage, semesters, sections, subjects, semesterMap),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );

    if (hasEnclosingScaffold) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/academics/courses'),
        ),
        title: Text(
          'Course Overview',
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontSize: 18),
        ),
      ),
      body: bodyContent,
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    bool isDark,
    bool isMobile,
    Course course,
    bool canManage,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AcadexColors.primary.withValues(alpha: 0.12),
                  borderRadius: AcadexRadius.borderRadiusMd,
                ),
                child: const Icon(LucideIcons.bookOpen, color: AcadexColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: AcadexTypography.heading1(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                            borderRadius: AcadexRadius.borderRadiusSm,
                          ),
                          child: Text(
                            'CODE: ${course.code}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: course.isActive ? AcadexColors.successLight : AcadexColors.errorLight,
                            borderRadius: AcadexRadius.borderRadiusFull,
                          ),
                          child: Text(
                            course.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: course.isActive ? AcadexColors.success : AcadexColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (canManage) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AcadexButton(
                  label: 'Edit Course',
                  icon: LucideIcons.edit,
                  variant: AcadexButtonVariant.primary,
                  onPressed: () => context.push('/academics/courses/edit/${widget.courseId}'),
                ),
                AcadexButton(
                  label: course.isActive ? 'Deactivate' : 'Activate',
                  icon: course.isActive ? LucideIcons.powerOff : LucideIcons.power,
                  variant: AcadexButtonVariant.secondary,
                  onPressed: () => _confirmStatusToggle(context, course.name, course.isActive),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard(
    BuildContext context,
    bool isDark,
    Course course,
  ) {
    return AcadexCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.info, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              const SizedBox(width: 8),
              Text(
                'Degree Program Details',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(isDark, LucideIcons.tag, 'Code', course.code),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.bookOpen, 'Program Name', course.name),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.calendar, 'Duration', '${course.duration} ${course.duration == 1 ? "Year" : "Years"}'),
          const Divider(height: 16),
          _infoRow(
            isDark,
            LucideIcons.activity,
            'Status',
            course.isActive ? 'Active (Accepting enrollments & curriculum)' : 'Inactive (Archived)',
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(
    BuildContext context,
    bool isDark,
    String deptName,
    String deptCode,
    String? deptId,
  ) {
    return AcadexCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.layers, size: 16, color: AcadexColors.primary),
              const SizedBox(width: 8),
              Text(
                'Department Affiliation',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
              borderRadius: AcadexRadius.borderRadiusMd,
              border: Border.all(
                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        deptName,
                        style: AcadexTypography.body(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ).copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    if (deptCode.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AcadexColors.primary.withValues(alpha: 0.12),
                          borderRadius: AcadexRadius.borderRadiusSm,
                        ),
                        child: Text(
                          deptCode,
                          style: const TextStyle(
                            color: AcadexColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (deptId != null && deptId.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(LucideIcons.arrowUpRight, size: 14),
                    label: const Text('View Department Overview', style: TextStyle(fontSize: 12)),
                    onPressed: () => context.push('/academics/departments/$deptId'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics(
    bool isDark,
    bool isMobile,
    int semesterCount,
    int sectionCount,
    int subjectCount,
  ) {
    final metrics = [
      (
        label: 'Semesters',
        count: semesterCount,
        icon: LucideIcons.calendarDays,
        tabIndex: 0,
        color: AcadexColors.primary,
      ),
      (
        label: 'Sections',
        count: sectionCount,
        icon: LucideIcons.users,
        tabIndex: 1,
        color: AcadexColors.info,
      ),
      (
        label: 'Subjects',
        count: subjectCount,
        icon: LucideIcons.bookCheck,
        tabIndex: 2,
        color: AcadexColors.success,
      ),
    ];

    return Row(
      children: metrics.map((m) {
        final isSelected = _selectedTabIndex == m.tabIndex;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = m.tabIndex),
              borderRadius: AcadexRadius.borderRadiusMd,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? m.color.withValues(alpha: 0.18) : m.color.withValues(alpha: 0.08))
                      : (isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface),
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(
                    color: isSelected ? m.color : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: m.color.withValues(alpha: 0.12),
                        borderRadius: AcadexRadius.borderRadiusSm,
                      ),
                      child: Icon(m.icon, color: m.color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.count.toString(),
                            style: AcadexTypography.heading2(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ).copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            m.label,
                            style: AcadexTypography.caption(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCurriculumTabs(
    BuildContext context,
    bool isDark,
    bool isMobile,
    bool canManage,
    List<Semester> semesters,
    List<Section> sections,
    List<Subject> subjects,
    Map<String, Semester> semesterMap,
  ) {
    return AcadexCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tab selector bar ──────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _tabChip('Semesters (${semesters.length})', 0, LucideIcons.calendarDays, isDark),
                const SizedBox(width: 8),
                _tabChip('Sections (${sections.length})', 1, LucideIcons.users, isDark),
                const SizedBox(width: 8),
                _tabChip('Subjects (${subjects.length})', 2, LucideIcons.bookCheck, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ── Tab Content ───────────────────────────────────────────
          if (_selectedTabIndex == 0)
            _buildSemestersTab(context, isDark, canManage, semesters)
          else if (_selectedTabIndex == 1)
            _buildSectionsTab(context, isDark, canManage, sections, semesterMap)
          else
            _buildSubjectsTab(context, isDark, canManage, subjects, semesterMap),
        ],
      ),
    );
  }

  Widget _tabChip(String title, int index, IconData icon, bool isDark) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: AcadexRadius.borderRadiusFull,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AcadexColors.primary.withValues(alpha: 0.12)
              : (isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft),
          borderRadius: AcadexRadius.borderRadiusFull,
          border: Border.all(
            color: isSelected ? AcadexColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AcadexColors.primary : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AcadexColors.primary : (isDark ? AcadexColors.darkInk : AcadexColors.ink),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemestersTab(
    BuildContext context,
    bool isDark,
    bool canManage,
    List<Semester> semesters,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Configured Semesters',
              style: AcadexTypography.body(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            if (canManage)
              AcadexButton(
                label: 'Add Semester',
                icon: LucideIcons.plus,
                size: AcadexButtonSize.sm,
                variant: AcadexButtonVariant.primary,
                onPressed: () => context.push('/academics/semesters/new?courseId=${widget.courseId}'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (semesters.isEmpty)
          AcadexEmptyState(
            title: 'No Semesters Configured',
            subtitle: 'Establish semesters for this degree program to organize academic terms.',
            icon: LucideIcons.calendarDays,
            actionLabel: canManage ? 'Add First Semester' : null,
            onActionTap: canManage ? () => context.push('/academics/semesters/new?courseId=${widget.courseId}') : null,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: semesters.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final s = semesters[i];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AcadexColors.primary.withValues(alpha: 0.12),
                        borderRadius: AcadexRadius.borderRadiusSm,
                      ),
                      child: Center(
                        child: Text(
                          'S${s.number}',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AcadexColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                s.name,
                                style: AcadexTypography.body(
                                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (s.isCurrent) ...[
                                const SizedBox(width: 8),
                                const AcadexBadge(label: 'CURRENT', variant: AcadexBadgeVariant.success),
                              ],
                            ],
                          ),
                          if (s.startDate != null && s.endDate != null)
                            Text(
                              'Term: ${s.startDate} → ${s.endDate}',
                              style: AcadexTypography.caption(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.arrowRight, size: 16),
                      tooltip: 'View Semester',
                      onPressed: () => context.push('/academics/semesters/${s.id}'),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSectionsTab(
    BuildContext context,
    bool isDark,
    bool canManage,
    List<Section> sections,
    Map<String, Semester> semesterMap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Course Sections',
              style: AcadexTypography.body(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            if (canManage)
              AcadexButton(
                label: 'Add Section',
                icon: LucideIcons.plus,
                size: AcadexButtonSize.sm,
                variant: AcadexButtonVariant.primary,
                onPressed: () => context.push('/academics/sections/new?courseId=${widget.courseId}'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (sections.isEmpty)
          AcadexEmptyState(
            title: 'No Sections Established',
            subtitle: 'Create cohorts and batch divisions under this course for timetable scheduling.',
            icon: LucideIcons.users,
            actionLabel: canManage ? 'Add First Section' : null,
            onActionTap: canManage ? () => context.push('/academics/sections/new?courseId=${widget.courseId}') : null,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final sec = sections[i];
              final sem = semesterMap[sec.semesterId];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AcadexColors.info.withValues(alpha: 0.12),
                        borderRadius: AcadexRadius.borderRadiusSm,
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.users, size: 18, color: AcadexColors.info),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sec.name,
                            style: AcadexTypography.body(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              Text(
                                'Capacity: ${sec.capacity} students',
                                style: AcadexTypography.caption(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ),
                              ),
                              if (sem != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '•  ${sem.name}',
                                  style: AcadexTypography.caption(
                                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.arrowRight, size: 16),
                      tooltip: 'View Section',
                      onPressed: () => context.push('/academics/sections/${sec.id}'),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSubjectsTab(
    BuildContext context,
    bool isDark,
    bool canManage,
    List<Subject> subjects,
    Map<String, Semester> semesterMap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Curriculum Subjects',
              style: AcadexTypography.body(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            if (canManage)
              AcadexButton(
                label: 'Add Subject',
                icon: LucideIcons.plus,
                size: AcadexButtonSize.sm,
                variant: AcadexButtonVariant.primary,
                onPressed: () => context.push('/academics/subjects/new?courseId=${widget.courseId}'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (subjects.isEmpty)
          AcadexEmptyState(
            title: 'No Subjects Added',
            subtitle: 'Add syllabus subjects with course credits and types (Theory/Lab).',
            icon: LucideIcons.bookCheck,
            actionLabel: canManage ? 'Add First Subject' : null,
            onActionTap: canManage ? () => context.push('/academics/subjects/new?courseId=${widget.courseId}') : null,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final sub = subjects[i];
              final sem = semesterMap[sub.semesterId];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AcadexColors.success.withValues(alpha: 0.12),
                        borderRadius: AcadexRadius.borderRadiusSm,
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.bookCheck, size: 18, color: AcadexColors.success),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                sub.name,
                                style: AcadexTypography.body(
                                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                                  borderRadius: AcadexRadius.borderRadiusSm,
                                  border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                                ),
                                child: Text(
                                  sub.code,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '${sub.credits} Credits • ${sub.type}',
                                style: AcadexTypography.caption(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ),
                              ),
                              if (sem != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '•  ${sem.name}',
                                  style: AcadexTypography.caption(
                                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.arrowRight, size: 16),
                      tooltip: 'View Subject',
                      onPressed: () => context.push('/academics/subjects/${sub.id}'),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _infoRow(bool isDark, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
        const SizedBox(width: 10),
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ).copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AcadexTypography.body(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ).copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
