import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/faculty_history_providers.dart';
import '../widgets/student_attendance_card.dart';
import '../widgets/faculty/audit_info_card.dart';
import '../widgets/faculty/attendance_lock_chip.dart';
import '../widgets/faculty/validation_banner.dart';
import 'package:intl/intl.dart';

class FacultyAttendanceDetailScreen extends ConsumerWidget {
  const FacultyAttendanceDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionProvider);
    if (session == null) {
      return const Scaffold(body: Center(child: Text("Session not found")));
    }

    final isEditMode = ref.watch(isEditModeProvider);
    final editRecords = ref.watch(editSessionProvider);
    final editNotifier = ref.read(editSessionProvider.notifier);

    final displayRecords = isEditMode ? editRecords : session.records;
    final isSaving = ref.watch(saveEditedSessionProvider).isLoading;

    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        backgroundColor: DashboardColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: DashboardColors.textPrimary),
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
            Text(isEditMode ? "Edit Attendance" : "Session Details", style: const TextStyle(color: DashboardColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("${session.subjectName} • ${session.sectionName}", style: const TextStyle(color: DashboardColors.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          if (!isEditMode && !session.isLocked)
            IconButton(
              icon: const Icon(LucideIcons.edit, color: DashboardColors.primary),
              tooltip: "Edit Records",
              onPressed: () {
                editNotifier.init(session.records);
                ref.read(isEditModeProvider.notifier).state = true;
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Header / Audit Info
          if (!isEditMode)
            Container(
              color: DashboardColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(session.date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      AttendanceLockChip(isLocked: session.isLocked),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                
                // Track changes UI
                bool hasChanged = isEditMode && record.status != record.oldStatus;
                
                return Column(
                  children: [
                    if (hasChanged)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.info_outline, size: 14, color: DashboardColors.warning),
                            const SizedBox(width: 4),
                            Text("Changed from: ${record.oldStatus?.displayName ?? 'None'}", style: const TextStyle(color: DashboardColors.warning, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    AbsorbPointer(
                      absorbing: !isEditMode,
                      child: Opacity(
                        opacity: isEditMode || session.isLocked ? 1.0 : 0.8, 
                        // If not editing but unlocked, slightly fade. Wait, if not editing, just display normally.
                        child: StudentAttendanceCard(
                          record: record,
                          onStatusChanged: (newStatus) {
                            if (isEditMode) {
                              editNotifier.updateStatus(record.studentId, newStatus);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          )
        ],
      ),
      bottomNavigationBar: isEditMode
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: DashboardColors.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => ref.read(isEditModeProvider.notifier).state = false,
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: editNotifier.remainingCount > 0 ? null : () async {
                          final success = await ref.read(saveEditedSessionProvider.future);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Changes saved successfully!"), backgroundColor: DashboardColors.success));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: DashboardColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Save Changes"),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
