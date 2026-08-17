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

class CourseListScreen extends ConsumerWidget {
  const CourseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Courses (Programs)", style: AcadexTypography.heading2(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text("Manage programs (e.g., B.Tech, MBA) offered by departments.", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),
          AcadexSearchFilterBar(
            searchHint: "Search courses...",
            onSearchChanged: (v) {},
            onActionTap: () => context.push('/academics/courses/new'),
            actionLabel: "Add Course",
          ),
          const SizedBox(height: 24),
          Expanded(
            child: coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: AppColors.warning))),
              data: (courses) => AcadexDataTable(
                columns: const ["Code", "Name", "Department", "Status", "Actions"],
                rows: courses.map((c) => DataRow(cells: [
                  DataCell(Text(c.code, style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
                  DataCell(Text(c.name)),
                  DataCell(Text(c.departmentId)),
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
                        IconButton(icon: Icon(LucideIcons.edit, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), onPressed: () => context.push('/academics/courses/edit/${c.id}')),
                        IconButton(icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.warning), onPressed: () {}),
                      ],
                    )
                  ),
                ])).toList(),
                emptyState: AcadexEmptyState(
                  title: "No Courses Found",
                  subtitle: "Get started by adding a program/course.",
                  icon: LucideIcons.book,
                  actionLabel: "Add Course",
                  onActionTap: () => context.push('/academics/courses/new'),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class CourseFormScreen extends StatelessWidget {
  final String? id;
  const CourseFormScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final isEdit = id != null;
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface), onPressed: () => context.pop()),
        title: Text(isEdit ? "Edit Course" : "Add Course", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AcadexFormCard(
              title: "Course Details",
              onCancel: () => context.pop(),
              onSave: () => context.pop(),
              child: Column(
                children: [
                  AcadexFormField(
                    label: "Course Name",
                    child: TextFormField(
                      initialValue: isEdit ? "B.Tech" : "",
                      style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(hintText: "e.g. B.Tech, MBA"),
                    ),
                  ),
                  AcadexFormField(
                    label: "Course Code",
                    child: TextFormField(
                      initialValue: isEdit ? "BTECH-CS" : "",
                      style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(hintText: "e.g. BTECH-CS"),
                    ),
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
                        DropdownMenuItem(value: "d2", child: Text("Mechanical Engineering")),
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
