import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/core/presentation/widgets/acadex_feedback.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_request_model.dart';
import 'package:campus_management/features/certificates/presentation/providers/certificate_request_providers.dart';

class CertificateRequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;
  final CertificateRequest? request;

  const CertificateRequestDetailScreen({
    super.key,
    required this.requestId,
    this.request,
  });

  @override
  ConsumerState<CertificateRequestDetailScreen> createState() => _CertificateRequestDetailScreenState();
}

class _CertificateRequestDetailScreenState extends ConsumerState<CertificateRequestDetailScreen> {
  bool _isProcessing = false;

  Color _statusColor(CertificateRequestStatus s) {
    switch (s) {
      case CertificateRequestStatus.pending:
        return AcadexColors.warning;
      case CertificateRequestStatus.underReview:
        return AcadexColors.info;
      case CertificateRequestStatus.approved:
        return AcadexColors.primary;
      case CertificateRequestStatus.rejected:
        return AcadexColors.error;
      case CertificateRequestStatus.ready:
        return AcadexColors.accentPurple;
      case CertificateRequestStatus.completed:
        return AcadexColors.success;
      case CertificateRequestStatus.cancelled:
        return AcadexColors.inkMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }
    final user = authState.user;

    final request = widget.request ?? ref.watch(certificateRequestByIdProvider(widget.requestId));

    if (request == null) {
      return Scaffold(
        backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        appBar: AppBar(
          title: const Text('Request Details'),
          backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
          elevation: 0,
        ),
        body: Center(
          child: AcadexEmptyState(
            icon: LucideIcons.fileQuestion,
            title: 'Request Not Found',
            subtitle: 'The requested certificate request could not be located.',
            actionLabel: 'Return to Requests',
            onActionTap: () => context.pop(),
          ),
        ),
      );
    }

    final canReview = user.role == AppRole.collegeAdmin || user.role == AppRole.hod || user.role == AppRole.superAdmin;
    final statusColor = _statusColor(request.status);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        title: Text(
          'Request Details',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                    borderRadius: BorderRadius.circular(AcadexRadius.lg),
                    border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? statusColor.withValues(alpha: 0.2) : statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AcadexRadius.full),
                              border: Border.all(
                                color: isDark ? statusColor.withValues(alpha: 0.4) : statusColor.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              request.status.displayName,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Request #${request.id.length > 8 ? request.id.substring(0, 8) : request.id}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        request.certificateTypeName,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Student ID: ${request.studentId}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Rejection Reason Alert
                if (request.status == CertificateRequestStatus.rejected && request.rejectionReason != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AcadexColors.error.withValues(alpha: 0.15) : AcadexColors.errorLight,
                      borderRadius: BorderRadius.circular(AcadexRadius.md),
                      border: Border.all(color: AcadexColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.alertCircle, color: AcadexColors.error, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Request Rejected',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AcadexColors.error,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                request.rejectionReason!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Request Information
                _buildSectionTitle('Request Information', isDark),
                const SizedBox(height: 12),
                _buildCard(
                  isDark,
                  children: [
                    _detailRow('Submitted', DateFormat('dd MMMM yyyy, hh:mm a').format(request.requestedAt), LucideIcons.calendar, isDark),
                    _detailRow('Last Updated', timeago.format(request.updatedAt), LucideIcons.clock, isDark),
                    if (request.purpose != null && request.purpose!.isNotEmpty)
                      _detailRow('Purpose', request.purpose!, LucideIcons.target, isDark),
                    if (request.reason != null && request.reason!.isNotEmpty)
                      _detailRow('Reason / Notes', request.reason!, LucideIcons.fileText, isDark),
                    if (request.reviewedBy != null && request.reviewedBy!.isNotEmpty)
                      _detailRow('Reviewed By', request.reviewedBy!, LucideIcons.userCheck, isDark),
                  ],
                ),
                const SizedBox(height: 24),

                // Administrative Review Actions (For College Admin & HOD)
                if (canReview && request.status == CertificateRequestStatus.pending) ...[
                  _buildSectionTitle('Administrative Decision', isDark),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AcadexColors.error,
                            side: const BorderSide(color: AcadexColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                          ),
                          onPressed: _isProcessing ? null : () => _showRejectDialog(context, request),
                          icon: const Icon(LucideIcons.xCircle, size: 16),
                          label: const Text('Reject Request', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AcadexColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                            elevation: 0,
                          ),
                          onPressed: _isProcessing ? null : () => _approveRequest(request),
                          icon: const Icon(LucideIcons.checkCircle2, size: 16),
                          label: const Text('Approve Request', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ] else if (canReview && request.status == CertificateRequestStatus.approved) ...[
                  _buildSectionTitle('Fulfillment', isDark),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AcadexColors.accentPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                            elevation: 0,
                          ),
                          onPressed: _isProcessing
                              ? null
                              : () => _updateStatus(request, CertificateRequestStatus.ready),
                          icon: const Icon(LucideIcons.packageCheck, size: 16),
                          label: const Text('Mark Ready for Pickup', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AcadexColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                            elevation: 0,
                          ),
                          onPressed: _isProcessing
                              ? null
                              : () => _updateStatus(request, CertificateRequestStatus.completed),
                          icon: const Icon(LucideIcons.badgeCheck, size: 16),
                          label: const Text('Mark Issued / Collected', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
      ),
    );
  }

  Widget _buildCard(bool isDark, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: BorderRadius.circular(AcadexRadius.lg),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest(CertificateRequest request) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(certificateRequestManagementProvider.notifier).updateStatus(
            requestId: request.id,
            status: CertificateRequestStatus.approved,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request approved successfully.'),
            backgroundColor: AcadexColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _updateStatus(CertificateRequest request, CertificateRequestStatus status) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(certificateRequestManagementProvider.notifier).updateStatus(
            requestId: request.id,
            status: status,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${status.displayName}.'),
            backgroundColor: AcadexColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showRejectDialog(BuildContext context, CertificateRequest request) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.lg)),
        title: Text('Reject Certificate Request', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please specify the reason for rejecting this certificate request.',
                style: GoogleFonts.inter(fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Rejection Reason *',
                  hintText: 'e.g., Pending fee dues, Incomplete academic prerequisites',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                ),
                maxLines: 3,
                validator: (val) => val == null || val.trim().isEmpty ? 'Rejection reason is required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.error, foregroundColor: Colors.white),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);
      try {
        await ref.read(certificateRequestManagementProvider.notifier).updateStatus(
              requestId: request.id,
              status: CertificateRequestStatus.rejected,
              rejectionReason: reasonController.text.trim(),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request marked as rejected.'),
              backgroundColor: AcadexColors.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }
}
