import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../domain/models/official_certificate_models.dart';

/// Status badge for Official Certificate requirements and submissions.
class OfficialCertificateStatusBadge extends StatelessWidget {
  final RequirementSubmissionStatus? calculatedStatus;
  final OfficialCertificateStatus? submissionStatus;

  const OfficialCertificateStatusBadge({
    super.key,
    this.calculatedStatus,
    this.submissionStatus,
  }) : assert(calculatedStatus != null || submissionStatus != null);

  @override
  Widget build(BuildContext context) {
    if (calculatedStatus != null) {
      switch (calculatedStatus!) {
        case RequirementSubmissionStatus.notSubmitted:
          return const AcadexBadge(
            label: 'Not Submitted',
            variant: AcadexBadgeVariant.neutral,
            icon: LucideIcons.circleDashed,
          );
        case RequirementSubmissionStatus.pendingVerification:
          return const AcadexBadge(
            label: 'Pending Verification',
            variant: AcadexBadgeVariant.warning,
            icon: LucideIcons.clock,
          );
        case RequirementSubmissionStatus.verified:
          return const AcadexBadge(
            label: 'Verified',
            variant: AcadexBadgeVariant.success,
            icon: LucideIcons.checkCircle2,
          );
        case RequirementSubmissionStatus.rejected:
          return const AcadexBadge(
            label: 'Rejected',
            variant: AcadexBadgeVariant.danger,
            icon: LucideIcons.xCircle,
          );
        case RequirementSubmissionStatus.resubmissionRequired:
          return const AcadexBadge(
            label: 'Resubmission Required',
            variant: AcadexBadgeVariant.warning,
            icon: LucideIcons.alertTriangle,
          );
        case RequirementSubmissionStatus.archived:
          return const AcadexBadge(
            label: 'Archived',
            variant: AcadexBadgeVariant.neutral,
            icon: LucideIcons.archive,
          );
      }
    }

    switch (submissionStatus!) {
      case OfficialCertificateStatus.pending:
        return const AcadexBadge(
          label: 'Pending',
          variant: AcadexBadgeVariant.warning,
          icon: LucideIcons.clock,
        );
      case OfficialCertificateStatus.verified:
        return const AcadexBadge(
          label: 'Verified',
          variant: AcadexBadgeVariant.success,
          icon: LucideIcons.checkCircle2,
        );
      case OfficialCertificateStatus.rejected:
        return const AcadexBadge(
          label: 'Rejected',
          variant: AcadexBadgeVariant.danger,
          icon: LucideIcons.xCircle,
        );
      case OfficialCertificateStatus.resubmissionRequired:
        return const AcadexBadge(
          label: 'Resubmission Required',
          variant: AcadexBadgeVariant.warning,
          icon: LucideIcons.alertTriangle,
        );
      case OfficialCertificateStatus.archived:
        return const AcadexBadge(
          label: 'Archived',
          variant: AcadexBadgeVariant.neutral,
          icon: LucideIcons.archive,
        );
    }
  }
}

/// Student requirement card.
class OfficialRequirementCard extends StatelessWidget {
  final RequirementWithSubmission item;
  final VoidCallback? onUpload;
  final VoidCallback? onUploadAgain;
  final VoidCallback? onView;

  const OfficialRequirementCard({
    super.key,
    required this.item,
    this.onUpload,
    this.onUploadAgain,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final req = item.requirement;
    final sub = item.submission;
    final status = item.calculatedStatus;

    return AcadexCard(
      padding: const EdgeInsets.all(AcadexSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: req.required
                      ? AcadexColors.primary.withValues(alpha: 0.1)
                      : (isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft),
                  borderRadius: BorderRadius.circular(AcadexRadius.md),
                ),
                child: Icon(
                  req.required ? LucideIcons.fileCheck2 : LucideIcons.fileText,
                  color: req.required ? AcadexColors.primary : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                  size: 22,
                ),
              ),
              const SizedBox(width: AcadexSpacing.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            req.name,
                            style: AcadexTypography.heading3(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                          ),
                        ),
                        OfficialCertificateStatusBadge(calculatedStatus: status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (req.required)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AcadexColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AcadexRadius.xs),
                            ),
                            child: Text(
                              'Required',
                              style: TextStyle(
                                color: AcadexColors.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          )
                        else
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft,
                              borderRadius: BorderRadius.circular(AcadexRadius.xs),
                            ),
                            child: Text(
                              'Optional',
                              style: TextStyle(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        Text(
                          'Scope: ${req.targetScopeDisplay}',
                          style: AcadexTypography.bodySmall(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  Category: ${req.category}',
                          style: AcadexTypography.bodySmall(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (req.description.isNotEmpty) ...[
            const SizedBox(height: AcadexSpacing.space8),
            Text(
              req.description,
              style: AcadexTypography.body(
                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
              ),
            ),
          ],
          if (sub != null && sub.rejectionReason != null && sub.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: AcadexSpacing.space16),
            Container(
              padding: const EdgeInsets.all(AcadexSpacing.space16),
              decoration: BoxDecoration(
                color: status == RequirementSubmissionStatus.resubmissionRequired
                    ? AcadexColors.warning.withValues(alpha: 0.1)
                    : AcadexColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AcadexRadius.sm),
                border: Border.all(
                  color: status == RequirementSubmissionStatus.resubmissionRequired
                      ? AcadexColors.warning.withValues(alpha: 0.3)
                      : AcadexColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    status == RequirementSubmissionStatus.resubmissionRequired
                        ? LucideIcons.alertTriangle
                        : LucideIcons.xCircle,
                    size: 18,
                    color: status == RequirementSubmissionStatus.resubmissionRequired
                        ? AcadexColors.warning
                        : AcadexColors.error,
                  ),
                  const SizedBox(width: AcadexSpacing.space8),
                  Expanded(
                    child: Text(
                      'Feedback: ${sub.rejectionReason}',
                      style: AcadexTypography.bodySmall(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AcadexSpacing.space16),
          const Divider(height: 1),
          const SizedBox(height: AcadexSpacing.space8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (sub != null)
                Row(
                  children: [
                    Icon(
                      LucideIcons.paperclip,
                      size: 14,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${sub.fileName} (${sub.fileSizeDisplay})',
                      style: AcadexTypography.bodySmall(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Accepted: ${req.allowedFileTypes.join(', ').toUpperCase()} (Max 10MB)',
                  style: AcadexTypography.bodySmall(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.canViewDocument)
                    AcadexButton(
                      label: 'View Document',
                      icon: LucideIcons.eye,
                      variant: AcadexButtonVariant.secondary,
                      size: AcadexButtonSize.sm,
                      onPressed: onView,
                    ),
                  if (item.canUpload) ...[
                    const SizedBox(width: 8),
                    AcadexButton(
                      label: 'Upload Document',
                      icon: LucideIcons.upload,
                      variant: AcadexButtonVariant.primary,
                      size: AcadexButtonSize.sm,
                      onPressed: onUpload,
                    ),
                  ],
                  if (item.canUploadAgain) ...[
                    const SizedBox(width: 8),
                    AcadexButton(
                      label: 'Upload Again',
                      icon: LucideIcons.refreshCw,
                      variant: AcadexButtonVariant.primary,
                      size: AcadexButtonSize.sm,
                      onPressed: onUploadAgain,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Metric card for dashboard statistics.
class OfficialCertificateMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const OfficialCertificateMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AcadexCard(
      padding: const EdgeInsets.all(AcadexSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AcadexTypography.caption(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AcadexRadius.sm),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AcadexSpacing.space16),
          Text(
            value,
            style: AcadexTypography.heading1(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AcadexTypography.bodySmall(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
