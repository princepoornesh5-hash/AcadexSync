import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_dialogs.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/request_model.dart';
import '../providers/requests_providers.dart';
import '../widgets/request_status_chip.dart';
import '../widgets/response_dialog.dart';

class RequestDetailScreen extends ConsumerWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hr = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hr:$min $ampm';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(requestDetailProvider(requestId));
    final authState = ref.watch(authProvider);

    String currentUserId = '';
    AppRole currentUserRole = AppRole.student;
    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
      currentUserRole = authState.user.role;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AcadexColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Request Details',
          style: AcadexTypography.heading3(color: AcadexColors.ink),
        ),
      ),
      body: requestAsync.when(
        loading: () => const Center(
          child: AcadexLoadingState(message: 'Loading request details...'),
        ),
        error: (err, _) => Center(
          child: AcadexErrorState(
            message: 'Unable to load request: $err',
            onRetry: () => ref.refresh(requestDetailProvider(requestId)),
          ),
        ),
        data: (request) {
          if (request == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.fileX, size: 40, color: AcadexColors.inkMuted),
                  const SizedBox(height: 12),
                  Text(
                    'This request could not be found.',
                    style: AcadexTypography.body(color: AcadexColors.inkSecondary),
                  ),
                ],
              ),
            );
          }

          final isRequester = request.requesterUserId == currentUserId;
          final isAuthorizedResponder = !isRequester &&
              (currentUserRole == AppRole.superAdmin ||
                  currentUserRole == AppRole.collegeAdmin ||
                  currentUserRole == AppRole.hod ||
                  currentUserRole == AppRole.faculty);

          final isOpen = request.status != RequestStatus.closed;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Top Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AcadexColors.canvasSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AcadexColors.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AcadexColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  request.requestType.icon,
                                  color: AcadexColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.requestType.displayName,
                                    style: AcadexTypography.bodySmall().copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AcadexColors.ink,
                                    ),
                                  ),
                                  Text(
                                    'ID: ${request.requestId}',
                                    style: AcadexTypography.caption().copyWith(
                                      color: AcadexColors.inkMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          RequestStatusChip(status: request.status),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AcadexColors.hairline),
                      const SizedBox(height: 12),

                      // Metadata Grid
                      Row(
                        children: [
                          Expanded(
                            child: _MetaItem(
                              label: 'Submitted by',
                              value: '${request.requesterName} (${request.requesterRole.displayName})',
                            ),
                          ),
                          Expanded(
                            child: _MetaItem(
                              label: 'Submitted to',
                              value: request.targetName ?? request.targetRole.displayName,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _MetaItem(
                        label: 'Submitted on',
                        value: _formatDateTime(request.createdAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Academic Context (if present)
                if (request.academicContext != null &&
                    (request.academicContext?.subjectName != null ||
                        request.academicContext?.sectionName != null ||
                        request.academicContext?.courseName != null)) ...[
                  _SectionCard(
                    title: 'Academic Context',
                    icon: LucideIcons.graduationCap,
                    children: [
                      if (request.academicContext?.subjectName != null)
                        _DetailRow(
                          label: 'Subject',
                          value: request.academicContext!.subjectName!,
                        ),
                      if (request.academicContext?.sectionName != null)
                        _DetailRow(
                          label: 'Section',
                          value: request.academicContext!.sectionName!,
                        ),
                      if (request.academicContext?.courseName != null)
                        _DetailRow(
                          label: 'Course / Program',
                          value: request.academicContext!.courseName!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Request Specific Details (Dates, Resource, etc.)
                if (request.details != null &&
                    (request.details?.startDate != null ||
                        request.details?.date != null ||
                        request.details?.resourceName != null ||
                        request.details?.requestedChange != null)) ...[
                  _SectionCard(
                    title: 'Specific Details',
                    icon: LucideIcons.info,
                    children: [
                      if (request.details?.startDate != null && request.details?.endDate != null)
                        _DetailRow(
                          label: 'Date Range',
                          value:
                              '${_formatDate(request.details!.startDate!)} to ${_formatDate(request.details!.endDate!)}',
                        )
                      else if (request.details?.date != null)
                        _DetailRow(
                          label: 'Date',
                          value: _formatDate(request.details!.date!),
                        ),
                      if (request.details?.resourceName != null)
                        _DetailRow(
                          label: 'Resource',
                          value: request.details!.resourceName!,
                        ),
                      if (request.details?.requestedChange != null)
                        _DetailRow(
                          label: 'Requested Change',
                          value: request.details!.requestedChange!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Description / Reason
                _SectionCard(
                  title: 'Description & Reason',
                  icon: LucideIcons.fileText,
                  children: [
                    Text(
                      request.description,
                      style: AcadexTypography.bodySmall().copyWith(
                        color: AcadexColors.ink,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Official Response Section
                _SectionCard(
                  title: 'Official Decision / Response',
                  icon: LucideIcons.checkSquare,
                  children: [
                    if (request.responseMessage != null && request.responseMessage!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: request.status.backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: request.status.color.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(request.status.icon, size: 16, color: request.status.color),
                                const SizedBox(width: 8),
                                Text(
                                  request.status.displayName,
                                  style: AcadexTypography.bodySmall().copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: request.status.color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              request.responseMessage!,
                              style: AcadexTypography.bodySmall().copyWith(
                                color: AcadexColors.ink,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Responded by ${request.respondedByName ?? "Authority"} • ${_formatDateTime(request.respondedAt ?? DateTime.now())}',
                              style: AcadexTypography.caption().copyWith(
                                color: AcadexColors.inkMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const Icon(LucideIcons.clock, size: 16, color: AcadexColors.inkMuted),
                          const SizedBox(width: 8),
                          Text(
                            'Pending response from ${request.targetName ?? request.targetRole.displayName}.',
                            style: AcadexTypography.caption().copyWith(
                              color: AcadexColors.inkSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Audit History
                if (request.history.isNotEmpty) ...[
                  _SectionCard(
                    title: 'Timeline & History',
                    icon: LucideIcons.history,
                    children: [
                      for (int i = 0; i < request.history.length; i++) ...[
                        _TimelineItem(
                          entry: request.history[i],
                          isLast: i == request.history.length - 1,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Action Buttons

                // 1. Authorized Responder Actions
                if (isAuthorizedResponder && isOpen) ...[
                  if (request.status == RequestStatus.submitted ||
                      request.status == RequestStatus.received) ...[
                    AcadexButton(
                      label: 'Mark In Review',
                      icon: LucideIcons.clock,
                      variant: AcadexButtonVariant.secondary,
                      onPressed: () async {
                        await ref.read(requestActionProvider.notifier).updateStatus(
                              id: request.id,
                              status: RequestStatus.inReview,
                              note: 'Under active review by department authority',
                            );
                        ref.invalidate(requestDetailProvider(requestId));
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: AcadexButton(
                          label: 'Approve / Resolve',
                          icon: LucideIcons.checkCircle,
                          onPressed: () async {
                            final changed = await ResponseDialog.show(
                              context,
                              requestId: request.id,
                              initialAction: 'APPROVED',
                            );
                            if (changed == true) {
                              ref.invalidate(requestDetailProvider(requestId));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AcadexButton(
                          label: 'Reject',
                          icon: LucideIcons.xCircle,
                          variant: AcadexButtonVariant.danger,
                          onPressed: () async {
                            final changed = await ResponseDialog.show(
                              context,
                              requestId: request.id,
                              initialAction: 'REJECTED',
                            );
                            if (changed == true) {
                              ref.invalidate(requestDetailProvider(requestId));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // 2. Close / Cancel Button for Requester or Responder
                if (isOpen && (isRequester || isAuthorizedResponder)) ...[
                  AcadexButton(
                    label: isRequester ? 'Cancel Request' : 'Close Request',
                    icon: LucideIcons.archive,
                    variant: AcadexButtonVariant.secondary,
                    onPressed: () async {
                      final confirmed = await AcadexConfirmationDialog.show(
                        context: context,
                        title: isRequester ? 'Cancel Request' : 'Close Request',
                        message: isRequester
                            ? 'Are you sure you want to cancel this request?'
                            : 'Are you sure you want to close this request?',
                        confirmLabel: isRequester ? 'Yes, Cancel' : 'Yes, Close',
                        isDestructive: true,
                      );

                      if (confirmed == true) {
                        final res = await ref.read(requestActionProvider.notifier).updateStatus(
                              id: request.id,
                              status: RequestStatus.closed,
                              note: isRequester ? 'Cancelled by requester' : 'Closed by authority',
                            );
                        if (res != null && context.mounted) {
                          AcadexSnackBar.showSuccess(
                            context,
                            isRequester ? 'Request cancelled.' : 'Request closed.',
                          );
                          ref.invalidate(requestDetailProvider(requestId));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AcadexTypography.caption().copyWith(
            color: AcadexColors.inkMuted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AcadexTypography.bodySmall().copyWith(
            fontWeight: FontWeight.w600,
            color: AcadexColors.ink,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AcadexColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AcadexColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: AcadexTypography.bodySmall().copyWith(
                  fontWeight: FontWeight.w700,
                  color: AcadexColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AcadexColors.hairline),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AcadexTypography.caption().copyWith(
                color: AcadexColors.inkSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AcadexTypography.bodySmall().copyWith(
                fontWeight: FontWeight.w600,
                color: AcadexColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final RequestAuditEntryModel entry;
  final bool isLast;

  const _TimelineItem({required this.entry, required this.isLast});

  String _formatTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hr = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]}, $hr:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: entry.status.color,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: AcadexColors.hairline,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.status.displayName,
                    style: AcadexTypography.caption().copyWith(
                      fontWeight: FontWeight.w700,
                      color: entry.status.color,
                    ),
                  ),
                  Text(
                    _formatTime(entry.timestamp),
                    style: AcadexTypography.caption().copyWith(
                      fontSize: 10,
                      color: AcadexColors.inkMuted,
                    ),
                  ),
                ],
              ),
              if (entry.note != null && entry.note!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 8),
                  child: Text(
                    entry.note!,
                    style: AcadexTypography.caption().copyWith(
                      color: AcadexColors.inkSecondary,
                    ),
                  ),
                )
              else
                const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}
