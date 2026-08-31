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
import '../providers/academic_providers.dart';
import '../../domain/models/academic_models.dart';

class SubjectListScreen extends ConsumerStatefulWidget {
  const SubjectListScreen({super.key});

  @override
  ConsumerState<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends ConsumerState<SubjectListScreen> {
  String _searchQuery = '';
  String _filter = 'all'; // 'all' | 'active' | 'archived' | 'theory' | 'lab'

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);

    final coursesMap = {for (final c in coursesAsync.valueOrNull ?? <Course>[]) c.id: c.name};
    final semsMap = {for (final s in semestersAsync.valueOrNull ?? <Semester>[]) s.id: s.name};

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcadexPageHeader(
            title: "Subjects & Modules",
            subtitle: "Manage course curriculum, lecture credits, and subject specifications.",
          ),
          AcadexSearchFilterBar(
            searchHint: "Search subjects by code or name...",
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onActionTap: () => context.push('/academics/subjects/new'),
            actionLabel: "Add Subject",
          ),
          const SizedBox(height: 10),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                for (final f in [
                  ('all', 'All Subjects'),
                  ('active', 'Active'),
                  ('archived', 'Archived'),
                  ('theory', 'Theory'),
                  ('lab', 'Practical / Lab'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.$2),
                      selected: _filter == f.$1,
                      onSelected: (_) => setState(() => _filter = f.$1),
                      selectedColor: AcadexColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AcadexColors.primary,
                      labelStyle: TextStyle(
                        color: _filter == f.$1 ? AcadexColors.primary : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                        fontWeight: _filter == f.$1 ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: _filter == f.$1 ? AcadexColors.primary : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: subjectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text("Error: $err", style: const TextStyle(color: AcadexColors.error)),
              ),
              data: (subjects) {
                final filtered = subjects.where((s) {
                  if (_filter == 'active' && !s.isActive) return false;
                  if (_filter == 'archived' && s.isActive) return false;
                  if (_filter == 'theory' && s.type.toLowerCase() != 'theory') return false;
                  if (_filter == 'lab' && s.type.toLowerCase() != 'lab' && s.type.toLowerCase() != 'practical') return false;

                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  final courseName = (coursesMap[s.courseId] ?? '').toLowerCase();
                  final semName = (semsMap[s.semesterId] ?? '').toLowerCase();
                  return s.name.toLowerCase().contains(q) ||
                      s.code.toLowerCase().contains(q) ||
                      courseName.contains(q) ||
                      semName.contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return AcadexEmptyState(
                    title: "No Subjects Found",
                    subtitle: _searchQuery.isNotEmpty
                        ? "No subjects match '$_searchQuery'."
                        : "Add curriculum subjects to your semesters and degree programs.",
                    icon: LucideIcons.bookOpen,
                    actionLabel: "Add Subject",
                    onActionTap: () => context.push('/academics/subjects/new'),
                  );
                }

                if (isMobile) {
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final s = filtered[i];
                      final courseName = coursesMap[s.courseId] ?? 'Program';
                      final semName = semsMap[s.semesterId] ?? 'Term';

                      return GestureDetector(
                        onTap: () => context.push('/academics/subjects/${s.id}'),
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
                                            s.code,
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
                                "Program: $courseName • Term: $semName",
                                style: AcadexTypography.caption(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    "${s.credits} Credits",
                                    style: AcadexTypography.caption(
                                      color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "• ${s.type}",
                                    style: AcadexTypography.caption(
                                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.arrowRight, size: 16, color: AcadexColors.primary),
                                    tooltip: "View Details",
                                    onPressed: () => context.push('/academics/subjects/${s.id}'),
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
                                    tooltip: "Edit Subject",
                                    onPressed: () => context.push('/academics/subjects/edit/${s.id}'),
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
                  columns: const ["Subject Name", "Code", "Program (Course)", "Semester / Term", "Credits", "Type", "Status", "Actions"],
                  rows: filtered.map((s) {
                    return DataRow(
                      onSelectChanged: (_) => context.push('/academics/subjects/${s.id}'),
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              const Icon(LucideIcons.bookOpen, size: 16, color: AcadexColors.primary),
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
                              s.code,
                              style: const TextStyle(color: AcadexColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                        DataCell(Text(coursesMap[s.courseId] ?? s.courseId)),
                        DataCell(Text(semsMap[s.semesterId] ?? s.semesterId)),
                        DataCell(Text("${s.credits} Credits", style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(s.type)),
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
                                onPressed: () => context.push('/academics/subjects/${s.id}'),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.edit, size: 18),
                                tooltip: "Edit",
                                onPressed: () => context.push('/academics/subjects/edit/${s.id}'),
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

class SubjectFormScreen extends ConsumerStatefulWidget {
  final String? id;
  const SubjectFormScreen({super.key, this.id});

  @override
  ConsumerState<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends ConsumerState<SubjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _creditsCtrl;
  String _selectedType = 'Theory';
  bool _isLoading = false;
  Subject? _existing;

  String? _selectedCourseId;
  String? _selectedSemesterId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _codeCtrl = TextEditingController();
    _creditsCtrl = TextEditingController(text: '3');

    if (widget.id != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final subjects = await ref.read(subjectsProvider.future);
      _existing = subjects.firstWhere((s) => s.id == widget.id);
      _nameCtrl.text = _existing!.name;
      _codeCtrl.text = _existing!.code;
      _creditsCtrl.text = _existing!.credits.toString();
      _selectedType = _existing!.type;
      _selectedSemesterId = _existing!.semesterId;
      _selectedCourseId = _existing!.courseId;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading subject: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _creditsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null || _selectedSemesterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course and Semester are required')));
      return;
    }

    final credits = int.tryParse(_creditsCtrl.text.trim()) ?? 3;

    setState(() => _isLoading = true);
    try {
      final sems = await ref.read(semestersProvider.future);
      final sem = sems.firstWhere((s) => s.id == _selectedSemesterId);

      final subject = Subject(
        id: _existing?.id ?? '',
        collegeId: _existing?.collegeId ?? sem.collegeId,
        departmentId: _existing?.departmentId ?? sem.departmentId,
        courseId: _selectedCourseId!,
        semesterId: _selectedSemesterId!,
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim().toUpperCase(),
        credits: credits,
        type: _selectedType,
        isActive: _existing?.isActive ?? true,
      );

      if (_existing == null) {
        await ref.read(subjectsProvider.notifier).addSubject(subject);
      } else {
        await ref.read(subjectsProvider.notifier).updateSubject(subject);
        ref.invalidate(subjectByIdProvider(widget.id!));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_existing == null ? 'Subject created successfully' : 'Subject updated successfully'),
            backgroundColor: AcadexColors.success,
          ),
        );
        context.safePop(fallbackRoute: '/academics/subjects');
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
    final semestersAsync = ref.watch(semestersProvider);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/academics/subjects'),
        ),
        title: Text(
          isEdit ? "Edit Subject" : "Add Subject",
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
                  title: "Curriculum Subject Details",
                  onCancel: () => context.safePop(fallbackRoute: '/academics/subjects'),
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
                                    const Text("You must create a course before adding a subject."),
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
                          error: (e, _) => Text('Error loading semesters: $e', style: const TextStyle(color: AcadexColors.error)),
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
                                    const Text("You must create at least one semester before adding a subject."),
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
                              dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                              initialValue: _selectedSemesterId,
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

                      // Name & Code Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: AcadexFormField(
                              label: "Subject Name *",
                              child: TextFormField(
                                controller: _nameCtrl,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Name is required';
                                  if (v.trim().length < 2) return 'Min 2 characters';
                                  if (v.trim().length > 100) return 'Max 100 characters';
                                  return null;
                                },
                                style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                                decoration: const InputDecoration(hintText: "e.g. Data Structures & Algorithms"),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: AcadexFormField(
                              label: "Subject Code *",
                              child: TextFormField(
                                controller: _codeCtrl,
                                textCapitalization: TextCapitalization.characters,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Code is required';
                                  if (v.trim().length < 2) return 'Min 2 characters';
                                  if (v.trim().length > 30) return 'Max 30 characters';
                                  return null;
                                },
                                style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                                decoration: const InputDecoration(hintText: "e.g. CS201"),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Credits & Type Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AcadexFormField(
                              label: "Credits (0 to 10) *",
                              child: TextFormField(
                                controller: _creditsCtrl,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Credits required';
                                  final num = int.tryParse(v.trim());
                                  if (num == null || num < 0 || num > 10) return '0 to 10';
                                  return null;
                                },
                                style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                                decoration: const InputDecoration(hintText: "3"),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AcadexFormField(
                              label: "Subject Type *",
                              child: DropdownButtonFormField<String>(
                                dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                value: _selectedType,
                                decoration: const InputDecoration(),
                                items: const [
                                  DropdownMenuItem(value: 'Theory', child: Text('Theory')),
                                  DropdownMenuItem(value: 'Practical', child: Text('Practical')),
                                  DropdownMenuItem(value: 'Lab', child: Text('Lab')),
                                  DropdownMenuItem(value: 'Elective', child: Text('Elective')),
                                ],
                                onChanged: (v) => setState(() => _selectedType = v ?? 'Theory'),
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
