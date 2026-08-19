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
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../widgets/assign_hod_dialog.dart';

class DepartmentListScreen extends ConsumerWidget {
  const DepartmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(departmentsProvider);
    final facultyState = ref.watch(facultyProvider(null));
    final facultyMap = {for (final f in facultyState.items) f.id: f};
    final facCounts = ref.watch(departmentFacultyCountsProvider).valueOrNull ?? {};
    final stuCounts = ref.watch(departmentStudentCountsProvider).valueOrNull ?? {};

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcadexPageHeader(
            title: "Departments",
            subtitle: "Manage college departments, faculty quotas, and HOD assignments.",
          ),
          AcadexSearchFilterBar(
            searchHint: "Search departments...",
            onSearchChanged: (v) {},
            onActionTap: () => context.push('/academics/departments/new'),
            actionLabel: "Add Department",
          ),
          const SizedBox(height: 24),
          Expanded(
            child: deptsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: AcadexColors.warning))),
              data: (depts) => AcadexDataTable(
                columns: const ["Department Code", "Department Name", "HOD", "Faculty Count", "Student Count", "Status", "Actions"],
                rows: depts.map((d) {
                  final hodFaculty = facultyMap[d.hodId];
                  final hodDisplay = hodFaculty != null
                      ? hodFaculty.name
                      : (d.hodId.isNotEmpty ? d.hodId : '— Unassigned —');

                  final fCount = facCounts[d.id] ?? 0;
                  final sCount = stuCounts[d.id] ?? 0;

                  return DataRow(cells: [
                    DataCell(Text(d.code, style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
                    DataCell(Text(d.name)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            d.hodId.isNotEmpty ? LucideIcons.shieldCheck : LucideIcons.userX,
                            size: 16,
                            color: d.hodId.isNotEmpty ? AcadexColors.primary : Theme.of(context).disabledColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hodDisplay,
                            style: TextStyle(
                              color: d.hodId.isNotEmpty ? Theme.of(context).colorScheme.onSurface : Theme.of(context).disabledColor,
                              fontWeight: d.hodId.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text("$fCount faculty", style: AcadexTypography.caption(color: Theme.of(context).colorScheme.onSurface))),
                    DataCell(Text("$sCount students", style: AcadexTypography.caption(color: Theme.of(context).colorScheme.onSurface))),
                    DataCell(
                      AcadexBadge(
                        label: d.isActive ? "ACTIVE" : "INACTIVE",
                        variant: d.isActive ? AcadexBadgeVariant.success : AcadexBadgeVariant.neutral,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            tooltip: "Assign HOD",
                            icon: const Icon(LucideIcons.userCheck, size: 18, color: AcadexColors.primary),
                            onPressed: () => AssignHodDialog.show(context, d),
                          ),
                          IconButton(
                            tooltip: "Edit Department",
                            icon: Icon(LucideIcons.edit, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                            onPressed: () => context.push('/academics/departments/edit/${d.id}'),
                          ),
                          IconButton(
                            tooltip: "Deactivate",
                            icon: const Icon(LucideIcons.trash2, size: 18, color: AcadexColors.warning),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Deactivate Department?'),
                                  content: Text('Are you sure you want to deactivate ${d.name}?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.warning),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Deactivate', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(departmentsProvider.notifier).deactivateDepartment(d.id);
                              }
                            },
                          ),
                        ],
                      )
                    ),
                  ]);
                }).toList(),
                emptyState: AcadexEmptyState(
                  title: "No Departments Found",
                  subtitle: "Get started by adding the first department.",
                  icon: LucideIcons.network,
                  actionLabel: "Add Department",
                  onActionTap: () => context.push('/academics/departments/new'),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class DepartmentFormScreen extends ConsumerStatefulWidget {
  final String? id;
  const DepartmentFormScreen({super.key, this.id});

  @override
  ConsumerState<DepartmentFormScreen> createState() => _DepartmentFormScreenState();
}

class _DepartmentFormScreenState extends ConsumerState<DepartmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _descCtrl;
  bool _isLoading = false;
  Department? _existing;
  
  String? _selectedCollegeId;
  String? _selectedHodId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _codeCtrl = TextEditingController();
    _descCtrl = TextEditingController();

    if (widget.id != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final depts = await ref.read(departmentsProvider.future);
      _existing = depts.firstWhere((c) => c.id == widget.id);
      _nameCtrl.text = _existing!.name;
      _codeCtrl.text = _existing!.code;
      _descCtrl.text = _existing!.description;
      _selectedCollegeId = _existing!.collegeId;
      _selectedHodId = _existing!.hodId.isEmpty ? null : _existing!.hodId;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading department: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCollegeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('College is required')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final dept = Department(
        id: _existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        collegeId: _selectedCollegeId!,
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim().toUpperCase(),
        description: _descCtrl.text.trim(),
        hodId: _selectedHodId ?? '',
        isActive: _existing?.isActive ?? true,
      );

      if (_existing == null) {
        await ref.read(departmentsProvider.notifier).addDepartment(dept);
      } else {
        await ref.read(departmentsProvider.notifier).updateDepartment(dept);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department saved successfully')));
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
    final facultyAsync = ref.watch(facultyProvider(null));
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(isEdit ? "Edit Department" : "Add Department", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AcadexPageContainer(
              maxWidth: AcadexLayout.formMaxWidth,
              child: Form(
                key: _formKey,
                child: AcadexFormCard(
                  title: "Department Details",
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
                              _selectedHodId = null; // reset hod since faculty depends on college
                            }),
                          ),
                        ),
                      ),
                      AcadexFormField(
                        label: "Department Name",
                        child: TextFormField(
                          controller: _nameCtrl,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                          decoration: const InputDecoration(hintText: "e.g. Computer Engineering"),
                        ),
                      ),
                      AcadexFormField(
                        label: "Department Code",
                        child: TextFormField(
                          controller: _codeCtrl,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                          decoration: const InputDecoration(hintText: "e.g. CS"),
                        ),
                      ),
                      AcadexFormField(
                        label: "Description",
                        child: TextFormField(
                          controller: _descCtrl,
                          maxLines: 3,
                          style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                          decoration: const InputDecoration(hintText: "Brief description of the department"),
                        ),
                      ),
                      AcadexFormField(
                        label: "HOD (Assign Faculty)",
                        child: facultyAsync.isLoading 
                          ? const CircularProgressIndicator()
                          : facultyAsync.error != null
                            ? Text('Error loading faculty', style: TextStyle(color: AcadexColors.warning))
                            : DropdownButtonFormField<String>(
                                dropdownColor: Theme.of(context).cardColor,
                                initialValue: _selectedHodId,
                                decoration: const InputDecoration(hintText: "Select HOD"),
                                items: facultyAsync.items.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
                                onChanged: (v) => setState(() => _selectedHodId = v),
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
