import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../providers/academic_providers.dart';
import '../../domain/models/academic_models.dart';

class SemesterListScreen extends ConsumerStatefulWidget {
  const SemesterListScreen({super.key});

  @override
  ConsumerState<SemesterListScreen> createState() => _SemesterListScreenState();
}

class _SemesterListScreenState extends ConsumerState<SemesterListScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all' | 'current' | 'active' | 'upcoming' | 'completed'

  @override
  Widget build(BuildContext context) {
    final semestersAsync = ref.watch(semestersProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final yearsAsync = ref.watch(academicYearsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);

    final coursesMap = {for (final c in coursesAsync.valueOrNull ?? <Course>[]) c.id: c.name};
    final yearsMap = {for (final y in yearsAsync.valueOrNull ?? <AcademicYear>[]) y.id: y.name};

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcadexPageHeader(
            title: "Semesters & Terms",
            subtitle: "Manage academic terms, semester numbers, curricula, and current cohorts.",
          ),
          AcadexSearchFilterBar(
            searchHint: "Search semesters or courses...",
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onActionTap: () => context.push('/academics/semesters/new'),
            actionLabel: "Add Semester",
          ),
          const SizedBox(height: 10),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                for (final f in [
                  ('all', 'All'),
                  ('current', 'Current Term'),
                  ('active', 'Active'),
                  ('upcoming', 'Upcoming'),
                  ('completed', 'Completed'),
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
            child: semestersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text("Error: $err", style: const TextStyle(color: AcadexColors.error)),
              ),
              data: (semesters) {
                final filtered = semesters.where((s) {
                  if (_statusFilter == 'current' && !s.isCurrent) return false;
                  if (_statusFilter == 'active' && (!s.isActive || s.status == 'completed' || s.status == 'archived')) return false;
                  if (_statusFilter == 'upcoming' && s.status != 'upcoming') return false;
                  if (_statusFilter == 'completed' && s.status != 'completed' && s.status != 'archived') return false;

                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  final cName = (coursesMap[s.courseId] ?? '').toLowerCase();
                  final yName = (yearsMap[s.academicYearId] ?? '').toLowerCase();
                  return s.name.toLowerCase().contains(q) ||
                      cName.contains(q) ||
                      yName.contains(q) ||
                      'term ${s.number}'.contains(q) ||
                      'semester ${s.number}'.contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return AcadexEmptyState(
                    title: "No Semesters Found",
                    subtitle: _searchQuery.isNotEmpty
                        ? "No semesters match '$_searchQuery'."
                        : "Create semester cycles for your degree programs and academic years.",
                    icon: LucideIcons.calendarClock,
                    actionLabel: "Add Semester",
                    onActionTap: () => context.push('/academics/semesters/new'),
                  );
                }

                if (isMobile) {
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final s = filtered[i];
                      final cName = coursesMap[s.courseId] ?? 'Course';
                      final yName = yearsMap[s.academicYearId] ?? 'Session';

                      return GestureDetector(
                        onTap: () => context.push('/academics/semesters/${s.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                            borderRadius: AcadexRadius.borderRadiusLg,
                            border: Border.all(
                              color: s.isCurrent
                                  ? AcadexColors.primary
                                  : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                              width: s.isCurrent ? 1.5 : 1,
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
                                            "Term ${s.number}",
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
                                            s.name,
                                            style: AcadexTypography.body(
                                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                            ).copyWith(fontWeight: FontWeight.w700),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (s.isCurrent)
                                    const AcadexBadge(label: "CURRENT", variant: AcadexBadgeVariant.primary)
                                  else
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
                                "Program: $cName",
                                style: AcadexTypography.caption(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ).copyWith(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Academic Year: $yName",
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
                                    onPressed: () => context.push('/academics/semesters/${s.id}'),
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
                                    tooltip: "Edit Semester",
                                    onPressed: () => context.push('/academics/semesters/edit/${s.id}'),
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
                  columns: const ["Semester Name", "Term #", "Program (Course)", "Academic Year", "Current", "Status", "Actions"],
                  rows: filtered.map((s) {
                    return DataRow(
                      onSelectChanged: (_) => context.push('/academics/semesters/${s.id}'),
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              Icon(LucideIcons.calendarClock, size: 16, color: s.isCurrent ? AcadexColors.primary : AcadexColors.inkMuted),
                              const SizedBox(width: 8),
                              Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AcadexColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "Term ${s.number}",
                              style: const TextStyle(color: AcadexColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                        DataCell(Text(coursesMap[s.courseId] ?? s.courseId)),
                        DataCell(Text(yearsMap[s.academicYearId] ?? s.academicYearId)),
                        DataCell(
                          s.isCurrent
                              ? const AcadexBadge(label: "CURRENT", variant: AcadexBadgeVariant.primary)
                              : const Text("—", style: TextStyle(color: AcadexColors.inkMuted)),
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
                                onPressed: () => context.push('/academics/semesters/${s.id}'),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.edit, size: 18),
                                tooltip: "Edit",
                                onPressed: () => context.push('/academics/semesters/edit/${s.id}'),
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

class SemesterFormScreen extends ConsumerStatefulWidget {
  final String? id;
  const SemesterFormScreen({super.key, this.id});

  @override
  ConsumerState<SemesterFormScreen> createState() => _SemesterFormScreenState();
}

class _SemesterFormScreenState extends ConsumerState<SemesterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  int _semesterNumber = 1;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrent = false;
  bool _isLoading = false;
  Semester? _existing;

  String? _selectedCourseId;
  String? _selectedAcademicYearId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();

    if (widget.id != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final sems = await ref.read(semestersProvider.future);
      _existing = sems.firstWhere((s) => s.id == widget.id);
      _nameCtrl.text = _existing!.name;
      _semesterNumber = _existing!.number;
      _selectedCourseId = _existing!.courseId;
      _selectedAcademicYearId = _existing!.academicYearId;
      _isCurrent = _existing!.isCurrent;
      _startDate = _existing!.startDate;
      _endDate = _existing!.endDate;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading semester: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null || _selectedAcademicYearId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both a Course and an Academic Year')),
      );
      return;
    }
    if (_startDate != null && _endDate != null && !_endDate!.isAfter(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after Start date')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final sem = Semester(
        id: _existing?.id ?? '',
        collegeId: _existing?.collegeId ?? '',
        departmentId: _existing?.departmentId ?? '',
        courseId: _selectedCourseId!,
        academicYearId: _selectedAcademicYearId!,
        name: _nameCtrl.text.trim(),
        number: _semesterNumber,
        startDate: _startDate,
        endDate: _endDate,
        status: _isCurrent ? 'active' : (_existing?.status ?? 'upcoming'),
        isCurrent: _isCurrent,
        isActive: _existing?.isActive ?? true,
      );

      if (_existing == null) {
        await ref.read(semestersProvider.notifier).addSemester(sem);
      } else {
        await ref.read(semestersProvider.notifier).updateSemester(sem);
        ref.invalidate(semesterByIdProvider(widget.id!));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_existing == null ? 'Semester created successfully' : 'Semester updated successfully'),
            backgroundColor: AcadexColors.success,
          ),
        );
        context.safePop(fallbackRoute: '/academics/semesters');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coursesAsync = ref.watch(coursesProvider);
    final yearsAsync = ref.watch(academicYearsProvider);
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/academics/semesters'),
        ),
        title: Text(
          isEdit ? "Edit Semester" : "Add Semester",
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
                  title: "Semester Term Details",
                  onCancel: () => context.safePop(fallbackRoute: '/academics/semesters'),
                  onSave: _save,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Selector
                      AcadexFormField(
                        label: "Degree Program (Course) *",
                        child: coursesAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Error loading courses: $e', style: const TextStyle(color: AcadexColors.error)),
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
                                    const Text("You must create at least one course (degree program) before adding a semester."),
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
                              decoration: const InputDecoration(hintText: "Select Degree Program / Course"),
                              validator: (v) => v == null ? 'Course is required' : null,
                              items: courses.map((c) => DropdownMenuItem(value: c.id, child: Text("${c.name} (${c.code})"))).toList(),
                              onChanged: isEdit ? null : (v) => setState(() => _selectedCourseId = v),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Academic Year Selector
                      AcadexFormField(
                        label: "Academic Session (Year) *",
                        child: yearsAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Error loading academic years: $e', style: const TextStyle(color: AcadexColors.error)),
                          data: (years) {
                            if (years.isEmpty) {
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
                                    const Text("No Academic Years Found", style: TextStyle(fontWeight: FontWeight.bold, color: AcadexColors.warning)),
                                    const SizedBox(height: 4),
                                    const Text("You must create at least one academic session/year before adding a semester."),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () => context.push('/academics/academic_years/new'),
                                      child: const Text("Create Academic Year"),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return DropdownButtonFormField<String>(
                              dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                              initialValue: _selectedAcademicYearId,
                              decoration: const InputDecoration(hintText: "Select Academic Session"),
                              validator: (v) => v == null ? 'Academic Year is required' : null,
                              items: years.map((y) => DropdownMenuItem(value: y.id, child: Text(y.name))).toList(),
                              onChanged: isEdit ? null : (v) => setState(() => _selectedAcademicYearId = v),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Name & Number Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: AcadexFormField(
                              label: "Semester Name *",
                              child: TextFormField(
                                controller: _nameCtrl,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Name is required';
                                  if (v.trim().length < 2) return 'Min 2 characters';
                                  if (v.trim().length > 50) return 'Max 50 characters';
                                  return null;
                                },
                                style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                                decoration: const InputDecoration(hintText: "e.g. Semester 1 or Fall 2026"),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: AcadexFormField(
                              label: "Term # *",
                              child: DropdownButtonFormField<int>(
                                dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                value: _semesterNumber,
                                decoration: const InputDecoration(),
                                items: List.generate(12, (i) => i + 1)
                                    .map((n) => DropdownMenuItem(value: n, child: Text("Term $n")))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      _semesterNumber = v;
                                      if (_nameCtrl.text.isEmpty || _nameCtrl.text.startsWith('Semester ')) {
                                        _nameCtrl.text = "Semester $v";
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Optional Start Date & End Date
                      Row(
                        children: [
                          Expanded(
                            child: AcadexFormField(
                              label: "Start Date (Optional)",
                              child: InkWell(
                                onTap: () => _pickDate(true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                    ),
                                    borderRadius: AcadexRadius.borderRadiusMd,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _startDate != null ? dateFormat.format(_startDate!) : "Select Date",
                                        style: AcadexTypography.body(
                                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                        ),
                                      ),
                                      Icon(LucideIcons.calendar, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AcadexFormField(
                              label: "End Date (Optional)",
                              child: InkWell(
                                onTap: () => _pickDate(false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                    ),
                                    borderRadius: AcadexRadius.borderRadiusMd,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _endDate != null ? dateFormat.format(_endDate!) : "Select Date",
                                        style: AcadexTypography.body(
                                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                        ),
                                      ),
                                      Icon(LucideIcons.calendar, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Current Term Switch
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                          borderRadius: AcadexRadius.borderRadiusMd,
                          border: Border.all(
                            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                          ),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _isCurrent,
                          activeThumbColor: AcadexColors.primary,
                          title: Text(
                            "Set as Current Ongoing Term",
                            style: AcadexTypography.body(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ).copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          subtitle: Text(
                            "Indicates this semester is currently active for teaching and section scheduling.",
                            style: AcadexTypography.caption(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ).copyWith(fontSize: 11),
                          ),
                          onChanged: (v) => setState(() => _isCurrent = v),
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
