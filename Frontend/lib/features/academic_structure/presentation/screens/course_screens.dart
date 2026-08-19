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

class CourseListScreen extends ConsumerWidget {
  const CourseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcadexPageHeader(
            title: "Courses (Programs)",
            subtitle: "Manage programs (e.g., B.Tech, MBA) offered by departments.",
          ),
          AcadexSearchFilterBar(
            searchHint: "Search courses...",
            onSearchChanged: (v) {},
            onActionTap: () => context.push('/academics/courses/new'),
            actionLabel: "Add Course",
          ),
          const SizedBox(height: 24),
          Expanded(
            child: coursesAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: AcadexColors.warning))),
              data: (courses) => AcadexDataTable(
                columns: const ["Code", "Name", "Department", "Status", "Actions"],
                rows: courses.map((c) => DataRow(cells: [
                  DataCell(Text(c.code, style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
                  DataCell(Text(c.name)),
                  DataCell(Text(c.departmentId)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.isActive ? Theme.of(context).primaryColor.withValues(alpha: 0.2) : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.1) ?? AcadexColors.inkMuted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(c.isActive ? "Active" : "Inactive", style: TextStyle(color: c.isActive ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(icon: Icon(LucideIcons.edit, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), onPressed: () => context.push('/academics/courses/edit/${c.id}')),
                        IconButton(icon: const Icon(LucideIcons.trash2, size: 18, color: AcadexColors.warning), onPressed: () {}),
                      ],
                    )
                  ),
                ])).toList(),
                emptyState: AcadexEmptyState(
                  title: "No Courses Found",
                  subtitle: "Get started by adding a program/course.",
                  icon: LucideIcons.book,
                  actionLabel: "Add Course",
                  onActionTap: () => context.push('/academics/courses/new'),
                ),
              ),
            ),
          )
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
  bool _isLoading = false;
  Course? _existing;
  
  String? _selectedCollegeId;
  String? _selectedDepartmentId;

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
      _selectedDepartmentId = _existing!.departmentId;
      
      final depts = await ref.read(departmentsProvider.future);
      final dept = depts.firstWhere((d) => d.id == _selectedDepartmentId);
      _selectedCollegeId = dept.collegeId;
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department is required')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final course = Course(
        id: _existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        collegeId: _selectedCollegeId!,
        departmentId: _selectedDepartmentId!,
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim().toUpperCase(),
        isActive: _existing?.isActive ?? true,
      );

      if (_existing == null) {
        await ref.read(coursesProvider.notifier).addCourse(course);
      } else {
        await ref.read(coursesProvider.notifier).updateCourse(course);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course saved successfully')));
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
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(isEdit ? "Edit Course" : "Add Course", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AcadexPageContainer(
              maxWidth: AcadexLayout.formMaxWidth,
              child: Form(
                key: _formKey,
                child: AcadexFormCard(
                  title: "Course Details",
                  onCancel: () => context.pop(),
                  onSave: _save,
                  child: Column(
                    children: [
                      AcadexFormField(
                        label: "College",
                        child: collegesAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (e, st) => Text('Error loading colleges', style: TextStyle(color: AcadexColors.warning)),
                          data: (colleges) => DropdownButtonFormField<String>(
                            dropdownColor: Theme.of(context).cardColor,
                            initialValue: _selectedCollegeId,
                            decoration: const InputDecoration(hintText: "Select College"),
                            validator: (v) => v == null ? 'Required' : null,
                            items: colleges.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                            onChanged: (v) => setState(() {
                              _selectedCollegeId = v;
                              _selectedDepartmentId = null; // reset dept
                            }),
                          ),
                        ),
                      ),
                      AcadexFormField(
                        label: "Department",
                        child: departmentsAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (e, st) => Text('Error loading departments', style: TextStyle(color: AcadexColors.warning)),
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
                              onChanged: (v) => setState(() => _selectedDepartmentId = v),
                            );
                          }
                        ),
                      ),
                      AcadexFormField(
                        label: "Course Name",
                        child: TextFormField(
                          controller: _nameCtrl,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                          decoration: const InputDecoration(hintText: "e.g. B.Tech, MBA"),
                        ),
                      ),
                      AcadexFormField(
                        label: "Course Code",
                        child: TextFormField(
                          controller: _codeCtrl,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                          decoration: const InputDecoration(hintText: "e.g. BTECH-CS"),
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
