import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/notifications/presentation/providers/notification_providers.dart';
import '../design_system/acadex_colors.dart';
import '../design_system/acadex_spacing.dart';
import 'app_avatar.dart';
import 'app_badge.dart';

class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AcadexColors.textPrimaryLight,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AcadexColors.textMutedLight,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
          if (currentUser != null) ...[
            AppBadge(
              label: currentUser.role.displayName,
              variant: AppBadgeVariant.primary,
            ),
            const SizedBox(width: AcadexSpacing.md),
          ],
        ],
      ),
      actions: [
        if (actions != null) ...actions!,
        // Notification bell with unread badge
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AcadexColors.textSecondaryLight),
              onPressed: onNotificationTap,
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AcadexColors.coralError,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        if (currentUser != null) ...[
          Padding(
            padding: const EdgeInsets.only(right: 12.0, left: 4.0),
            child: GestureDetector(
              onTap: onProfileTap,
              child: AppAvatar(
                imageUrl: currentUser.profilePictureUrl,
                name: currentUser.name,
                size: 32,
              ),
            ),
          ),
        ],
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1.0),
        child: Divider(height: 1, color: AcadexColors.borderLight),
      ),
    );
  }
}
