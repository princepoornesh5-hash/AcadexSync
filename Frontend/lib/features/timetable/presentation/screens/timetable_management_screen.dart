import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/domain/models/academic_models.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_providers.dart';
import '../providers/timetable_lookup_providers.dart';
import '../widgets/timetable_widgets.dart';
import '../widgets/timetable_class_editor_dialog.dart';
import '../widgets/teacher_substitution_dialog.dart';
import 'timetable_setup_screen.dart';
import 'timetable_designer_screen.dart';

class TimetableFilterState {
  final String? departmentId;
  final String? courseId;
  final String? academicYearId;
  final String? semesterId;
  final String? sectionId;
  final TimetableDay? day;
  final TimetableStatus? status;
  final String searchQuery;

  TimetableFilterState({
    this.departmentId,
    this.courseId,
    this.academicYearId,
    this.semesterId,
    this.sectionId,
    this.day,
    this.status,
    this.searchQuery = '',
  });

  TimetableFilterState copyWith({
    String? departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    TimetableDay? day,
    bool clearDay = false,
    TimetableStatus? status,
    bool clearStatus = false,
    String? searchQuery,
    bool clearDepartment = false,
    bool clearCourse = false,
    bool clearAcademicYear = false,
    bool clearSemester = false,
    bool clearSection = false,
  }) {
    return TimetableFilterState(
      departmentId: clearDepartment ? null : (departmentId ?? this.departmentId),
      courseId: clearCourse ? null : (courseId ?? this.courseId),
      academicYearId: clearAcademicYear ? null : (academicYearId ?? this.academicYearId),
      semesterId: clearSemester ? null : (semesterId ?? this.semesterId),
      sectionId: clearSection ? null : (sectionId ?? this.sectionId),
      day: clearDay ? null : (day ?? this.day),
      status: clearStatus ? null : (status ?? this.status),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasActiveFilters =>
      departmentId != null ||
      courseId != null ||
      academicYearId != null ||
      semesterId != null ||
      sectionId != null ||
      day != null ||
      status != null ||
      searchQuery.isNotEmpty;
}

final timetableFilterProvider = StateProvider<TimetableFilterState>((ref) => TimetableFilterState());

final managementContainersProvider = FutureProvider.autoDispose<List<TimetableContainerModel>>((ref) async {
  final filters = ref.watch(timetableFilterProvider);
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];

  final user = authState.user;
  final repo = ref.watch(timetableRepositoryProvider);

  final deptId = (user.role == AppRole.hod) ? user.departmentId : filters.departmentId;

  final containers = await repo.getTimetableContainers(
    collegeId: user.collegeId ?? '',
    departmentId: deptId,
    courseId: filters.courseId,
    academicYearId: filters.academicYearId,
    semesterId: filters.semesterId,
    sectionId: filters.sectionId,
    status: filters.status,
  );

  if (filters.searchQuery.trim().isEmpty) return containers;

  final query = filters.searchQuery.trim().toLowerCase();
  return containers.where((c) {
    return c.name.toLowerCase().contains(query);
  }).toList();
});

final managementTimetableProvider = FutureProvider<List<TimetableModel>>((ref) async {
  final filters = ref.watch(timetableFilterProvider);
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];

  final user = authState.user;
  final repo = ref.watch(timetableRepositoryProvider);

  // HOD implicitly filters by their own department if they are HOD
  final deptId = (user.role == AppRole.hod) ? user.departmentId : filters.departmentId;

  final entries = await repo.getTimetable(
    collegeId: user.collegeId ?? '',
    departmentId: deptId,
    courseId: filters.courseId,
    semesterId: filters.semesterId,
    sectionId: filters.sectionId,
  );

  var filtered = entries;
  if (filters.day != null) {
    filtered = filtered.where((e) => e.dayOfWeek == filters.day).toList();
  }

  // Local case-insensitive search matching subject, code, faculty, room, building, section
  if (filters.searchQuery.trim().isNotEmpty) {
    final query = filters.searchQuery.trim().toLowerCase();
    final subjectMap = ref.read(timetableSubjectMapProvider);
    final facultyMap = ref.read(timetableFacultyMapProvider);
    final sectionMap = ref.read(timetableSectionMapProvider);

    filtered = filtered.where((e) {
      final subject = subjectMap[e.subjectId];
      final faculty = facultyMap[e.facultyId];
      final section = sectionMap[e.sectionId];

      final subjectMatch = subject != null && (subject.name.toLowerCase().contains(query) || subject.code.toLowerCase().contains(query));
      final facultyMatch = faculty != null && faculty.name.toLowerCase().contains(query);
      final sectionMatch = section != null && section.name.toLowerCase().contains(query);
      final roomMatch = e.roomNumber.toLowerCase().contains(query) || (e.building?.toLowerCase().contains(query) ?? false);
      final rawIdMatch = e.subjectId.toLowerCase().contains(query) || e.facultyId.toLowerCase().contains(query);

      return subjectMatch || facultyMatch || sectionMatch || roomMatch || rawIdMatch;
    }).toList();
  }

  // Sort by day, then time
  filtered.sort((a, b) {
    int dayCmp = a.dayOfWeek.index.compareTo(b.dayOfWeek.index);
    if (dayCmp != 0) return dayCmp;
    return a.startTime.compareTo(b.startTime);
  });

  return filtered;
});

class TimetableManagementScreen extends ConsumerStatefulWidget {
  const TimetableManagementScreen({super.key});

  @override
  ConsumerState<TimetableManagementScreen> createState() => _TimetableManagementScreenState();
}

class _TimetableManagementScreenState extends ConsumerState<TimetableManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _substitutionSelectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final user = authState.user;
    if (user.role != AppRole.superAdmin && user.role != AppRole.collegeAdmin && user.role != AppRole.hod) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unauthorized')),
        body: const Center(child: Text('Unauthorized: Only administrators and HODs can manage timetables.')),
      );
    }

    final canCreate = user.role == AppRole.collegeAdmin || user.role == AppRole.hod;
    final filters = ref.watch(timetableFilterProvider);
    final isGradientRole = user.role == AppRole.superAdmin ||
        user.role == AppRole.collegeAdmin ||
        user.role == AppRole.hod;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                // Header with Create Timetable Action
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 8 : 16),
                  child: AcadexPageHeader(
                    title: 'Manage Timetable',
                    subtitle: isMobile ? null : 'Create master timetable containers, configure periods & breaks, and manage live published schedules.',
                    actions: [
                      if (canCreate) ...[
                        AcadexButton(
                          label: 'Add Schedule',
                          icon: LucideIcons.calendarPlus,
                          variant: AcadexButtonVariant.secondary,
                          size: isMobile ? AcadexButtonSize.sm : AcadexButtonSize.md,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TimetableSetupScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        AcadexButton(
                          label: 'Create Timetable',
                          icon: LucideIcons.sparkles,
                          variant: AcadexButtonVariant.primary,
                          size: isMobile ? AcadexButtonSize.sm : AcadexButtonSize.md,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TimetableSetupScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                // Top View Switcher (Master Timetable Containers vs Class Slots)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AcadexColors.darkCanvasSoft : (isGradientRole ? AcadexColors.surface : AcadexColors.canvasSoft),
                      borderRadius: AcadexRadius.borderRadiusSm,
                      border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: isGradientRole ? const Color(0xFF003366) : AcadexColors.primary,
                        borderRadius: AcadexRadius.borderRadiusSm,
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark ? AcadexColors.darkInkMuted : (isGradientRole ? const Color(0xFF475569) : AcadexColors.inkMuted),
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.calendarRange, size: 16),
                              SizedBox(width: 8),
                              Text('Master Timetables'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.list, size: 16),
                              SizedBox(width: 8),
                              Text('Class Slots'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.swap_horiz_rounded, size: 16),
                              SizedBox(width: 8),
                              Text('Substitutions'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Responsive Filter Toolbar
                _buildFilterBar(context, ref, user.role, filters),

                // Tab Content Views or Section Authoring
                Expanded(
                  child: filters.sectionId != null && filters.courseId != null && filters.semesterId != null
                      ? _buildSectionAuthoringView(
                          context: context,
                          ref: ref,
                          filters: filters,
                          isDark: isDark,
                          isMobile: isMobile,
                          canCreate: canCreate,
                          userId: user.id,
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            // TAB 1: MASTER TIMETABLE CONTAINERS
                            _buildContainersTab(context, ref, isDark, isMobile, canCreate),

                            // TAB 2: INDIVIDUAL CLASS SLOTS
                            _buildLegacySlotsTab(context, ref, isDark, isMobile, filters),

                            // TAB 3: TEACHER SUBSTITUTIONS
                            _buildSubstitutionsTab(context, ref, isDark, isMobile, user),
                          ],
                        ),
                ),
              ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1: MASTER TIMETABLE CONTAINERS (DRAFT, PUBLISHED, ARCHIVED)
  // =========================================================================
  Widget _buildContainersTab(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    bool isMobile,
    bool canCreate,
  ) {
    final containersAsync = ref.watch(managementContainersProvider);
    final deptMap = ref.watch(timetableDepartmentMapProvider);
    final courseMap = ref.watch(timetableCourseMapProvider);
    final sectionMap = ref.watch(timetableSectionMapProvider);

    return containersAsync.when(
      loading: () => const AcadexLoadingState(message: 'Loading timetables...'),
      error: (e, st) => AcadexErrorState(
        message: 'Failed to load timetables: $e',
        onRetry: () => ref.refresh(managementContainersProvider),
      ),
      data: (containers) {
        if (containers.isEmpty) {
          return Center(
            child: AcadexEmptyState(
              title: 'No Timetables Found',
              subtitle: canCreate
                  ? 'Click "Create Timetable" to start your first master timetable container.'
                  : 'No timetable containers have been published for your scope yet.',
              icon: LucideIcons.calendarX,
              actionLabel: canCreate ? 'Create Timetable' : null,
              onActionTap: canCreate
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TimetableSetupScreen(),
                        ),
                      );
                    }
                  : null,
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          itemCount: containers.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
          itemBuilder: (ctx, index) {
            final container = containers[index];
            final deptName = deptMap[container.departmentId]?.name ?? container.departmentId;
            final courseName = courseMap[container.courseId]?.name ?? container.courseId;
            final sectionName = sectionMap[container.sectionId]?.name ?? container.sectionId;

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                borderRadius: AcadexRadius.borderRadiusLg,
                border: Border.all(
                  color: container.status == TimetableStatus.published
                      ? AcadexColors.success.withValues(alpha: 0.4)
                      : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                ),
                boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status Badge & Version
                      Row(
                        children: [
                          _buildStatusBadge(container.status, isDark),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                              borderRadius: AcadexRadius.borderRadiusXs,
                            ),
                            child: Text(
                              'v${container.version}',
                              style: AcadexTypography.caption(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),

                      // Timing Mode Tag
                      Text(
                        '${container.activeDays.length} Active Days • ${container.timingMode.displayName}',
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Container Title
                  Text(
                    container.name,
                    style: AcadexTypography.heading3(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Academic Context Breadcrumb
                  Text(
                    '$deptName • $courseName • Sem ${container.semesterId} • Section $sectionName',
                    style: AcadexTypography.bodySmall(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),

                  const SizedBox(height: 16),
                  Divider(height: 1, color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                  const SizedBox(height: 14),

                  // Context-Specific Actions based on Status
                  _buildContainerActions(context, ref, container, isDark),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(TimetableStatus status, bool isDark) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case TimetableStatus.published:
        bg = isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight;
        fg = isDark ? Colors.green.shade200 : AcadexColors.success;
        label = 'PUBLISHED';
        break;
      case TimetableStatus.draft:
        bg = isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight;
        fg = isDark ? Colors.amber.shade200 : AcadexColors.warningDark;
        label = 'DRAFT';
        break;
      case TimetableStatus.archived:
        bg = isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft;
        fg = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;
        label = 'ARCHIVED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AcadexRadius.borderRadiusXs,
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildContainerActions(
    BuildContext context,
    WidgetRef ref,
    TimetableContainerModel container,
    bool isDark,
  ) {
    if (container.status == TimetableStatus.draft) {
      return Align(
        alignment: Alignment.centerRight,
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: () => _confirmDeleteContainer(context, ref, container),
              icon: const Icon(LucideIcons.trash2, size: 16, color: AcadexColors.error),
              label: const Text('Delete', style: TextStyle(color: AcadexColors.error)),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final repo = ref.read(timetableRepositoryProvider);
                  await repo.publishTimetable(container.id, publishedBy: 'user');
                  ref.invalidate(managementContainersProvider);
                  ref.invalidate(managementTimetableProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Timetable published to live schedule!'), backgroundColor: AcadexColors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Cannot publish: $e'), backgroundColor: AcadexColors.error),
                    );
                  }
                }
              },
              icon: const Icon(LucideIcons.send, size: 16),
              label: const Text('Publish'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TimetableDesignerScreen(timetableId: container.id),
                  ),
                );
              },
              icon: const Icon(LucideIcons.edit3, size: 16, color: Colors.white),
              label: const Text('Continue Editing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
            ),
          ],
        ),
      );
    } else if (container.status == TimetableStatus.published) {
      return Align(
        alignment: Alignment.centerRight,
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: () async {
                final repo = ref.read(timetableRepositoryProvider);
                await repo.unpublishTimetable(container.id);
                ref.invalidate(managementContainersProvider);
                ref.invalidate(managementTimetableProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Timetable unpublished.'), backgroundColor: AcadexColors.warning),
                  );
                }
              },
              icon: const Icon(LucideIcons.archive, size: 16),
              label: const Text('Unpublish'),
            ),
            OutlinedButton.icon(
              onPressed: () => _handleCreateDraftOrEditVersion(context, ref, container),
              icon: const Icon(LucideIcons.copy, size: 16),
              label: const Text('Edit Draft / New Version'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TimetableDesignerScreen(timetableId: container.id),
                  ),
                );
              },
              icon: const Icon(LucideIcons.eye, size: 16, color: Colors.white),
              label: const Text('View Designer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
            ),
          ],
        ),
      );
    } else {
      return Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TimetableDesignerScreen(timetableId: container.id),
              ),
            );
          },
          icon: const Icon(LucideIcons.eye, size: 16, color: Colors.white),
          label: const Text('View Archived', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
        ),
      );
    }
  }

  Future<void> _handleCreateDraftOrEditVersion(
    BuildContext context,
    WidgetRef ref,
    TimetableContainerModel container,
  ) async {
    final repo = ref.read(timetableRepositoryProvider);

    // Check if an existing draft exists
    final existingDrafts = await repo.getTimetableContainers(
      collegeId: container.collegeId,
      departmentId: container.departmentId,
      courseId: container.courseId,
      semesterId: container.semesterId,
      sectionId: container.sectionId,
      status: TimetableStatus.draft,
    );

    if (existingDrafts.isNotEmpty) {
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TimetableDesignerScreen(timetableId: existingDrafts.first.id),
          ),
        );
      }
      return;
    }

    // Clone into new draft version
    final newDraft = container.copyWith(
      id: '',
      version: container.version + 1,
      status: TimetableStatus.draft,
      name: '${container.name} (v${container.version + 1} Draft)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final newServerId = await repo.createTimetableContainer(newDraft);
    if (newServerId.trim().isEmpty) {
      throw Exception('Server returned an empty or invalid timetable ID.');
    }

    final periods = await repo.getPeriods(container.id);
    if (periods.isNotEmpty) {
      await repo.savePeriodsBatch(newServerId, periods.map((p) => p.copyWith(id: const Uuid().v4())).toList());
    }

    final breaks = await repo.getBreaks(container.id);
    if (breaks.isNotEmpty) {
      await repo.saveBreaksBatch(newServerId, breaks.map((b) => b.copyWith(id: const Uuid().v4())).toList());
    }

    final entries = await repo.getGridEntries(container.id);
    if (entries.isNotEmpty) {
      await repo.saveGridEntriesBatch(newServerId, entries.map((e) => e.copyWith(id: const Uuid().v4())).toList());
    }

    ref.invalidate(managementContainersProvider);

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TimetableDesignerScreen(timetableId: newServerId),
        ),
      );
    }
  }

  void _confirmDeleteContainer(
    BuildContext context,
    WidgetRef ref,
    TimetableContainerModel container,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Timetable Draft?'),
        content: Text('Are you sure you want to delete "${container.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final repo = ref.read(timetableRepositoryProvider);
              try {
                await repo.deleteTimetableContainer(container.id);
                ref.invalidate(managementContainersProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Timetable draft deleted.'), backgroundColor: AcadexColors.error),
                  );
                }
              } catch (e) {
                final errorMsg = e.toString().replaceFirst('Exception: ', '');
                if (errorMsg.contains('attendance') || errorMsg.contains('archive') || errorMsg.contains('Cannot delete timetable with existing attendance')) {
                  if (context.mounted) {
                    showDialog<void>(
                      context: context,
                      builder: (alertCtx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusLg),
                        title: const Row(
                          children: [
                            Icon(LucideIcons.alertTriangle, color: AcadexColors.warning, size: 22),
                            SizedBox(width: 8),
                            Text('Cannot Delete Timetable'),
                          ],
                        ),
                        content: const Text(
                          'Attendance history exists for this timetable. It cannot be permanently deleted. Please archive the timetable instead.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(alertCtx).pop(),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(LucideIcons.archive, size: 16),
                            label: const Text('Archive Timetable'),
                            style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary, foregroundColor: Colors.white),
                            onPressed: () async {
                              Navigator.of(alertCtx).pop();
                              try {
                                await repo.archiveTimetableContainer(container.id);
                                ref.invalidate(managementContainersProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Timetable successfully archived.'), backgroundColor: AcadexColors.success),
                                  );
                                }
                              } catch (archiveErr) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(archiveErr.toString().replaceFirst('Exception: ', '')), backgroundColor: AcadexColors.error),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMsg), backgroundColor: AcadexColors.error),
                    );
                  }
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: LEGACY LIVE CLASS SLOTS LIST
  // =========================================================================
  Widget _buildLegacySlotsTab(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    bool isMobile,
    TimetableFilterState filters,
  ) {
    final timetableAsync = ref.watch(managementTimetableProvider);

    return AnimatedSwitcher(
      duration: AcadexMotion.resolveDuration(context, AcadexMotion.fast),
      switchInCurve: AcadexMotion.curveStandard,
      switchOutCurve: AcadexMotion.curveStandard,
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: timetableAsync.when(
        loading: () => const AcadexLoadingState(key: ValueKey('mgt_loading'), message: 'Loading schedule entries...'),
        error: (e, st) => AcadexErrorState(
          key: const ValueKey('mgt_error'),
          message: 'Failed to load schedule entries: $e',
          onRetry: () => ref.refresh(managementTimetableProvider),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              key: const ValueKey('mgt_empty'),
              child: AcadexEmptyState(
                title: filters.hasActiveFilters ? 'No matching schedules found' : 'No timetable entries found',
                subtitle: filters.hasActiveFilters
                    ? 'Try adjusting your filters or search query.'
                    : 'Click "Add Schedule" or "Create Timetable" to create timetable schedules.',
                icon: LucideIcons.calendarX,
                actionLabel: filters.hasActiveFilters ? 'Clear All Filters' : null,
                onActionTap: filters.hasActiveFilters
                    ? () => ref.read(timetableFilterProvider.notifier).state = TimetableFilterState()
                    : null,
              ),
            );
          }

          final authState = ref.watch(authProvider);
          final userRole = authState is AuthAuthenticated ? authState.user.role : null;
          final isHodOrAdmin = userRole == AppRole.hod || userRole == AppRole.collegeAdmin || userRole == AppRole.superAdmin;

          return ListView.builder(
            key: ValueKey('mgt_list_${entries.length}_${filters.day?.name ?? 'all'}'),
            padding: const EdgeInsets.all(20),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return TimetableManagementCard(
                entry: entry,
                onEdit: () {
                  if (entry.timetableId != null && entry.timetableId!.isNotEmpty) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TimetableDesignerScreen(timetableId: entry.timetableId!),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TimetableSetupScreen(),
                      ),
                    );
                  }
                },
                onDuplicate: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TimetableSetupScreen(),
                    ),
                  );
                },
                onSubstitute: isHodOrAdmin && entry.timetableId != null && entry.timetableId!.isNotEmpty
                    ? () {
                        TeacherSubstitutionDialog.show(
                          context,
                          timetableId: entry.timetableId!,
                          timetableEntryId: entry.id,
                          dayOfWeek: entry.dayOfWeek,
                          startTime: entry.startTime,
                          endTime: entry.endTime,
                          subjectId: entry.subjectId,
                          originalFacultyId: entry.facultyId,
                          sectionId: entry.sectionId,
                          roomNumber: entry.roomNumber,
                        );
                      }
                    : null,
                onDelete: () => _confirmDeleteSlot(context, ref, entry),
              );
            },
          );
        },
      ),
    );
  }

  // =========================================================================
  // TAB 3: TEACHER SUBSTITUTIONS
  // =========================================================================
  Widget _buildSubstitutionsTab(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    bool isMobile,
    dynamic user,
  ) {
    final y = _substitutionSelectedDate.year.toString().padLeft(4, '0');
    final m = _substitutionSelectedDate.month.toString().padLeft(2, '0');
    final d = _substitutionSelectedDate.day.toString().padLeft(2, '0');
    final dateStr = '$y-$m-$d';

    final deptId = user.role == AppRole.hod ? user.departmentId as String? : null;
    final query = TeacherSubstitutionsQuery(date: dateStr, departmentId: deptId);
    final subsAsync = ref.watch(teacherSubstitutionsProvider(query));

    final facultyMap = ref.watch(timetableFacultyMapProvider);
    final sectionMap = ref.watch(timetableSectionMapProvider);

    return Column(
      children: [
        // Date Selector Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AcadexRadius.borderRadiusMd,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.event, size: 18, color: AcadexColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Active Substitutions for $dateStr',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 14),
                label: const Text('Change Date'),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _substitutionSelectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 60)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _substitutionSelectedDate = picked;
                    });
                  }
                },
              ),
            ],
          ),
        ),

        // List or Empty
        Expanded(
          child: subsAsync.when(
            loading: () => const AcadexLoadingState(key: ValueKey('subs_loading'), message: 'Loading substitutions...'),
            error: (e, _) => AcadexErrorState(
              key: const ValueKey('subs_error'),
              message: 'Failed to load substitutions: $e',
              onRetry: () => ref.refresh(teacherSubstitutionsProvider(query)),
            ),
            data: (subs) {
              if (subs.isEmpty) {
                return Center(
                  key: const ValueKey('subs_empty'),
                  child: AcadexEmptyState(
                    title: 'No substitutions on this date',
                    subtitle: 'To assign a teacher substitute, go to the "Class Slots" tab and click the Substitute icon on any class slot.',
                    icon: Icons.swap_horiz_rounded,
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: subs.length,
                itemBuilder: (ctx, index) {
                  final sub = subs[index];
                  final origFac = facultyMap[sub.originalFacultyId];
                  final subFac = facultyMap[sub.substituteFacultyId];
                  final section = sectionMap[sub.sectionId];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AcadexColors.primary.withValues(alpha: 0.1),
                                  borderRadius: AcadexRadius.borderRadiusSm,
                                ),
                                child: Text(
                                  sub.date,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AcadexColors.primary),
                                ),
                              ),
                              if (section != null)
                                Text('Section ${section.name}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Original Faculty', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(origFac?.name ?? sub.originalFacultyId, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.grey),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Substitute Faculty', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(subFac?.name ?? sub.substituteFacultyId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AcadexColors.primary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Reason: ${sub.reason}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // FILTER BAR
  // =========================================================================
  Widget _buildFilterBar(BuildContext context, WidgetRef ref, AppRole role, TimetableFilterState filters) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by subject, faculty, room or section...',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              suffixIcon: filters.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () => ref.read(timetableFilterProvider.notifier).state = filters.copyWith(searchQuery: ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: AcadexRadius.borderRadiusMd),
              isDense: true,
            ),
            onChanged: (val) {
              ref.read(timetableFilterProvider.notifier).state = filters.copyWith(searchQuery: val);
            },
          ),
          const SizedBox(height: 12),

          // Dropdowns & Status Filters (Horizontally scrollable for responsiveness)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Status Dropdown
                DropdownButton<TimetableStatus?>(
                  value: filters.status,
                  hint: const Text('All Statuses'),
                  isDense: true,
                  items: const [
                    DropdownMenuItem<TimetableStatus?>(value: null, child: Text('All Statuses', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: TimetableStatus.draft, child: Text('Draft', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: TimetableStatus.published, child: Text('Published', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: TimetableStatus.archived, child: Text('Archived', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) {
                    ref.read(timetableFilterProvider.notifier).state = filters.copyWith(status: val, clearStatus: val == null);
                  },
                ),
                const SizedBox(width: 12),

                // Day Dropdown
                DropdownButton<TimetableDay?>(
                  value: filters.day,
                  hint: const Text('All Days'),
                  isDense: true,
                  items: [
                    const DropdownMenuItem<TimetableDay?>(value: null, child: Text('All Days', overflow: TextOverflow.ellipsis)),
                    ...TimetableDay.values.map((d) => DropdownMenuItem(value: d, child: Text(d.displayName, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (val) {
                    ref.read(timetableFilterProvider.notifier).state = filters.copyWith(day: val, clearDay: val == null);
                  },
                ),
                const SizedBox(width: 12),

                // Department Dropdown
                if (role != AppRole.hod) ...[
                  Consumer(
                    builder: (context, ref, _) {
                      final deptsAsync = ref.watch(departmentsProvider);
                      return deptsAsync.maybeWhen(
                        data: (depts) => DropdownButton<String?>(
                          value: filters.departmentId,
                          hint: const Text('All Departments'),
                          isDense: true,
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('All Departments', overflow: TextOverflow.ellipsis)),
                            ...depts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name.isNotEmpty ? d.name : d.code, overflow: TextOverflow.ellipsis))),
                          ],
                          onChanged: (val) {
                            ref.read(timetableFilterProvider.notifier).state = filters.copyWith(departmentId: val);
                          },
                        ),
                        orElse: () => const SizedBox.shrink(),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                ],

                // Course Dropdown
                Consumer(
                  builder: (context, ref, _) {
                    final coursesAsync = ref.watch(coursesProvider);
                    return coursesAsync.maybeWhen(
                      data: (courses) => DropdownButton<String?>(
                        value: filters.courseId,
                        hint: const Text('All Courses'),
                        isDense: true,
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('All Courses', overflow: TextOverflow.ellipsis)),
                          ...courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name.isNotEmpty ? c.name : c.code, overflow: TextOverflow.ellipsis))),
                        ],
                        onChanged: (val) {
                          ref.read(timetableFilterProvider.notifier).state = filters.copyWith(
                            courseId: val,
                            clearCourse: val == null,
                            clearSemester: true,
                            clearSection: true,
                          );
                        },
                      ),
                      orElse: () => const SizedBox.shrink(),
                    );
                  },
                ),
                const SizedBox(width: 12),

                // Academic Year Dropdown
                Consumer(
                  builder: (context, ref, _) {
                    final yearsAsync = ref.watch(academicYearsProvider);
                    return yearsAsync.maybeWhen(
                      data: (years) => DropdownButton<String?>(
                        value: filters.academicYearId,
                        hint: const Text('All Academic Years'),
                        isDense: true,
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('All Academic Years', overflow: TextOverflow.ellipsis)),
                          ...years.map((y) => DropdownMenuItem(value: y.id, child: Text(y.name, overflow: TextOverflow.ellipsis))),
                        ],
                        onChanged: (val) {
                          ref.read(timetableFilterProvider.notifier).state = filters.copyWith(
                            academicYearId: val,
                            clearAcademicYear: val == null,
                          );
                        },
                      ),
                      orElse: () => const SizedBox.shrink(),
                    );
                  },
                ),
                const SizedBox(width: 12),

                // Semester Dropdown (Cascading from Course)
                Consumer(
                  builder: (context, ref, _) {
                    final semsAsync = ref.watch(semestersProvider);
                    return semsAsync.maybeWhen(
                      data: (sems) {
                        final filteredSems = filters.courseId != null
                            ? sems.where((s) => s.courseId == filters.courseId).toList()
                            : sems;
                        return DropdownButton<String?>(
                          value: filters.semesterId != null && filteredSems.any((s) => s.id == filters.semesterId)
                              ? filters.semesterId
                              : null,
                          hint: const Text('All Semesters'),
                          isDense: true,
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('All Semesters', overflow: TextOverflow.ellipsis)),
                            ...filteredSems.map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name.isNotEmpty ? s.name : 'Semester ${s.number}', overflow: TextOverflow.ellipsis),
                                )),
                          ],
                          onChanged: (val) {
                            ref.read(timetableFilterProvider.notifier).state = filters.copyWith(
                              semesterId: val,
                              clearSemester: val == null,
                              clearSection: true,
                            );
                          },
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    );
                  },
                ),
                const SizedBox(width: 12),

                // Section Dropdown (Cascading from Semester)
                Consumer(
                  builder: (context, ref, _) {
                    final sectionsAsync = ref.watch(sectionsProvider);
                    return sectionsAsync.maybeWhen(
                      data: (sections) {
                        final filteredSections = filters.semesterId != null
                            ? sections.where((s) => s.semesterId == filters.semesterId).toList()
                            : sections;
                        return DropdownButton<String?>(
                          value: filters.sectionId != null && filteredSections.any((s) => s.id == filters.sectionId)
                              ? filters.sectionId
                              : null,
                          hint: const Text('All Sections'),
                          isDense: true,
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('All Sections', overflow: TextOverflow.ellipsis)),
                            ...filteredSections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))),
                          ],
                          onChanged: (val) {
                            ref.read(timetableFilterProvider.notifier).state = filters.copyWith(
                              sectionId: val,
                              clearSection: val == null,
                            );
                          },
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    );
                  },
                ),

                // Clear Filter Button
                if (filters.hasActiveFilters) ...[
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () => ref.read(timetableFilterProvider.notifier).state = TimetableFilterState(),
                    icon: const Icon(LucideIcons.x, size: 14),
                    label: const Text('Clear Filters'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SECTION-FIRST TIMETABLE AUTHORING VIEW (HOD PROMPT 4 WORKFLOW)
  // =========================================================================
  Widget _buildSectionAuthoringView({
    required BuildContext context,
    required WidgetRef ref,
    required TimetableFilterState filters,
    required bool isDark,
    required bool isMobile,
    required bool canCreate,
    required String userId,
  }) {
    final containersAsync = ref.watch(managementContainersProvider);
    final subjectMap = ref.watch(timetableSubjectMapProvider);
    final facultyMap = ref.watch(timetableFacultyMapProvider);
    final sectionMap = ref.watch(timetableSectionMapProvider);
    final courseMap = ref.watch(timetableCourseMapProvider);
    final semMap = ref.watch(timetableSemesterMapProvider);

    final sectionName = sectionMap[filters.sectionId]?.name ?? filters.sectionId ?? '';
    final courseName = courseMap[filters.courseId]?.name ?? filters.courseId ?? '';
    final semName = semMap[filters.semesterId]?.name ?? 'Semester ${filters.semesterId}';

    return containersAsync.when(
      loading: () => const AcadexLoadingState(message: 'Loading timetable context...'),
      error: (e, st) => AcadexErrorState(
        message: 'Failed to load timetable: $e',
        onRetry: () => ref.refresh(managementContainersProvider),
      ),
      data: (containers) {
        final sectionContainer = containers.where((c) => c.sectionId == filters.sectionId).firstOrNull;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HOD READINESS CARD
              HodTimetableReadinessCard(
                courseId: filters.courseId!,
                academicYearId: filters.academicYearId,
                semesterId: filters.semesterId!,
                sectionId: filters.sectionId!,
              ),
              const SizedBox(height: 16),

              // 2. CONTAINER STATUS & CONTROLS
              if (sectionContainer == null) ...[
                // NO CONTAINER YET
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                    borderRadius: AcadexRadius.borderRadiusLg,
                    border: Border.all(
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.calendarClock, size: 40, color: AcadexColors.primary),
                      const SizedBox(height: 12),
                      Text(
                        'No Timetable Container Found',
                        style: AcadexTypography.heading3(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create a timetable container for $courseName • $semName • Section $sectionName to schedule periods and publish.',
                        textAlign: TextAlign.center,
                        style: AcadexTypography.bodySmall(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (canCreate)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TimetableSetupScreen(
                                  initialContainer: TimetableContainerModel(
                                    id: const Uuid().v4(),
                                    collegeId: '',
                                    departmentId: '',
                                    courseId: filters.courseId!,
                                    academicYearId: filters.academicYearId ?? '',
                                    semesterId: filters.semesterId!,
                                    sectionId: filters.sectionId!,
                                    name: '$courseName - $semName - Sec $sectionName',
                                    activeDays: [
                                      TimetableDay.monday,
                                      TimetableDay.tuesday,
                                      TimetableDay.wednesday,
                                      TimetableDay.thursday,
                                      TimetableDay.friday,
                                    ],
                                    status: TimetableStatus.draft,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                          label: const Text('Create Timetable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AcadexColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusSm),
                          ),
                        ),
                    ],
                  ),
                ),
              ] else ...[
                // CONTAINER EXISTS: SHOW REAL-TIME AUTHORING STATE
                Consumer(
                  builder: (ctx, ref, _) {
                    final authoringState = ref.watch(timetableAuthoringProvider(sectionContainer.id));
                    final isDraft = sectionContainer.status == TimetableStatus.draft;
                    final isPublished = sectionContainer.status == TimetableStatus.published;
                    final entries = authoringState.entries;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Container Control Bar
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                            borderRadius: AcadexRadius.borderRadiusLg,
                            border: Border.all(
                              color: isPublished
                                  ? AcadexColors.success.withValues(alpha: 0.5)
                                  : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                            ),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildStatusBadge(sectionContainer.status, isDark),
                                      const SizedBox(width: 8),
                                      Text(
                                        'v${sectionContainer.version}',
                                        style: AcadexTypography.caption(
                                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                        ).copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    sectionContainer.name,
                                    style: AcadexTypography.heading3(
                                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (isDraft && canCreate) ...[
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        showTimetableClassEditorDialog(
                                          context: context,
                                          timetableId: sectionContainer.id,
                                          day: TimetableDay.monday,
                                          startPeriodIndex: 1,
                                        );
                                      },
                                      icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                                      label: const Text('Add Class', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AcadexColors.primary,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusSm),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _handlePublish(context, ref, sectionContainer, userId),
                                      icon: const Icon(LucideIcons.send, size: 16, color: Colors.white),
                                      label: const Text('Publish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AcadexColors.success,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusSm),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => TimetableDesignerScreen(timetableId: sectionContainer.id),
                                          ),
                                        );
                                      },
                                      icon: const Icon(LucideIcons.layoutGrid, size: 16),
                                      label: const Text('Weekly Grid'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusSm),
                                      ),
                                    ),
                                  ],
                                  if (isPublished && canCreate) ...[
                                    OutlinedButton.icon(
                                      onPressed: () => _handleUnpublish(context, ref, sectionContainer),
                                      icon: const Icon(LucideIcons.archive, size: 16, color: AcadexColors.warningDark),
                                      label: Text('Unpublish', style: TextStyle(color: isDark ? Colors.amber.shade200 : AcadexColors.warningDark)),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: isDark ? Colors.amber.shade400 : AcadexColors.warning),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusSm),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => _handleCreateDraftOrEditVersion(context, ref, sectionContainer),
                                      icon: const Icon(LucideIcons.copy, size: 16),
                                      label: const Text('Edit Version'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusSm),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => TimetableDesignerScreen(timetableId: sectionContainer.id),
                                          ),
                                        );
                                      },
                                      icon: const Icon(LucideIcons.eye, size: 16, color: Colors.white),
                                      label: const Text('View Grid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AcadexColors.primary,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusSm),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Chronological Daily Class Cards (Section 21 Mobile Management UI)
                        Text(
                          'Schedule Entries (${entries.length})',
                          style: AcadexTypography.heading3(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (entries.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                              borderRadius: AcadexRadius.borderRadiusMd,
                              border: Border.all(
                                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.calendar, size: 36, color: AcadexColors.primary.withValues(alpha: 0.6)),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No Classes Scheduled Yet',
                                    style: AcadexTypography.body(
                                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap "+ Add Class" to schedule teaching periods for this section.',
                                    style: AcadexTypography.caption(
                                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          // Render Day by Day Chronologically
                          ...TimetableDay.values.map((day) {
                            final dayEntries = entries.where((e) => e.dayOfWeek == day).toList()
                              ..sort((a, b) => a.startTime.compareTo(b.startTime));

                            if (dayEntries.isEmpty) return const SizedBox.shrink();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                borderRadius: AcadexRadius.borderRadiusMd,
                                border: Border.all(
                                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Day Subheader
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          day.displayName.toUpperCase(),
                                          style: AcadexTypography.caption(
                                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                          ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8),
                                        ),
                                        Text(
                                          '${dayEntries.length} class${dayEntries.length > 1 ? 'es' : ''}',
                                          style: AcadexTypography.caption(
                                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // List of Classes
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: dayEntries.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                    ),
                                    itemBuilder: (ctx, idx) {
                                      final e = dayEntries[idx];
                                      final sub = subjectMap[e.subjectId];
                                      final subName = sub?.name ?? e.subjectId;
                                      final subCode = sub?.code ?? '';
                                      final facName = facultyMap[e.facultyId]?.name ?? e.facultyId;

                                      return Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Time column
                                            Container(
                                              width: 90,
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AcadexColors.primary.withValues(alpha: 0.08),
                                                borderRadius: AcadexRadius.borderRadiusXs,
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '${e.startTime}–${e.endTime}',
                                                    style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.w700),
                                                  ),
                                                  Text(
                                                    'P${e.startPeriodIndex}${e.periodSpan > 1 ? "-${e.endPeriodIndex}" : ""}',
                                                    style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontSize: 10),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Details column
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '$subName${subCode.isNotEmpty ? " ($subCode)" : ""}',
                                                    style: AcadexTypography.body(
                                                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                                    ).copyWith(fontWeight: FontWeight.w600),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Row(
                                                    children: [
                                                      Icon(LucideIcons.user, size: 13, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          facName,
                                                          style: AcadexTypography.caption(
                                                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Wrap(
                                                     crossAxisAlignment: WrapCrossAlignment.center,
                                                     spacing: 8,
                                                     runSpacing: 4,
                                                     children: [
                                                       Row(
                                                         mainAxisSize: MainAxisSize.min,
                                                         children: [
                                                           Icon(LucideIcons.doorOpen, size: 13, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                                           const SizedBox(width: 4),
                                                           Flexible(
                                                             child: Text(
                                                               'Room: ${e.roomNumber}${e.building != null ? " (${e.building})" : ""}',
                                                               style: AcadexTypography.caption(
                                                                 color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                                               ),
                                                               overflow: TextOverflow.ellipsis,
                                                             ),
                                                           ),
                                                         ],
                                                       ),
                                                       Container(
                                                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                         decoration: BoxDecoration(
                                                           color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                                                           borderRadius: AcadexRadius.borderRadiusXs,
                                                         ),
                                                         child: Text(
                                                           e.sessionType.displayName,
                                                           style: AcadexTypography.caption(
                                                             color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                                           ).copyWith(fontSize: 10),
                                                         ),
                                                       ),
                                                     ],
                                                   ),
                                                ],
                                              ),
                                            ),
                                            // Actions (if draft)
                                            if (isDraft && canCreate) ...[
                                              IconButton(
                                                icon: const Icon(LucideIcons.pencil, size: 16),
                                                tooltip: 'Edit Class',
                                                onPressed: () {
                                                  showTimetableClassEditorDialog(
                                                    context: context,
                                                    timetableId: sectionContainer.id,
                                                    day: e.dayOfWeek,
                                                    startPeriodIndex: e.startPeriodIndex,
                                                    existingEntry: e,
                                                  );
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(LucideIcons.trash2, size: 16, color: AcadexColors.error),
                                                tooltip: 'Delete Class',
                                                onPressed: () {
                                                  _confirmDeleteSectionEntry(context, ref, sectionContainer, e);
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePublish(
    BuildContext context,
    WidgetRef ref,
    TimetableContainerModel container,
    String userId,
  ) async {
    final notifier = ref.read(timetableAuthoringProvider(container.id).notifier);
    final success = await notifier.publish(publishedBy: userId);

    if (success) {
      ref.invalidate(managementContainersProvider);
      ref.invalidate(managementTimetableProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timetable published successfully! Live schedules updated.'),
            backgroundColor: AcadexColors.success,
          ),
        );
      }
    } else {
      final state = ref.read(timetableAuthoringProvider(container.id));
      final errorMsg = state.errorMessage ?? 'Publish failed. Check for scheduling conflicts.';
      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusLg),
            title: const Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: AcadexColors.error, size: 22),
                SizedBox(width: 8),
                Text('Cannot Publish Timetable'),
              ],
            ),
            content: Text(
              errorMsg,
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleUnpublish(
    BuildContext context,
    WidgetRef ref,
    TimetableContainerModel container,
  ) async {
    final notifier = ref.read(timetableAuthoringProvider(container.id).notifier);
    final success = await notifier.unpublish();

    if (success) {
      ref.invalidate(managementContainersProvider);
      ref.invalidate(managementTimetableProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timetable reverted to DRAFT status.'),
            backgroundColor: AcadexColors.warningDark,
          ),
        );
      }
    } else {
      final state = ref.read(timetableAuthoringProvider(container.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage ?? 'Failed to unpublish timetable.'),
            backgroundColor: AcadexColors.error,
          ),
        );
      }
    }
  }

  void _confirmDeleteSlot(BuildContext context, WidgetRef ref, TimetableModel entry) {
    final subjectMap = ref.read(timetableSubjectMapProvider);
    final subject = subjectMap[entry.subjectId];
    final subjectName = subject?.name ?? entry.subjectId;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusXl),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: AcadexColors.error, size: 20),
            SizedBox(width: 8),
            Text('Delete this schedule slot?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to remove this timetable slot? This will update the timetable container on the server.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                borderRadius: AcadexRadius.borderRadiusMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subject: $subjectName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Day: ${entry.dayOfWeek.displayName}', style: const TextStyle(fontSize: 12)),
                  Text('Time: ${entry.startTime} – ${entry.endTime}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(timetableRepositoryProvider);
              try {
                String? targetTimetableId = entry.timetableId;
                if (targetTimetableId == null || targetTimetableId.isEmpty) {
                  final containers = await repo.getTimetableContainers(
                    collegeId: entry.collegeId,
                    sectionId: entry.sectionId,
                  );
                  final draft = containers.where((c) => c.status == TimetableStatus.draft).firstOrNull;
                  final published = containers.where((c) => c.status == TimetableStatus.published).firstOrNull;
                  if (draft != null) {
                    targetTimetableId = draft.id;
                  } else if (published != null) {
                    throw StateError('Published timetables cannot be modified directly. Please unpublish or create a revision first.');
                  } else if (containers.isNotEmpty) {
                    targetTimetableId = containers.first.id;
                  }
                }

                if (targetTimetableId == null || targetTimetableId.isEmpty) {
                  throw Exception('No associated timetable container found for this entry.');
                }

                final container = await repo.getTimetableContainer(targetTimetableId);
                if (container != null && container.status == TimetableStatus.published) {
                  throw StateError('Published timetables cannot be modified directly. Please unpublish or create a revision first.');
                }

                await repo.deleteGridEntry(targetTimetableId, entry.id);

                ref.invalidate(managementTimetableProvider);
                ref.invalidate(managementContainersProvider);
                ref.invalidate(timetableGridEntriesStreamProvider(targetTimetableId));
                ref.invalidate(timetableContainerStreamProvider(targetTimetableId));

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Timetable entry deleted successfully.'),
                      backgroundColor: AcadexColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete entry: $e'),
                      backgroundColor: AcadexColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSectionEntry(
    BuildContext context,
    WidgetRef ref,
    TimetableContainerModel container,
    TimetableGridEntryModel entry,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusXl),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: AcadexColors.error, size: 20),
            SizedBox(width: 8),
            Text('Delete Class Entry?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to remove this class from the draft timetable? This will update the timetable container on the server.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(timetableAuthoringProvider(container.id).notifier).deleteEntryAuthoritatively(entry.id);
                ref.invalidate(timetableGridEntriesStreamProvider(container.id));
                ref.invalidate(timetableContainerStreamProvider(container.id));
                ref.invalidate(managementContainersProvider);
                ref.invalidate(managementTimetableProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Class entry removed successfully.'), backgroundColor: AcadexColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete entry: $e'), backgroundColor: AcadexColors.error),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Authoritative readiness check card for HOD timetable authoring.
/// Shows real-time counts of subjects, faculty assignments, and enrollments
/// for the selected section context.
class HodTimetableReadinessCard extends ConsumerWidget {
  final String courseId;
  final String? academicYearId;
  final String semesterId;
  final String sectionId;

  const HodTimetableReadinessCard({
    super.key,
    required this.courseId,
    this.academicYearId,
    required this.semesterId,
    required this.sectionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Subject> subjects = ref.watch(subjectsForSemesterProvider(semesterId));
    final List<FacultyAssignment> assignments = ref.watch(facultyAssignmentsBySectionProvider(sectionId));
    final List<Subject> unassignedSubjects = ref.watch(
      unassignedSubjectsForSectionProvider((semesterId: semesterId, sectionId: sectionId)),
    );
    final int enrollmentCount = ref.watch(sectionActiveEnrollmentCountProvider(sectionId));

    final totalSubjects = subjects.length;
    final activeAssignments = assignments.where((a) => a.isActive).toList();
    final assignedCount = activeAssignments.length;
    final unassignedCount = unassignedSubjects.length;

    final bool isReady = unassignedCount == 0 && totalSubjects > 0;

    final badgeLabel = totalSubjects == 0
        ? 'NO SUBJECTS'
        : isReady
            ? 'READY FOR TIMETABLE'
            : '$unassignedCount UNASSIGNED';

    final badgeVariant = totalSubjects == 0
        ? AcadexBadgeVariant.neutral
        : isReady
            ? AcadexBadgeVariant.success
            : AcadexBadgeVariant.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isReady
              ? (isDark ? AcadexColors.success.withValues(alpha: 0.3) : AcadexColors.successLight)
              : (isDark ? AcadexColors.warning.withValues(alpha: 0.3) : AcadexColors.warningLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isReady ? AcadexColors.success : AcadexColors.warning).withValues(alpha: 0.12),
                      borderRadius: AcadexRadius.borderRadiusMd,
                    ),
                    child: Icon(
                      isReady ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                      size: 18,
                      color: isReady ? AcadexColors.success : AcadexColors.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Academic Readiness Status',
                      style: AcadexTypography.bodyMedium(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              AcadexBadge(
                label: badgeLabel,
                variant: badgeVariant,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isReady
                ? 'All semester subjects have faculty assigned and ready for scheduling.'
                : 'Assign faculty to all subjects in Academic Setup before completing timetable.',
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildMetricChip(
                context,
                icon: LucideIcons.bookOpen,
                label: '$totalSubjects Subjects',
                isDark: isDark,
              ),
              _buildMetricChip(
                context,
                icon: LucideIcons.userCheck,
                label: '$assignedCount Assigned',
                isDark: isDark,
              ),
              _buildMetricChip(
                context,
                icon: LucideIcons.userX,
                label: '$unassignedCount Unassigned',
                isDark: isDark,
                isWarning: unassignedCount > 0,
              ),
              _buildMetricChip(
                context,
                icon: LucideIcons.users,
                label: '$enrollmentCount Enrolled',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isDark,
    bool isWarning = false,
  }) {
    final chipColor = isWarning
        ? (isDark ? AcadexColors.warning.withValues(alpha: 0.15) : AcadexColors.warningLight)
        : (isDark ? AcadexColors.darkSurface : AcadexColors.canvasSoft);
    final textColor = isWarning
        ? AcadexColors.warning
        : (isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isWarning
              ? AcadexColors.warning.withValues(alpha: 0.3)
              : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: AcadexTypography.caption(color: textColor).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

