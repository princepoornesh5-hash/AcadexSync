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
import '../widgets/faculty_assignment_dialog.dart';
import '../widgets/import_data_dialog.dart';

class FacultyListScreen extends ConsumerStatefulWidget {
  const FacultyListScreen({super.key});

  @override
  ConsumerState<FacultyListScreen> createState() => _FacultyListScreenState();
}

class _FacultyListScreenState extends ConsumerState<FacultyListScreen> {
  void _showImportDialog() {
    showDialog(context: context, builder: (ctx) => const ImportDataDialog(entityName: 'Faculty'));
  }

  void _showAssignmentDialog(String facultyId, String facultyName, List<String> subjects, List<String> sections) async {
    final result = await showDialog(
      context: context,
      builder: (ctx) => FacultyAssignmentDialog(
        facultyId: facultyId,
        facultyName: facultyName,
        initialSubjectIds: subjects,
        initialSectionIds: sections,
      ),
    );
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faculty assignments updated successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final facultyAsync = ref.watch(facultyProvider);

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
                  Text("Faculty", style: AcadexTypography.heading2(color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Text("Manage faculty members and teaching assignments.", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _showImportDialog,
                icon: const Icon(LucideIcons.uploadCloud, size: 16),
                label: const Text("Import CSV"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  side: BorderSide(color: Theme.of(context).cardColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AcadexSearchFilterBar(
            searchHint: "Search faculty by name or employee ID...",
            onSearchChanged: (v) {},
            onActionTap: () => context.push('/academics/faculty/new'),
            actionLabel: "Add Faculty",
          ),
          const SizedBox(height: 24),
          Expanded(
            child: facultyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: AppColors.warning))),
              data: (faculty) => AcadexDataTable(
                columns: const ["Employee ID", "Name", "Department", "Assignments", "Status", "Actions"],
                rows: faculty.map((f) => DataRow(cells: [
                  DataCell(Text(f.employeeId, style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
                  DataCell(Text(f.name)),
                  DataCell(Text(f.departmentId)),
                  DataCell(
                    f.subjectIds.isEmpty && f.sectionIds.isEmpty
                      ? const Text("Unassigned", style: TextStyle(color: AppColors.warning, fontStyle: FontStyle.italic))
                      : Text("${f.subjectIds.length} Subjects, ${f.sectionIds.length} Sections", style: const TextStyle(color: AppColors.primary))
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: f.isActive ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceDarkElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(f.isActive ? "Active" : "Inactive", style: TextStyle(color: f.isActive ? AppColors.primary : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          tooltip: "Assign Subjects",
                          icon: const Icon(LucideIcons.bookOpen, size: 18, color: AppColors.primary), 
                          onPressed: () => _showAssignmentDialog(f.id, f.name, f.subjectIds, f.sectionIds)
                        ),
                        IconButton(icon: Icon(LucideIcons.edit, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), onPressed: () => context.push('/academics/faculty/edit/${f.id}')),
                        IconButton(icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.warning), onPressed: () {}),
                      ],
                    )
                  ),
                ])).toList(),
                emptyState: AcadexEmptyState(
                  title: "No Faculty Found",
                  subtitle: "Add faculty members to assign them to subjects.",
                  icon: LucideIcons.user,
                  actionLabel: "Add Faculty",
                  onActionTap: () => context.push('/academics/faculty/new'),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class FacultyFormScreen extends StatelessWidget {
  final String? id;
  const FacultyFormScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final isEdit = id != null;
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface), onPressed: () => context.pop()),
        title: Text(isEdit ? "Edit Faculty" : "Add Faculty", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface)),
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
                        initialValue: isEdit ? "Prof. Alan Turing" : "",
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: "Email Address", prefixIcon: Icon(LucideIcons.mail)),
                              initialValue: isEdit ? "alan@git.edu" : "",
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(LucideIcons.phone)),
                              initialValue: isEdit ? "9876543210" : "",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AcadexFormCard(
                  title: "Employment Details",
                  icon: LucideIcons.briefcase,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: "Employee ID", prefixIcon: Icon(LucideIcons.hash)),
                              initialValue: isEdit ? "EMP001" : "",
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
                        context.pop();
                      },
                      child: const Text("Save Faculty"),
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
