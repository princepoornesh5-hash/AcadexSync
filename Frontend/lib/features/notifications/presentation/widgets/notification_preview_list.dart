import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/notification_providers.dart';
import 'notification_card.dart';

class NotificationPreviewList extends ConsumerWidget {
  const NotificationPreviewList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return notificationsAsync.when(
      loading: () => const SizedBox(
        height: 64,
        child: Center(
          child: Text('Loading notifications...', style: TextStyle(fontSize: 13, color: AcadexColors.inkMuted)),
        ),
      ),
      error: (err, stack) => Text('Error loading notifications', style: AcadexTypography.bodySmall(color: AcadexColors.error)),
      data: (notifications) {
        if (notifications.isEmpty) {
          return Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AcadexRadius.borderRadiusLg,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.bell, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('All caught up!', style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('You have no new notifications.', style: AcadexTypography.bodySmall(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final previews = notifications.take(3).toList();

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AcadexRadius.borderRadiusLg,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.bellRing, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Latest Notifications',
                          style: AcadexTypography.title(color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.go('/module/Notifications'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('View All', style: AcadexTypography.button(color: Theme.of(context).primaryColor)),
                    ),
                  ],
                ),
              ),
              Divider(color: Theme.of(context).dividerColor, height: 1),
              ...previews.map((notification) => NotificationCard(
                    notification: notification,
                    onReadToggle: () {
                      ref.read(notificationsProvider.notifier).markAsRead(notification.id);
                    },
                    onDelete: () {
                      ref.read(notificationsProvider.notifier).deleteNotification(notification.id);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }
}
