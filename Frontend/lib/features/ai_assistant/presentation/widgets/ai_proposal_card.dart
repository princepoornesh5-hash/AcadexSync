import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../domain/models/ai_message.dart';

class AiProposalCard extends StatelessWidget {
  final AiMessage message;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback? onReconcile;

  const AiProposalCard({
    super.key,
    required this.message,
    required this.onConfirm,
    required this.onCancel,
    this.onReconcile,
  });

  @override
  Widget build(BuildContext context) {
    final proposal = message.proposal;
    if (proposal == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionType = proposal['actionType'] as String? ?? 'PROPOSAL';
    final preview = (proposal['preview'] as Map<String, dynamic>?) ?? {};
    final status = message.actionStatus ?? 'PENDING';
    final isAssignment = actionType == 'CREATE_ASSIGNMENT';

    // Color accents
    final accentColor = isAssignment ? const Color(0xFF0052CC) : const Color(0xFF7C3AED);
    final badgeBg = isAssignment
        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
        : (isDark ? const Color(0xFF2E1065) : const Color(0xFFF5F3FF));

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(status, isDark, accentColor),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isAssignment ? LucideIcons.bookOpen : LucideIcons.calendar,
                  size: 18,
                  color: accentColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAssignment ? 'Assignment Draft Proposal' : 'Calendar Event Proposal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                _buildStatusBadge(status, isDark),
              ],
            ),
          ),

          // Main Preview Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  preview['title'] as String? ?? 'Untitled Action',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),

                // Key metadata grid
                if (isAssignment) ...[
                  _buildMetaRow(
                    context,
                    icon: LucideIcons.graduationCap,
                    label: 'Subject',
                    value: preview['subject'] as String? ?? 'Course Subject',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildMetaRow(
                    context,
                    icon: LucideIcons.users,
                    label: 'Target Section',
                    value: preview['section'] as String? ?? 'Section',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildMetaRow(
                    context,
                    icon: LucideIcons.clock,
                    label: 'Due Date & Time',
                    value: '${preview['dueDate'] ?? 'Upcoming'} at ${preview['dueTime'] ?? '11:59 PM'}',
                    isDark: isDark,
                  ),
                  if (preview['maximumMarks'] != null) ...[
                    const SizedBox(height: 8),
                    _buildMetaRow(
                      context,
                      icon: LucideIcons.award,
                      label: 'Maximum Marks',
                      value: '${preview['maximumMarks']} marks',
                      isDark: isDark,
                    ),
                  ],
                ] else ...[
                  _buildMetaRow(
                    context,
                    icon: LucideIcons.calendar,
                    label: 'Date',
                    value: preview['startDate'] as String? ?? 'Scheduled Date',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildMetaRow(
                    context,
                    icon: LucideIcons.clock,
                    label: 'Time',
                    value: preview['startTime'] != null
                        ? '${preview['startTime']}${preview['endTime'] != null ? ' - ' + preview['endTime'] : ''}'
                        : 'All Day',
                    isDark: isDark,
                  ),
                  if (preview['location'] != null) ...[
                    const SizedBox(height: 8),
                    _buildMetaRow(
                      context,
                      icon: LucideIcons.mapPin,
                      label: 'Location',
                      value: preview['location'] as String,
                      isDark: isDark,
                    ),
                  ],
                  if (preview['eventType'] != null) ...[
                    const SizedBox(height: 8),
                    _buildMetaRow(
                      context,
                      icon: LucideIcons.tag,
                      label: 'Type',
                      value: preview['eventType'] as String,
                      isDark: isDark,
                    ),
                  ],
                ],

                // Conflict warning if any
                if (preview['conflictWarning'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.alertTriangle, size: 16, color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            preview['conflictWarning'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Description
                if (preview['description'] != null &&
                    preview['description'].toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    preview['description'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ],

                // Success execution note
                if (status == 'EXECUTED' && message.executionResultSummary != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.checkCircle2, size: 16, color: Color(0xFF059669)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message.executionResultSummary!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Buttons for PENDING / FAILED / UNCERTAIN
                const SizedBox(height: 16),
                _buildActionButtons(context, status, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case 'EXECUTED':
        bg = const Color(0xFFDEF7EC);
        fg = const Color(0xFF03543F);
        label = 'CONFIRMED';
        icon = LucideIcons.checkCircle2;
        break;
      case 'CONFIRMING':
        bg = const Color(0xFFFEF08A);
        fg = const Color(0xFF713F12);
        label = 'CONFIRMING...';
        icon = LucideIcons.loader2;
        break;
      case 'RECONCILING':
        bg = const Color(0xFFFEF08A);
        fg = const Color(0xFF713F12);
        label = 'RECONCILING...';
        icon = LucideIcons.refreshCw;
        break;
      case 'UNCERTAIN':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        label = 'OUTCOME UNCERTAIN';
        icon = LucideIcons.alertTriangle;
        break;
      case 'EXPIRED':
        bg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
        fg = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        label = 'EXPIRED';
        icon = LucideIcons.clockAlert;
        break;
      case 'CANCELLED':
        bg = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
        fg = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
        label = 'CANCELLED';
        icon = LucideIcons.ban;
        break;
      case 'FAILED':
        bg = const Color(0xFFFDE8E8);
        fg = const Color(0xFF9B1C1C);
        label = 'FAILED';
        icon = LucideIcons.alertCircle;
        break;
      case 'PENDING':
      default:
        bg = const Color(0xFFE1EFFE);
        fg = const Color(0xFF1E429F);
        label = 'AWAITING APPROVAL';
        icon = LucideIcons.clock;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String status, bool isDark) {
    if (status == 'EXECUTED') {
      return Row(
        children: [
          const Icon(LucideIcons.check, size: 16, color: Color(0xFF059669)),
          const SizedBox(width: 6),
          const Text(
            'Official record committed',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF059669),
            ),
          ),
        ],
      );
    }

    if (status == 'CANCELLED') {
      return Row(
        children: [
          Icon(
            LucideIcons.x,
            size: 16,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Text(
            'Proposal was cancelled without changes',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      );
    }

    if (status == 'EXPIRED') {
      return Row(
        children: [
          Icon(
            LucideIcons.clockAlert,
            size: 16,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Text(
            'Proposal expired. Please request a fresh preview.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      );
    }

    if (status == 'CONFIRMING' || status == 'RECONCILING') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              status == 'RECONCILING'
                  ? 'Reconciling persistence state with server...'
                  : 'Persisting to official ACADEX records...',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (status == 'UNCERTAIN') {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              key: const Key('ai_proposal_reconcile_button'),
              onPressed: onReconcile,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Reconcile Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              key: const Key('ai_proposal_cancel_button'),
              onPressed: onCancel,
              icon: const Icon(LucideIcons.x, size: 16),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
                side: BorderSide(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // PENDING or FAILED
    return Row(
      children: [
        // Confirm Button
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            key: const Key('ai_proposal_confirm_button'),
            onPressed: onConfirm,
            icon: const Icon(LucideIcons.check, size: 16),
            label: Text(status == 'FAILED' ? 'Retry Confirm' : 'Confirm & Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052CC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Cancel Button
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            key: const Key('ai_proposal_cancel_button'),
            onPressed: onCancel,
            icon: const Icon(LucideIcons.x, size: 16),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
              side: BorderSide(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getBorderColor(String status, bool isDark, Color defaultAccent) {
    switch (status) {
      case 'EXECUTED':
        return const Color(0xFF10B981);
      case 'FAILED':
        return const Color(0xFFEF4444);
      case 'CANCELLED':
        return isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
      case 'CONFIRMING':
      case 'RECONCILING':
        return const Color(0xFFF59E0B);
      case 'UNCERTAIN':
        return const Color(0xFFD97706);
      case 'EXPIRED':
        return isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);
      case 'PENDING':
      default:
        return isDark ? const Color(0xFF334155) : defaultAccent.withValues(alpha: 0.35);
    }
  }
}
