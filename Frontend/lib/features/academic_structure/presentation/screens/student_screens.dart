import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';
import '../providers/academic_providers.dart';
import '../widgets/student_bulk_action_dialogs.dart';
import '../widgets/import_data_dialog.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  final Set<String> _selectedIds = {};

  void _showBulkPromotionDialog() async {
    if (_selectedIds.isEmpty) return;
    final result = await showDialog(
      context: context,
      builder: (ctx) => StudentPromotionDialog(studentIds: _selectedIds.toList()),
    );
    if (result == true) {
      setState(() => _selectedIds.clear());
    }
  }

  void _showBulkTransferDialog() async {
    if (_selectedIds.isEmpty) return;
    final result = await showDialog(
      context: context,
      builder: (ctx) => StudentTransferDialog(studentIds: _selectedIds.toList()),
    );
    if (result == true) {
      setState(() => _selectedIds.clear());
    }
  }

  void _showImportDialog() {
    showDialog(context: context, builder: (ctx) => const ImportDataDialog(entityName: 'Students'));
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Students", style: AcadexTypography.heading2(color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Text("Manage student directory and academic enrollment.", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _showImportDialog,
                    icon: const Icon(LucideIcons.uploadCloud, size: 16),
                    label: const Text("Import CSV"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(color: Theme.of(context).cardColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_selectedIds.isNotEmpty) ...[
                    DropdownButton<String>(
                      dropdownColor: Theme.of(context).cardColor,
                      hint: Text("${_selectedIds.length} Selected", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      underline: const SizedBox(),
                      icon: const Icon(LucideIcons.chevronDown, color: AppColors.primary),
                      items: [
                        DropdownMenuItem(value: 'promote', child: Text("Promote Students", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface))),
                        DropdownMenuItem(value: 'transfer', child: Text("Transfer Section", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface))),
                      ],
                      onChanged: (val) {
                        if (val == 'promote') _showBulkPromotionDialog();
                        if (val == 'transfer') _showBulkTransferDialog();
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          AcadexSearchFilterBar(
            searchHint: "Search students by name or roll number...",
            onSearchChanged: (v) {},
            onActionTap: () => context.push('/academics/students/new'),
            actionLabel: "Add Student",
          ),
          const SizedBox(height: 24),
          Expanded(
            child: studentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: AppColors.warning))),
              data: (students) => AcadexDataTable(
                columns: const ["Roll No", "Name", "Department", "Semester", "Section", "Status", "Actions"],
                rows: students.map((s) => DataRow(
                  selected: _selectedIds.contains(s.id),
                  onSelectChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedIds.add(s.id);
                      } else {
                        _selectedIds.remove(s.id);
                      }
                    });
                  },
                  cells: [
                    DataCell(Text(s.rollNumber, style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
                    DataCell(Text(s.name)),
                    DataCell(Text(s.departmentId)),
                    DataCell(Text(s.semesterId)),
                    DataCell(Text(s.sectionId)),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: s.isActive ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceDarkElevated,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(s.isActive ? "Active" : "Inactive", style: TextStyle(color: s.isActive ? AppColors.primary : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(icon: Icon(LucideIcons.edit, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), onPressed: () => context.push('/academics/students/edit/${s.id}')),
                          IconButton(icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.warning), onPressed: () {}),
                        ],
                      )
                    ),
                  ],
                )).toList(),
                emptyState: AcadexEmptyState(
                  title: "No Students Found",
                  subtitle: "Enroll students into sections to get started.",
                  icon: LucideIcons.users,
                  actionLabel: "Add Student",
                  onActionTap: () => context.push('/academics/students/new'),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class StudentFormScreen extends StatelessWidget {
  final String? id;
  const StudentFormScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final isEdit = id != null;
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface), onPressed: () => context.pop()),
        title: Text(isEdit ? "Edit Student" : "Add Student", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AcadexFormCard(
                  title: "Personal Information",
                  icon: LucideIcons.user,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(LucideIcons.user)),
                        initialValue: isEdit ? "John Doe" : "",
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: "Email Address", prefixIcon: Icon(LucideIcons.mail)),
                              initialValue: isEdit ? "john@student.git.edu" : "",
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(LucideIcons.phone)),
                              initialValue: isEdit ? "5551234567" : "",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AcadexFormCard(
                  title: "Academic Enrollment",
                  icon: LucideIcons.graduationCap,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: "Roll Number", prefixIcon: Icon(LucideIcons.hash)),
                              initialValue: isEdit ? "CS2025001" : "",
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: "Department", prefixIcon: Icon(LucideIcons.building)),
                              items: const [DropdownMenuItem(value: 'd1', child: Text("Computer Engineering"))],
                              onChanged: (v) {},
                              initialValue: 'd1',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: "Semester", prefixIcon: Icon(LucideIcons.calendar)),
                              items: const [DropdownMenuItem(value: 'sem1', child: Text("Semester 1"))],
                              onChanged: (v) {},
                              initialValue: 'sem1',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: "Section", prefixIcon: Icon(LucideIcons.users)),
                              items: const [DropdownMenuItem(value: 'sec1', child: Text("Section A"))],
                              onChanged: (v) {},
                              initialValue: 'sec1',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text("Cancel", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        // In a real app we would read controllers and submit
                        context.pop();
                      },
                      child: const Text("Save Student"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
