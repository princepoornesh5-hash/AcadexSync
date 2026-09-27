import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/academic_models.dart';
import '../../../institution_config/domain/models/institution_config_models.dart';
import '../../../institution_config/presentation/providers/institution_config_providers.dart';

/// Intelligent program selector that auto-resolves if only 1 program exists in context
class ContextProgramSelector extends ConsumerStatefulWidget {
  final List<Course> courses;
  final String? selectedCourseId;
  final ValueChanged<String?> onCourseChanged;
  final bool isEdit;
  final String? validatorMessage;

  const ContextProgramSelector({
    super.key,
    required this.courses,
    required this.selectedCourseId,
    required this.onCourseChanged,
    this.isEdit = false,
    this.validatorMessage,
  });

  @override
  ConsumerState<ContextProgramSelector> createState() => _ContextProgramSelectorState();
}

class _ContextProgramSelectorState extends ConsumerState<ContextProgramSelector> {
  @override
  void initState() {
    super.initState();
    _checkAutoResolve();
  }

  @override
  void didUpdateWidget(covariant ContextProgramSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAutoResolve();
  }

  void _checkAutoResolve() {
    if (widget.courses.length == 1) {
      final singleCourseId = widget.courses.first.id;
      if (widget.selectedCourseId != singleCourseId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onCourseChanged(singleCourseId);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final terminology = ref.watch(terminologyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final programLabel = terminology.label(AcademicConcept.program);

    if (widget.courses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.warningLight,
          borderRadius: AcadexRadius.borderRadiusMd,
          border: Border.all(color: AcadexColors.warning),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No $programLabel Found', style: const TextStyle(fontWeight: FontWeight.bold, color: AcadexColors.warning)),
            const SizedBox(height: 4),
            Text('You must create at least one ${programLabel.toLowerCase()} before proceeding.'),
          ],
        ),
      );
    }

    // Auto-resolved single program display (Requirement 9: Single-Program Department Intelligence)
    if (widget.courses.length == 1) {
      final singleCourse = widget.courses.first;
      return Container(
        key: const Key('single_program_autoresolved_banner'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.primary.withValues(alpha: 0.05),
          borderRadius: AcadexRadius.borderRadiusMd,
          border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.graduationCap, size: 20, color: AcadexColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${singleCourse.name} (${singleCourse.code})',
                    style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Auto-resolved ($programLabel)',
                    style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.checkCircle2, size: 16, color: AcadexColors.success),
          ],
        ),
      );
    }

    // Multiple programs: show standard dropdown
    return DropdownButtonFormField<String>(
      key: const Key('context_program_dropdown'),
      dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
      value: widget.selectedCourseId,
      decoration: InputDecoration(hintText: 'Select $programLabel'),
      validator: (v) => v == null ? (widget.validatorMessage ?? '$programLabel is required') : null,
      items: widget.courses
          .map((c) => DropdownMenuItem(
                value: c.id,
                child: Text('${c.name} (${c.code})'),
              ))
          .toList(),
      onChanged: widget.isEdit ? null : widget.onCourseChanged,
    );
  }
}
