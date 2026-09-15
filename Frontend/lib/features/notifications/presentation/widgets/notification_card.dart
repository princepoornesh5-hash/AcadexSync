import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/notification_models.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onReadToggle;
  final VoidCallback onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onReadToggle,
    required this.onDelete,
  });

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return '${time.day}/${time.month}/${time.year}';
  }

  IconData _getIconForCategory(NotificationCategory category) {
    if (category == NotificationCategory.attendance) {
      final titleLower = notification.title.toLowerCase();
      if (titleLower.contains('recovered')) return LucideIcons.circleCheck;
      if (titleLower.contains('drop')) return LucideIcons.trendingDown;
      if (titleLower.contains('absence')) return LucideIcons.userX;
      if (titleLower.contains('unmarked') || titleLower.contains('missing')) return LucideIcons.calendarX;
      if (notification.priority == NotificationPriority.critical) return LucideIcons.shieldAlert;
      return LucideIcons.calendarCheck;
    }

    switch (category) {
      case NotificationCategory.attendance: return LucideIcons.calendarCheck;
      case NotificationCategory.academic: return LucideIcons.bookOpen;
      case NotificationCategory.system: return LucideIcons.settings;
      case NotificationCategory.profile: return LucideIcons.user;
      case NotificationCategory.security: return LucideIcons.shieldAlert;
      case NotificationCategory.notes: return LucideIcons.fileText;
      case NotificationCategory.certificates: return LucideIcons.award;
      case NotificationCategory.timetable: return LucideIcons.calendarDays;
      case NotificationCategory.general: return LucideIcons.bell;
    }
  }

  Color _getColorForPriority(BuildContext context, NotificationPriority priority) {
    if (notification.category == NotificationCategory.attendance &&
        notification.title.toLowerCase().contains('recovered')) {
      return AcadexColors.success;
    }
    switch (priority) {
      case NotificationPriority.critical: return AcadexColors.error;
      case NotificationPriority.high: return AcadexColors.warning;
      case NotificationPriority.normal: return Theme.of(context).primaryColor;
      case NotificationPriority.low: return Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final iconColor = _getColorForPriority(context, notification.priority);
    final bgColor = Theme.of(context).colorScheme.surface;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AcadexColors.error,
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      child: InkWell(
        onTap: () {
          if (isUnread) onReadToggle();
          if (notification.navigationTarget != null) {
            context.push(notification.navigationTarget!);
          }
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForCategory(notification.category),
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AcadexTypography.body(
                              color: isUnread ? AcadexColors.ink : AcadexColors.inkSecondary,
                            ).copyWith(
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _formatRelativeTime(notification.timestamp),
                          style: AcadexTypography.caption(color: AcadexColors.inkMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: AcadexTypography.bodySmall(color: AcadexColors.inkSecondary),
                    ),
                    if (notification.navigationTarget != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Text(
                              'View details',
                              style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.chevronRight, size: 14, color: AcadexColors.primary),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              // Unread Dot
              if (isUnread)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
