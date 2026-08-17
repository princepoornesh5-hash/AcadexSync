import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
      error: (err, stack) => Text('Error loading notifications', style: GoogleFonts.inter(color: DashboardColors.error)),
      data: (notifications) {
        if (notifications.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceDarkElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.hairlineDark),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.bell, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('All caught up!', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onDark)),
                      const SizedBox(height: 4),
                      Text('You have no new notifications.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted)),
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
            color: DashboardColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hairlineDark),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.bellRing, color: AppColors.onDark, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Latest Notifications',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onDark),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.go('/module/Notifications'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('View All', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.hairlineDark, height: 1),
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
