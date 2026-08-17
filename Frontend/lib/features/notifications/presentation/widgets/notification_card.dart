import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

  Color _getColorForPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.critical: return DashboardColors.error;
      case NotificationPriority.high: return DashboardColors.warning;
      case NotificationPriority.normal: return DashboardColors.primary;
      case NotificationPriority.low: return DashboardColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final iconColor = _getColorForPriority(notification.priority);
    final bgColor = isUnread ? DashboardColors.surface : DashboardColors.surface;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: DashboardColors.error,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(bottom: BorderSide(color: AppColors.hairlineDark)),
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
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                              color: isUnread ? AppColors.onDark : AppColors.textMuted,
                            ),
                          ),
                        ),
                        Text(
                          _formatRelativeTime(notification.timestamp),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    if (notification.navigationTarget != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Text(
                              'View details',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.primary),
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
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
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
