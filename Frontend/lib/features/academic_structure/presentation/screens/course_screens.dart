import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../features/auth/domain/models/auth_state.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/academic_providers.dart';
import '../../domain/models/academic_models.dart';

class CourseListScreen extends ConsumerStatefulWidget {
  const CourseListScreen({super.key});

  @override
  ConsumerState<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends ConsumerState<CourseListScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all' | 'active' | 'inactive'

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    final deptMap = ref.watch(departmentMapProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcadexPageHeader(
            title: "Courses (Degree Programs)",
            subtitle: "Manage academic degree programs, duration, and curricula offered across departments.",
          ),
          AcadexSearchFilterBar(
            searchHint: "Search courses by name, code, or department...",
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onActionTap: () => context.push('/academics/courses/new'),
            actionLabel: "Add Course",
          ),
          const SizedBox(height: 10),
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                for (final f in [('all', 'All'), ('active', 'Active'), ('inactive', 'Inactive')])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.$2),
                      selected: _statusFilter == f.$1,
                      onSelected: (_) => setState(() => _statusFilter = f.$1),
                      selectedColor: AcadexColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AcadexColors.primary,
                      labelStyle: TextStyle(
                        color: _statusFilter == f.$1 ? AcadexColors.primary : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                        fontWeight: _statusFilter == f.$1 ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: _statusFilter == f.$1 ? AcadexColors.primary : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text("Error: $err", style: const TextStyle(color: AcadexColors.error)),
              ),
              data: (courses) {
                final filtered = courses.where((c) {
                  // Status filter
                  if (_statusFilter == 'active' && !c.isActive) return false;
                  if (_statusFilter == 'inactive' && c.isActive) return false;
                  // Search query
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  final deptName = deptMap[c.departmentId]?.name ?? '';
                  return c.name.toLowerCase().contains(q) ||
                      c.code.toLowerCase().contains(q) ||
                      deptName.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return AcadexEmptyState(
                    title: "No Courses Found",
                    subtitle: _searchQuery.isNotEmpty
                        ? "No courses match '$_searchQuery'."
                        : "Get started by adding your first degree program or course.",
                    icon: LucideIcons.bookOpen,
                    actionLabel: "Add Course",
                    onActionTap: () => context.push('/academics/courses/new'),
                  );
                }

                if (isMobile) {
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      final deptName = deptMap[c.departmentId]?.name ??
                          (c.departmentId.isNotEmpty ? c.departmentId : 'Unassigned Dept');

                      return GestureDetector(
                        onTap: () => context.push('/academics/courses/${c.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                            borderRadius: AcadexRadius.borderRadiusLg,
                            border: Border.all(
                              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.name,
                                      style: AcadexTypography.body(
                                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: c.isActive
                                          ? (isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight)
                                          : (isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft),
                                      borderRadius: AcadexRadius.borderRadiusFull,
                                    ),
                                    child: Text(
                                      c.isActive ? "Active" : "Inactive",
                                      style: TextStyle(
                                        color: c.isActive ? AcadexColors.success : AcadexColors.inkMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    "Code: ${c.code}",
                                    style: AcadexTypography.caption(
                                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "•  ${c.duration} ${c.duration == 1 ? 'Year' : 'Years'}",
                                    style: AcadexTypography.caption(
                                      color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Department: $deptName",
                                style: AcadexTypography.caption(
                                  color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.arrowRight, size: 16, color: AcadexColors.primary),
                                    tooltip: "View Details",
                                    onPressed: () => context.push('/academics/courses/${c.id}'),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: Icon(
                                      LucideIcons.edit,
                                      size: 18,
                                      color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                                    ),
                                    tooltip: "Edit Course",
                                    onPressed: () => context.push('/academics/courses/edit/${c.id}'),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                return AcadexDataTable(
                  columns: const ["Code", "Course Name", "Department", "Duration", "Status", "Actions"],
                  rows: filtered.map((c) {
                    final deptName = deptMap[c.departmentId]?.name ??
                        (c.departmentId.isNotEmpty ? c.departmentId : 'Unassigned');

                    return DataRow(
                      onSelectChanged: (_) => context.push('/academics/courses/${c.id}'),
                      cells: [
                        DataCell(Text(c.code, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(c.name)),
                        DataCell(Text(deptName)),
                        DataCell(Text("${c.duration} ${c.duration == 1 ? 'Year' : 'Years'}")),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: c.isActive ? AcadexColors.successLight : AcadexColors.canvasSoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              c.isActive ? "Active" : "Inactive",
                              style: TextStyle(
                                color: c.isActive ? AcadexColors.success : AcadexColors.inkMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.eye, size: 18),
                                tooltip: "View Details",
                                onPressed: () => context.push('/academics/courses/${c.id}'),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.edit, size: 18),
                                tooltip: "Edit Course",
                                onPressed: () => context.push('/academics/courses/edit/${c.id}'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CourseFormScreen extends ConsumerStatefulWidget {
  final String? id;
  const CourseFormScreen({super.key, this.id});

  @override
  ConsumerState<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends ConsumerState<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  int _duration = 3;
  bool _isLoading = false;
  Course? _existing;
  String? _selectedDepartmentId;
  String? _selectedCollegeId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _codeCtrl = TextEditingController();

    if (widget.id != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final courses = await ref.read(coursesProvider.future);
      _existing = courses.firstWhere((c) => c.id == widget.id);
      _nameCtrl.text = _existing!.name;
      _codeCtrl.text = _existing!.code;
      _duration = _existing!.duration;
      _selectedDepartmentId = _existing!.departmentId;
      _selectedCollegeId = _existing!.collegeId;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading course: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(String? userCollegeId, bool isSuperAdmin) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null || _selectedDepartmentId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a department')));
      return;
    }

    final targetCollegeId = isSuperAdmin && (userCollegeId == null || userCollegeId.isEmpty)
        ? _selectedCollegeId
        : (userCollegeId ?? _selectedCollegeId ?? '');

    setState(() => _isLoading = true);
    try {
      final course = Course(
        id: _existing?.id ?? '',
        collegeId: targetCollegeId ?? '',
        departmentId: _selectedDepartmentId!,
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim().toUpperCase(),
        duration: _duration,
        isActive: _existing?.isActive ?? true,
      );

      if (_existing == null) {
        await ref.read(coursesProvider.notifier).addCourse(course);
      } else {
        await ref.read(coursesProvider.notifier).updateCourse(course);
        ref.invalidate(courseByIdProvider(widget.id!));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_existing == null ? 'Course created successfully' : 'Course updated successfully'),
            backgroundColor: AcadexColors.success,
          ),
        );
        context.safePop(fallbackRoute: '/academics/courses');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AcadexColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.id != null;
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isSuperAdmin = user?.role == AppRole.superAdmin;
    final userCollegeId = user?.collegeId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final departmentsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/academics/courses'),
        ),
        title: Text(
          isEdit ? "Edit Course" : "Add Course",
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AcadexPageContainer(
              maxWidth: AcadexLayout.formMaxWidth,
              child: Form(
                key: _formKey,
                child: AcadexFormCard(
                  title: "Course Details",
                  onCancel: () => context.safePop(fallbackRoute: '/academics/courses'),
                  onSave: () => _save(userCollegeId, isSuperAdmin),
                  child: Column(
                    children: [
                      // Department Selector (Scoped to College)
                      AcadexFormField(
                        label: "Department *",
                        child: departmentsAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (e, _) => Text('Error loading departments: $e', style: const TextStyle(color: AcadexColors.error)),
                          data: (depts) {
                            if (depts.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight,
                                  borderRadius: AcadexRadius.borderRadiusMd,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.triangleAlert, color: AcadexColors.warning, size: 18),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'No departments found. Create a department first.',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.push('/academics/departments/new'),
                                      child: const Text('Add Dept'),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return DropdownButtonFormField<String>(
                              dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                              initialValue: _selectedDepartmentId,
                              decoration: const InputDecoration(hintText: "Select Department"),
                              validator: (v) => v == null || v.isEmpty ? 'Department is required' : null,
                              items: depts.map((d) => DropdownMenuItem(value: d.id, child: Text("${d.name} (${d.code})"))).toList(),
                              onChanged: isEdit ? null : (v) => setState(() => _selectedDepartmentId = v),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      AcadexFormField(
                        label: "Course Name *",
                        child: TextFormField(
                          controller: _nameCtrl,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Course Name is required';
                            if (v.trim().length < 2) return 'Must be at least 2 characters';
                            if (v.trim().length > 100) return 'Must be at most 100 characters';
                            return null;
                          },
                          style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                          decoration: const InputDecoration(hintText: "e.g. Bachelor of Technology in CS"),
                        ),
                      ),
                      const SizedBox(height: 14),

                      AcadexFormField(
                        label: "Course Code *",
                        child: TextFormField(
                          controller: _codeCtrl,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Course Code is required';
                            if (v.trim().length < 2) return 'Must be at least 2 characters';
                            if (v.trim().length > 30) return 'Must be at most 30 characters';
                            final regex = RegExp(r'^[A-Za-z0-9\-_]+$');
                            if (!regex.hasMatch(v.trim())) {
                              return 'Only alphanumeric characters, hyphens, and underscores';
                            }
                            return null;
                          },
                          style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                          decoration: const InputDecoration(hintText: "e.g. BTECH-CSE"),
                        ),
                      ),
                      const SizedBox(height: 14),

                      AcadexFormField(
                        label: "Duration (Years) *",
                        child: DropdownButtonFormField<int>(
                          dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                          value: _duration,
                          decoration: const InputDecoration(hintText: "Select Program Duration"),
                          items: [1, 2, 3, 4, 5, 6].map((yrs) => DropdownMenuItem(
                            value: yrs,
                            child: Text('$yrs ${yrs == 1 ? "Year" : "Years"}'),
                          )).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _duration = v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
