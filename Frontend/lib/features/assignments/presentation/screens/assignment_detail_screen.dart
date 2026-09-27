import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/assignment_models.dart';
import '../providers/assignments_providers.dart';
import '../../../institution_config/presentation/providers/institution_config_providers.dart';

class AssignmentDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  ConsumerState<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends ConsumerState<AssignmentDetailScreen> {
  bool _isProcessing = false;

  Future<void> _handleMarkDone() async {
    setState(() => _isProcessing = true);
    final notifier = ref.read(assignmentActionProvider.notifier);
    final success = await notifier.completeAssignment(widget.assignmentId);
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        AcadexSnackBar.showSuccess(context, 'Assignment marked as completed.');
      } else {
        AcadexSnackBar.showError(context, "Couldn't mark assignment as done. Please try again.");
      }
    }
  }

  Future<void> _handlePublish() async {
    setState(() => _isProcessing = true);
    final notifier = ref.read(assignmentActionProvider.notifier);
    final success = await notifier.publishAssignment(widget.assignmentId);
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        AcadexSnackBar.showSuccess(context, 'Assignment published successfully.');
      } else {
        AcadexSnackBar.showError(context, "Couldn't publish assignment. Please try again.");
      }
    }
  }

  Future<void> _handleClose() async {
    setState(() => _isProcessing = true);
    final notifier = ref.read(assignmentActionProvider.notifier);
    final success = await notifier.closeAssignment(widget.assignmentId);
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        AcadexSnackBar.showSuccess(context, 'Assignment closed.');
      } else {
        AcadexSnackBar.showError(context, "Couldn't close assignment. Please try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assignmentAsync = ref.watch(assignmentDetailProvider(widget.assignmentId));
    final authState = ref.watch(authProvider);
    final terminology = ref.watch(terminologyProvider);

    final isStudent = authState is AuthAuthenticated && authState.user.role == AppRole.student;
    final isFacultyOrAdmin = authState is AuthAuthenticated &&
        (authState.user.role == AppRole.faculty ||
            authState.user.role == AppRole.hod ||
            authState.user.role == AppRole.collegeAdmin);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/assignments'),
        ),
        title: Text(
          'Assignment Detail',
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
      ),
      body: assignmentAsync.when(
        loading: () => const AcadexLoadingState(message: 'Loading assignment...'),
        error: (err, stack) => Center(
          child: AcadexErrorState(
            message: "This item is no longer available.",
            retryLabel: 'Retry',
            onRetry: () => ref.refresh(assignmentDetailProvider(widget.assignmentId)),
          ),
        ),
        data: (asgn) {
          final isCompleted = asgn.studentStatus == StudentTaskStatus.completed;
          final isOverdue = asgn.studentStatus == StudentTaskStatus.overdue;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  asgn.title,
                  style: AcadexTypography.heading1(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  terminology.formatCompactContext(
                    subjectName: asgn.subjectName,
                    sectionName: asgn.sectionName,
                  ),
                  style: AcadexTypography.bodyMedium(
                    color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                  ),
                ),

                const SizedBox(height: 18),

                // Due & Max Marks info card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DUE DATE & TIME',
                              style: AcadexTypography.eyebrow(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${asgn.dueDate}, ${asgn.dueTime}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MAXIMUM MARKS',
                              style: AcadexTypography.eyebrow(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${asgn.maximumMarks} Marks',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Student Status / Results Card
                if (isStudent)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFFF0FDF4)
                          : (isOverdue ? const Color(0xFFFEF2F2) : AcadexColors.primaryTint),
                      borderRadius: AcadexRadius.borderRadiusMd,
                      border: Border.all(
                        color: isCompleted
                            ? const Color(0xFFBBF7D0)
                            : (isOverdue ? const Color(0xFFFECACA) : AcadexColors.primaryLight),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCompleted
                              ? LucideIcons.checkCircle2
                              : (isOverdue ? LucideIcons.alertCircle : LucideIcons.clock),
                          size: 20,
                          color: isCompleted
                              ? const Color(0xFF15803D)
                              : (isOverdue ? const Color(0xFFDC2626) : AcadexColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isCompleted
                                    ? 'Completed'
                                    : (isOverdue ? 'Overdue' : 'Pending'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isCompleted
                                      ? const Color(0xFF15803D)
                                      : (isOverdue ? const Color(0xFFDC2626) : AcadexColors.primary),
                                ),
                              ),
                              if (asgn.marks != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Marks: ${asgn.marks} / ${asgn.maximumMarks} (Faculty Reviewed)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ] else if (isCompleted) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Review Pending',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Description
                Text(
                  'INSTRUCTIONS / DESCRIPTION',
                  style: AcadexTypography.eyebrow(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  asgn.description,
                  style: AcadexTypography.body(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),

                const SizedBox(height: 20),

                // Questions
                if (asgn.questions.isNotEmpty) ...[
                  Text(
                    'QUESTIONS',
                    style: AcadexTypography.eyebrow(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...asgn.questions.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final qText = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$idx. ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              qText,
                              style: AcadexTypography.body(
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // Attachments
                if (asgn.attachments.isNotEmpty) ...[
                  Text(
                    'ATTACHMENTS',
                    style: AcadexTypography.eyebrow(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...asgn.attachments.map((att) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                        borderRadius: AcadexRadius.borderRadiusMd,
                        border: Border.all(
                          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.paperclip, size: 16, color: AcadexColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              att.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                // Action Area
                if (isStudent && !isCompleted) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: AcadexButton(
                      label: _isProcessing ? 'Saving...' : 'Mark as Done',
                      icon: LucideIcons.checkCircle2,
                      onPressed: _isProcessing ? null : _handleMarkDone,
                    ),
                  ),
                ],

                if (isFacultyOrAdmin) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: AcadexButton(
                      label: 'View Activity & Record Marks',
                      icon: LucideIcons.users,
                      onPressed: () => context.push('/assignments/${asgn.id}/activity'),
                    ),
                  ),
                  if (asgn.status == AssignmentStatus.draft) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _handlePublish,
                        icon: const Icon(LucideIcons.send, size: 16),
                        label: const Text('Publish Assignment'),
                      ),
                    ),
                  ],
                  if (asgn.status == AssignmentStatus.published) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _handleClose,
                        icon: const Icon(LucideIcons.lock, size: 16),
                        label: const Text('Close Assignment'),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
