import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/announcement_model.dart';
import '../../domain/models/notification_models.dart';
import '../providers/notification_providers.dart';

class AnnouncementListScreen extends ConsumerStatefulWidget {
  const AnnouncementListScreen({super.key});

  @override
  ConsumerState<AnnouncementListScreen> createState() => _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends ConsumerState<AnnouncementListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth is! AuthAuthenticated) return const SizedBox.shrink();
    final user = auth.user;

    final isAdmin = user.role == AppRole.superAdmin ||
        user.role == AppRole.collegeAdmin ||
        user.role == AppRole.hod;

    return Scaffold(
      backgroundColor: AcadexColors.canvas,
      body: SafeArea(
        child: AcadexPageContainer(
          maxWidth: AcadexLayout.contentMaxWidth,
          scrollable: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: AcadexColors.ink),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/dashboard');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Announcements',
                            style: AcadexTypography.heading2(color: AcadexColors.ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAdmin
                                ? 'Manage and publish institutional broadcasts'
                                : 'Official announcements and notices for you',
                            style: AcadexTypography.bodySmall(color: AcadexColors.inkSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (isAdmin)
                      AcadexButton(
                        label: 'Create Announcement',
                        icon: LucideIcons.plus,
                        size: AcadexButtonSize.md,
                        onPressed: () => context.push('/announcements/create'),
                      ),
                  ],
                ),
              ),

              // Admin filter tabs
              if (isAdmin)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    color: AcadexColors.surface,
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(color: AcadexColors.hairline),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AcadexColors.primary,
                    indicatorWeight: 2.5,
                    labelColor: AcadexColors.primary,
                    unselectedLabelColor: AcadexColors.inkSecondary,
                    labelStyle: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.bold),
                    unselectedLabelStyle: AcadexTypography.caption(color: AcadexColors.inkSecondary),
                    tabs: const [
                      Tab(text: 'All (Admin)'),
                      Tab(text: 'Published'),
                      Tab(text: 'Drafts'),
                      Tab(text: 'My Feed'),
                    ],
                  ),
                ),

              // Content Area
              Expanded(
                child: isAdmin
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAdminList(null),
                          _buildAdminList(AnnouncementStatus.published),
                          _buildAdminList(AnnouncementStatus.draft),
                          _buildUserFeed(),
                        ],
                      )
                    : _buildUserFeed(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminList(AnnouncementStatus? filterStatus) {
    final announcementsAsync = ref.watch(adminAnnouncementsProvider);

    return announcementsAsync.when(
      data: (announcements) {
        final filtered = filterStatus == null
            ? announcements
            : announcements.where((a) => a.status == filterStatus).toList();

        if (filtered.isEmpty) {
          return _buildEmptyState(
            title: filterStatus == AnnouncementStatus.draft
                ? 'No draft announcements'
                : 'No announcements found',
            subtitle: filterStatus == AnnouncementStatus.draft
                ? 'Drafts will appear here before being broadcast.'
                : 'Create an announcement to broadcast to students and staff.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminAnnouncementsProvider);
            ref.invalidate(announcementsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return _AdminAnnouncementCard(
                announcement: filtered[index],
                onTap: () => context.push('/announcements/${filtered[index].id}'),
                onPublish: () => _confirmPublish(filtered[index]),
                onArchive: () => _confirmArchive(filtered[index]),
                onDelete: () => _confirmDelete(filtered[index]),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _buildErrorState(err.toString(), () => ref.invalidate(adminAnnouncementsProvider)),
    );
  }

  Widget _buildUserFeed() {
    final feedAsync = ref.watch(announcementsProvider);

    return feedAsync.when(
      data: (announcements) {
        if (announcements.isEmpty) {
          return _buildEmptyState(
            title: 'No announcements yet',
            subtitle: 'You are all caught up! Check back later for institutional updates.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(announcementsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              return _UserAnnouncementCard(
                announcement: announcements[index],
                onTap: () => context.push('/announcements/${announcements[index].id}'),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _buildErrorState(err.toString(), () => ref.invalidate(announcementsProvider)),
    );
  }

  Widget _buildEmptyState({required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AcadexColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AcadexColors.hairline),
              ),
              child: const Icon(LucideIcons.megaphone, size: 40, color: AcadexColors.inkSecondary),
            ),
            const SizedBox(height: 16),
            Text(title, style: AcadexTypography.heading3(color: AcadexColors.ink)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AcadexTypography.body(color: AcadexColors.inkSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, size: 40, color: AcadexColors.error),
            const SizedBox(height: 12),
            Text('Failed to load announcements', style: AcadexTypography.heading3(color: AcadexColors.ink)),
            const SizedBox(height: 6),
            Text(
              message.replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: AcadexTypography.bodySmall(color: AcadexColors.error),
            ),
            const SizedBox(height: 16),
            AcadexButton(
              label: 'Retry',
              icon: LucideIcons.refreshCw,
              onPressed: onRetry,
              size: AcadexButtonSize.sm,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPublish(AnnouncementModel announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish Announcement'),
        content: Text('Are you sure you want to publish "${announcement.title}"? This will resolve recipients and send push/in-app notifications immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AcadexColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Publish Now'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(announcementCreationProvider.notifier).publishAnnouncement(announcement.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement published successfully!'), backgroundColor: AcadexColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AcadexColors.error),
          );
        }
      }
    }
  }

  Future<void> _confirmArchive(AnnouncementModel announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Announcement'),
        content: Text('Archive "${announcement.title}"? It will no longer appear on active user feeds.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AcadexColors.warning),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(announcementCreationProvider.notifier).archiveAnnouncement(announcement.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement archived successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AcadexColors.error),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(AnnouncementModel announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Permanently delete draft "${announcement.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AcadexColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(announcementCreationProvider.notifier).deleteAnnouncement(announcement.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AcadexColors.error),
          );
        }
      }
    }
  }
}

class _AdminAnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback onTap;
  final VoidCallback onPublish;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _AdminAnnouncementCard({
    required this.announcement,
    required this.onTap,
    required this.onPublish,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDraft = announcement.status == AnnouncementStatus.draft;
    final isPublished = announcement.status == AnnouncementStatus.published;

    Color statusColor;
    switch (announcement.status) {
      case AnnouncementStatus.published:
        statusColor = AcadexColors.success;
        break;
      case AnnouncementStatus.draft:
        statusColor = AcadexColors.warning;
        break;
      case AnnouncementStatus.archived:
        statusColor = AcadexColors.inkSecondary;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: announcement.isPinned ? AcadexColors.primary.withOpacity(0.5) : AcadexColors.hairline,
          width: announcement.isPinned ? 1.5 : 1.0,
        ),
        boxShadow: AcadexShadows.lightSm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AcadexRadius.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badges Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: AcadexRadius.borderRadiusSm,
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      announcement.status.label.toUpperCase(),
                      style: AcadexTypography.caption(color: statusColor).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AcadexColors.canvas,
                      borderRadius: AcadexRadius.borderRadiusSm,
                      border: Border.all(color: AcadexColors.hairline),
                    ),
                    child: Text(
                      announcement.audienceScope.displayName,
                      style: AcadexTypography.caption(color: AcadexColors.inkSecondary),
                    ),
                  ),
                  if (announcement.isPinned) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AcadexColors.primaryLight,
                        borderRadius: AcadexRadius.borderRadiusSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.pin, size: 12, color: AcadexColors.primary),
                          const SizedBox(width: 4),
                          Text('Pinned', style: AcadexTypography.caption(color: AcadexColors.primary)),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    DateFormat('d MMM, h:mm a').format(announcement.createdAt),
                    style: AcadexTypography.caption(color: AcadexColors.inkSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                announcement.title,
                style: AcadexTypography.heading3(color: AcadexColors.ink),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Body preview
              Text(
                announcement.body,
                style: AcadexTypography.body(color: AcadexColors.inkSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),

              // Actions & Metadata Row
              Row(
                children: [
                  if (announcement.recipientCount > 0) ...[
                    const Icon(LucideIcons.users, size: 14, color: AcadexColors.inkSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${announcement.recipientCount} recipients',
                      style: AcadexTypography.caption(color: AcadexColors.inkSecondary),
                    ),
                  ],
                  const Spacer(),
                  if (isDraft) ...[
                    TextButton.icon(
                      icon: const Icon(LucideIcons.trash2, size: 14, color: AcadexColors.error),
                      label: Text('Delete', style: AcadexTypography.caption(color: AcadexColors.error)),
                      onPressed: onDelete,
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: const Icon(LucideIcons.send, size: 14),
                      label: const Text('Publish'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AcadexColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: onPublish,
                    ),
                  ] else if (isPublished) ...[
                    OutlinedButton.icon(
                      icon: const Icon(LucideIcons.archive, size: 14),
                      label: const Text('Archive'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AcadexColors.inkSecondary,
                        side: const BorderSide(color: AcadexColors.hairline),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: onArchive,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback onTap;

  const _UserAnnouncementCard({
    required this.announcement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color priorityColor;
    switch (announcement.priority) {
      case NotificationPriority.critical:
        priorityColor = AcadexColors.error;
        break;
      case NotificationPriority.high:
        priorityColor = AcadexColors.warning;
        break;
      case NotificationPriority.normal:
        priorityColor = AcadexColors.primary;
        break;
      case NotificationPriority.low:
        priorityColor = AcadexColors.inkSecondary;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: announcement.isPinned ? AcadexColors.primary.withOpacity(0.5) : AcadexColors.hairline,
          width: announcement.isPinned ? 1.5 : 1.0,
        ),
        boxShadow: AcadexShadows.lightSm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AcadexRadius.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top tags
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.12),
                      borderRadius: AcadexRadius.borderRadiusSm,
                    ),
                    child: Text(
                      announcement.category.toUpperCase(),
                      style: AcadexTypography.caption(color: priorityColor).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (announcement.isPinned) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AcadexColors.primaryLight,
                        borderRadius: AcadexRadius.borderRadiusSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.pin, size: 12, color: AcadexColors.primary),
                          const SizedBox(width: 4),
                          Text('Pinned', style: AcadexTypography.caption(color: AcadexColors.primary)),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    DateFormat('d MMM, h:mm a').format(announcement.publishedAt ?? announcement.publishAt),
                    style: AcadexTypography.caption(color: AcadexColors.inkSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                announcement.title,
                style: AcadexTypography.heading3(color: AcadexColors.ink),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Body preview
              Text(
                announcement.body,
                style: AcadexTypography.body(color: AcadexColors.inkSecondary),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),

              // Footer: Scope and View Details link
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AcadexColors.canvas,
                      borderRadius: AcadexRadius.borderRadiusSm,
                      border: Border.all(color: AcadexColors.hairline),
                    ),
                    child: Text(
                      announcement.audienceScope.displayName,
                      style: AcadexTypography.caption(color: AcadexColors.inkSecondary),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        'Read more',
                        style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.arrowRight, size: 14, color: AcadexColors.primary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
