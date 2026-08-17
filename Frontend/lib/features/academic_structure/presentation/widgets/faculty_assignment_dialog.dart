import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme/app_theme.dart';
import '../providers/academic_providers.dart';

class FacultyAssignmentDialog extends ConsumerStatefulWidget {
  final String facultyId;
  final String facultyName;
  final List<String> initialSubjectIds;
  final List<String> initialSectionIds;

  const FacultyAssignmentDialog({
    super.key,
    required this.facultyId,
    required this.facultyName,
    required this.initialSubjectIds,
    required this.initialSectionIds,
  });

  @override
  ConsumerState<FacultyAssignmentDialog> createState() => _FacultyAssignmentDialogState();
}

class _FacultyAssignmentDialogState extends ConsumerState<FacultyAssignmentDialog> {
  late Set<String> _selectedSubjectIds;
  late Set<String> _selectedSectionIds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedSubjectIds = Set.from(widget.initialSubjectIds);
    _selectedSectionIds = Set.from(widget.initialSectionIds);
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final sectionsAsync = ref.watch(sectionsProvider);

    return AlertDialog(
      backgroundColor: AppColors.surfaceDarkCard,
      title: Text('Assign Subjects to ${widget.facultyName}', style: const TextStyle(color: AppColors.onDark)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Subjects', style: TextStyle(color: AppColors.onDark, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              subjectsAsync.when(
                data: (subjects) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subjects.map((sub) => FilterChip(
                    label: Text(sub.name),
                    selected: _selectedSubjectIds.contains(sub.id),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSubjectIds.add(sub.id);
                        } else {
                          _selectedSubjectIds.remove(sub.id);
                        }
                      });
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.3),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(color: _selectedSubjectIds.contains(sub.id) ? AppColors.primary : AppColors.onDark),
                    backgroundColor: AppColors.canvasDark,
                  )).toList(),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, _) => const Text('Error loading subjects'),
              ),
              const SizedBox(height: 24),
              const Text('Select Sections', style: TextStyle(color: AppColors.onDark, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              sectionsAsync.when(
                data: (sections) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sections.map((sec) => FilterChip(
                    label: Text("Section ${sec.name}"),
                    selected: _selectedSectionIds.contains(sec.id),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSectionIds.add(sec.id);
                        } else {
                          _selectedSectionIds.remove(sec.id);
                        }
                      });
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.3),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(color: _selectedSectionIds.contains(sec.id) ? AppColors.primary : AppColors.onDark),
                    backgroundColor: AppColors.canvasDark,
                  )).toList(),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, _) => const Text('Error loading sections'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onDark),
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  await ref.read(facultyProvider.notifier).bulkAssignSubjects(
                    widget.facultyId,
                    _selectedSubjectIds.toList(),
                    _selectedSectionIds.toList(),
                  );
                  if (context.mounted) Navigator.pop(context, true);
                },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onDark)) : const Text('Save Assignments'),
        ),
      ],
    );
  }
}
