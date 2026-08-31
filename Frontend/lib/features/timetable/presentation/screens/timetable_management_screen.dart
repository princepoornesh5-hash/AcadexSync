import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_providers.dart';
import '../providers/timetable_lookup_providers.dart';
import '../widgets/timetable_widgets.dart';
import 'timetable_setup_screen.dart';
import 'timetable_designer_screen.dart';

class TimetableFilterState {
  final String? departmentId;
  final String? courseId;
  final String? semesterId;
  final String? sectionId;
  final TimetableDay? day;
  final TimetableStatus? status;
  final String searchQuery;

  TimetableFilterState({
    this.departmentId,
    this.courseId,
    this.semesterId,
    this.sectionId,
    this.day,
    this.status,
    this.searchQuery = '',
  });

  TimetableFilterState copyWith({
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    TimetableDay? day,
    bool clearDay = false,
    TimetableStatus? status,
    bool clearStatus = false,
    String? searchQuery,
  }) {
    return TimetableFilterState(
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      day: clearDay ? null : (day ?? this.day),
      status: clearStatus ? null : (status ?? this.status),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasActiveFilters =>
      departmentId != null ||
      courseId != null ||
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                // Header with Create Timetable Action
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
                  child: AcadexPageHeader(
                    title: 'Manage Timetable',
                    subtitle: 'Create master timetable containers, configure periods & breaks, and manage live published schedules.',
                    actions: [
                      if (canCreate) ...[
                        AcadexButton(
                          label: 'Create Timetable',
                          icon: LucideIcons.sparkles,
                          variant: AcadexButtonVariant.primary,
                          size: AcadexButtonSize.md,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TimetableSetupScreen(),
                              ),
                            );
                          },
                        ),
                        AcadexButton(
                          label: 'Add Schedule',
                          icon: LucideIcons.plus,
                          variant: AcadexButtonVariant.secondary,
                          size: AcadexButtonSize.md,
                          onPressed: () => context.go('/timetable/new'),
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
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Responsive Filter Toolbar
                _buildFilterBar(context, ref, user.role, filters),

                // Tab Content Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: MASTER TIMETABLE CONTAINERS
                      _buildContainersTab(context, ref, isDark, isMobile, canCreate),

                      // TAB 2: INDIVIDUAL CLASS SLOTS
                      _buildLegacySlotsTab(context, ref, isDark, isMobile, filters),
                    ],
                  ),
                ),
              ],
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
    final newVersionId = const Uuid().v4();
    final newDraft = container.copyWith(
      id: newVersionId,
      version: container.version + 1,
      status: TimetableStatus.draft,
      name: '${container.name} (v${container.version + 1} Draft)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repo.createTimetableContainer(newDraft);

    final periods = await repo.getPeriods(container.id);
    if (periods.isNotEmpty) {
      await repo.savePeriodsBatch(newVersionId, periods.map((p) => p.copyWith(id: const Uuid().v4())).toList());
    }

    final breaks = await repo.getBreaks(container.id);
    if (breaks.isNotEmpty) {
      await repo.saveBreaksBatch(newVersionId, breaks.map((b) => b.copyWith(id: const Uuid().v4())).toList());
    }

    final entries = await repo.getGridEntries(container.id);
    if (entries.isNotEmpty) {
      await repo.saveGridEntriesBatch(newVersionId, entries.map((e) => e.copyWith(id: const Uuid().v4())).toList());
    }

    ref.invalidate(managementContainersProvider);

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TimetableDesignerScreen(timetableId: newVersionId),
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
              await repo.deleteTimetableContainer(container.id);
              ref.invalidate(managementContainersProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Timetable draft deleted.'), backgroundColor: AcadexColors.error),
                );
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

          return ListView.builder(
            key: ValueKey('mgt_list_${entries.length}_${filters.day?.name ?? 'all'}'),
            padding: const EdgeInsets.all(20),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return TimetableManagementCard(
                entry: entry,
                onEdit: () => context.go('/timetable/edit/${entry.id}', extra: entry),
                onDuplicate: () {
                  context.go('/timetable/new', extra: entry.copyWith(id: ''));
                },
                onDelete: () => _confirmDeleteSlot(context, ref, entry),
              );
            },
          );
        },
      ),
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

          // Dropdowns & Status Filters
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Status Dropdown
              DropdownButton<TimetableStatus?>(
                value: filters.status,
                hint: const Text('All Statuses'),
                isDense: true,
                items: const [
                  DropdownMenuItem<TimetableStatus?>(value: null, child: Text('All Statuses')),
                  DropdownMenuItem(value: TimetableStatus.draft, child: Text('Draft')),
                  DropdownMenuItem(value: TimetableStatus.published, child: Text('Published')),
                  DropdownMenuItem(value: TimetableStatus.archived, child: Text('Archived')),
                ],
                onChanged: (val) {
                  ref.read(timetableFilterProvider.notifier).state = filters.copyWith(status: val, clearStatus: val == null);
                },
              ),

              // Day Dropdown
              DropdownButton<TimetableDay?>(
                value: filters.day,
                hint: const Text('All Days'),
                isDense: true,
                items: [
                  const DropdownMenuItem<TimetableDay?>(value: null, child: Text('All Days')),
                  ...TimetableDay.values.map((d) => DropdownMenuItem(value: d, child: Text(d.displayName))),
                ],
                onChanged: (val) {
                  ref.read(timetableFilterProvider.notifier).state = filters.copyWith(day: val, clearDay: val == null);
                },
              ),

              // Department Dropdown
              if (role != AppRole.hod)
                Consumer(
                  builder: (context, ref, _) {
                    final deptsAsync = ref.watch(departmentsProvider);
                    return deptsAsync.maybeWhen(
                      data: (depts) => DropdownButton<String?>(
                        value: filters.departmentId,
                        hint: const Text('All Departments'),
                        isDense: true,
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('All Departments')),
                          ...depts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name.isNotEmpty ? d.name : d.code))),
                        ],
                        onChanged: (val) {
                          ref.read(timetableFilterProvider.notifier).state = filters.copyWith(departmentId: val);
                        },
                      ),
                      orElse: () => const SizedBox.shrink(),
                    );
                  },
                ),

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
                        const DropdownMenuItem<String?>(value: null, child: Text('All Courses')),
                        ...courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name.isNotEmpty ? c.name : c.code))),
                      ],
                      onChanged: (val) {
                        ref.read(timetableFilterProvider.notifier).state = filters.copyWith(courseId: val);
                      },
                    ),
                    orElse: () => const SizedBox.shrink(),
                  );
                },
              ),

              // Section Dropdown
              Consumer(
                builder: (context, ref, _) {
                  final sectionsAsync = ref.watch(sectionsProvider);
                  return sectionsAsync.maybeWhen(
                    data: (sections) => DropdownButton<String?>(
                      value: filters.sectionId,
                      hint: const Text('All Sections'),
                      isDense: true,
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All Sections')),
                        ...sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                      ],
                      onChanged: (val) {
                        ref.read(timetableFilterProvider.notifier).state = filters.copyWith(sectionId: val);
                      },
                    ),
                    orElse: () => const SizedBox.shrink(),
                  );
                },
              ),

              // Clear Filter Button
              if (filters.hasActiveFilters)
                TextButton.icon(
                  onPressed: () => ref.read(timetableFilterProvider.notifier).state = TimetableFilterState(),
                  icon: const Icon(LucideIcons.x, size: 14),
                  label: const Text('Clear Filters'),
                  style: TextButton.styleFrom(
                    foregroundColor: AcadexColors.error,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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
            const Text('Are you sure you want to remove this timetable slot?'),
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
              await ref.read(timetableManagementProvider.notifier).deleteEntry(entry.id);
              ref.invalidate(managementTimetableProvider);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
