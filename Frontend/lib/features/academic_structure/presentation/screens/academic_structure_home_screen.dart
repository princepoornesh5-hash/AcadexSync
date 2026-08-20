import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../core/presentation/widgets/app_card.dart';
import '../../../../core/presentation/widgets/app_button.dart';
import '../../../../core/presentation/widgets/app_badge.dart';
import '../../../../core/presentation/widgets/app_search_field.dart';
import '../../../../core/presentation/widgets/app_stat_card.dart';
import '../../../../core/presentation/widgets/app_loading_state.dart';
import '../../../../core/presentation/widgets/app_error_state.dart';
import '../../../../core/presentation/widgets/app_empty_state.dart';
import '../../../../core/presentation/widgets/app_avatar.dart';

import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/academic_models.dart';
import '../providers/academic_providers.dart';

class AcademicStructureHomeScreen extends ConsumerStatefulWidget {
  const AcademicStructureHomeScreen({super.key});

  @override
  ConsumerState<AcademicStructureHomeScreen> createState() =>
      _AcademicStructureHomeScreenState();
}

class _AcademicStructureHomeScreenState
    extends ConsumerState<AcademicStructureHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedDepartmentFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final userRole = currentUser?.role ?? AppRole.student;

    final deptsAsync = ref.watch(departmentsProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final sectionsAsync = ref.watch(sectionsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return AppScaffold(
      title: 'Academic Structure',
      subtitle: _getSubtitleForRole(userRole),
      topBarActions: _buildHeaderActions(context, userRole),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(departmentsProvider);
          ref.invalidate(coursesProvider);
          ref.invalidate(semestersProvider);
          ref.invalidate(sectionsProvider);
          ref.invalidate(subjectsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Personalized Role-Aware Card (For Faculty / Students)
              if (userRole == AppRole.faculty || userRole == AppRole.student)
                _buildPersonalizedRoleCard(context, currentUser, isDark),

              // 2. Summary KPI Metric Cards Deck
              _buildStatsDeck(
                deptsAsync: deptsAsync,
                coursesAsync: coursesAsync,
                semestersAsync: semestersAsync,
                sectionsAsync: sectionsAsync,
                subjectsAsync: subjectsAsync,
                isMobile: isMobile,
              ),
              const SizedBox(height: 24),

              // 3. Search and Department Filter Toolbar
              Row(
                children: [
                  Expanded(
                    child: AppSearchField(
                      hintText: 'Search academic entities (name, code)...',
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 12),
                    deptsAsync.maybeWhen(
                      data: (depts) => _buildDepartmentFilterDropdown(depts, isDark),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // 4. Hierarchical Navigation Tabs
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                  borderRadius: AcadexRadius.borderRadiusLg,
                  border: Border.all(
                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AcadexColors.primary,
                  unselectedLabelColor:
                      isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  indicatorColor: AcadexColors.primary,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(icon: Icon(LucideIcons.building2, size: 16), text: 'Departments'),
                    Tab(icon: Icon(LucideIcons.graduationCap, size: 16), text: 'Programs / Courses'),
                    Tab(icon: Icon(LucideIcons.calendarDays, size: 16), text: 'Semesters'),
                    Tab(icon: Icon(LucideIcons.layoutGrid, size: 16), text: 'Sections'),
                    Tab(icon: Icon(LucideIcons.bookOpen, size: 16), text: 'Subjects Catalog'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Tab Content Area
              SizedBox(
                height: 600,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDepartmentsTab(deptsAsync, userRole, isDark),
                    _buildCoursesTab(coursesAsync, deptsAsync, userRole, isDark),
                    _buildSemestersTab(semestersAsync, coursesAsync, userRole, isDark),
                    _buildSectionsTab(sectionsAsync, semestersAsync, userRole, isDark),
                    _buildSubjectsTab(subjectsAsync, deptsAsync, userRole, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitleForRole(AppRole role) {
    switch (role) {
      case AppRole.superAdmin:
        return 'Global academic architecture and multi-institution catalog.';
      case AppRole.collegeAdmin:
        return 'Manage college departments, degree programs, semesters, sections, and subjects.';
      case AppRole.hod:
        return 'Departmental academic structure, curriculum, and class allocations.';
      case AppRole.faculty:
        return 'Academic overview of assigned curriculum, courses, and sections.';
      case AppRole.student:
        return 'Enrolled degree program, current semester, section, and syllabus.';
    }
  }

  List<Widget> _buildHeaderActions(BuildContext context, AppRole role) {
    if (role == AppRole.collegeAdmin || role == AppRole.superAdmin) {
      return [
        AppButton(
          label: 'Add Department',
          icon: LucideIcons.plus,
          onPressed: () => context.push('/academics/departments/new'),
        ),
      ];
    } else if (role == AppRole.hod) {
      return [
        AppButton(
          label: 'Add Course',
          icon: LucideIcons.plus,
          onPressed: () => context.push('/academics/courses/new'),
        ),
      ];
    }
    return [];
  }

  Widget _buildPersonalizedRoleCard(
      BuildContext context, dynamic currentUser, bool isDark) {
    final isFaculty = currentUser?.role == AppRole.faculty;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AcadexColors.primary.withValues(alpha: 0.15)
            : AcadexColors.primaryLight.withValues(alpha: 0.5),
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: AcadexColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AcadexColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFaculty ? LucideIcons.briefcase : LucideIcons.graduationCap,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFaculty
                      ? 'Faculty Workload & Class Roster'
                      : 'Student Curriculum & Schedule',
                  style: AcadexTypography.heading3(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isFaculty
                      ? 'Quickly jump to your assigned sections, timetable, and attendance marking.'
                      : 'View your course subjects, study resources, and academic timetable.',
                  style: AcadexTypography.bodySmall(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: isFaculty ? 'My Workload' : 'My Timetable',
            variant: AppButtonVariant.secondary,
            icon: isFaculty ? LucideIcons.activity : LucideIcons.calendar,
            onPressed: () {
              if (isFaculty) {
                context.push('/faculty-workload');
              } else {
                context.push('/timetable');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsDeck({
    required AsyncValue<List<Department>> deptsAsync,
    required AsyncValue<List<Course>> coursesAsync,
    required AsyncValue<List<Semester>> semestersAsync,
    required AsyncValue<List<Section>> sectionsAsync,
    required AsyncValue<List<Subject>> subjectsAsync,
    required bool isMobile,
  }) {
    final deptCount = deptsAsync.valueOrNull?.length ?? 0;
    final courseCount = coursesAsync.valueOrNull?.length ?? 0;
    final semCount = semestersAsync.valueOrNull?.length ?? 0;
    final sectionCount = sectionsAsync.valueOrNull?.length ?? 0;
    final subjectCount = subjectsAsync.valueOrNull?.length ?? 0;

    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = isMobile
          ? 2
          : constraints.maxWidth > 1000
              ? 5
              : 3;

      return GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isMobile ? 1.3 : 1.25,
        children: [
          AppStatCard(
            title: 'Departments',
            value: deptCount.toString(),
            icon: LucideIcons.building2,
            subtitle: 'Active Units',
          ),
          AppStatCard(
            title: 'Programs',
            value: courseCount.toString(),
            icon: LucideIcons.graduationCap,
            subtitle: 'Degree Tracks',
          ),
          AppStatCard(
            title: 'Semesters',
            value: semCount.toString(),
            icon: LucideIcons.calendarDays,
            subtitle: 'Academic Terms',
          ),
          AppStatCard(
            title: 'Sections',
            value: sectionCount.toString(),
            icon: LucideIcons.layoutGrid,
            subtitle: 'Classrooms',
          ),
          AppStatCard(
            title: 'Subjects',
            value: subjectCount.toString(),
            icon: LucideIcons.bookOpen,
            subtitle: 'Curriculum Items',
          ),
        ],
      );
    });
  }

  Widget _buildDepartmentFilterDropdown(List<Department> depts, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDepartmentFilter,
          icon: const Icon(LucideIcons.chevronDown, size: 16),
          style: AcadexTypography.body(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
          dropdownColor:
              isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
          items: [
            const DropdownMenuItem(
              value: 'ALL',
              child: Text('All Departments'),
            ),
            ...depts.map((d) => DropdownMenuItem(
                  value: d.id,
                  child: Text(d.name),
                )),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedDepartmentFilter = val);
            }
          },
        ),
      ),
    );
  }

  // --- TAB 1: DEPARTMENTS ---
  Widget _buildDepartmentsTab(
      AsyncValue<List<Department>> deptsAsync, AppRole role, bool isDark) {
    return deptsAsync.when(
      loading: () => const AppLoadingState(message: 'Loading departments...'),
      error: (e, _) => AppErrorState(message: e.toString()),
      data: (depts) {
        final filtered = depts.where((d) {
          final matchesQuery = _searchQuery.isEmpty ||
              d.name.toLowerCase().contains(_searchQuery) ||
              d.code.toLowerCase().contains(_searchQuery);
          final matchesDept = _selectedDepartmentFilter == 'ALL' ||
              d.id == _selectedDepartmentFilter;
          return matchesQuery && matchesDept;
        }).toList();

        if (filtered.isEmpty) {
          return AppEmptyState(
            title: 'No Departments Found',
            description: 'No academic departments match your active search filters.',
            icon: LucideIcons.building2,
            actionLabel: (role == AppRole.collegeAdmin || role == AppRole.superAdmin)
                ? 'Create Department'
                : null,
            onAction: () => context.push('/academics/departments/new'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 8),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final dept = filtered[index];
            return AppCard(
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  leading: AppAvatar(
                    name: dept.name,
                    size: 40,
                  ),
                  title: Text(
                    dept.name,
                    style: AcadexTypography.heading3(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Code: ${dept.code} • ${dept.description}',
                    style: AcadexTypography.bodySmall(
                      color: isDark
                          ? AcadexColors.darkInkMuted
                          : AcadexColors.inkMuted,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppBadge(
                        label: dept.isActive ? 'Active' : 'Inactive',
                        variant: dept.isActive
                            ? AppBadgeVariant.success
                            : AppBadgeVariant.neutral,
                      ),
                      const SizedBox(width: 8),
                      if (role == AppRole.collegeAdmin || role == AppRole.superAdmin)
                        IconButton(
                          icon: const Icon(LucideIcons.edit3, size: 18),
                          tooltip: 'Edit Department',
                          onPressed: () =>
                              context.push('/academics/departments/edit/${dept.id}'),
                        ),
                    ],
                  ),
                  onTap: () => context.push('/academics/departments'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 2: COURSES & PROGRAMS ---
  Widget _buildCoursesTab(AsyncValue<List<Course>> coursesAsync,
      AsyncValue<List<Department>> deptsAsync, AppRole role, bool isDark) {
    return coursesAsync.when(
      loading: () => const AppLoadingState(message: 'Loading degree programs...'),
      error: (e, _) => AppErrorState(message: e.toString()),
      data: (courses) {
        final filtered = courses.where((c) {
          final matchesQuery = _searchQuery.isEmpty ||
              c.name.toLowerCase().contains(_searchQuery) ||
              c.code.toLowerCase().contains(_searchQuery);
          final matchesDept = _selectedDepartmentFilter == 'ALL' ||
              c.departmentId == _selectedDepartmentFilter;
          return matchesQuery && matchesDept;
        }).toList();

        if (filtered.isEmpty) {
          return AppEmptyState(
            title: 'No Programs Found',
            description: 'No academic courses or degree programs available.',
            icon: LucideIcons.graduationCap,
            actionLabel: (role == AppRole.collegeAdmin || role == AppRole.hod)
                ? 'Create Course'
                : null,
            onAction: () => context.push('/academics/courses/new'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 8),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final course = filtered[index];
            return AppCard(
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AcadexColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.bookOpenCheck,
                        color: AcadexColors.primary, size: 20),
                  ),
                  title: Text(
                    course.name,
                    style: AcadexTypography.heading3(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Code: ${course.code}',
                    style: AcadexTypography.bodySmall(
                      color: isDark
                          ? AcadexColors.darkInkMuted
                          : AcadexColors.inkMuted,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppBadge(
                        label: course.isActive ? 'Active' : 'Inactive',
                        variant: course.isActive
                            ? AppBadgeVariant.success
                            : AppBadgeVariant.neutral,
                      ),
                      const SizedBox(width: 8),
                      if (role == AppRole.collegeAdmin || role == AppRole.hod)
                        IconButton(
                          icon: const Icon(LucideIcons.edit3, size: 18),
                          tooltip: 'Edit Course',
                          onPressed: () =>
                              context.push('/academics/courses/edit/${course.id}'),
                        ),
                    ],
                  ),
                  onTap: () => context.push('/academics/courses'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 3: SEMESTERS ---
  Widget _buildSemestersTab(AsyncValue<List<Semester>> semestersAsync,
      AsyncValue<List<Course>> coursesAsync, AppRole role, bool isDark) {
    return semestersAsync.when(
      loading: () => const AppLoadingState(message: 'Loading semesters...'),
      error: (e, _) => AppErrorState(message: e.toString()),
      data: (semesters) {
        final filtered = semesters.where((s) {
          return _searchQuery.isEmpty ||
              s.name.toLowerCase().contains(_searchQuery) ||
              s.number.toString().contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return AppEmptyState(
            title: 'No Semesters Found',
            description: 'No academic terms or semesters configured.',
            icon: LucideIcons.calendarDays,
            actionLabel: (role == AppRole.collegeAdmin || role == AppRole.hod)
                ? 'Add Semester'
                : null,
            onAction: () => context.push('/academics/semesters/new'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 8),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final sem = filtered[index];
            return AppCard(
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AcadexColors.secondary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'S${sem.number}',
                        style: AcadexTypography.body(
                          color: AcadexColors.secondary,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  title: Text(
                    sem.name,
                    style: AcadexTypography.heading3(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Semester ${sem.number} • Status: ${sem.status.toUpperCase()}',
                    style: AcadexTypography.bodySmall(
                      color: isDark
                          ? AcadexColors.darkInkMuted
                          : AcadexColors.inkMuted,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppBadge(
                        label: sem.status.toUpperCase(),
                        variant: sem.status == 'active'
                            ? AppBadgeVariant.success
                            : AppBadgeVariant.neutral,
                      ),
                      const SizedBox(width: 8),
                      if (role == AppRole.collegeAdmin || role == AppRole.hod)
                        IconButton(
                          icon: const Icon(LucideIcons.edit3, size: 18),
                          tooltip: 'Edit Semester',
                          onPressed: () =>
                              context.push('/academics/semesters/edit/${sem.id}'),
                        ),
                    ],
                  ),
                  onTap: () => context.push('/academics/semesters'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 4: SECTIONS ---
  Widget _buildSectionsTab(AsyncValue<List<Section>> sectionsAsync,
      AsyncValue<List<Semester>> semestersAsync, AppRole role, bool isDark) {
    return sectionsAsync.when(
      loading: () => const AppLoadingState(message: 'Loading sections...'),
      error: (e, _) => AppErrorState(message: e.toString()),
      data: (sections) {
        final filtered = sections.where((s) {
          return _searchQuery.isEmpty ||
              s.name.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return AppEmptyState(
            title: 'No Sections Found',
            description: 'No classroom sections configured.',
            icon: LucideIcons.layoutGrid,
            actionLabel: (role == AppRole.collegeAdmin || role == AppRole.hod)
                ? 'Add Section'
                : null,
            onAction: () => context.push('/academics/sections/new'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 8),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final sec = filtered[index];
            return AppCard(
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AcadexColors.accentSky.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        sec.name.substring(0, sec.name.length.clamp(0, 2)),
                        style: AcadexTypography.body(
                          color: AcadexColors.accentSky,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  title: Text(
                    'Section ${sec.name}',
                    style: AcadexTypography.heading3(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Capacity: ${sec.capacity} students • Status: ${sec.status.toUpperCase()}',
                    style: AcadexTypography.bodySmall(
                      color: isDark
                          ? AcadexColors.darkInkMuted
                          : AcadexColors.inkMuted,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton(
                        label: 'Timetable',
                        variant: AppButtonVariant.outline,
                        icon: LucideIcons.calendar,
                        onPressed: () => context.push('/timetable'),
                      ),
                      const SizedBox(width: 8),
                      if (role == AppRole.collegeAdmin || role == AppRole.hod)
                        IconButton(
                          icon: const Icon(LucideIcons.edit3, size: 18),
                          tooltip: 'Edit Section',
                          onPressed: () =>
                              context.push('/academics/sections/edit/${sec.id}'),
                        ),
                    ],
                  ),
                  onTap: () => context.push('/academics/sections'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 5: SUBJECTS CATALOG ---
  Widget _buildSubjectsTab(AsyncValue<List<Subject>> subjectsAsync,
      AsyncValue<List<Department>> deptsAsync, AppRole role, bool isDark) {
    return subjectsAsync.when(
      loading: () => const AppLoadingState(message: 'Loading subjects catalog...'),
      error: (e, _) => AppErrorState(message: e.toString()),
      data: (subjects) {
        final filtered = subjects.where((s) {
          final matchesQuery = _searchQuery.isEmpty ||
              s.name.toLowerCase().contains(_searchQuery) ||
              s.code.toLowerCase().contains(_searchQuery);
          final matchesDept = _selectedDepartmentFilter == 'ALL' ||
              s.departmentId == _selectedDepartmentFilter;
          return matchesQuery && matchesDept;
        }).toList();

        if (filtered.isEmpty) {
          return AppEmptyState(
            title: 'No Subjects Found',
            description: 'No academic subjects in the syllabus catalog.',
            icon: LucideIcons.bookOpen,
            actionLabel: (role == AppRole.collegeAdmin || role == AppRole.hod)
                ? 'Add Subject'
                : null,
            onAction: () => context.push('/academics/subjects/new'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 8),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final sub = filtered[index];
            return AppCard(
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AcadexColors.accentGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.bookOpen,
                        color: AcadexColors.accentGreen, size: 20),
                  ),
                  title: Text(
                    sub.name,
                    style: AcadexTypography.heading3(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Code: ${sub.code} • ${sub.credits} Credits • ${sub.type.toUpperCase()}',
                    style: AcadexTypography.bodySmall(
                      color: isDark
                          ? AcadexColors.darkInkMuted
                          : AcadexColors.inkMuted,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton(
                        label: 'Notes',
                        variant: AppButtonVariant.outline,
                        icon: LucideIcons.fileText,
                        onPressed: () => context.push('/notes'),
                      ),
                      const SizedBox(width: 8),
                      if (role == AppRole.collegeAdmin || role == AppRole.hod)
                        IconButton(
                          icon: const Icon(LucideIcons.edit3, size: 18),
                          tooltip: 'Edit Subject',
                          onPressed: () =>
                              context.push('/academics/subjects/edit/${sub.id}'),
                        ),
                    ],
                  ),
                  onTap: () => context.push('/academics/subjects'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
