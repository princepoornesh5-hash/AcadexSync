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

class CollegeListScreen extends ConsumerWidget {
  const CollegeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collegesAsync = ref.watch(collegesProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Colleges", style: AcadexTypography.heading2(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text("Manage registered colleges in the system.", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),
          AcadexSearchFilterBar(
            searchHint: "Search colleges...",
            onSearchChanged: (v) {},
            onActionTap: () => context.push('/academics/colleges/new'),
            actionLabel: "Add College",
          ),
          const SizedBox(height: 24),
          Expanded(
            child: collegesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: AppColors.warning))),
              data: (colleges) => AcadexDataTable(
                columns: const ["Code", "Name", "Principal", "Email", "Phone", "Status", "Actions"],
                rows: colleges.map((c) => DataRow(cells: [
                  DataCell(Text(c.code, style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
                  DataCell(Text(c.name)),
                  DataCell(Text(c.principal)),
                  DataCell(Text(c.email)),
                  DataCell(Text(c.phone)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.isActive ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceDarkElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(c.isActive ? "Active" : "Inactive", style: TextStyle(color: c.isActive ? AppColors.primary : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(icon: Icon(LucideIcons.edit, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), onPressed: () => context.push('/academics/colleges/edit/${c.id}')),
                        IconButton(icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.warning), onPressed: () {}),
                      ],
                    )
                  ),
                ])).toList(),
                emptyState: AcadexEmptyState(
                  title: "No Colleges Found",
                  subtitle: "Get started by adding the first college.",
                  icon: LucideIcons.building,
                  actionLabel: "Add College",
                  onActionTap: () => context.push('/academics/colleges/new'),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class CollegeFormScreen extends StatelessWidget {
  final String? collegeId;
  const CollegeFormScreen({super.key, this.collegeId});

  @override
  Widget build(BuildContext context) {
    final isEdit = collegeId != null;
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(isEdit ? "Edit College" : "Add College", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AcadexFormCard(
              title: "College Details",
              onCancel: () => context.pop(),
              onSave: () {
                // Mock Save
                context.pop();
              },
              child: Column(
                children: [
                  AcadexFormField(
                    label: "College Name",
                    child: TextFormField(
                      initialValue: isEdit ? "Global Institute of Technology" : "",
                      style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(hintText: "e.g. Global Institute of Technology"),
                    ),
                  ),
                  AcadexFormField(
                    label: "College Code",
                    child: TextFormField(
                      initialValue: isEdit ? "GIT" : "",
                      style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(hintText: "e.g. GIT"),
                    ),
                  ),
                  AcadexFormField(
                    label: "Principal Name",
                    child: TextFormField(
                      initialValue: isEdit ? "Dr. Smith" : "",
                      style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(hintText: "e.g. Dr. Smith"),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AcadexFormField(
                          label: "Email",
                          child: TextFormField(
                            initialValue: isEdit ? "admin@git.edu" : "",
                            style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(hintText: "e.g. admin@college.edu"),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AcadexFormField(
                          label: "Phone",
                          child: TextFormField(
                            initialValue: isEdit ? "1234567890" : "",
                            style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(hintText: "e.g. 9876543210"),
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
      ),
    );
  }

  }
