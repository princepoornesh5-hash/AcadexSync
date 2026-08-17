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

class SemesterListScreen extends ConsumerWidget {
  const SemesterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semestersAsync = ref.watch(semestersProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Semesters", style: AcadexTypography.heading2(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text("Manage academic terms for courses.", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),
          AcadexSearchFilterBar(
            searchHint: "Search semesters...",
            onSearchChanged: (v) {},
            onActionTap: () => context.push('/academics/semesters/new'),
            actionLabel: "Add Semester",
          ),
          const SizedBox(height: 24),
          Expanded(
            child: semestersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: AppColors.warning))),
              data: (semesters) => AcadexDataTable(
                columns: const ["Name", "Course", "Academic Year", "Status", "Actions"],
                rows: semesters.map((s) => DataRow(cells: [
                  DataCell(Text(s.name, style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
                  DataCell(Text(s.courseId)),
                  DataCell(Text(s.academicYearId)),
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
                        IconButton(icon: Icon(LucideIcons.edit, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), onPressed: () => context.push('/academics/semesters/edit/${s.id}')),
                        IconButton(icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.warning), onPressed: () {}),
                      ],
                    )
                  ),
                ])).toList(),
                emptyState: AcadexEmptyState(
                  title: "No Semesters",
                  subtitle: "Create a semester to organize sections.",
                  icon: LucideIcons.calendarClock,
                  actionLabel: "Add Semester",
                  onActionTap: () => context.push('/academics/semesters/new'),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class SemesterFormScreen extends StatelessWidget {
  final String? id;
  const SemesterFormScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final isEdit = id != null;
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface), onPressed: () => context.pop()),
        title: Text(isEdit ? "Edit Semester" : "Add Semester", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AcadexFormCard(
              title: "Semester Details",
              onCancel: () => context.pop(),
              onSave: () => context.pop(),
              child: Column(
                children: [
                  AcadexFormField(
                    label: "Semester Name",
                    child: TextFormField(
                      initialValue: isEdit ? "Semester 1" : "",
                      style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(hintText: "e.g. Semester 1"),
                    ),
                  ),
                  AcadexFormField(
                    label: "Course",
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Theme.of(context).cardColor,
                      initialValue: isEdit ? "cr1" : null,
                      style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(hintText: "Select Course"),
                      items: const [
                        DropdownMenuItem(value: "cr1", child: Text("B.Tech (CS)")),
                        DropdownMenuItem(value: "cr2", child: Text("M.Tech (CS)")),
                      ],
                      onChanged: (v) {},
                    ),
                  ),
                  AcadexFormField(
                    label: "Academic Year",
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Theme.of(context).cardColor,
                      decoration: InputDecoration(hintText: "Select Academic Year"),
                      items: const [
                        DropdownMenuItem(value: "ay1", child: Text("2025-2026")),
                      ],
                      onChanged: (v) {},
                      initialValue: 'ay1',
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
