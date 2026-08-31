import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/notification_providers.dart';

class NotificationBadge extends ConsumerWidget {
  final Color iconColor;
  final double size;

  const NotificationBadge({
    super.key,
    this.iconColor = AcadexColors.inkSecondary,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return IconButton(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      padding: const EdgeInsets.all(8),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(LucideIcons.bell, color: iconColor, size: size),
          if (unreadCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AcadexColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: AcadexTypography.caption(
                      color: Colors.white,
                    ).copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
      tooltip: 'Notifications',
      onPressed: () => context.go('/notifications'),
      splashRadius: 24,
    );
  }
}
