import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/attendance_status.dart';
import '../providers/attendance_providers.dart';

class AttendanceCorrectionDialog extends ConsumerStatefulWidget {
  final AttendanceRecord record;
  final String sessionId;
  final String subjectName;
  final String sectionName;
  final VoidCallback? onCorrectionSuccess;

  const AttendanceCorrectionDialog({
    super.key,
    required this.record,
    required this.sessionId,
    required this.subjectName,
    required this.sectionName,
    this.onCorrectionSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required AttendanceRecord record,
    required String sessionId,
    required String subjectName,
    required String sectionName,
    VoidCallback? onCorrectionSuccess,
  }) async {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    if (isDesktop) {
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: AttendanceCorrectionDialog(
              record: record,
              sessionId: sessionId,
              subjectName: subjectName,
              sectionName: sectionName,
              onCorrectionSuccess: onCorrectionSuccess,
            ),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).brightness == Brightness.dark
                  ? AcadexColors.darkSurface
                  : AcadexColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: AttendanceCorrectionDialog(
                record: record,
                sessionId: sessionId,
                subjectName: subjectName,
                sectionName: sectionName,
                onCorrectionSuccess: onCorrectionSuccess,
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<AttendanceCorrectionDialog> createState() => _AttendanceCorrectionDialogState();
}

class _AttendanceCorrectionDialogState extends ConsumerState<AttendanceCorrectionDialog> {
  late AttendanceStatus _selectedStatus;
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.record.status ?? AttendanceStatus.present;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStatus == widget.record.status) {
      setState(() {
        _errorMessage = 'Please select a different attendance status to correct.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final recordId = widget.record.id;
      if (recordId.isEmpty) {
        throw StateError('Record ID is not available for correction.');
      }

      await ref.read(correctRecordProvider((
        recordId: recordId,
        newStatus: _selectedStatus,
        reason: _reasonController.text.trim(),
        sessionId: widget.sessionId,
      )).future);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attendance corrected successfully for ${widget.record.studentName}',
              style: AcadexTypography.bodySmall(color: Colors.white),
            ),
            backgroundColor: AcadexColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onCorrectionSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AcadexColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.filePenLine,
                          color: AcadexColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Correct Attendance",
                            style: AcadexTypography.heading3(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                          ),
                          Text(
                            "${widget.subjectName} • ${widget.sectionName}",
                            style: AcadexTypography.caption(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      size: 18,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Audited notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      LucideIcons.shieldCheck,
                      color: AcadexColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Attendance corrections are strictly audited. All changes are permanently recorded in the institutional audit log with your user ID and timestamp.",
                        style: AcadexTypography.caption(
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Student details card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.record.studentName,
                            style: AcadexTypography.body(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Roll No: ${widget.record.rollNumber}",
                            style: AcadexTypography.caption(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (widget.record.status?.color ?? AcadexColors.inkMuted).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Current: ${widget.record.status?.displayName ?? 'Unmarked'}",
                        style: AcadexTypography.caption(
                          color: widget.record.status?.color ?? AcadexColors.inkMuted,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Status picker
              Text(
                "SELECT NEW STATUS",
                style: AcadexTypography.eyebrow(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AttendanceStatus.present,
                  AttendanceStatus.absent,
                  AttendanceStatus.late,
                  AttendanceStatus.excused,
                  AttendanceStatus.medicalLeave,
                  AttendanceStatus.onDuty,
                ].map((status) {
                  final isSelected = _selectedStatus == status;
                  return ChoiceChip(
                    label: Text(status.displayName),
                    selected: isSelected,
                    selectedColor: status.color.withValues(alpha: 0.2),
                    backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? status.color
                          : (isDark ? AcadexColors.darkInk : AcadexColors.ink),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? status.color
                          : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                      width: isSelected ? 1.5 : 1,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedStatus = status);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Reason input
              Text(
                "REASON FOR CORRECTION *",
                style: AcadexTypography.eyebrow(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                minLines: 2,
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: "Enter explanation for this correction (e.g. Approved medical leave, OD request)...",
                  hintStyle: AcadexTypography.bodySmall(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                  filled: true,
                  fillColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 3) {
                    return "Please enter a valid reason (minimum 3 characters)";
                  }
                  return null;
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: AcadexTypography.caption(color: AcadexColors.error),
                ),
              ],
              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      "Cancel",
                      style: AcadexTypography.button(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AcadexButton(
                    label: _isSubmitting ? "Saving..." : "Confirm Correction",
                    icon: LucideIcons.check,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _handleSubmit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
