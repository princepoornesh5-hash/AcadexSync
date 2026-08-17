import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/notification_providers.dart';
import '../widgets/notification_card.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final filteredNotifications = ref.watch(filteredNotificationsProvider);
    final authState = ref.watch(authProvider);

    final bool canCreateAnnouncement = authState is AuthAuthenticated && 
        (authState.user.role == AppRole.superAdmin || 
         authState.user.role == AppRole.collegeAdmin || 
         authState.user.role == AppRole.hod);

    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: DashboardColors.textPrimary,
          ),
        ),
        backgroundColor: DashboardColors.surface,
        elevation: 0,
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: () {
              ref.read(notificationsProvider.notifier).markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
            icon: const Icon(LucideIcons.checkCheck, size: 18),
            label: const Text('Mark all read'),
            style: TextButton.styleFrom(
              foregroundColor: DashboardColors.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
        iconTheme: const IconThemeData(color: DashboardColors.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _FilterBar(),
        ),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, color: DashboardColors.error, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load notifications', style: GoogleFonts.inter(fontSize: 16)),
              TextButton(
                onPressed: () => ref.refresh(notificationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (_) {
          if (filteredNotifications.isEmpty) {
            return _EmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filteredNotifications.length,
            itemBuilder: (context, index) {
              final notification = filteredNotifications[index];
              return NotificationCard(
                notification: notification,
                onReadToggle: () {
                  if (notification.isRead) {
                    ref.read(notificationsProvider.notifier).markAsUnread(notification.id);
                  } else {
                    ref.read(notificationsProvider.notifier).markAsRead(notification.id);
                  }
                },
                onDelete: () {
                  ref.read(notificationsProvider.notifier).deleteNotification(notification.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Notification deleted'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          // Undo functionality not implemented in mock yet
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: canCreateAnnouncement
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/settings/notifications/create'),
              backgroundColor: DashboardColors.primary,
              icon: const Icon(LucideIcons.megaphone, color: Colors.white),
              label: Text('New Announcement', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
            )
          : null,
    );
  }
}

class _FilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(notificationFilterProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: DashboardColors.surface,
        border: Border(bottom: BorderSide(color: DashboardColors.border)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: NotificationFilter.values.map((filter) {
          final isSelected = currentFilter == filter;
          String label = filter.toString().split('.').last;
          label = label[0].toUpperCase() + label.substring(1);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(notificationFilterProvider.notifier).state = filter;
                }
              },
              backgroundColor: DashboardColors.background,
              selectedColor: DashboardColors.primaryLight,
              labelStyle: TextStyle(
                color: isSelected ? DashboardColors.primary : DashboardColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? DashboardColors.primary.withValues(alpha: 0.5) : DashboardColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(notificationFilterProvider);
    
    String title = "All caught up!";
    String message = "You don't have any notifications right now.";
    IconData icon = LucideIcons.bellRing;

    if (currentFilter != NotificationFilter.all) {
      title = "No matches found";
      message = "You don't have any notifications for the selected filter.";
      icon = LucideIcons.filterX;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DashboardColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: DashboardColors.textSecondary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: DashboardColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (currentFilter != NotificationFilter.all)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: TextButton.icon(
                onPressed: () => ref.read(notificationFilterProvider.notifier).state = NotificationFilter.all,
                icon: const Icon(LucideIcons.x),
                label: const Text('Clear Filters'),
              ),
            ),
        ],
      ),
    );
  }
}
