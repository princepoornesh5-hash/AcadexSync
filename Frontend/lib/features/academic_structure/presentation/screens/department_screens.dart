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

class DepartmentListScreen extends ConsumerWidget {
  const DepartmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(departmentsProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Departments", style: AcadexTypography.heading2(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text("Manage college departments and HOD assignments.", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),
          AcadexSearchFilterBar(
            searchHint: "Search departments...",
            onSearchChanged: (v) {},
            onActionTap: () => context.push('/academics/departments/new'),
            actionLabel: "Add Department",
          ),
          const SizedBox(height: 24),
          Expanded(
            child: deptsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: AppColors.warning))),
              data: (depts) => AcadexDataTable(
                columns: const ["Code", "Name", "HOD", "Description", "Status", "Actions"],
                rows: depts.map((d) => DataRow(cells: [
                  DataCell(Text(d.code, style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
                  DataCell(Text(d.name)),
                  DataCell(Text(d.hodId)),
                  DataCell(Text(d.description)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: d.isActive ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceDarkElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(d.isActive ? "Active" : "Inactive", style: TextStyle(color: d.isActive ? AppColors.primary : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(icon: Icon(LucideIcons.edit, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), onPressed: () => context.push('/academics/departments/edit/${d.id}')),
                        IconButton(icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.warning), onPressed: () {}),
                      ],
                    )
                  ),
                ])).toList(),
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

class DepartmentFormScreen extends StatelessWidget {
  final String? id;
  const DepartmentFormScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final isEdit = id != null;
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(isEdit ? "Edit Department" : "Add Department", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AcadexFormCard(
              title: "Department Details",
              onCancel: () => context.pop(),
              onSave: () => context.pop(),
              child: Column(
                children: [
                  AcadexFormField(
                    label: "Department Name",
                    child: TextFormField(
                      initialValue: isEdit ? "Computer Engineering" : "",
                      style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(hintText: "e.g. Computer Engineering"),
                    ),
                  ),
                  AcadexFormField(
                    label: "Department Code",
                    child: TextFormField(
                      initialValue: isEdit ? "CS" : "",
                      style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(hintText: "e.g. CS"),
                    ),
                  ),
                  AcadexFormField(
                    label: "Description",
                    child: TextFormField(
                      initialValue: isEdit ? "Computing & AI" : "",
                      maxLines: 3,
                      style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(hintText: "Brief description of the department"),
                    ),
                  ),
                  AcadexFormField(
                    label: "HOD (Assign Faculty)",
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Theme.of(context).cardColor,
                      initialValue: isEdit ? "f1" : null,
                      style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(hintText: "Select HOD"),
                      items: const [
                        DropdownMenuItem(value: "f1", child: Text("Prof. Alan Turing")),
                        DropdownMenuItem(value: "f2", child: Text("Prof. Nikola Tesla")),
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
