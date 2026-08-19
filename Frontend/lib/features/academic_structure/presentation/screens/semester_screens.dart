import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../providers/academic_providers.dart';
import '../../domain/models/academic_models.dart';

class SemesterListScreen extends ConsumerWidget {
  const SemesterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semestersAsync = ref.watch(semestersProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final yearsAsync = ref.watch(academicYearsProvider);
    final theme = Theme.of(context);

    final coursesMap = {for (final c in coursesAsync.valueOrNull ?? <Course>[]) c.id: c.name};
    final yearsMap = {for (final y in yearsAsync.valueOrNull ?? <AcademicYear>[]) y.id: y.name};

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcadexPageHeader(
            title: "Semesters",
            subtitle: "Manage academic terms and semester lifecycle for courses.",
          ),
          AcadexSearchFilterBar(
            searchHint: "Search semesters...",
            onSearchChanged: (v) {},
            onActionTap: () => context.push('/academics/semesters/new'),
            actionLabel: "Add Semester",
          ),
          const SizedBox(height: 24),
          Expanded(
            child: semestersAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: theme.primaryColor)),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: AcadexColors.warning))),
              data: (semesters) => AcadexDataTable(
                columns: const ["Semester Name", "Course", "Academic Year", "Status", "Current", "Actions"],
                rows: semesters.map((s) {
                  final isCurrent = s.isCurrent || s.status == 'active';
                  AcadexBadgeVariant statusVariant;
                  if (s.status == 'active') {
                    statusVariant = AcadexBadgeVariant.success;
                  } else if (s.status == 'upcoming') {
                    statusVariant = AcadexBadgeVariant.info;
                  } else if (s.status == 'completed') {
                    statusVariant = AcadexBadgeVariant.neutral;
                  } else {
                    statusVariant = AcadexBadgeVariant.warning;
                  }

                  return DataRow(cells: [
                    DataCell(
                      Row(
                        children: [
                          Icon(LucideIcons.calendarClock, size: 16, color: isCurrent ? AcadexColors.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          const SizedBox(width: 8),
                          Text(s.name, style: AcadexTypography.body(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataCell(Text(coursesMap[s.courseId] ?? s.courseId)),
                    DataCell(Text(yearsMap[s.academicYearId] ?? s.academicYearId)),
                    DataCell(AcadexBadge(label: s.status.toUpperCase(), variant: statusVariant)),
                    DataCell(
                      isCurrent
                          ? const AcadexBadge(label: "CURRENT", variant: AcadexBadgeVariant.primary)
                          : s.status == 'completed'
                              ? Text("Completed", style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))
                              : TextButton(
                                  child: const Text("Set Current"),
                                  onPressed: () async {
                                    await ref.read(semestersProvider.notifier).activateSemester(s.collegeId, s.courseId, s.id);
                                  },
                                ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(LucideIcons.edit, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                            onPressed: () => context.push('/academics/semesters/edit/${s.id}'),
                          ),
                          if (isCurrent)
                            IconButton(
                              icon: const Icon(LucideIcons.checkCheck, size: 18, color: AcadexColors.info),
                              tooltip: "Mark Semester as Completed",
                              onPressed: () async {
                                await ref.read(semestersProvider.notifier).completeSemester(s.id);
                              },
                            ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 18, color: AcadexColors.warning),
                            onPressed: () async {
                              await ref.read(semestersProvider.notifier).deactivateSemester(s.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ]);
                }).toList(),
                emptyState: AcadexEmptyState(
                  title: "No Semesters",
                  subtitle: "Create a semester to organize sections and batches.",
                  icon: LucideIcons.calendarClock,
                  actionLabel: "Add Semester",
                  onActionTap: () => context.push('/academics/semesters/new'),
                ),
              ),
            ),
          )
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
  late TextEditingController _numberCtrl;
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  String _selectedStatus = 'upcoming';
  bool _isCurrent = false;
  bool _isLoading = false;
  Semester? _existing;
  
  String? _selectedCollegeId;
  String? _selectedDepartmentId;
  String? _selectedCourseId;
  String? _selectedAcademicYearId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _numberCtrl = TextEditingController(text: '1');
    _startCtrl = TextEditingController();
    _endCtrl = TextEditingController();

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
      _numberCtrl.text = _existing!.number.toString();
      _selectedCourseId = _existing!.courseId;
      _selectedAcademicYearId = _existing!.academicYearId;
      _selectedStatus = _existing!.status;
      _isCurrent = _existing!.isCurrent;
      if (_existing!.startDate != null) {
        _startCtrl.text = _existing!.startDate!.toIso8601String().split('T').first;
      }
      if (_existing!.endDate != null) {
        _endCtrl.text = _existing!.endDate!.toIso8601String().split('T').first;
      }
      
      final courses = await ref.read(coursesProvider.future);
      final course = courses.firstWhere((c) => c.id == _selectedCourseId);
      _selectedDepartmentId = course.departmentId;

      final depts = await ref.read(departmentsProvider.future);
      final dept = depts.firstWhere((d) => d.id == _selectedDepartmentId);
      _selectedCollegeId = dept.collegeId;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading semester: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null || _selectedAcademicYearId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course and Academic Year are required')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      DateTime? start = _startCtrl.text.trim().isNotEmpty ? DateTime.tryParse(_startCtrl.text.trim()) : null;
      DateTime? end = _endCtrl.text.trim().isNotEmpty ? DateTime.tryParse(_endCtrl.text.trim()) : null;

      if (start != null && end != null && !end.isAfter(start)) {
        throw Exception("End date must be after start date.");
      }

      final sem = Semester(
        id: _existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        collegeId: _selectedCollegeId ?? 'c1',
        departmentId: _selectedDepartmentId ?? 'd1',
        courseId: _selectedCourseId!,
        academicYearId: _selectedAcademicYearId!,
        name: _nameCtrl.text.trim(),
        number: int.tryParse(_numberCtrl.text.trim()) ?? 1,
        startDate: start,
        endDate: end,
        status: _isCurrent ? 'active' : _selectedStatus,
        isCurrent: _isCurrent,
        isActive: _existing?.isActive ?? true,
      );

      if (_existing == null) {
        await ref.read(semestersProvider.notifier).addSemester(sem);
      } else {
        await ref.read(semestersProvider.notifier).updateSemester(sem);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semester saved successfully'), backgroundColor: AcadexColors.success));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e'), backgroundColor: AcadexColors.warning));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.id != null;
    final collegesAsync = ref.watch(collegesProvider);
    final departmentsAsync = ref.watch(departmentsProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final yearsAsync = ref.watch(academicYearsProvider);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(isEdit ? "Edit Semester" : "Add Semester", style: AcadexTypography.heading3(color: theme.colorScheme.onSurface)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AcadexPageContainer(
              maxWidth: AcadexLayout.formMaxWidth,
              child: Form(
                key: _formKey,
                child: AcadexFormCard(
                  title: "Semester Details",
                  onCancel: () => context.pop(),
                  onSave: _save,
                  child: Column(
                    children: [
                      AcadexFormField(
                        label: "College",
                        child: collegesAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (e, st) => const Text('Error loading colleges', style: TextStyle(color: AcadexColors.warning)),
                          data: (colleges) => DropdownButtonFormField<String>(
                            dropdownColor: theme.cardColor,
                            initialValue: _selectedCollegeId,
                            decoration: const InputDecoration(hintText: "Select College"),
                            validator: (v) => v == null ? 'Required' : null,
                            items: colleges.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                            onChanged: (v) => setState(() {
                              _selectedCollegeId = v;
                              _selectedDepartmentId = null;
                              _selectedCourseId = null;
                            }),
                          ),
                        ),
                      ),
                      AcadexFormField(
                        label: "Department",
                        child: departmentsAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (e, st) => const Text('Error loading departments', style: TextStyle(color: AcadexColors.warning)),
                          data: (depts) {
                            final filtered = _selectedCollegeId == null 
                              ? <Department>[] 
                              : depts.where((d) => d.collegeId == _selectedCollegeId).toList();
                            return DropdownButtonFormField<String>(
                              dropdownColor: theme.cardColor,
                              initialValue: _selectedDepartmentId,
                              decoration: const InputDecoration(hintText: "Select Department"),
                              validator: (v) => v == null ? 'Required' : null,
                              items: filtered.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                              onChanged: (v) => setState(() {
                                _selectedDepartmentId = v;
                                _selectedCourseId = null;
                              }),
                            );
                          }
                        ),
                      ),
                      AcadexFormField(
                        label: "Course",
                        child: coursesAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (e, st) => const Text('Error loading courses', style: TextStyle(color: AcadexColors.warning)),
                          data: (courses) {
                            final filtered = _selectedDepartmentId == null 
                              ? <Course>[] 
                              : courses.where((c) => c.departmentId == _selectedDepartmentId).toList();
                            return DropdownButtonFormField<String>(
                              dropdownColor: theme.cardColor,
                              initialValue: _selectedCourseId,
                              decoration: const InputDecoration(hintText: "Select Course"),
                              validator: (v) => v == null ? 'Required' : null,
                              items: filtered.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                              onChanged: (v) => setState(() => _selectedCourseId = v),
                            );
                          }
                        ),
                      ),
                      AcadexFormField(
                        label: "Academic Year",
                        child: yearsAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (e, st) => const Text('Error loading years', style: TextStyle(color: AcadexColors.warning)),
                          data: (years) {
                            return DropdownButtonFormField<String>(
                              dropdownColor: theme.cardColor,
                              initialValue: _selectedAcademicYearId,
                              decoration: const InputDecoration(hintText: "Select Academic Year"),
                              validator: (v) => v == null ? 'Required' : null,
                              items: years.map((y) => DropdownMenuItem(value: y.id, child: Text(y.name))).toList(),
                              onChanged: (v) => setState(() => _selectedAcademicYearId = v),
                            );
                          }
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: AcadexFormField(
                              label: "Semester Name",
                              child: TextFormField(
                                controller: _nameCtrl,
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                                style: AcadexTypography.body(color: theme.colorScheme.onSurface),
                                decoration: const InputDecoration(hintText: "e.g. Semester 3"),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: AcadexFormField(
                              label: "Semester Number",
                              child: TextFormField(
                                controller: _numberCtrl,
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                                style: AcadexTypography.body(color: theme.colorScheme.onSurface),
                                decoration: const InputDecoration(hintText: "1"),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: AcadexFormField(
                              label: "Start Date (Optional)",
                              child: TextFormField(
                                controller: _startCtrl,
                                style: AcadexTypography.body(color: theme.colorScheme.onSurface),
                                decoration: const InputDecoration(hintText: "YYYY-MM-DD"),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AcadexFormField(
                              label: "End Date (Optional)",
                              child: TextFormField(
                                controller: _endCtrl,
                                style: AcadexTypography.body(color: theme.colorScheme.onSurface),
                                decoration: const InputDecoration(hintText: "YYYY-MM-DD"),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: _isCurrent,
                        title: Text("Set as Current Semester for Course", style: AcadexTypography.body(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Text("Marks any prior active semester for this course as completed.", style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                        onChanged: (checked) {
                          setState(() {
                            _isCurrent = checked ?? false;
                            if (_isCurrent) _selectedStatus = 'active';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

