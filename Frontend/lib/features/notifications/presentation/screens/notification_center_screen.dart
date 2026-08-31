import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/notification_models.dart';
import '../providers/notification_providers.dart';
import '../widgets/notification_card.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_adaptive_gradient_text.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final filteredNotifications = ref.watch(filteredNotificationsProvider);
    final authState = ref.watch(authProvider);
    final isGradientRole = authState is AuthAuthenticated &&
        (authState.user.role == AppRole.superAdmin ||
            authState.user.role == AppRole.collegeAdmin ||
            authState.user.role == AppRole.hod ||
            authState.user.role == AppRole.faculty ||
            authState.user.role == AppRole.student);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasEnclosingScaffold = Scaffold.maybeOf(context) != null;

    final bodyList = notificationsAsync.when(
      loading: () => const AcadexLoadingState(message: "Loading notifications..."),
      error: (err, stack) => Center(
        child: AcadexErrorState(
          message: 'Failed to load notifications: $err',
          onRetry: () => ref.refresh(notificationsProvider),
        ),
      ),
      data: (_) {
        if (filteredNotifications.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(notificationsProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: AcadexEmptyState(
                    icon: LucideIcons.bellRing,
                    title: "All caught up!",
                    subtitle: "You don't have any notifications right now.",
                  ),
                ),
              ],
            ),
          );
        }

        final grouped = _groupNotificationsByDate(filteredNotifications);

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(notificationsProvider),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final item = grouped[index];
              if (item is _GroupHeader) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: isGradientRole
                      ? AcadexAdaptiveGradientText(
                          item.title.toUpperCase(),
                          style: AcadexTypography.eyebrow().copyWith(fontWeight: FontWeight.w700),
                        )
                      : Text(
                          item.title.toUpperCase(),
                          style: AcadexTypography.eyebrow(
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ),
                        ),
                );
              } else if (item is _GroupItem) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ClipRRect(
                    borderRadius: AcadexRadius.borderRadiusMd,
                    child: NotificationCard(
                      notification: item.notification,
                      onReadToggle: () {
                        if (item.notification.isRead) {
                          ref.read(notificationsProvider.notifier).markAsUnread(item.notification.id);
                        } else {
                          ref.read(notificationsProvider.notifier).markAsRead(item.notification.id);
                        }
                      },
                      onDelete: () {
                        ref.read(notificationsProvider.notifier).deleteNotification(item.notification.id);
                      },
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );

    final isAdmin = authState is AuthAuthenticated &&
        (authState.user.role == AppRole.superAdmin ||
            authState.user.role == AppRole.collegeAdmin ||
            authState.user.role == AppRole.hod);

    final fab = isAdmin
        ? FloatingActionButton.extended(
            onPressed: () => context.push('/settings/notifications/create'),
            icon: const Icon(LucideIcons.plus),
            label: const Text('New Announcement'),
          )
        : null;

    if (hasEnclosingScaffold) {
      return Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _FilterBar(isDark: isDark, isSuperAdmin: isGradientRole),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                          icon: Icon(
                            LucideIcons.checkCheck,
                            size: 16,
                            color: isGradientRole ? const Color(0xFFCCE6FF) : null,
                          ),
                          label: Text(
                            'Mark all read',
                            style: TextStyle(
                              color: isGradientRole ? Colors.white : null,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            LucideIcons.settings,
                            size: 19,
                            color: isGradientRole ? Colors.white : null,
                          ),
                          tooltip: 'Notification Settings',
                          onPressed: () => context.push('/settings/notifications/preferences'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(child: bodyList),
            ],
          ),
          if (fab != null)
            Positioned(
              bottom: 24,
              right: 24,
              child: fab,
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: isGradientRole ? Colors.transparent : (isDark ? AcadexColors.darkCanvas : AcadexColors.canvas),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isGradientRole ? Colors.white : (isDark ? AcadexColors.darkInk : AcadexColors.ink)),
          onPressed: () => context.safePop(fallbackRoute: '/dashboard'),
        ),
        backgroundColor: isGradientRole ? Colors.transparent : null,
        title: Text(
          'Notification Center',
          style: AcadexTypography.title(
            color: isGradientRole ? Colors.white : (isDark ? AcadexColors.darkInk : AcadexColors.ink),
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
            icon: Icon(
              LucideIcons.checkCheck,
              size: 16,
              color: isGradientRole ? const Color(0xFFCCE6FF) : null,
            ),
            label: Text(
              'Mark all read',
              style: TextStyle(
                color: isGradientRole ? Colors.white : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              LucideIcons.settings,
              size: 20,
              color: isGradientRole ? Colors.white : null,
            ),
            tooltip: 'Notification Settings',
            onPressed: () => context.push('/settings/notifications/preferences'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _FilterBar(isDark: isDark, isSuperAdmin: isGradientRole),
        ),
      ),
      floatingActionButton: fab,
      body: bodyList,
    );
  }

  List<dynamic> _groupNotificationsByDate(List<NotificationModel> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeek = today.subtract(const Duration(days: 7));

    final todayItems = <NotificationModel>[];
    final yesterdayItems = <NotificationModel>[];
    final thisWeekItems = <NotificationModel>[];
    final earlierItems = <NotificationModel>[];

    for (final n in notifications) {
      final nDate = DateTime(n.timestamp.year, n.timestamp.month, n.timestamp.day);
      if (nDate.isAtSameMomentAs(today)) {
        todayItems.add(n);
      } else if (nDate.isAtSameMomentAs(yesterday)) {
        yesterdayItems.add(n);
      } else if (nDate.isAfter(thisWeek)) {
        thisWeekItems.add(n);
      } else {
        earlierItems.add(n);
      }
    }

    final result = <dynamic>[];

    if (todayItems.isNotEmpty) {
      result.add(_GroupHeader('Today'));
      result.addAll(todayItems.map((e) => _GroupItem(e)));
    }
    if (yesterdayItems.isNotEmpty) {
      result.add(_GroupHeader('Yesterday'));
      result.addAll(yesterdayItems.map((e) => _GroupItem(e)));
    }
    if (thisWeekItems.isNotEmpty) {
      result.add(_GroupHeader('Earlier this week'));
      result.addAll(thisWeekItems.map((e) => _GroupItem(e)));
    }
    if (earlierItems.isNotEmpty) {
      result.add(_GroupHeader('Older'));
      result.addAll(earlierItems.map((e) => _GroupItem(e)));
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
  final bool isSuperAdmin;
  const _FilterBar({required this.isDark, this.isSuperAdmin = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(notificationFilterProvider);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSuperAdmin ? const Color.fromRGBO(255, 255, 255, 0.74) : (isDark ? AcadexColors.darkSurface : AcadexColors.surface),
        borderRadius: AcadexRadius.borderRadiusSm,
        border: Border.all(
          color: isSuperAdmin ? const Color.fromRGBO(255, 255, 255, 0.45) : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
