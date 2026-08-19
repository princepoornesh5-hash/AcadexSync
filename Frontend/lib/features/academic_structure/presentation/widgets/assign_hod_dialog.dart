import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../domain/models/academic_models.dart';
import '../providers/academic_providers.dart';

class AssignHodDialog extends ConsumerStatefulWidget {
  final Department department;

  const AssignHodDialog({
    super.key,
    required this.department,
  });

  static Future<void> show(BuildContext context, Department department) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AssignHodDialog(department: department),
    );
  }

  @override
  ConsumerState<AssignHodDialog> createState() => _AssignHodDialogState();
}

class _AssignHodDialogState extends ConsumerState<AssignHodDialog> {
  String? _selectedFacultyId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedFacultyId = widget.department.hodId.isNotEmpty ? widget.department.hodId : null;
  }

  Future<void> _handleSave() async {
    if (_selectedFacultyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a faculty member to assign as HOD')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(departmentsProvider.notifier).assignHod(
        widget.department.id,
        _selectedFacultyId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('HOD assigned successfully'),
            backgroundColor: AcadexColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AcadexColors.warning),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final facultyState = ref.watch(facultyProvider(widget.department.id));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.lg)),
      backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AcadexColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AcadexRadius.md),
                      ),
                      child: const Icon(LucideIcons.shieldCheck, color: AcadexColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Assign Head of Dept (HOD)', style: AcadexTypography.heading3(color: theme.colorScheme.onSurface)),
                        Text(widget.department.name, style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),

            Text(
              'Select a faculty member from ${widget.department.name} to assume administrative department head responsibility.',
              style: AcadexTypography.body(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 16),

            if (facultyState.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (facultyState.error != null)
              Text('Error loading faculty: ${facultyState.error}', style: const TextStyle(color: AcadexColors.warning))
            else if (facultyState.items.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkSurfaceCard : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(AcadexRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info, size: 18, color: AcadexColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No faculty found in this department. Please add faculty first.',
                        style: AcadexTypography.caption(color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                initialValue: _selectedFacultyId,
                decoration: const InputDecoration(
                  labelText: 'Select Faculty Member *',
                  hintText: 'Choose from department faculty',
                ),
                items: facultyState.items.map((f) => DropdownMenuItem(
                  value: f.id,
                  child: Text('${f.name} (${f.employeeId})'),
                )).toList(),
                onChanged: (val) => setState(() => _selectedFacultyId = val),
              ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                AcadexButton(
                  label: _isSubmitting ? 'Saving...' : 'Save HOD Assignment',
                  icon: LucideIcons.check,
                  isLoading: _isSubmitting,
                  onPressed: facultyState.items.isEmpty ? null : _handleSave,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
