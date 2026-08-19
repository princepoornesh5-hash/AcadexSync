import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../providers/academic_providers.dart';
import '../../domain/models/academic_models.dart';

class SubjectListScreen extends ConsumerWidget {
  const SubjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcadexPageHeader(
            title: "Subjects",
            subtitle: "Manage subjects, credits, and lab/theory types.",
          ),
          AcadexSearchFilterBar(
            searchHint: "Search subjects...",
            onSearchChanged: (v) {},
            onActionTap: () => context.push('/academics/subjects/new'),
            actionLabel: "Add Subject",
          ),
          const SizedBox(height: 24),
          Expanded(
            child: subjectsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: AcadexColors.warning))),
              data: (subjects) => AcadexDataTable(
                columns: const ["Code", "Name", "Credits", "Type", "Department", "Status", "Actions"],
                rows: subjects.map((s) => DataRow(cells: [
                  DataCell(Text(s.code, style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
                  DataCell(Text(s.name)),
                  DataCell(Text(s.credits.toString())),
                  DataCell(Text(s.type)),
                  DataCell(Text(s.departmentId)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: s.isActive ? Theme.of(context).primaryColor.withValues(alpha: 0.2) : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.1) ?? AcadexColors.inkMuted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(s.isActive ? "Active" : "Inactive", style: TextStyle(color: s.isActive ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(icon: Icon(LucideIcons.edit, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), onPressed: () => context.push('/academics/subjects/edit/${s.id}')),
                        IconButton(icon: const Icon(LucideIcons.trash2, size: 18, color: AcadexColors.warning), onPressed: () {}),
                      ],
                    )
                  ),
                ])).toList(),
                emptyState: AcadexEmptyState(
                  title: "No Subjects",
                  subtitle: "Add subjects to departments and semesters.",
                  icon: LucideIcons.bookOpen,
                  actionLabel: "Add Subject",
                  onActionTap: () => context.push('/academics/subjects/new'),
                ),
              ),
            ),
          )
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
  bool _isElective = false;
  bool _isLoading = false;
  Subject? _existing;
  
  String? _selectedCollegeId;
  String? _selectedDepartmentId;
  String? _selectedCourseId;
  String? _selectedSemesterId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _codeCtrl = TextEditingController();
    _creditsCtrl = TextEditingController();

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
      _selectedSemesterId = _existing!.semesterId;
      _selectedDepartmentId = _existing!.departmentId;
      
      final sems = await ref.read(semestersProvider.future);
      final sem = sems.firstWhere((s) => s.id == _selectedSemesterId);
      _selectedCourseId = sem.courseId;

      final depts = await ref.read(departmentsProvider.future);
      final dept = depts.firstWhere((d) => d.id == _selectedDepartmentId);
      _selectedCollegeId = dept.collegeId;
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
    if (_selectedDepartmentId == null || _selectedSemesterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department and Semester are required')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final subject = Subject(
        id: _existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        collegeId: 'c1', // Fixed placeholder
        departmentId: _selectedDepartmentId!,
        semesterId: _selectedSemesterId!,
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim().toUpperCase(),
        credits: int.tryParse(_creditsCtrl.text.trim()) ?? 3,
        type: _existing?.type ?? 'Theory',
        isActive: _existing?.isActive ?? true,
      );

      if (_existing == null) {
        await ref.read(subjectsProvider.notifier).addSubject(subject);
      } else {
        await ref.read(subjectsProvider.notifier).updateSubject(subject);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject saved successfully')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
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
    final semestersAsync = ref.watch(semestersProvider);
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(isEdit ? "Edit Subject" : "Add Subject", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AcadexPageContainer(
              maxWidth: AcadexLayout.formMaxWidth,
              child: Form(
                key: _formKey,
                child: AcadexFormCard(
                  title: "Subject Details",
                  onCancel: () => context.pop(),
                  onSave: _save,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AcadexFormField(
                              label: "College",
                              child: collegesAsync.when(
                                loading: () => const CircularProgressIndicator(),
                                error: (e, st) => Text('Error', style: TextStyle(color: AcadexColors.warning)),
                                data: (colleges) => DropdownButtonFormField<String>(
                                  dropdownColor: Theme.of(context).cardColor,
                                  initialValue: _selectedCollegeId,
                                  decoration: const InputDecoration(hintText: "Select College"),
                                  validator: (v) => v == null ? 'Required' : null,
                                  items: colleges.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                  onChanged: (v) => setState(() {
                                    _selectedCollegeId = v;
                                    _selectedDepartmentId = null;
                                    _selectedCourseId = null;
                                    _selectedSemesterId = null;
                                  }),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AcadexFormField(
                              label: "Department",
                              child: departmentsAsync.when(
                                loading: () => const CircularProgressIndicator(),
                                error: (e, st) => Text('Error', style: TextStyle(color: AcadexColors.warning)),
                                data: (depts) {
                                  final filtered = _selectedCollegeId == null 
                                    ? <Department>[] 
                                    : depts.where((d) => d.collegeId == _selectedCollegeId).toList();
                                  return DropdownButtonFormField<String>(
                                    dropdownColor: Theme.of(context).cardColor,
                                    initialValue: _selectedDepartmentId,
                                    decoration: const InputDecoration(hintText: "Select Department"),
                                    validator: (v) => v == null ? 'Required' : null,
                                    items: filtered.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                                    onChanged: (v) => setState(() {
                                      _selectedDepartmentId = v;
                                      _selectedCourseId = null;
                                      _selectedSemesterId = null;
                                    }),
                                  );
                                }
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: AcadexFormField(
                              label: "Course",
                              child: coursesAsync.when(
                                loading: () => const CircularProgressIndicator(),
                                error: (e, st) => Text('Error', style: TextStyle(color: AcadexColors.warning)),
                                data: (courses) {
                                  final filtered = _selectedDepartmentId == null 
                                    ? <Course>[] 
                                    : courses.where((c) => c.departmentId == _selectedDepartmentId).toList();
                                  return DropdownButtonFormField<String>(
                                    dropdownColor: Theme.of(context).cardColor,
                                    initialValue: _selectedCourseId,
                                    decoration: const InputDecoration(hintText: "Select Course"),
                                    validator: (v) => v == null ? 'Required' : null,
                                    items: filtered.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                                    onChanged: (v) => setState(() {
                                      _selectedCourseId = v;
                                      _selectedSemesterId = null;
                                    }),
                                  );
                                }
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AcadexFormField(
                              label: "Semester",
                              child: semestersAsync.when(
                                loading: () => const CircularProgressIndicator(),
                                error: (e, st) => Text('Error', style: TextStyle(color: AcadexColors.warning)),
                                data: (sems) {
                                  final filtered = _selectedCourseId == null 
                                    ? <Semester>[] 
                                    : sems.where((s) => s.courseId == _selectedCourseId).toList();
                                  return DropdownButtonFormField<String>(
                                    dropdownColor: Theme.of(context).cardColor,
                                    initialValue: _selectedSemesterId,
                                    decoration: const InputDecoration(hintText: "Select Semester"),
                                    validator: (v) => v == null ? 'Required' : null,
                                    items: filtered.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                                    onChanged: (v) => setState(() => _selectedSemesterId = v),
                                  );
                                }
                              ),
                            ),
                          ),
                        ],
                      ),
                      AcadexFormField(
                        label: "Subject Code",
                        child: TextFormField(
                          controller: _codeCtrl,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          decoration: const InputDecoration(hintText: "e.g. CS101"),
                        ),
                      ),
                      AcadexFormField(
                        label: "Subject Name",
                        child: TextFormField(
                          controller: _nameCtrl,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          decoration: const InputDecoration(hintText: "e.g. Data Structures"),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: AcadexFormField(
                              label: "Credits",
                              child: TextFormField(
                                controller: _creditsCtrl,
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                                decoration: const InputDecoration(hintText: "e.g. 4"),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AcadexFormField(
                              label: "Elective",
                              child: DropdownButtonFormField<bool>(
                                dropdownColor: Theme.of(context).cardColor,
                                initialValue: _isElective,
                                decoration: const InputDecoration(hintText: "Select Type"),
                                items: const [
                                  DropdownMenuItem(value: false, child: Text("Core")),
                                  DropdownMenuItem(value: true, child: Text("Elective")),
                                ],
                                onChanged: (v) => setState(() => _isElective = v ?? false),
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
