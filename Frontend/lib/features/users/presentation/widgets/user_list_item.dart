import 'package:flutter/material.dart';
import '../../../../core/presentation/design_system/acadex_colors.dart';
import '../../../../core/presentation/design_system/acadex_spacing.dart';
import '../../../../core/presentation/design_system/acadex_typography.dart';
import '../../../../core/presentation/widgets/acadex_avatar.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
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
    final idLabel = user.employeeId ?? user.rollNumber ?? '';

    return AcadexCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AcadexSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AcadexAvatar(
            name: user.name,
            imageUrl: user.profilePictureUrl,
            size: 44,
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
                        color: AcadexColors.textPrimary,
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
                          const Icon(Icons.email_outlined, size: 13, color: AcadexColors.textSecondary),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              user.email,
                              style: AcadexTypography.caption.copyWith(
                                color: AcadexColors.textSecondary,
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
                          const Icon(Icons.badge_outlined, size: 13, color: AcadexColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            idLabel,
                            style: AcadexTypography.caption.copyWith(
                              color: AcadexColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    if (departmentName != null && departmentName!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_tree_outlined, size: 13, color: AcadexColors.textSecondary),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              departmentName!,
                              style: AcadexTypography.caption.copyWith(
                                color: AcadexColors.textSecondary,
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
          const Icon(
            Icons.chevron_right,
            color: AcadexColors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
