import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/faculty_history_providers.dart';
import '../widgets/student_attendance_card.dart';
import '../widgets/faculty/audit_info_card.dart';
import '../widgets/faculty/attendance_lock_chip.dart';
import '../widgets/faculty/validation_banner.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';

import '../../domain/models/attendance_status.dart';
import '../widgets/attendance_summary_card.dart';

class FacultyAttendanceDetailScreen extends ConsumerWidget {
  const FacultyAttendanceDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (session == null) {
      return Scaffold(
        backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: AcadexEmptyState(
            title: "Session Not Found",
            subtitle: "The requested attendance session record is not available.",
            icon: LucideIcons.fileX,
          ),
        ),
      );
    }

    final isEditMode = ref.watch(isEditModeProvider);
    final editRecords = ref.watch(editSessionProvider);
    final editNotifier = ref.read(editSessionProvider.notifier);

    final displayRecords = isEditMode ? editRecords : session.records;
    final isSaving = ref.watch(saveEditedSessionProvider).isLoading;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () {
            if (isEditMode) {
              ref.read(isEditModeProvider.notifier).state = false;
            } else {
              context.pop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditMode ? "Edit Attendance Session" : "Session Details",
              style: AcadexTypography.title(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ),
            ),
            Text(
              "${session.subjectName} • ${session.sectionName}",
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
            ),
          ],
        ),
        actions: [
          if (!isEditMode && !session.isLocked)
            IconButton(
              icon: Icon(LucideIcons.pencil, color: AcadexColors.primary, size: 18),
              tooltip: "Edit Records",
              onPressed: () {
                editNotifier.init(session.records);
                ref.read(isEditModeProvider.notifier).state = true;
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              // Header / Audit Info
              if (!isEditMode)
                Container(
                  color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMMM dd, yyyy').format(session.date),
                            style: AcadexTypography.title(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                          ),
                          AttendanceLockChip(isLocked: session.isLocked),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AttendanceSummaryCard(
                        summary: {
                          for (final status in AttendanceStatus.values)
                            status: session.records.where((r) => r.status == status).length
                        },
                        remainingCount: session.records.where((r) => r.status == null).length,
                        totalStudents: session.records.length,
                        isVertical: false,
                      ),
                      const SizedBox(height: 14),
                      AuditInfoCard(session: session),
                    ],
                  ),
                ),
              
              // Edit Validation
              if (isEditMode)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ValidationBanner(remainingCount: editNotifier.remainingCount),
                ),

              // Student List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayRecords.length,
                  itemBuilder: (context, index) {
                    final record = displayRecords[index];
                    bool hasChanged = isEditMode && record.status != record.oldStatus;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasChanged)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, left: 4),
                            child: Row(
                              children: [
                                Icon(LucideIcons.info, size: 13, color: AcadexColors.warning),
                                const SizedBox(width: 4),
                                Text(
                                  "Modified from: ${record.oldStatus?.displayName ?? 'None'}",
                                  style: AcadexTypography.caption(
                                    color: AcadexColors.warning,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        AbsorbPointer(
                          absorbing: !isEditMode,
                          child: StudentAttendanceCard(
                            record: record,
                            onStatusChanged: (newStatus) {
                              if (isEditMode) {
                                editNotifier.updateStatus(record.studentId, newStatus);
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isEditMode
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    ),
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Row(
                      children: [
                        Expanded(
                          child: AcadexButton(
                            label: "Cancel",
                            variant: AcadexButtonVariant.secondary,
                            onPressed: () => ref.read(isEditModeProvider.notifier).state = false,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: AcadexButton(
                            label: "Save Changes",
                            icon: LucideIcons.check,
                            isLoading: isSaving,
                            variant: AcadexButtonVariant.primary,
                            onPressed: editNotifier.remainingCount > 0
                                ? null
                                : () async {
                                    final success = await ref.read(saveEditedSessionProvider.future);
                                    if (success && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Changes saved successfully!",
                                            style: AcadexTypography.bodySmall(color: Colors.white),
                                          ),
                                          backgroundColor: AcadexColors.success,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
