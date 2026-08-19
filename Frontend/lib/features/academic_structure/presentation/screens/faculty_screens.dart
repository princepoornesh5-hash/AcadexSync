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

  void _showAssignmentDialog(Faculty? faculty) {
    FacultyAssignmentDialog.show(context, faculty: faculty);
  }

  @override
  Widget build(BuildContext context) {
    final facultyAsync = ref.watch(facultyProvider(null));
    final deptMap = ref.watch(departmentMapProvider);
    final assignmentsAsync = ref.watch(facultyAssignmentsProvider);
    final allAssignments = assignmentsAsync.valueOrNull ?? [];

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: AcadexPageHeader(
                  title: "Faculty",
                  subtitle: "Manage faculty members and teaching assignments.",
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showAssignmentDialog(null),
                    icon: const Icon(LucideIcons.userPlus, size: 16),
                    label: const Text("Assign Classes"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcadexColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/faculty-assignments'),
                    icon: const Icon(LucideIcons.userCheck, size: 16),
                    label: const Text("All Assignments"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
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
            ],
          ),
          AcadexSearchFilterBar(
            searchHint: "Search faculty by name or employee ID...",
            onSearchChanged: (v) {},
            onActionTap: () => context.push('/academics/faculty/new'),
            actionLabel: "Add Faculty",
          ),
          const SizedBox(height: 24),
          Expanded(
            child: (facultyAsync.isLoading && facultyAsync.items.isEmpty)
              ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
              : facultyAsync.error != null 
                ? Center(child: Text("Error: ${facultyAsync.error}", style: const TextStyle(color: AcadexColors.warning)))
                : AcadexDataTable(
                    columns: const ["Employee ID", "Name", "Department", "Teaching Assignments", "Status", "Actions"],
                    rows: facultyAsync.items.map((f) {
                      final deptName = deptMap[f.departmentId]?.name ?? (f.departmentId.isNotEmpty ? f.departmentId : 'Unassigned');
                      final facultyAssignments = allAssignments.where((a) => a.facultyId == f.id).toList();
                      final hasAssignments = facultyAssignments.isNotEmpty || f.subjectIds.isNotEmpty || f.sectionIds.isNotEmpty;
                      final assignmentCount = facultyAssignments.isNotEmpty ? facultyAssignments.length : (f.subjectIds.length);

                      return DataRow(cells: [
                        DataCell(Text(f.employeeId, style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
                        DataCell(Text(f.name)),
                        DataCell(Text(deptName)),
                        DataCell(
                          !hasAssignments
                            ? const Text("Unassigned", style: TextStyle(color: AcadexColors.warning, fontStyle: FontStyle.italic))
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "$assignmentCount Active Class${assignmentCount == 1 ? '' : 'es'}",
                                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: f.isActive ? Theme.of(context).primaryColor.withValues(alpha: 0.2) : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.1) ?? AcadexColors.inkMuted.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(f.isActive ? "Active" : "Inactive", style: TextStyle(color: f.isActive ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                          )
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                tooltip: "Assign Classes / Subjects",
                                icon: Icon(LucideIcons.bookOpen, size: 18, color: Theme.of(context).primaryColor), 
                                onPressed: () => _showAssignmentDialog(f),
                              ),
                              IconButton(
                                tooltip: "Edit Faculty",
                                icon: Icon(LucideIcons.edit, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                                onPressed: () => context.push('/academics/faculty/edit/${f.id}'),
                              ),
                              IconButton(
                                tooltip: "Deactivate",
                                icon: const Icon(LucideIcons.trash2, size: 18, color: AcadexColors.warning),
                                onPressed: () {},
                              ),
                            ],
                          )
                        ),
                      ]);
                    }).toList(),
                    emptyState: AcadexEmptyState(
                      title: "No Faculty Found",
                      subtitle: "Add faculty members to assign them to subjects.",
                      icon: LucideIcons.user,
                      actionLabel: "Add Faculty",
                      onActionTap: () => context.push('/academics/faculty/new'),
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
      body: AcadexPageContainer(
        maxWidth: AcadexLayout.formMaxWidth,
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
                    backgroundColor: Theme.of(context).primaryColor,
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
    );
  }
}
