import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/attendance_providers.dart';
import '../providers/faculty_history_providers.dart';
import '../widgets/student_attendance_card.dart';
import '../widgets/faculty/audit_info_card.dart';
import '../widgets/faculty/attendance_lock_chip.dart';
import '../widgets/faculty/validation_banner.dart';
import '../widgets/attendance_correction_dialog.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';

import '../../domain/models/attendance_status.dart';
import '../widgets/attendance_summary_card.dart';

class FacultyAttendanceDetailScreen extends ConsumerWidget {
  const FacultyAttendanceDetailScreen({super.key});

  void _confirmLockSession(BuildContext context, WidgetRef ref, String sessionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.lock, size: 20, color: AcadexColors.warning),
            SizedBox(width: 8),
            Text('Lock Attendance Session'),
          ],
        ),
        content: const Text(
          'Locking this session makes all student attendance records immutable for standard marking. Further modifications will require audited HOD/Admin corrections.\n\nAre you sure you want to lock this session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.warning),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(lockSessionProvider(sessionId).future);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Attendance session locked successfully.'),
                      backgroundColor: AcadexColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to lock session: $e'),
                      backgroundColor: AcadexColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Lock Session', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmCloseSession(BuildContext context, WidgetRef ref, String sessionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.checkCircle, size: 20, color: AcadexColors.success),
            SizedBox(width: 8),
            Text('Close Attendance Session'),
          ],
        ),
        content: const Text(
          'Closing this session marks the session as fully finalized and archived. No further regular modifications will be permitted.\n\nAre you sure you want to close this session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.success),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(closeSessionProvider(sessionId).future);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Attendance session closed successfully.'),
                      backgroundColor: AcadexColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to close session: $e'),
                      backgroundColor: AcadexColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Close Session', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmCancelSession(BuildContext context, WidgetRef ref, String sessionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.ban, size: 20, color: AcadexColors.error),
            SizedBox(width: 8),
            Text('Cancel Attendance Session'),
          ],
        ),
        content: const Text(
          'Cancelling this session invalidates the session and marks all its attendance records as cancelled. Cancelled records will no longer count toward student percentages.\n\nAre you sure you want to cancel this session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(cancelSessionProvider(sessionId).future);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Attendance session cancelled.'),
                      backgroundColor: AcadexColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel session: $e'),
                      backgroundColor: AcadexColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Cancel Session', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (session == null) {
      return Scaffold(
        backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
            onPressed: () => context.safePop(fallbackRoute: '/attendance/faculty_history'),
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

    final isHodOrAdmin = currentUser != null &&
        (currentUser.role == AppRole.hod ||
            currentUser.role == AppRole.collegeAdmin ||
            currentUser.role == AppRole.superAdmin);

    final canFacultyEdit = session.isOpen && !isHodOrAdmin;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () {
            if (isEditMode) {
              ref.read(isEditModeProvider.notifier).state = false;
            } else {
              context.safePop(fallbackRoute: '/attendance/faculty_history');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditMode ? "Edit Attendance Session" : "Session Details",
              style: AcadexTypography.title(
                color: Colors.white,
              ),
            ),
            Text(
              "${session.subjectName} • ${session.sectionName}",
              style: AcadexTypography.caption(
                color: const Color(0xFFCCE6FF),
              ),
            ),
          ],
        ),
        actions: [
          if (!isEditMode && canFacultyEdit)
            IconButton(
              icon: Icon(LucideIcons.pencil, color: AcadexColors.primary, size: 18),
              tooltip: "Edit Records",
              onPressed: () {
                editNotifier.init(session.records);
                ref.read(isEditModeProvider.notifier).state = true;
              },
            ),
          if (!isEditMode && session.isOpen)
            IconButton(
              icon: const Icon(LucideIcons.lock, color: AcadexColors.warning, size: 18),
              tooltip: "Lock Session",
              onPressed: () => _confirmLockSession(context, ref, session.id),
            ),
          if (!isEditMode && isHodOrAdmin)
            PopupMenuButton<String>(
              icon: Icon(
                LucideIcons.moreVertical,
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                size: 18,
              ),
              onSelected: (action) {
                if (action == 'close') {
                  _confirmCloseSession(context, ref, session.id);
                } else if (action == 'cancel') {
                  _confirmCancelSession(context, ref, session.id);
                } else if (action == 'lock') {
                  _confirmLockSession(context, ref, session.id);
                }
              },
              itemBuilder: (ctx) => [
                if (!session.isLockedState)
                  const PopupMenuItem(
                    value: 'lock',
                    child: Row(
                      children: [
                        Icon(LucideIcons.lock, size: 16, color: AcadexColors.warning),
                        SizedBox(width: 8),
                        Text('Lock Session'),
                      ],
                    ),
                  ),
                if (!session.isClosed)
                  const PopupMenuItem(
                    value: 'close',
                    child: Row(
                      children: [
                        Icon(LucideIcons.checkCircle, size: 16, color: AcadexColors.success),
                        SizedBox(width: 8),
                        Text('Close Session'),
                      ],
                    ),
                  ),
                if (!session.isCancelled)
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(LucideIcons.ban, size: 16, color: AcadexColors.error),
                        SizedBox(width: 8),
                        Text('Cancel Session'),
                      ],
                    ),
                  ),
              ],
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('MMMM dd, yyyy').format(session.date),
                                style: AcadexTypography.title(
                                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                ),
                              ),
                              if (session.timeSlot.isNotEmpty)
                                Text(
                                  session.timeSlot,
                                  style: AcadexTypography.caption(
                                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                  ),
                                ),
                            ],
                          ),
                          AttendanceLockChip(isLocked: session.isLocked, status: session.status),
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
                        if (record.oldStatus != null && !isEditMode)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4, left: 4),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.shieldCheck, size: 12, color: AcadexColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  "Audited correction from ${record.oldStatus?.displayName ?? '-'}${record.remarks != null ? ': ${record.remarks}' : ''}",
                                  style: AcadexTypography.caption(
                                    color: AcadexColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        InkWell(
                          onTap: (isHodOrAdmin && !session.isCancelled && !isEditMode)
                              ? () {
                                  AttendanceCorrectionDialog.show(
                                    context,
                                    record: record,
                                    sessionId: session.id,
                                    subjectName: session.subjectName,
                                    sectionName: session.sectionName,
                                    onCorrectionSuccess: () {
                                      ref.invalidate(sessionDetailProvider(session.id));
                                      ref.invalidate(facultyHistoryListProvider);
                                    },
                                  );
                                }
                              : null,
                          borderRadius: BorderRadius.circular(10),
                          child: AbsorbPointer(
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
