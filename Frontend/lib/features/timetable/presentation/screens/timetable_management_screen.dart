import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_providers.dart';
import '../providers/timetable_lookup_providers.dart';
import '../widgets/timetable_widgets.dart';

class TimetableFilterState {
  final String? departmentId;
  final String? courseId;
  final String? semesterId;
  final String? sectionId;
  final TimetableDay? day;
  final String searchQuery;

  TimetableFilterState({
    this.departmentId,
    this.courseId,
    this.semesterId,
    this.sectionId,
    this.day,
    this.searchQuery = '',
  });

  TimetableFilterState copyWith({
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    TimetableDay? day,
    bool clearDay = false,
    String? searchQuery,
  }) {
    return TimetableFilterState(
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      day: clearDay ? null : (day ?? this.day),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasActiveFilters =>
      departmentId != null || courseId != null || semesterId != null || sectionId != null || day != null || searchQuery.isNotEmpty;
}

final timetableFilterProvider = StateProvider<TimetableFilterState>((ref) => TimetableFilterState());

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

class TimetableManagementScreen extends ConsumerWidget {
  const TimetableManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    
    final user = authState.user;
    if (user.role != AppRole.superAdmin && user.role != AppRole.collegeAdmin && user.role != AppRole.hod) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unauthorized')),
        body: const Center(child: Text('Unauthorized: Only administrators and HODs can manage timetables.')),
      );
    }

    final filters = ref.watch(timetableFilterProvider);
    final timetableAsync = ref.watch(managementTimetableProvider);
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
                // Header with Add Schedule CTA
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
                  child: AcadexPageHeader(
                    title: 'Manage Timetable',
                    subtitle: 'Create, edit and maintain academic schedules.',
                    actions: [
                      AcadexButton(
                        label: 'Add Schedule',
                        icon: LucideIcons.plus,
                        variant: AcadexButtonVariant.primary,
                        size: AcadexButtonSize.md,
                        onPressed: () => context.go('/timetable/new'),
                      ),
                    ],
                  ),
                ),

                // Responsive Filter Toolbar
                _buildFilterBar(context, ref, user.role, filters),

                // Timetable Entries List with smooth AnimatedSwitcher
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AcadexMotion.resolveDuration(context, AcadexMotion.fast),
                    switchInCurve: AcadexMotion.curveStandard,
                    switchOutCurve: AcadexMotion.curveStandard,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: timetableAsync.when(
                      loading: () => const Center(
                        key: ValueKey('mgt_loading'),
                        child: CircularProgressIndicator(),
                      ),
                      error: (e, st) => Center(
                        key: const ValueKey('mgt_error'),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.alertCircle, size: 48, color: AcadexColors.error),
                              const SizedBox(height: 16),
                              Text('Failed to load schedule entries', style: AcadexTypography.heading3(color: Theme.of(context).colorScheme.onSurface)),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  // ignore: unused_result
                                  ref.refresh(managementTimetableProvider);
                                },
                                icon: const Icon(LucideIcons.refreshCw, size: 16),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (entries) {
                        if (entries.isEmpty) {
                          return Center(
                            key: const ValueKey('mgt_empty'),
                            child: AcadexEmptyState(
                              title: filters.hasActiveFilters ? 'No matching schedules found' : 'No timetable entries found',
                              subtitle: filters.hasActiveFilters
                                  ? 'Try adjusting your filters or search query.'
                                  : 'Click "Add Schedule" to create your first class timetable slot.',
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
                                // Pre-fill new timetable form with existing entry values
                                context.go('/timetable/new', extra: entry.copyWith(id: ''));
                              },
                              onDelete: () => _confirmDelete(context, ref, entry),
                            );
                          },
                        );
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
          // Row 1: Case-Insensitive Search Field
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

          // Row 2: Dropdowns & Clear Filter
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
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

              // Department Dropdown (Super Admin & College Admin)
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

              // Clear Filter Button with AnimatedSize
              AnimatedSize(
                duration: AcadexMotion.resolveDuration(context, AcadexMotion.micro),
                curve: AcadexMotion.curveStandard,
                child: filters.hasActiveFilters
                    ? TextButton.icon(
                        onPressed: () => ref.read(timetableFilterProvider.notifier).state = TimetableFilterState(),
                        icon: const Icon(LucideIcons.x, size: 14),
                        label: const Text('Clear Filters'),
                        style: TextButton.styleFrom(
                          foregroundColor: AcadexColors.error,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, TimetableModel entry) {
    final subjectMap = ref.read(timetableSubjectMapProvider);
    final subject = subjectMap[entry.subjectId];
    final subjectName = subject?.name ?? entry.subjectId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusXl),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: AcadexColors.error, size: 20),
            SizedBox(width: 8),
            Text('Delete this schedule?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to remove this timetable slot? This will remove the class from student and faculty calendars.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
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
                  if (entry.roomNumber.isNotEmpty)
                    Text('Room: ${entry.roomNumber}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(timetableManagementProvider.notifier).deleteEntry(entry.id);
              // ignore: unused_result
              ref.refresh(managementTimetableProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Timetable entry deleted successfully.'),
                    backgroundColor: AcadexColors.success,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
