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
import '../widgets/section_transfer_stepper_dialog.dart';

class SectionListScreen extends ConsumerWidget {
  const SectionListScreen({super.key});

  void _showEditCapacityDialog(BuildContext context, WidgetRef ref, Section section) {
    final ctrl = TextEditingController(text: section.capacity.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.lg)),
        title: Text("Update Section Capacity", style: AcadexTypography.heading3(color: Theme.of(ctx).colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Set new maximum student seating for Section ${section.name}.", style: AcadexTypography.caption(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 16),
            TextFormField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Capacity",
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.users, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.secondary,
              foregroundColor: Colors.white,
            ),
            child: const Text("Save Capacity"),
            onPressed: () async {
              final newCap = int.tryParse(ctrl.text.trim());
              if (newCap != null && newCap > 0) {
                Navigator.of(ctx).pop();
                try {
                  await ref.read(sectionsProvider.notifier).updateSectionCapacity(section.id, newCap);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Capacity for Section ${section.name} updated to $newCap.'), backgroundColor: AcadexColors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AcadexColors.warning),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(sectionsProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final theme = Theme.of(context);

    final semsMap = {for (final s in semestersAsync.valueOrNull ?? <Semester>[]) s.id: s.name};

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcadexPageHeader(
            title: "Sections & Batches",
            subtitle: "Manage section capacity, live student rosters, and batch transfers.",
          ),
          AcadexSearchFilterBar(
            searchHint: "Search sections...",
            onSearchChanged: (v) {},
            onActionTap: () => context.push('/academics/sections/new'),
            actionLabel: "Add Section",
          ),
          const SizedBox(height: 24),
          Expanded(
            child: sectionsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: theme.primaryColor)),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: AcadexColors.warning))),
              data: (sections) => AcadexDataTable(
                columns: const ["Section Name", "Semester", "Capacity & Roster", "Available Seats", "Status", "Actions"],
                rows: sections.map((s) {
                  return DataRow(cells: [
                    DataCell(
                      Row(
                        children: [
                          const Icon(LucideIcons.users, size: 16, color: AcadexColors.secondary),
                          const SizedBox(width: 8),
                          Text("Section ${s.name}", style: AcadexTypography.body(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataCell(Text(semsMap[s.semesterId] ?? s.semesterId)),
                    DataCell(
                      Consumer(
                        builder: (context, ref, _) {
                          final capAsync = ref.watch(sectionCapacityInfoProvider(s.id));
                          return capAsync.when(
                            loading: () => Text("Capacity: ${s.capacity}"),
                            error: (_, __) => Text("Capacity: ${s.capacity}"),
                            data: (capInfo) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${capInfo.enrolledCount} / ${capInfo.capacity} students", style: AcadexTypography.caption(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 110,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: capInfo.capacity > 0 ? (capInfo.enrolledCount / capInfo.capacity).clamp(0.0, 1.0) : 0.0,
                                      backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        capInfo.utilizationPercentage > 90 ? AcadexColors.warning : AcadexColors.secondary,
                                      ),
                                      minHeight: 5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    DataCell(
                      Consumer(
                        builder: (context, ref, _) {
                          final capAsync = ref.watch(sectionCapacityInfoProvider(s.id));
                          return capAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (capInfo) {
                              if (capInfo.isFull) {
                                return const AcadexBadge(label: "FULL", variant: AcadexBadgeVariant.warning);
                              }
                              return AcadexBadge(label: "${capInfo.availableSeats} left", variant: AcadexBadgeVariant.success);
                            },
                          );
                        },
                      ),
                    ),
                    DataCell(
                      AcadexBadge(
                        label: s.status.toUpperCase(),
                        variant: s.status == 'active' ? AcadexBadgeVariant.success : AcadexBadgeVariant.neutral,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(LucideIcons.edit, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                            tooltip: "Edit Section",
                            onPressed: () => context.push('/academics/sections/edit/${s.id}'),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.slidersHorizontal, size: 18, color: AcadexColors.secondary),
                            tooltip: "Update Capacity",
                            onPressed: () => _showEditCapacityDialog(context, ref, s),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.arrowRightLeft, size: 18, color: AcadexColors.primary),
                            tooltip: "Transfer Students",
                            onPressed: () => SectionTransferStepperDialog.show(context, sourceSectionId: s.id),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 18, color: AcadexColors.warning),
                            tooltip: "Deactivate",
                            onPressed: () async {
                              await ref.read(sectionsProvider.notifier).deactivateSection(s.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ]);
                }).toList(),
                emptyState: AcadexEmptyState(
                  title: "No Sections Found",
                  subtitle: "Create sections to group students and schedule classes.",
                  icon: LucideIcons.users,
                  actionLabel: "Add Section",
                  onActionTap: () => context.push('/academics/sections/new'),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class SectionFormScreen extends ConsumerStatefulWidget {
  final String? id;
  const SectionFormScreen({super.key, this.id});

  @override
  ConsumerState<SectionFormScreen> createState() => _SectionFormScreenState();
}

class _SectionFormScreenState extends ConsumerState<SectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _capacityCtrl;
  bool _isLoading = false;
  Section? _existing;
  
  String? _selectedCollegeId;
  String? _selectedDepartmentId;
  String? _selectedCourseId;
  String? _selectedSemesterId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _capacityCtrl = TextEditingController(text: '60');

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
      
      final sems = await ref.read(semestersProvider.future);
      final sem = sems.firstWhere((s) => s.id == _selectedSemesterId);
      _selectedCourseId = sem.courseId;
      
      final courses = await ref.read(coursesProvider.future);
      final course = courses.firstWhere((c) => c.id == _selectedCourseId);
      _selectedDepartmentId = course.departmentId;

      final depts = await ref.read(departmentsProvider.future);
      final dept = depts.firstWhere((d) => d.id == _selectedDepartmentId);
      _selectedCollegeId = dept.collegeId;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading section: $e')));
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
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSemesterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semester is required')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final cap = int.tryParse(_capacityCtrl.text.trim()) ?? 60;
      if (cap <= 0) {
        throw Exception("Section capacity must be greater than 0");
      }

      final section = Section(
        id: _existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        collegeId: _selectedCollegeId ?? _existing?.collegeId ?? 'c1',
        departmentId: _selectedDepartmentId ?? _existing?.departmentId ?? 'd1',
        courseId: _selectedCourseId ?? _existing?.courseId ?? '',
        semesterId: _selectedSemesterId!,
        name: _nameCtrl.text.trim().toUpperCase(),
        capacity: cap,
        status: _existing?.status ?? 'active',
        isActive: _existing?.isActive ?? true,
      );

      if (_existing == null) {
        await ref.read(sectionsProvider.notifier).addSection(section);
      } else {
        await ref.read(sectionsProvider.notifier).updateSection(section);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Section saved successfully'), backgroundColor: AcadexColors.success));
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
    final semestersAsync = ref.watch(semestersProvider);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(isEdit ? "Edit Section" : "Add Section", style: AcadexTypography.heading3(color: theme.colorScheme.onSurface)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AcadexPageContainer(
              maxWidth: AcadexLayout.formMaxWidth,
              child: Form(
                key: _formKey,
                child: AcadexFormCard(
                  title: "Section Information",
                  icon: LucideIcons.users,
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
                                error: (e, st) => const Text('Error', style: TextStyle(color: AcadexColors.warning)),
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
                                error: (e, st) => const Text('Error', style: TextStyle(color: AcadexColors.warning)),
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
                                error: (e, st) => const Text('Error', style: TextStyle(color: AcadexColors.warning)),
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
                                error: (e, st) => const Text('Error', style: TextStyle(color: AcadexColors.warning)),
                                data: (sems) {
                                  final filtered = _selectedCourseId == null 
                                    ? <Semester>[] 
                                    : sems.where((s) => s.courseId == _selectedCourseId).toList();
                                  return DropdownButtonFormField<String>(
                                    dropdownColor: theme.cardColor,
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
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: AcadexFormField(
                              label: "Section Name",
                              child: TextFormField(
                                controller: _nameCtrl,
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                                style: AcadexTypography.body(color: theme.colorScheme.onSurface),
                                decoration: const InputDecoration(hintText: "e.g. A, B", prefixIcon: Icon(LucideIcons.hash)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: AcadexFormField(
                              label: "Capacity",
                              child: TextFormField(
                                controller: _capacityCtrl,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  final num = int.tryParse(v);
                                  if (num == null || num <= 0) return 'Must be > 0';
                                  return null;
                                },
                                style: AcadexTypography.body(color: theme.colorScheme.onSurface),
                                decoration: const InputDecoration(hintText: "60", prefixIcon: Icon(LucideIcons.users)),
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

