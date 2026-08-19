import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../domain/models/achievement_models.dart';

/// Status badge for achievement verification.
class AchievementStatusBadge extends StatelessWidget {
  final AchievementVerificationStatus status;

  const AchievementStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case AchievementVerificationStatus.verified:
        return const AcadexBadge(
          label: 'Verified',
          variant: AcadexBadgeVariant.success,
          icon: LucideIcons.checkCircle2,
        );
      case AchievementVerificationStatus.pending:
        return const AcadexBadge(
          label: 'Pending Verification',
          variant: AcadexBadgeVariant.warning,
          icon: LucideIcons.clock,
        );
      case AchievementVerificationStatus.rejected:
        return const AcadexBadge(
          label: 'Rejected',
          variant: AcadexBadgeVariant.danger,
          icon: LucideIcons.xCircle,
        );
      case AchievementVerificationStatus.unverified:
        return const AcadexBadge(
          label: 'Unverified',
          variant: AcadexBadgeVariant.neutral,
          icon: LucideIcons.circle,
        );
    }
  }
}

/// Category badge with category icon.
class AchievementCategoryBadge extends StatelessWidget {
  final AchievementCategory category;

  const AchievementCategoryBadge({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft,
        borderRadius: BorderRadius.circular(AcadexRadius.xs),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            category.icon,
            size: 13,
            color: AcadexColors.primary,
          ),
          const SizedBox(width: 5),
          Text(
            category.displayName.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium Card representation of an Achievement.
class AchievementCard extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showReviewAction;
  final VoidCallback? onReview;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onView,
    this.onEdit,
    this.onDelete,
    this.showReviewAction = false,
    this.onReview,
  });

  @override
  State<AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<AchievementCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final a = widget.achievement;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        child: AcadexCard(
          padding: const EdgeInsets.all(AcadexSpacing.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category Badge + Verification Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AchievementCategoryBadge(category: a.category),
                  AchievementStatusBadge(status: a.verificationStatus),
                ],
              ),
              const SizedBox(height: AcadexSpacing.space16),

              // Title
              Text(
                a.title,
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Issuer / Organization
              Row(
                children: [
                  Icon(
                    LucideIcons.building,
                    size: 14,
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      a.issuer,
                      style: AcadexTypography.bodyMedium(
                        color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Date
              Row(
                children: [
                  Icon(
                    LucideIcons.calendar,
                    size: 14,
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${a.achievementDate.day} ${_monthName(a.achievementDate.month)} ${a.achievementDate.year}',
                    style: AcadexTypography.bodySmall(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),
                ],
              ),

              // Skills / Tags
              if (a.skills.isNotEmpty) ...[
                const SizedBox(height: AcadexSpacing.space12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: a.skills.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AcadexColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AcadexRadius.xs),
                      ),
                      child: Text(
                        skill,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AcadexColors.primaryMuted : AcadexColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Rejection Note Alert if Rejected
              if (a.isRejected && a.verificationNote != null && a.verificationNote!.isNotEmpty) ...[
                const SizedBox(height: AcadexSpacing.space12),
                Container(
                  padding: const EdgeInsets.all(AcadexSpacing.space12),
                  decoration: BoxDecoration(
                    color: AcadexColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AcadexRadius.sm),
                    border: Border.all(color: AcadexColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: AcadexColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: ${a.verificationNote}',
                          style: AcadexTypography.bodySmall(color: AcadexColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AcadexSpacing.space16),
              const Divider(height: 1),
              const SizedBox(height: AcadexSpacing.space12),

              // Footer: File Attachment Indicator + Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (a.hasFile)
                    Row(
                      children: [
                        Icon(
                          a.isPdf ? LucideIcons.fileText : LucideIcons.image,
                          size: 16,
                          color: AcadexColors.primary,
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: Text(
                            a.fileName ?? 'Proof Document',
                            style: AcadexTypography.caption(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${a.fileSizeDisplay})',
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'No proof attached',
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.showReviewAction && widget.onReview != null) ...[
                        AcadexButton(
                          label: 'Review',
                          icon: LucideIcons.eye,
                          variant: AcadexButtonVariant.primary,
                          size: AcadexButtonSize.sm,
                          onPressed: widget.onReview,
                        ),
                      ] else ...[
                        AcadexButton(
                          label: 'View',
                          icon: LucideIcons.eye,
                          variant: AcadexButtonVariant.secondary,
                          size: AcadexButtonSize.sm,
                          onPressed: widget.onView,
                        ),
                        if (widget.onEdit != null) ...[
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(LucideIcons.pencil, size: 16),
                            tooltip: 'Edit',
                            onPressed: widget.onEdit,
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

/// Statistic Card for summary metrics.
class AchievementMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const AchievementMetricCard({
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
