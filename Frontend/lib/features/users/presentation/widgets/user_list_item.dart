import 'package:flutter/material.dart';
import '../../../../core/presentation/design_system/acadex_colors.dart';
import '../../../../core/presentation/design_system/acadex_spacing.dart';
import '../../../../core/presentation/design_system/acadex_typography.dart';
import '../../../../core/presentation/widgets/app_avatar.dart';
import '../../../../core/presentation/widgets/app_card.dart';
import '../../domain/models/user_profile_model.dart';
import 'user_role_badge.dart';
import 'user_status_badge.dart';

class UserListItem extends StatelessWidget {
  final UserProfileModel user;
  final String? departmentName;
  final String? collegeName;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStatus;

  const UserListItem({
    super.key,
    required this.user,
    this.departmentName,
    this.collegeName,
    this.onTap,
    this.onEdit,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final idLabel = user.employeeId ?? user.rollNumber ?? '';

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AcadexSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppAvatar(
            name: user.name,
            imageUrl: user.profilePictureUrl,
            size: 48,
          ),
          const SizedBox(width: AcadexSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: AcadexSpacing.xs,
                  runSpacing: AcadexSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      user.name,
                      style: AcadexTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AcadexColors.darkTextPrimary : AcadexColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    UserRoleBadge(role: user.role),
                    UserStatusBadge(status: user.accountStatus),
                  ],
                ),
                const SizedBox(height: AcadexSpacing.xxs),
                Wrap(
                  spacing: AcadexSpacing.sm,
                  runSpacing: AcadexSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (user.email.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.email_outlined, size: 13, color: isDark ? AcadexColors.darkTextSecondary : AcadexColors.textSecondary),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              user.email,
                              style: AcadexTypography.caption.copyWith(
                                color: isDark ? AcadexColors.darkTextSecondary : AcadexColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    if (idLabel.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.badge_outlined, size: 13, color: isDark ? AcadexColors.darkTextSecondary : AcadexColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            idLabel,
                            style: AcadexTypography.caption.copyWith(
                              color: isDark ? AcadexColors.darkTextSecondary : AcadexColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    if (departmentName != null && departmentName!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_tree_outlined, size: 13, color: isDark ? AcadexColors.darkTextSecondary : AcadexColors.textSecondary),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              departmentName!,
                              style: AcadexTypography.caption.copyWith(
                                color: isDark ? AcadexColors.darkTextSecondary : AcadexColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AcadexSpacing.sm),
          Icon(
            Icons.chevron_right,
            color: isDark ? AcadexColors.darkTextSecondary : AcadexColors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
