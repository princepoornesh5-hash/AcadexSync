import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/notification_models.dart';
import '../providers/notification_providers.dart';
import '../widgets/notification_card.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final filteredNotifications = ref.watch(filteredNotificationsProvider);
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool canCreateAnnouncement = authState is AuthAuthenticated && 
        (authState.user.role == AppRole.superAdmin || 
         authState.user.role == AppRole.collegeAdmin || 
         authState.user.role == AppRole.hod);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        title: Text(
          'Notification Center',
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              ref.read(notificationsProvider.notifier).markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                  backgroundColor: AcadexColors.success,
                ),
              );
            },
            icon: const Icon(LucideIcons.checkCheck, size: 16),
            label: const Text('Mark all read'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.settings, size: 20),
            tooltip: 'Notification Settings',
            onPressed: () => context.push('/settings/notifications/preferences'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _FilterBar(isDark: isDark),
        ),
      ),
      body: notificationsAsync.when(
        loading: () => const AcadexLoadingState(message: "Loading notifications..."),
        error: (err, stack) => Center(
          child: AcadexErrorState(
            message: 'Failed to load notifications: $err',
            onRetry: () => ref.refresh(notificationsProvider),
          ),
        ),
        data: (_) {
          if (filteredNotifications.isEmpty) {
            return const Center(
              child: AcadexEmptyState(
                icon: LucideIcons.bellRing,
                title: "All caught up!",
                subtitle: "You don't have any notifications right now.",
              ),
            );
          }

          final grouped = _groupNotificationsByTime(filteredNotifications);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final item = grouped[index];
                if (item is _GroupHeader) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                    child: Text(
                      item.title,
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                      ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                  );
                }

                final notification = (item as _GroupItem).notification;
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
                      const SnackBar(content: Text('Notification dismissed')),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: canCreateAnnouncement
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/settings/notifications/create'),
              backgroundColor: AcadexColors.primary,
              icon: const Icon(LucideIcons.megaphone, color: Colors.white, size: 18),
              label: Text(
                'New Announcement',
                style: AcadexTypography.button(color: Colors.white),
              ),
            )
          : null,
    );
  }

  List<dynamic> _groupNotificationsByTime(List<NotificationModel> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <NotificationModel>[];
    final yesterdayItems = <NotificationModel>[];
    final earlierItems = <NotificationModel>[];

    for (final notif in notifications) {
      final notifDate = DateTime(notif.timestamp.year, notif.timestamp.month, notif.timestamp.day);
      if (notifDate.isAtSameMomentAs(today) || notifDate.isAfter(today)) {
        todayItems.add(notif);
      } else if (notifDate.isAtSameMomentAs(yesterday)) {
        yesterdayItems.add(notif);
      } else {
        earlierItems.add(notif);
      }
    }

    final result = <dynamic>[];
    if (todayItems.isNotEmpty) {
      result.add(_GroupHeader('TODAY'));
      result.addAll(todayItems.map((n) => _GroupItem(n)));
    }
    if (yesterdayItems.isNotEmpty) {
      result.add(_GroupHeader('YESTERDAY'));
      result.addAll(yesterdayItems.map((n) => _GroupItem(n)));
    }
    if (earlierItems.isNotEmpty) {
      result.add(_GroupHeader('EARLIER'));
      result.addAll(earlierItems.map((n) => _GroupItem(n)));
    }
    return result;
  }
}

class _GroupHeader {
  final String title;
  _GroupHeader(this.title);
}

class _GroupItem {
  final NotificationModel notification;
  _GroupItem(this.notification);
}

class _FilterBar extends ConsumerWidget {
  final bool isDark;
  const _FilterBar({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(notificationFilterProvider);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          ),
        ),
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
            child: AcadexChip(
              label: label,
              isSelected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(notificationFilterProvider.notifier).state = filter;
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
