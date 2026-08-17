import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme/app_theme.dart';
import '../providers/academic_providers.dart';
import '../../domain/models/academic_models.dart';

class StudentPromotionDialog extends ConsumerStatefulWidget {
  final List<String> studentIds;

  const StudentPromotionDialog({super.key, required this.studentIds});

  @override
  ConsumerState<StudentPromotionDialog> createState() => _StudentPromotionDialogState();
}

class _StudentPromotionDialogState extends ConsumerState<StudentPromotionDialog> {
  String? _selectedSemesterId;
  String? _selectedSectionId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final semestersAsync = ref.watch(semestersProvider);
    final sectionsAsync = ref.watch(sectionsProvider);

    return AlertDialog(
      backgroundColor: AppColors.surfaceDarkCard,
      title: const Text('Promote Students', style: TextStyle(color: AppColors.onDark)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Promoting ${widget.studentIds.length} students.', style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 24),
            const Text('Select Target Semester', style: TextStyle(color: AppColors.onDark, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            semestersAsync.when(
              data: (semesters) => DropdownButtonFormField<String>(
                dropdownColor: AppColors.surfaceDarkElevated,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.canvasDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                initialValue: _selectedSemesterId,
                items: semesters.map((sem) => DropdownMenuItem(value: sem.id, child: Text(sem.name, style: const TextStyle(color: AppColors.onDark)))).toList(),
                onChanged: (val) => setState(() => _selectedSemesterId = val),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, _) => const Text('Error loading semesters', style: TextStyle(color: AppColors.warning)),
            ),
            const SizedBox(height: 16),
            const Text('Select Target Section', style: TextStyle(color: AppColors.onDark, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            sectionsAsync.when(
              data: (sections) {
                // Filter sections by selected semester
                final filtered = _selectedSemesterId != null 
                    ? sections.where((s) => s.semesterId == _selectedSemesterId).toList()
                    : <Section>[];

                return DropdownButtonFormField<String>(
                  dropdownColor: AppColors.surfaceDarkElevated,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.canvasDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  initialValue: _selectedSectionId,
                  items: filtered.map((sec) => DropdownMenuItem(value: sec.id, child: Text("Section ${sec.name}", style: const TextStyle(color: AppColors.onDark)))).toList(),
                  onChanged: (val) => setState(() => _selectedSectionId = val),
                  hint: const Text("Select Section", style: TextStyle(color: AppColors.textMuted)),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, _) => const Text('Error loading sections', style: TextStyle(color: AppColors.warning)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onDark,
          ),
          onPressed: (_isLoading || _selectedSemesterId == null || _selectedSectionId == null)
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  await ref.read(studentsProvider.notifier).promoteStudents(
                    widget.studentIds,
                    _selectedSemesterId!,
                    _selectedSectionId!,
                  );
                  if (context.mounted) Navigator.pop(context, true);
                },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onDark)) : const Text('Confirm Promotion'),
        ),
      ],
    );
  }
}

class StudentTransferDialog extends ConsumerStatefulWidget {
  final List<String> studentIds;

  const StudentTransferDialog({super.key, required this.studentIds});

  @override
  ConsumerState<StudentTransferDialog> createState() => _StudentTransferDialogState();
}

class _StudentTransferDialogState extends ConsumerState<StudentTransferDialog> {
  String? _selectedSectionId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(sectionsProvider);

    return AlertDialog(
      backgroundColor: AppColors.surfaceDarkCard,
      title: const Text('Transfer Students', style: TextStyle(color: AppColors.onDark)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transferring ${widget.studentIds.length} students to a new section.', style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 24),
            const Text('Select Target Section', style: TextStyle(color: AppColors.onDark, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            sectionsAsync.when(
              data: (sections) => DropdownButtonFormField<String>(
                dropdownColor: AppColors.surfaceDarkElevated,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.canvasDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                initialValue: _selectedSectionId,
                items: sections.map((sec) => DropdownMenuItem(value: sec.id, child: Text("Section ${sec.name}", style: const TextStyle(color: AppColors.onDark)))).toList(),
                onChanged: (val) => setState(() => _selectedSectionId = val),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, _) => const Text('Error loading sections', style: TextStyle(color: AppColors.warning)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onDark,
          ),
          onPressed: (_isLoading || _selectedSectionId == null)
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  await ref.read(studentsProvider.notifier).transferStudents(
                    widget.studentIds,
                    _selectedSectionId!,
                  );
                  if (context.mounted) Navigator.pop(context, true);
                },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onDark)) : const Text('Confirm Transfer'),
        ),
      ],
    );
  }
}
