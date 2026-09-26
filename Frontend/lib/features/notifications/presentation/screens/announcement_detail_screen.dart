import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/announcement_model.dart';
import '../../domain/models/notification_models.dart';
import '../providers/notification_providers.dart';

class AnnouncementDetailScreen extends ConsumerStatefulWidget {
  final String announcementId;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcementId,
  });

  @override
  ConsumerState<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends ConsumerState<AnnouncementDetailScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final announcementAsync = ref.watch(announcementByIdProvider(widget.announcementId));
    final auth = ref.watch(authProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;

    final isAdmin = user?.role == AppRole.superAdmin ||
        user?.role == AppRole.collegeAdmin ||
        user?.role == AppRole.hod;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Announcement Details', style: AcadexTypography.heading3(color: AcadexColors.ink)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AcadexColors.ink),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/announcements');
            }
          },
        ),
      ),
      body: announcementAsync.when(
        data: (announcement) {
          if (announcement == null) {
            return Center(
              child: Text('Announcement not found', style: AcadexTypography.body(color: AcadexColors.inkSecondary)),
            );
          }
          return _buildContent(context, announcement, isAdmin);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertCircle, size: 48, color: AcadexColors.error),
                const SizedBox(height: 12),
                Text('Failed to load announcement', style: AcadexTypography.heading3(color: AcadexColors.ink)),
                const SizedBox(height: 6),
                Text(
                  err.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: AcadexTypography.body(color: AcadexColors.error),
                ),
                const SizedBox(height: 16),
                AcadexButton(
                  label: 'Retry',
                  icon: LucideIcons.refreshCw,
                  size: AcadexButtonSize.sm,
                  onPressed: () => ref.invalidate(announcementByIdProvider(widget.announcementId)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AnnouncementModel announcement, bool isAdmin) {
    final isDraft = announcement.status == AnnouncementStatus.draft;
    final isPublished = announcement.status == AnnouncementStatus.published;

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

    return AcadexPageContainer(
      maxWidth: AcadexLayout.formMaxWidth,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Container Card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AcadexColors.surface,
                borderRadius: AcadexRadius.borderRadiusLg,
                border: Border.all(color: AcadexColors.hairline),
                boxShadow: AcadexShadows.lightSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Status Badge (if Admin)
                      if (isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: announcement.status == AnnouncementStatus.published
                                ? AcadexColors.success.withOpacity(0.12)
                                : AcadexColors.warning.withOpacity(0.12),
                            borderRadius: AcadexRadius.borderRadiusSm,
                            border: Border.all(
                              color: announcement.status == AnnouncementStatus.published
                                  ? AcadexColors.success.withOpacity(0.3)
                                  : AcadexColors.warning.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            announcement.status.label.toUpperCase(),
                            style: AcadexTypography.caption(
                              color: announcement.status == AnnouncementStatus.published
                                  ? AcadexColors.success
                                  : AcadexColors.warning,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),

                      // Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.12),
                          borderRadius: AcadexRadius.borderRadiusSm,
                        ),
                        child: Text(
                          announcement.category.toUpperCase(),
                          style: AcadexTypography.caption(color: priorityColor).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),

                      // Priority Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AcadexColors.canvas,
                          borderRadius: AcadexRadius.borderRadiusSm,
                          border: Border.all(color: AcadexColors.hairline),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.flag, size: 12, color: priorityColor),
                            const SizedBox(width: 4),
                            Text(
                              announcement.priority.name.toUpperCase(),
                              style: AcadexTypography.caption(color: AcadexColors.ink),
                            ),
                          ],
                        ),
                      ),

                      // Scope Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AcadexColors.canvas,
                          borderRadius: AcadexRadius.borderRadiusSm,
                          border: Border.all(color: AcadexColors.hairline),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.target, size: 12, color: AcadexColors.inkSecondary),
                            const SizedBox(width: 4),
                            Text(
                              announcement.audienceScope.displayName,
                              style: AcadexTypography.caption(color: AcadexColors.inkSecondary),
                            ),
                          ],
                        ),
                      ),

                      // Pinned indicator
                      if (announcement.isPinned)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    announcement.title,
                    style: AcadexTypography.heading2(color: AcadexColors.ink),
                  ),
                  const SizedBox(height: 12),

                  // Meta Info (Author, Date, Expiry)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AcadexColors.canvas,
                      borderRadius: AcadexRadius.borderRadiusMd,
                      border: Border.all(color: AcadexColors.hairline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.calendar, size: 16, color: AcadexColors.inkSecondary),
                            const SizedBox(width: 8),
                            Text(
                              'Published: ${DateFormat('EEEE, d MMMM yyyy, h:mm a').format(announcement.publishedAt ?? announcement.publishAt)}',
                              style: AcadexTypography.bodySmall(color: AcadexColors.inkSecondary),
                            ),
                          ],
                        ),
                        if (announcement.expiresAt != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(LucideIcons.clock, size: 16, color: AcadexColors.warning),
                              const SizedBox(width: 8),
                              Text(
                                'Expires: ${DateFormat('EEEE, d MMMM yyyy, h:mm a').format(announcement.expiresAt!)}',
                                style: AcadexTypography.bodySmall(color: AcadexColors.warning),
                              ),
                            ],
                          ),
                        ],
                        if (isAdmin && announcement.recipientCount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(LucideIcons.users, size: 16, color: AcadexColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Delivered to ${announcement.recipientCount} target recipients',
                                style: AcadexTypography.bodySmall(color: AcadexColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Divider(color: AcadexColors.hairline),
                  const SizedBox(height: 20),

                  // Announcement Body
                  SelectableText(
                    announcement.body,
                    style: AcadexTypography.body(color: AcadexColors.ink).copyWith(
                      height: 1.6,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Admin Action Buttons
                  if (isAdmin) ...[
                    const Divider(color: AcadexColors.hairline),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isDraft) ...[
                          OutlinedButton.icon(
                            icon: const Icon(LucideIcons.trash2, size: 16, color: AcadexColors.error),
                            label: const Text('Delete Draft'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AcadexColors.error,
                              side: const BorderSide(color: AcadexColors.hairline),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onPressed: _isProcessing ? null : () => _delete(announcement),
                          ),
                          const SizedBox(width: 12),
                          AcadexButton(
                            label: 'Publish Now',
                            icon: LucideIcons.send,
                            isLoading: _isProcessing,
                            size: AcadexButtonSize.md,
                            onPressed: _isProcessing ? null : () => _publish(announcement),
                          ),
                        ] else if (isPublished) ...[
                          OutlinedButton.icon(
                            icon: const Icon(LucideIcons.archive, size: 16),
                            label: const Text('Archive Announcement'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AcadexColors.inkSecondary,
                              side: const BorderSide(color: AcadexColors.hairline),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onPressed: _isProcessing ? null : () => _archive(announcement),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publish(AnnouncementModel announcement) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(announcementCreationProvider.notifier).publishAnnouncement(announcement.id);
      ref.invalidate(announcementByIdProvider(announcement.id));
      if (mounted) {
        AcadexSnackBar.showSuccess(
          context,
          'Announcement published successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        AcadexSnackBar.showError(
          context,
          e,
          fallbackMessage: 'Failed to publish announcement',
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _archive(AnnouncementModel announcement) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(announcementCreationProvider.notifier).archiveAnnouncement(announcement.id);
      ref.invalidate(announcementByIdProvider(announcement.id));
      if (mounted) {
        AcadexSnackBar.showSuccess(
          context,
          'Announcement archived successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        AcadexSnackBar.showError(
          context,
          e,
          fallbackMessage: 'Failed to archive announcement',
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _delete(AnnouncementModel announcement) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(announcementCreationProvider.notifier).deleteAnnouncement(announcement.id);
      if (mounted) {
        AcadexSnackBar.showSuccess(
          context,
          'Announcement deleted successfully!',
        );
        context.go('/announcements');
      }
    } catch (e) {
      if (mounted) {
        AcadexSnackBar.showError(
          context,
          e,
          fallbackMessage: 'Failed to delete announcement',
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
