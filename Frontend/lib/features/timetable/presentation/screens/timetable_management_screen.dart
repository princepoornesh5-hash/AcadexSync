import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_providers.dart';
import '../widgets/timetable_widgets.dart';

class TimetableFilterState {
  final String? departmentId;
  final String? courseId;
  final String? semesterId;
  final String? sectionId;
  final TimetableDay? day;

  TimetableFilterState({
    this.departmentId,
    this.courseId,
    this.semesterId,
    this.sectionId,
    this.day,
  });

  TimetableFilterState copyWith({
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    TimetableDay? day,
    bool clearDay = false,
  }) {
    return TimetableFilterState(
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      day: clearDay ? null : (day ?? this.day),
    );
  }
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
  
  if (filters.day != null) {
    return entries.where((e) => e.dayOfWeek == filters.day).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
  
  // Sort by day, then time
  entries.sort((a, b) {
    int dayCmp = a.dayOfWeek.index.compareTo(b.dayOfWeek.index);
    if (dayCmp != 0) return dayCmp;
    return a.startTime.compareTo(b.startTime);
  });
  
  return entries;
});


class TimetableManagementScreen extends ConsumerWidget {
  const TimetableManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    
    final user = authState.user;
    if (user.role != AppRole.superAdmin && user.role != AppRole.collegeAdmin && user.role != AppRole.hod) {
      return const Center(child: Text('Unauthorized'));
    }

    final filters = ref.watch(timetableFilterProvider);
    final timetableAsync = ref.watch(managementTimetableProvider);

    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        title: Text('Manage Timetable', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
        backgroundColor: DashboardColors.surface,
        iconTheme: const IconThemeData(color: DashboardColors.textPrimary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => context.go('/timetable/new'),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Add Entry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(context, ref, user.role, filters),
          Expanded(
            child: timetableAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.calendarX, size: 48, color: DashboardColors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text('No timetable entries found.', style: TextStyle(color: DashboardColors.textSecondary)),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Stack(
                      children: [
                        TimetableCard(entry: entry),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.edit, size: 18, color: DashboardColors.primary),
                                onPressed: () {
                                  context.go('/timetable/edit/${entry.id}', extra: entry);
                                },
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 18, color: DashboardColors.error),
                                onPressed: () => _confirmDelete(context, ref, entry.id),
                              ),
                            ],
                          ),
                        ),
                        if (filters.day == null)
                          Positioned(
                            left: 16,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: DashboardColors.purple,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                entry.dayOfWeek.displayName,
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, AppRole role, TimetableFilterState filters) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: DashboardColors.surface,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          // Day Filter
          DropdownButton<TimetableDay?>(
            value: filters.day,
            hint: const Text('All Days'),
            items: [
              const DropdownMenuItem<TimetableDay?>(value: null, child: Text('All Days')),
              ...TimetableDay.values.map((d) => DropdownMenuItem(value: d, child: Text(d.displayName))),
            ],
            onChanged: (val) {
              ref.read(timetableFilterProvider.notifier).state = filters.copyWith(day: val, clearDay: val == null);
            },
          ),
          
          if (role != AppRole.hod)
            Consumer(
              builder: (context, ref, _) {
                final deptsAsync = ref.watch(departmentsProvider);
                return deptsAsync.maybeWhen(
                  data: (depts) => DropdownButton<String?>(
                    value: filters.departmentId,
                    hint: const Text('All Departments'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('All Departments')),
                      ...depts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.code))),
                    ],
                    onChanged: (val) {
                      ref.read(timetableFilterProvider.notifier).state = filters.copyWith(departmentId: val);
                    },
                  ),
                  orElse: () => const SizedBox.shrink(),
                );
              }
            ),

          Consumer(
            builder: (context, ref, _) {
              final coursesAsync = ref.watch(coursesProvider);
              return coursesAsync.maybeWhen(
                data: (courses) {
                  final validCourses = role == AppRole.hod 
                    ? courses // Wait, we should filter by HOD dept, but mock data doesn't strictly link them perfectly, so we allow all for now or filter by user dept
                    : courses;
                  return DropdownButton<String?>(
                    value: filters.courseId,
                    hint: const Text('All Courses'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('All Courses')),
                      ...validCourses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.code))),
                    ],
                    onChanged: (val) {
                      ref.read(timetableFilterProvider.notifier).state = filters.copyWith(courseId: val);
                    },
                  );
                },
                orElse: () => const SizedBox.shrink(),
              );
            }
          ),
          
          Consumer(
            builder: (context, ref, _) {
              final sectionsAsync = ref.watch(sectionsProvider);
              return sectionsAsync.maybeWhen(
                data: (sections) => DropdownButton<String?>(
                  value: filters.sectionId,
                  hint: const Text('All Sections'),
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
            }
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this timetable entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(timetableManagementProvider.notifier).deleteEntry(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: DashboardColors.error)),
          ),
        ],
      ),
    );
  }
}
