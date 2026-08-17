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

class SubjectListScreen extends ConsumerWidget {
  const SubjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Subjects", style: AcadexTypography.heading2(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text("Manage subjects, credits, and lab/theory types.", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),
          AcadexSearchFilterBar(
            searchHint: "Search subjects...",
            onSearchChanged: (v) {},
            onActionTap: () => context.push('/academics/subjects/new'),
            actionLabel: "Add Subject",
          ),
          const SizedBox(height: 24),
          Expanded(
            child: subjectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: AppColors.warning))),
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
                        color: s.isActive ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceDarkElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(s.isActive ? "Active" : "Inactive", style: TextStyle(color: s.isActive ? AppColors.primary : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(icon: Icon(LucideIcons.edit, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), onPressed: () => context.push('/academics/subjects/edit/${s.id}')),
                        IconButton(icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.warning), onPressed: () {}),
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

class SubjectFormScreen extends StatelessWidget {
  final String? id;
  const SubjectFormScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final isEdit = id != null;
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface), onPressed: () => context.pop()),
        title: Text(isEdit ? "Edit Subject" : "Add Subject", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AcadexFormCard(
              title: "Subject Details",
              onCancel: () => context.pop(),
              onSave: () => context.pop(),
              child: Column(
                children: [
                  AcadexFormField(
                    label: "Subject Code",
                    child: TextFormField(
                      initialValue: isEdit ? "CS101" : "",
                      style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(hintText: "e.g. CS101"),
                    ),
                  ),
                  AcadexFormField(
                    label: "Subject Name",
                    child: TextFormField(
                      initialValue: isEdit ? "Data Structures" : "",
                      style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(hintText: "e.g. Data Structures"),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AcadexFormField(
                          label: "Credits",
                          child: TextFormField(
                            initialValue: isEdit ? "4" : "",
                            keyboardType: TextInputType.number,
                            style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(hintText: "e.g. 4"),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AcadexFormField(
                          label: "Type",
                          child: DropdownButtonFormField<String>(
                            dropdownColor: Theme.of(context).cardColor,
                            initialValue: isEdit ? "Theory" : null,
                            style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(hintText: "Select Type"),
                            items: const [
                              DropdownMenuItem(value: "Theory", child: Text("Theory")),
                              DropdownMenuItem(value: "Lab", child: Text("Lab")),
                            ],
                            onChanged: (v) {},
                          ),
                        ),
                      ),
                    ],
                  ),
                  AcadexFormField(
                    label: "Department",
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Theme.of(context).cardColor,
                      initialValue: isEdit ? "d1" : null,
                      style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(hintText: "Select Department"),
                      items: const [
                        DropdownMenuItem(value: "d1", child: Text("Computer Engineering")),
                      ],
                      onChanged: (v) {},
                    ),
                  ),
                  AcadexFormField(
                    label: "Semester",
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Theme.of(context).cardColor,
                      initialValue: isEdit ? "sem1" : null,
                      style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(hintText: "Select Semester"),
                      items: const [
                        DropdownMenuItem(value: "sem1", child: Text("Semester 1")),
                      ],
                      onChanged: (v) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  }
