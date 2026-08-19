import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/achievement_models.dart';
import '../providers/achievement_providers.dart';
import '../widgets/achievement_widgets.dart';

class AchievementDetailScreen extends ConsumerStatefulWidget {
  final String achievementId;
  final Achievement? achievement;

  const AchievementDetailScreen({
    super.key,
    required this.achievementId,
    this.achievement,
  });

  @override
  ConsumerState<AchievementDetailScreen> createState() => _AchievementDetailScreenState();
}

class _AchievementDetailScreenState extends ConsumerState<AchievementDetailScreen> {
  Achievement? _resolvedAchievement;
  bool _isLoading = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _resolvedAchievement = widget.achievement;
    if (_resolvedAchievement == null) {
      _loadAchievement();
    }
  }

  Future<void> _loadAchievement() async {
    setState(() => _isLoading = true);
    final repo = ref.read(achievementRepositoryProvider);
    final a = await repo.getAchievementById(widget.achievementId);
    if (mounted) {
      setState(() {
        _resolvedAchievement = a;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAchievement() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.lg)),
        title: const Text('Delete Achievement'),
        content: const Text(
          'Are you sure you want to permanently delete this achievement? This will also remove the attached proof file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          AcadexButton(
            label: 'Delete',
            variant: AcadexButtonVariant.danger,
            size: AcadexButtonSize.sm,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(achievementRepositoryProvider);
      await repo.deleteAchievement(
        achievementId: widget.achievementId,
        storagePath: _resolvedAchievement?.storagePath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Achievement deleted.'),
            backgroundColor: AcadexColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e'), backgroundColor: AcadexColors.error),
        );
      }
    }
  }

  void _openReviewDialog() {
    if (_resolvedAchievement == null) return;
    showDialog(
      context: context,
      builder: (ctx) => _ReviewAchievementDialog(
        achievement: _resolvedAchievement!,
        onUpdated: () => _loadAchievement(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final a = _resolvedAchievement;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        body: const Center(child: AcadexLoadingState()),
      );
    }

    if (a == null) {
      return Scaffold(
        backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        body: Center(
          child: AcadexEmptyState(
            title: 'Achievement Not Found',
            subtitle: 'The requested achievement record could not be loaded.',
            actionLabel: 'Back to Achievements',
            onActionTap: () => context.pop(),
          ),
        ),
      );
    }

    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isOwner = user != null && user.id == a.studentUid;
    final canReview = user != null &&
        (user.role == AppRole.hod || user.role == AppRole.faculty || user.role == AppRole.collegeAdmin);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        maxWidth: 900,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AcadexSpacing.space48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              AcadexPageHeader(
                title: a.title,
                subtitle: 'Issued by ${a.issuer} on ${a.achievementDate.day}/${a.achievementDate.month}/${a.achievementDate.year}',
                actions: [
                  if (isOwner) ...[
                    AcadexButton(
                      label: 'Edit',
                      icon: LucideIcons.pencil,
                      variant: AcadexButtonVariant.secondary,
                      onPressed: () => context.push('/achievements/${a.id}/edit', extra: a),
                    ),
                    const SizedBox(width: 8),
                    AcadexButton(
                      label: 'Delete',
                      icon: LucideIcons.trash2,
                      variant: AcadexButtonVariant.danger,
                      onPressed: _isProcessing ? null : _deleteAchievement,
                    ),
                  ],
                  if (canReview) ...[
                    AcadexButton(
                      label: 'Review Verification',
                      icon: LucideIcons.checkCircle,
                      variant: AcadexButtonVariant.primary,
                      onPressed: _openReviewDialog,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AcadexSpacing.space16),

              // Details Card
              AcadexCard(
                padding: const EdgeInsets.all(AcadexSpacing.space24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AchievementCategoryBadge(category: a.category),
                        AchievementStatusBadge(status: a.verificationStatus),
                      ],
                    ),
                    const SizedBox(height: AcadexSpacing.space20),

                    // Title & Description
                    Text(
                      a.title,
                      style: AcadexTypography.heading2(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (a.description.isNotEmpty) ...[
                      Text(
                        a.description,
                        style: AcadexTypography.body(
                          color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                        ),
                      ),
                      const SizedBox(height: AcadexSpacing.space20),
                    ],

                    // Info Grid
                    _infoRow('Issuer / Organization', a.issuer, isDark),
                    _infoRow(
                      'Achievement Date',
                      '${a.achievementDate.day}/${a.achievementDate.month}/${a.achievementDate.year}',
                      isDark,
                    ),
                    _infoRow('Student Name', a.studentName, isDark),
                    _infoRow('Department', a.departmentId.toUpperCase(), isDark),
                    if (a.courseId.isNotEmpty || a.semesterId.isNotEmpty)
                      _infoRow('Academic Scope', 'Sem: ${a.semesterId} • Sec: ${a.sectionId}', isDark),

                    const SizedBox(height: AcadexSpacing.space20),
                    const Divider(),
                    const SizedBox(height: AcadexSpacing.space16),

                    // Skills & Tags
                    if (a.skills.isNotEmpty) ...[
                      Text(
                        'Skills & Tags',
                        style: AcadexTypography.title(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: a.skills.map((skill) {
                          return Chip(
                            label: Text(skill),
                            backgroundColor: AcadexColors.primary.withValues(alpha: 0.1),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AcadexSpacing.space20),
                      const Divider(),
                      const SizedBox(height: AcadexSpacing.space16),
                    ],

                    // Attached Proof Document
                    Text(
                      'Certificate & Proof Document',
                      style: AcadexTypography.title(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (a.hasFile)
                      Container(
                        padding: const EdgeInsets.all(AcadexSpacing.space16),
                        decoration: BoxDecoration(
                          color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft,
                          borderRadius: BorderRadius.circular(AcadexRadius.md),
                          border: Border.all(
                            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AcadexColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AcadexRadius.sm),
                              ),
                              child: Icon(
                                a.isPdf ? LucideIcons.fileText : LucideIcons.image,
                                color: AcadexColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AcadexSpacing.space16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.fileName ?? 'Proof File',
                                    style: AcadexTypography.bodyMedium(
                                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                    ),
                                  ),
                                  Text(
                                    '${a.fileType?.toUpperCase()} • ${a.fileSizeDisplay}',
                                    style: AcadexTypography.caption(
                                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AcadexButton(
                              label: 'Preview',
                              icon: LucideIcons.externalLink,
                              variant: AcadexButtonVariant.secondary,
                              size: AcadexButtonSize.sm,
                              onPressed: () {
                                _showPreviewDialog(context, a);
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        'No proof file was uploaded for this achievement.',
                        style: AcadexTypography.bodySmall(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),

                    // Verification Timeline
                    if (a.isVerified || a.isRejected || a.isPending) ...[
                      const SizedBox(height: AcadexSpacing.space24),
                      const Divider(),
                      const SizedBox(height: AcadexSpacing.space16),
                      Text(
                        'Institutional Verification Status',
                        style: AcadexTypography.title(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (a.isVerified) ...[
                        _infoRow('Verification Status', 'Verified ✓', isDark),
                        if (a.verifiedBy != null) _infoRow('Verified By', a.verifiedBy!, isDark),
                        if (a.verifiedAt != null)
                          _infoRow('Verified On', a.verifiedAt.toString().substring(0, 16), isDark),
                      ] else if (a.isPending) ...[
                        _infoRow('Verification Status', 'Pending Review by Faculty / HOD', isDark),
                      ] else if (a.isRejected) ...[
                        _infoRow('Verification Status', 'Rejected', isDark),
                        if (a.verifiedBy != null) _infoRow('Reviewed By', a.verifiedBy!, isDark),
                        if (a.verificationNote != null)
                          _infoRow('Feedback Reason', a.verificationNote!, isDark),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: AcadexTypography.bodySmall(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AcadexTypography.bodyMedium(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPreviewDialog(BuildContext context, Achievement a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.lg)),
        title: Text(a.fileName ?? 'Proof Preview'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AcadexColors.canvasSoft,
                  borderRadius: BorderRadius.circular(AcadexRadius.md),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      a.isPdf ? LucideIcons.fileText : LucideIcons.image,
                      size: 48,
                      color: AcadexColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      a.fileName ?? 'Document File',
                      style: AcadexTypography.heading3(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${a.fileType?.toUpperCase()} • ${a.fileSizeDisplay}',
                      style: AcadexTypography.caption(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ReviewAchievementDialog extends ConsumerStatefulWidget {
  final Achievement achievement;
  final VoidCallback onUpdated;

  const _ReviewAchievementDialog({
    required this.achievement,
    required this.onUpdated,
  });

  @override
  ConsumerState<_ReviewAchievementDialog> createState() => _ReviewAchievementDialogState();
}

class _ReviewAchievementDialogState extends ConsumerState<_ReviewAchievementDialog> {
  final _noteController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _updateVerification(AchievementVerificationStatus status) async {
    if (status == AchievementVerificationStatus.rejected && _noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A verification note is mandatory when rejecting.'),
          backgroundColor: AcadexColors.error,
        ),
      );
      return;
    }

    final authState = ref.read(authProvider);
    final reviewerName = authState is AuthAuthenticated ? authState.user.name : 'Reviewer';
    final reviewerUid = authState is AuthAuthenticated ? authState.user.id : 'reviewer';

    setState(() => _isProcessing = true);

    try {
      final repo = ref.read(achievementRepositoryProvider);
      await repo.reviewVerification(
        achievementId: widget.achievement.id,
        reviewerUid: reviewerUid,
        reviewerName: reviewerName,
        status: status,
        verificationNote: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );

      widget.onUpdated();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Achievement verification updated to: ${status.displayName}'),
            backgroundColor: AcadexColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AcadexColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final a = widget.achievement;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.lg)),
      title: Row(
        children: [
          const Icon(LucideIcons.award, color: AcadexColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('Verify: ${a.title}')),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student: ${a.studentName} (${a.studentId})', style: AcadexTypography.bodyMedium()),
              const SizedBox(height: 4),
              Text('Issuer: ${a.issuer}', style: AcadexTypography.bodySmall()),
              const SizedBox(height: 4),
              Text('Date: ${a.achievementDate.day}/${a.achievementDate.month}/${a.achievementDate.year}',
                  style: AcadexTypography.bodySmall()),
              const SizedBox(height: AcadexSpacing.space16),
              const Divider(),
              const SizedBox(height: AcadexSpacing.space8),
              Text(
                'Review Feedback / Rejection Note',
                style: AcadexTypography.title(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter feedback or reason (mandatory for rejection)...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AcadexButton(
          label: 'Reject',
          icon: LucideIcons.xCircle,
          variant: AcadexButtonVariant.secondary,
          size: AcadexButtonSize.sm,
          onPressed: _isProcessing ? null : () => _updateVerification(AchievementVerificationStatus.rejected),
        ),
        AcadexButton(
          label: 'Approve & Verify',
          icon: LucideIcons.checkCircle2,
          variant: AcadexButtonVariant.primary,
          size: AcadexButtonSize.sm,
          onPressed: _isProcessing ? null : () => _updateVerification(AchievementVerificationStatus.verified),
        ),
      ],
    );
  }
}
