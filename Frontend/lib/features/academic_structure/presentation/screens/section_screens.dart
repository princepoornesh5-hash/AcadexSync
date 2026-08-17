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

class SectionListScreen extends ConsumerWidget {
  const SectionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(sectionsProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Sections", style: AcadexTypography.heading2(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text("Manage sections, merge, and archive.", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),
          AcadexSearchFilterBar(
            searchHint: "Search sections...",
            onSearchChanged: (v) {},
            onActionTap: () => context.push('/academics/sections/new'),
            actionLabel: "Add Section",
          ),
          const SizedBox(height: 24),
          Expanded(
            child: sectionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: AppColors.warning))),
              data: (sections) => AcadexDataTable(
                columns: const ["Section Name", "Semester", "Status", "Actions"],
                rows: sections.map((s) => DataRow(cells: [
                  DataCell(Text("Section ${s.name}", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
                  DataCell(Text(s.semesterId)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: s.isActive ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceDarkElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(s.isActive ? "Active" : "Archived", style: TextStyle(color: s.isActive ? AppColors.primary : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(icon: Icon(LucideIcons.edit, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), onPressed: () => context.push('/academics/sections/edit/${s.id}')),
                        PopupMenuButton<String>(
                          icon: Icon(LucideIcons.moreVertical, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                          color: Theme.of(context).cardColor,
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'merge', child: Text("Merge Section", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface))),
                            const PopupMenuItem(value: 'archive', child: Text("Archive", style: TextStyle(color: AppColors.warning))),
                          ],
                          onSelected: (val) {
                            if (val == 'merge') {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Merge feature coming soon.")));
                            }
                            if (val == 'archive') {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Section archived.")));
                            }
                          },
                        )
                      ],
                    )
                  ),
                ])).toList(),
                emptyState: AcadexEmptyState(
                  title: "No Sections Found",
                  subtitle: "Create sections to group your students.",
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

class SectionFormScreen extends StatelessWidget {
  final String? id;
  const SectionFormScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final isEdit = id != null;
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface), onPressed: () => context.pop()),
        title: Text(isEdit ? "Edit Section" : "Add Section", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface)),
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
                  title: "Section Information",
                  icon: LucideIcons.users,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: "Section Name (e.g. A, B)", prefixIcon: Icon(LucideIcons.hash)),
                              initialValue: isEdit ? "A" : "",
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: "Semester", prefixIcon: Icon(LucideIcons.calendar)),
                              items: const [DropdownMenuItem(value: 'sem1', child: Text("Semester 1"))],
                              onChanged: (v) {},
                              initialValue: 'sem1',
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
                      child: const Text("Save Section"),
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
