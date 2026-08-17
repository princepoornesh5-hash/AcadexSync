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

class AcademicYearListScreen extends ConsumerWidget {
  const AcademicYearListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearsAsync = ref.watch(academicYearsProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Academic Years", style: AcadexTypography.heading2(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text("Manage academic sessions.", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),
          AcadexSearchFilterBar(
            searchHint: "Search years...",
            onSearchChanged: (v) {},
            onActionTap: () => context.push('/academics/academic_years/new'),
            actionLabel: "Add Year",
          ),
          const SizedBox(height: 24),
          Expanded(
            child: yearsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: AppColors.warning))),
              data: (years) => AcadexDataTable(
                columns: const ["Name", "Start Date", "End Date", "Status", "Actions"],
                rows: years.map((y) => DataRow(cells: [
                  DataCell(Text(y.name, style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
                  DataCell(Text(y.startDate.toString().split(' ')[0])),
                  DataCell(Text(y.endDate.toString().split(' ')[0])),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: y.isActive ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceDarkElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(y.isActive ? "Active" : "Inactive", style: TextStyle(color: y.isActive ? AppColors.primary : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(icon: Icon(LucideIcons.edit, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), onPressed: () => context.push('/academics/academic_years/edit/${y.id}')),
                        IconButton(icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.warning), onPressed: () {}),
                      ],
                    )
                  ),
                ])).toList(),
                emptyState: AcadexEmptyState(
                  title: "No Academic Years",
                  subtitle: "Create an academic session to get started.",
                  icon: LucideIcons.calendar,
                  actionLabel: "Add Year",
                  onActionTap: () => context.push('/academics/academic_years/new'),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class AcademicYearFormScreen extends StatelessWidget {
  final String? id;
  const AcademicYearFormScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final isEdit = id != null;
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface), onPressed: () => context.pop()),
        title: Text(isEdit ? "Edit Academic Year" : "Add Academic Year", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AcadexFormCard(
              title: "Academic Year Details",
              onCancel: () => context.pop(),
              onSave: () => context.pop(),
              child: Column(
                children: [
                  AcadexFormField(
                    label: "Year Name",
                    child: TextFormField(
                      initialValue: isEdit ? "2025-2026" : "",
                      style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(hintText: "e.g. 2025-2026"),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AcadexFormField(
                          label: "Start Date",
                          child: TextFormField(
                            initialValue: isEdit ? "2025-08-01" : "",
                            style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(hintText: "YYYY-MM-DD"),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AcadexFormField(
                          label: "End Date",
                          child: TextFormField(
                            initialValue: isEdit ? "2026-07-31" : "",
                            style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(hintText: "YYYY-MM-DD"),
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
