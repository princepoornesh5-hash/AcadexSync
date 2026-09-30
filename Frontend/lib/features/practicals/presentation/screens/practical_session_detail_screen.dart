import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/practical_models.dart';
import '../providers/practicals_providers.dart';
import '../widgets/practical_participation_card.dart';

class PracticalSessionDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const PracticalSessionDetailScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<PracticalSessionDetailScreen> createState() => _PracticalSessionDetailScreenState();
}

class _PracticalSessionDetailScreenState extends ConsumerState<PracticalSessionDetailScreen> {
  bool _isProcessingAction = false;

  Future<void> _handleOpenSession() async {
    setState(() => _isProcessingAction = true);
    try {
      await ref.read(practicalActionProvider.notifier).openSession(widget.sessionId);
      if (mounted) {
        AcadexSnackBar.showSuccess(context, 'Practical session is now OPEN for execution!');
      }
    } catch (e) {
      if (mounted) AcadexSnackBar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _handleCompleteSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Practical Session?'),
        content: const Text(
          'Finalizing this session will complete student practical records for today. Historical participation will be archived.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
            child: const Text('Complete Session', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessingAction = true);
    try {
      await ref.read(practicalActionProvider.notifier).completeSession(widget.sessionId);
      if (mounted) {
        AcadexSnackBar.showSuccess(context, 'Practical session marked COMPLETED!');
      }
    } catch (e) {
      if (mounted) AcadexSnackBar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _handleCancelSession() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Practical Session?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this practical session?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Back')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Session', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessingAction = true);
    try {
      await ref.read(practicalActionProvider.notifier).cancelSession(
        widget.sessionId,
        reason: reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : null,
      );
      if (mounted) {
        AcadexSnackBar.showSuccess(context, 'Practical session cancelled.');
      }
    } catch (e) {
      if (mounted) AcadexSnackBar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _handleBulkMarkAll(
    List<PracticalParticipationModel> participations,
    PracticalParticipationStatus newStatus,
  ) async {
    setState(() => _isProcessingAction = true);
    try {
      final updates = participations.map((p) => {
        'studentId': p.studentId,
        'status': newStatus.backendValue,
      }).toList();

      await ref.read(practicalActionProvider.notifier).bulkUpdateParticipation(
        sessionId: widget.sessionId,
        updates: updates,
      );
      if (mounted) {
        AcadexSnackBar.showSuccess(context, 'Updated all students to ${newStatus.displayName}!');
      }
    } catch (e) {
      if (mounted) AcadexSnackBar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  void _showEditNotesSheet(PracticalParticipationModel p) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: p.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notes for ${p.studentName}',
                style: AcadexTypography.heading2(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter observation, code issue, or lab remark...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: AcadexButton(
                  label: 'Save Notes',
                  icon: LucideIcons.check,
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await ref.read(practicalActionProvider.notifier).updateParticipation(
                      sessionId: widget.sessionId,
                      studentId: p.studentId,
                      status: p.status,
                      notes: controller.text.trim(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isStudent = user?.role == AppRole.student;

    final detailAsync = ref.watch(practicalSessionDetailProvider(widget.sessionId));

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/practicals'),
        ),
        title: Text(
          'Practical Session',
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
      ),
      body: detailAsync.when(
        loading: () => const AcadexLoadingState(message: 'Loading practical session details...'),
        error: (err, stack) => Center(
          child: AcadexErrorState(
            message: "Couldn't load practical session.",
            retryLabel: 'Retry',
            onRetry: () => ref.refresh(practicalSessionDetailProvider(widget.sessionId)),
          ),
        ),
        data: (data) {
          final session = data.session;
          final participations = data.participations;
          final isOpen = session.status == PracticalSessionStatus.open;
          final isPlanned = session.status == PracticalSessionStatus.planned;

          return Column(
            children: [
              // Header Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            session.subjectName ?? session.subjectCode ?? 'Practical Subject',
                            style: AcadexTypography.caption(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? const Color(0xFFDCFCE7)
                                : (session.status == PracticalSessionStatus.completed
                                    ? AcadexColors.primaryTint
                                    : (isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            session.status.displayName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isOpen
                                  ? const Color(0xFF15803D)
                                  : (session.status == PracticalSessionStatus.completed
                                      ? AcadexColors.primary
                                      : (isDark ? AcadexColors.darkInk : AcadexColors.ink)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      session.topic,
                      style: AcadexTypography.heading2(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Metrics row (horizontally scrollable to avoid 360px overflow)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildMetricChip(
                            label: '${session.completedCount} / ${session.totalEnrolled} Completed',
                            color: const Color(0xFF15803D),
                            bg: const Color(0xFFDCFCE7),
                          ),
                          const SizedBox(width: 8),
                          _buildMetricChip(
                            label: '${session.inProgressCount} In Progress',
                            color: AcadexColors.primary,
                            bg: AcadexColors.primaryTint,
                          ),
                          if (session.absentCount > 0) ...[
                            const SizedBox(width: 8),
                            _buildMetricChip(
                              label: '${session.absentCount} Absent',
                              color: const Color(0xFFDC2626),
                              bg: const Color(0xFFFEE2E2),
                            ),
                          ],
                          if (session.roomNumber != null) ...[
                            const SizedBox(width: 8),
                            _buildMetricChip(
                              label: 'Room: ${session.roomNumber}',
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              bg: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Faculty Actions Bar (Open, Complete, Cancel, Bulk Mark)
              if (!isStudent) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (isPlanned)
                          ElevatedButton.icon(
                            onPressed: _isProcessingAction ? null : _handleOpenSession,
                            icon: const Icon(LucideIcons.play, size: 14, color: Colors.white),
                            label: const Text('Open Session', style: TextStyle(color: Colors.white, fontSize: 12)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D)),
                          ),
                        if (isOpen) ...[
                          ElevatedButton.icon(
                            onPressed: _isProcessingAction ? null : _handleCompleteSession,
                            icon: const Icon(LucideIcons.checkCheck, size: 14, color: Colors.white),
                            label: const Text('Complete Session', style: TextStyle(color: Colors.white, fontSize: 12)),
                            style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _isProcessingAction
                                ? null
                                : () => _handleBulkMarkAll(participations, PracticalParticipationStatus.completed),
                            child: const Text('Mark All Completed', style: TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _isProcessingAction
                                ? null
                                : () => _handleBulkMarkAll(participations, PracticalParticipationStatus.inProgress),
                            child: const Text('Mark All Present', style: TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _isProcessingAction ? null : _handleCancelSession,
                            child: const Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 11)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              // Enrolled Students Roster
              Expanded(
                child: participations.isEmpty
                    ? const Center(
                        child: AcadexEmptyState(
                          icon: LucideIcons.users,
                          title: 'No Enrolled Students',
                          subtitle: 'No active student enrollments found for this practical class context.',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: participations.length,
                        itemBuilder: (context, index) {
                          final p = participations[index];
                          return PracticalParticipationCard(
                            participation: p,
                            isSessionOpen: isOpen && !isStudent,
                            onStatusChanged: (newStatus) {
                              ref.read(practicalActionProvider.notifier).updateParticipation(
                                sessionId: session.id,
                                studentId: p.studentId,
                                status: newStatus,
                              );
                            },
                            onEditNotes: !isStudent ? () => _showEditNotesSheet(p) : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
