import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../features/auth/domain/models/auth_state.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/errors/acadex_error.dart';
import '../providers/academic_providers.dart';
import '../providers/department_setup_provider.dart';
import '../widgets/fresh_department_setup_card.dart';
import '../widgets/setup_continuation_dialog.dart';
import '../utils/academic_prerequisite_guard.dart';
import '../../../../core/presentation/widgets/acadex_workflow_context_banner.dart';
import '../../domain/models/academic_models.dart';

class SectionListScreen extends ConsumerStatefulWidget {
  const SectionListScreen({super.key});

  @override
  ConsumerState<SectionListScreen> createState() => _SectionListScreenState();
}

class _SectionListScreenState extends ConsumerState<SectionListScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all' | 'active' | 'archived'
  String? _selectedCourseId;
  String? _selectedAcademicYearId;
  String? _selectedSemesterId;

  void _navigateCreateSection(BuildContext context, List<Course> courses, List<Semester> semesters) {
    final check = AcademicPrerequisiteGuard.checkSectionPrerequisites(
      courses: courses,
      semesters: semesters,
    );
    if (!check.isSatisfied) {
      AcademicPrerequisiteGuard.showBlockerDialog(context, check);
      return;
    }
    context.push('/academics/sections/new');
  }

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(sectionsProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final yearsAsync = ref.watch(academicYearsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);

    final coursesList = coursesAsync.valueOrNull ?? <Course>[];
    final semsList = semestersAsync.valueOrNull ?? <Semester>[];
    final yearsList = yearsAsync.valueOrNull ?? <AcademicYear>[];

    final semsMap = {for (final s in semsList) s.id: s.name};
    final coursesMap = {for (final c in coursesList) c.id: c.name};

    // Filter available semesters by selected course and academic year
    final availableSems = semsList.where((s) {
      if (_selectedCourseId != null && s.courseId != _selectedCourseId) return false;
      if (_selectedAcademicYearId != null && s.academicYearId != _selectedAcademicYearId) return false;
      return true;
    }).toList();

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcadexPageHeader(
            title: "Sections",
            subtitle: "Manage section capacity, classroom cohorts, and academic assignments.",
          ),
          AcadexSearchFilterBar(
            searchHint: "Search sections, courses, or semesters...",
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onActionTap: () => _navigateCreateSection(context, coursesList, semsList),
            actionLabel: "Create Section",
          ),
          const SizedBox(height: 10),

          // Contextual Selector Row: Course + Academic Year + Semester + Clear Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                // Course Context Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(
                      color: _selectedCourseId != null ? AcadexColors.primary : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCourseId ?? 'all',
                      isDense: true,
                      dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('All Courses', style: TextStyle(fontSize: 12))),
                        for (final c in coursesList)
                          DropdownMenuItem(value: c.id, child: Text("${c.name} (${c.code})", style: const TextStyle(fontSize: 12))),
                      ],
                      onChanged: (v) => setState(() {
                        _selectedCourseId = v == 'all' ? null : v;
                        _selectedSemesterId = null;
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Academic Year Context Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(
                      color: _selectedAcademicYearId != null ? AcadexColors.primary : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAcademicYearId ?? 'all',
                      isDense: true,
                      dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('All Academic Years', style: TextStyle(fontSize: 12))),
                        for (final y in yearsList)
                          DropdownMenuItem(value: y.id, child: Text(y.name, style: const TextStyle(fontSize: 12))),
                      ],
                      onChanged: (v) => setState(() {
                        _selectedAcademicYearId = v == 'all' ? null : v;
                        _selectedSemesterId = null;
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Semester Context Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(
                      color: _selectedSemesterId != null ? AcadexColors.primary : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSemesterId ?? 'all',
                      isDense: true,
                      dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('All Semesters', style: TextStyle(fontSize: 12))),
                        for (final s in availableSems)
                          DropdownMenuItem(value: s.id, child: Text("${s.name} (Term ${s.number})", style: const TextStyle(fontSize: 12))),
                      ],
                      onChanged: (v) => setState(() => _selectedSemesterId = v == 'all' ? null : v),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Clear Context Button
                if (_selectedCourseId != null || _selectedAcademicYearId != null || _selectedSemesterId != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(LucideIcons.x, size: 14, color: AcadexColors.error),
                      label: const Text('Reset Filter', style: TextStyle(fontSize: 12, color: AcadexColors.error)),
                      backgroundColor: AcadexColors.error.withValues(alpha: 0.1),
                      side: BorderSide(color: AcadexColors.error.withValues(alpha: 0.3)),
                      onPressed: () => setState(() {
                        _selectedCourseId = null;
                        _selectedAcademicYearId = null;
                        _selectedSemesterId = null;
                      }),
                    ),
                  ),

                // Status Filter Chips
                for (final f in [
                  ('all', 'All Sections'),
                  ('active', 'Active'),
                  ('archived', 'Archived'),
                ])
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
            child: sectionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => AcadexErrorState.fromError(
                error: err,
                title: "Unable to load sections",
                onRetry: () => ref.invalidate(sectionsProvider),
              ),
              data: (sections) {
                // If department has no sections at all, show guided roadmap
                if (sections.isEmpty) {
                  if (coursesList.isEmpty) {
                    return FreshDepartmentSetupCard(
                      currentStep: AcademicSetupStep.course,
                      actionLabel: "Create Course",
                      onAction: () => context.push('/academics/courses/new'),
                      customMessage: "No courses found. Create a course first before creating sections.",
                    );
                  }
                  if (semsList.isEmpty) {
                    return FreshDepartmentSetupCard(
                      currentStep: AcademicSetupStep.semester,
                      actionLabel: "Create Semester",
                      onAction: () => context.push('/academics/semesters/new'),
                      customMessage: "No semesters found. Create semesters for your courses before creating sections.",
                    );
                  }
                  return FreshDepartmentSetupCard(
                    currentStep: AcademicSetupStep.section,
                    actionLabel: "Create First Section",
                    onAction: () => context.push('/academics/sections/new'),
                    customMessage: "Courses and semesters are configured. Create your first class section.",
                  );
                }

                final filtered = sections.where((s) {
                  if (_selectedCourseId != null && s.courseId != _selectedCourseId) return false;
                  if (_selectedSemesterId != null && s.semesterId != _selectedSemesterId) return false;
                  if (_selectedAcademicYearId != null && s.academicYearId != _selectedAcademicYearId) return false;
                  if (_statusFilter == 'active' && !s.isActive) return false;
                  if (_statusFilter == 'archived' && s.isActive) return false;

                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  final semName = (semsMap[s.semesterId] ?? '').toLowerCase();
                  final courseName = (coursesMap[s.courseId] ?? '').toLowerCase();
                  return s.name.toLowerCase().contains(q) ||
                      semName.contains(q) ||
                      courseName.contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return AcadexEmptyState.filterEmpty(
                    filterSummary: _searchQuery.isNotEmpty ? "query '$_searchQuery'" : "selected filter criteria",
                    onClearFilters: () => setState(() {
                      _searchQuery = '';
                      _selectedCourseId = null;
                      _selectedAcademicYearId = null;
                      _selectedSemesterId = null;
                      _statusFilter = 'all';
                    }),
                  );
                }

                if (isMobile) {
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final s = filtered[i];
                      final semName = semsMap[s.semesterId] ?? 'Term';
                      final courseName = coursesMap[s.courseId] ?? 'Course';

                      return GestureDetector(
                        onTap: () => context.push('/academics/sections/${s.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                            borderRadius: AcadexRadius.borderRadiusLg,
                            border: Border.all(
                              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AcadexColors.primary.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            "${s.capacity} Seats",
                                            style: const TextStyle(
                                              color: AcadexColors.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Section ${s.name}",
                                            style: AcadexTypography.body(
                                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                            ).copyWith(fontWeight: FontWeight.w700),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: s.isActive
                                          ? (isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight)
                                          : (isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft),
                                      borderRadius: AcadexRadius.borderRadiusFull,
                                    ),
                                    child: Text(
                                      s.isActive ? "Active" : "Archived",
                                      style: TextStyle(
                                        color: s.isActive ? AcadexColors.success : AcadexColors.inkMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                                Text(
                                  "Course: $courseName • Semester: $semName",
                                  style: AcadexTypography.caption(
                                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.arrowRight, size: 16, color: AcadexColors.primary),
                                    tooltip: "View Details",
                                    onPressed: () => context.push('/academics/sections/${s.id}'),
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
                                    tooltip: "Edit Section",
                                    onPressed: () => context.push('/academics/sections/edit/${s.id}'),
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
                  columns: const ["Section Name", "Course", "Semester", "Seating Capacity", "Status", "Actions"],
                  rows: filtered.map((s) {
                    return DataRow(
                      onSelectChanged: (_) => context.push('/academics/sections/${s.id}'),
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              const Icon(LucideIcons.users, size: 16, color: AcadexColors.primary),
                              const SizedBox(width: 8),
                              Text("Section ${s.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        DataCell(Text(coursesMap[s.courseId] ?? s.courseId)),
                        DataCell(Text(semsMap[s.semesterId] ?? s.semesterId)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AcadexColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${s.capacity} seats",
                              style: const TextStyle(color: AcadexColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: s.isActive ? AcadexColors.successLight : AcadexColors.canvasSoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              s.isActive ? "Active" : "Archived",
                              style: TextStyle(
                                color: s.isActive ? AcadexColors.success : AcadexColors.inkMuted,
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
                                onPressed: () => context.push('/academics/sections/${s.id}'),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.edit, size: 18),
                                tooltip: "Edit",
                                onPressed: () => context.push('/academics/sections/edit/${s.id}'),
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

class SectionFormScreen extends ConsumerStatefulWidget {
  final String? id;
  final String? initialCourseId;
  final String? initialSemesterId;
  const SectionFormScreen({
    super.key,
    this.id,
    this.initialCourseId,
    this.initialSemesterId,
  });

  @override
  ConsumerState<SectionFormScreen> createState() => _SectionFormScreenState();
}

class _SectionFormScreenState extends ConsumerState<SectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _capacityCtrl;
  bool _isLoading = false;
  Section? _existing;

  String? _selectedCourseId;
  String? _selectedSemesterId;
  bool _showManualContext = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _capacityCtrl = TextEditingController(text: '60');
    _selectedCourseId = widget.initialCourseId;
    _selectedSemesterId = widget.initialSemesterId;

    if (widget.id != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final sections = await ref.read(sectionsProvider.future);
      _existing = sections.firstWhere((s) => s.id == widget.id);
      _nameCtrl.text = _existing!.name;
      _capacityCtrl.text = _existing!.capacity.toString();
      _selectedSemesterId = _existing!.semesterId;
      _selectedCourseId = _existing!.courseId;
    } catch (e) {
      if (mounted) AcadexSnackBar.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSemesterId == null) {
      AcadexSnackBar.showWarning(context, 'Please select a Semester');
      return;
    }

    final cap = int.tryParse(_capacityCtrl.text.trim()) ?? 60;
    if (cap <= 0) {
      AcadexSnackBar.showWarning(context, 'Capacity must be greater than 0');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final sems = await ref.read(semestersProvider.future);
      final sem = sems.firstWhere((s) => s.id == _selectedSemesterId);

      final section = Section(
        id: _existing?.id ?? '',
        collegeId: _existing?.collegeId ?? sem.collegeId,
        departmentId: _existing?.departmentId ?? sem.departmentId,
        courseId: sem.courseId,
        academicYearId: sem.academicYearId,
        semesterId: _selectedSemesterId!,
        name: _nameCtrl.text.trim().toUpperCase(),
        capacity: cap,
        status: _existing?.status ?? 'active',
        isActive: _existing?.isActive ?? true,
      );

      if (_existing == null) {
        await ref.read(sectionsProvider.notifier).addSection(section);
        ref.invalidate(sectionsProvider);
        if (section.departmentId.isNotEmpty) {
          ref.invalidate(departmentSetupProvider(section.departmentId));
        }

        final freshSections = await ref.read(sectionsProvider.future);
        final createdSection = freshSections.where((s) =>
            s.semesterId == section.semesterId &&
            s.name.toUpperCase() == section.name.toUpperCase()).firstOrNull ?? section;

        if (mounted) {
          AcadexSnackBar.showSuccess(context, 'Section created successfully.');

          SetupContinuationDialog.show(
            context,
            title: 'Section Created Successfully',
            entityName: 'Section ${createdSection.name}',
            message: 'Section ${createdSection.name} is ready. Continue to define syllabus subjects for this semester.',
            primaryActionLabel: 'Continue to Subject',
            onContinue: () {
              context.push(
                '/academics/subjects/new?courseId=${createdSection.courseId}&semesterId=${createdSection.semesterId}&sectionId=${createdSection.id}',
              );
            },
            secondaryActionLabel: 'Done',
            onDone: () => context.safePop(fallbackRoute: '/academics/sections'),
          );
        }
      } else {
        await ref.read(sectionsProvider.notifier).updateSection(section);
        ref.invalidate(sectionByIdProvider(widget.id!));
        if (section.departmentId.isNotEmpty) {
          ref.invalidate(departmentSetupProvider(section.departmentId));
        }

        if (mounted) {
          AcadexSnackBar.showSuccess(context, 'Section updated successfully.');
          context.safePop(fallbackRoute: '/academics/sections');
        }
      }
    } catch (e) {
      if (mounted) {
        AcadexSnackBar.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.id != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coursesAsync = ref.watch(coursesProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isHod = user?.role == AppRole.hod;
    final userDepartmentId = user?.departmentId ?? '';
    final deptMap = ref.watch(departmentMapProvider);
    final effectiveDeptName = deptMap[userDepartmentId]?.name ??
        (userDepartmentId.isNotEmpty ? userDepartmentId : 'Assigned Department');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/academics/sections'),
        ),
        title: Text(
          isEdit ? "Edit Section" : "Create Section",
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontSize: 18),
        ),
      ),
      body: (isEdit && _existing == null && _isLoading)
          ? const Center(child: CircularProgressIndicator())
          : AcadexPageContainer(
              maxWidth: AcadexLayout.formMaxWidth,
              child: Form(
                key: _formKey,
                child: AcadexFormCard(
                  title: isEdit ? "Edit Section" : "Section Information",
                  isSaving: _isLoading,
                  saveLabel: isEdit ? "Update Section" : "Create Section",
                  onCancel: () => context.safePop(fallbackRoute: '/academics/sections'),
                  onSave: _save,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Department Info for HOD
                      if (isHod && effectiveDeptName.isNotEmpty) ...[
                        AcadexFormField(
                          label: "Department",
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                              borderRadius: AcadexRadius.borderRadiusMd,
                              border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.building2, size: 18, color: AcadexColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    effectiveDeptName,
                                    style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const AcadexBadge(label: "YOUR DEPARTMENT", variant: AcadexBadgeVariant.primary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Contextual Header when entered with known Course / Semester
                      Builder(builder: (context) {
                        final hasInheritedContext = !isEdit &&
                            widget.initialCourseId != null &&
                            _selectedCourseId != null &&
                            !_showManualContext;
                        final selectedCourse = coursesAsync.valueOrNull
                            ?.where((c) => c.id == _selectedCourseId)
                            .firstOrNull;
                        final selectedSemester = semestersAsync.valueOrNull
                            ?.where((s) => s.id == _selectedSemesterId)
                            .firstOrNull;

                        if (hasInheritedContext && selectedCourse != null) {
                          return AcadexWorkflowContextBanner(
                            targetEntityName: 'Section',
                            contextItems: [
                              AcadexContextItem(
                                label: 'Course',
                                value: '${selectedCourse.name} (${selectedCourse.code})',
                                icon: LucideIcons.bookOpen,
                              ),
                              if (selectedSemester != null)
                                AcadexContextItem(
                                  label: 'Semester',
                                  value: selectedSemester.name,
                                  icon: LucideIcons.calendar,
                                ),
                            ],
                            onChangeContext: () => setState(() => _showManualContext = true),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Course Selector
                            AcadexFormField(
                              label: "Course *",
                              child: coursesAsync.when(
                                loading: () => const LinearProgressIndicator(),
                                error: (e, _) => Text(AcadexException.sanitizedMessage(e), style: const TextStyle(color: AcadexColors.error)),
                                data: (courses) {
                                  if (courses.isEmpty) {
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.warningLight,
                                        borderRadius: AcadexRadius.borderRadiusMd,
                                        border: Border.all(color: AcadexColors.warning),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("No Courses Found", style: TextStyle(fontWeight: FontWeight.bold, color: AcadexColors.warning)),
                                          const SizedBox(height: 4),
                                          const Text("You must create a course before creating a section."),
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: () => context.push('/academics/courses/new'),
                                            child: const Text("Create Course"),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return DropdownButtonFormField<String>(
                                    dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                    initialValue: _selectedCourseId,
                                    decoration: const InputDecoration(hintText: "Select Course"),
                                    validator: (v) => v == null ? 'Course is required' : null,
                                    items: courses.map((c) => DropdownMenuItem(value: c.id, child: Text("${c.name} (${c.code})"))).toList(),
                                    onChanged: isEdit
                                        ? null
                                        : (v) => setState(() {
                                              _selectedCourseId = v;
                                              _selectedSemesterId = null;
                                            }),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Semester Selector (Filtered to selected course)
                            AcadexFormField(
                              label: "Semester / Academic Term *",
                              child: semestersAsync.when(
                                loading: () => const LinearProgressIndicator(),
                                error: (e, _) => Text(AcadexException.sanitizedMessage(e), style: const TextStyle(color: AcadexColors.error)),
                                data: (semesters) {
                                  final availableSems = _selectedCourseId == null
                                      ? semesters
                                      : semesters.where((s) => s.courseId == _selectedCourseId).toList();

                                  if (semesters.isEmpty) {
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.warningLight,
                                        borderRadius: AcadexRadius.borderRadiusMd,
                                        border: Border.all(color: AcadexColors.warning),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("No Semesters Found", style: TextStyle(fontWeight: FontWeight.bold, color: AcadexColors.warning)),
                                          const SizedBox(height: 4),
                                          const Text("You must create at least one semester before adding a section."),
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: () => context.push('/academics/semesters/new'),
                                            child: const Text("Create Semester"),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return DropdownButtonFormField<String>(
                                    key: ValueKey('section_sem_dropdown_$_selectedCourseId'),
                                    dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                    value: _selectedSemesterId,
                                    decoration: const InputDecoration(hintText: "Select Semester Term"),
                                    validator: (v) => v == null ? 'Semester is required' : null,
                                    items: availableSems.map((s) => DropdownMenuItem(value: s.id, child: Text("${s.name} (Term ${s.number})"))).toList(),
                                    onChanged: isEdit
                                        ? null
                                        : (v) => setState(() {
                                              _selectedSemesterId = v;
                                              if (v != null && _selectedCourseId == null) {
                                                final sem = semesters.firstWhere((s) => s.id == v);
                                                _selectedCourseId = sem.courseId;
                                              }
                                            }),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                        );
                      }),

                      // Section Name & Capacity Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: AcadexFormField(
                              label: "Section Name *",
                              child: TextFormField(
                                controller: _nameCtrl,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Name is required';
                                  if (v.trim().length > 30) return 'Max 30 characters';
                                  return null;
                                },
                                style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                                decoration: const InputDecoration(hintText: "e.g. A, B, or C"),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: AcadexFormField(
                              label: "Seating Capacity *",
                              child: TextFormField(
                                controller: _capacityCtrl,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Required';
                                  final num = int.tryParse(v.trim());
                                  if (num == null || num <= 0) return 'Min 1';
                                  return null;
                                },
                                style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                                decoration: const InputDecoration(hintText: "60"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
