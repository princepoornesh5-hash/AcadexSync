import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_request_model.dart';
import 'package:campus_management/features/certificates/presentation/providers/certificate_request_providers.dart';

class CertificateRequestDetailScreen extends ConsumerWidget {
  final CertificateRequest request;

  const CertificateRequestDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final user = authState.user;
    final isAdmin = user.role == AppRole.collegeAdmin || user.role == AppRole.hod || user.role == AppRole.superAdmin;

    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        title: Text('Request Details', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
        backgroundColor: DashboardColors.surface,
        iconTheme: const IconThemeData(color: DashboardColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _buildStatusBadge(request.status),
                const SizedBox(width: 12),
                Text(
                  'ID: ${request.id}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: DashboardColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              request.certificateTypeName,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: DashboardColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Student ID: ${request.studentId}',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: DashboardColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('Request Information'),
            _buildInfoRow('Submitted On', _formatDateTime(request.requestedAt)),
            _buildInfoRow('Last Updated', timeago.format(request.updatedAt)),
            
            if (request.reason != null && request.reason!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoColumn('Reason', request.reason!),
            ],
            
            if (request.purpose != null && request.purpose!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoColumn('Purpose', request.purpose!),
            ],

            const SizedBox(height: 32),

            if (request.status == CertificateRequestStatus.rejected && request.rejectionReason != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DashboardColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DashboardColors.error.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, color: DashboardColors.error, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Rejection Reason',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: DashboardColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      request.rejectionReason!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: DashboardColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            if (request.documentUrl != null && request.documentUrl!.isNotEmpty) ...[
              _buildSectionTitle('Document'),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: DashboardColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DashboardColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(LucideIcons.fileCheck, size: 48, color: DashboardColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Certificate Available',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _openUrl(context, request.documentUrl!),
                      icon: const Icon(LucideIcons.download, size: 18),
                      label: const Text('Download / Open'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DashboardColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            if (request.status == CertificateRequestStatus.completed && request.documentUrl == null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DashboardColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DashboardColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info, color: DashboardColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Certificate file is not available yet.',
                        style: GoogleFonts.inter(color: DashboardColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            if (isAdmin) _buildAdminActions(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: DashboardColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DashboardColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: DashboardColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: DashboardColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DashboardColors.border),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: DashboardColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(CertificateRequestStatus status) {
    Color color;
    switch (status) {
      case CertificateRequestStatus.approved:
      case CertificateRequestStatus.ready:
      case CertificateRequestStatus.completed:
        color = DashboardColors.success;
        break;
      case CertificateRequestStatus.pending:
      case CertificateRequestStatus.underReview:
        color = DashboardColors.warning;
        break;
      case CertificateRequestStatus.rejected:
      case CertificateRequestStatus.cancelled:
        color = DashboardColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.displayName,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openUrl(BuildContext context, String urlString) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Viewing documents is currently disabled in this demo.')));
    }
  }

  Widget _buildAdminActions(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Admin Actions'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (request.status == CertificateRequestStatus.pending || request.status == CertificateRequestStatus.underReview) ...[
              ElevatedButton.icon(
                onPressed: () => _updateStatus(context, ref, CertificateRequestStatus.approved),
                icon: const Icon(LucideIcons.check, size: 18),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(backgroundColor: DashboardColors.success, foregroundColor: Colors.white),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRejectDialog(context, ref),
                icon: const Icon(LucideIcons.x, size: 18),
                label: const Text('Reject'),
                style: ElevatedButton.styleFrom(backgroundColor: DashboardColors.error, foregroundColor: Colors.white),
              ),
            ],
            if (request.status == CertificateRequestStatus.approved) ...[
              ElevatedButton.icon(
                onPressed: () => _updateStatus(context, ref, CertificateRequestStatus.ready),
                icon: const Icon(LucideIcons.fileCheck, size: 18),
                label: const Text('Mark Ready'),
                style: ElevatedButton.styleFrom(backgroundColor: DashboardColors.primary, foregroundColor: Colors.white),
              ),
            ],
            if (request.status == CertificateRequestStatus.ready) ...[
              ElevatedButton.icon(
                onPressed: () => _updateStatus(context, ref, CertificateRequestStatus.completed),
                icon: const Icon(LucideIcons.checkCircle, size: 18),
                label: const Text('Mark Completed'),
                style: ElevatedButton.styleFrom(backgroundColor: DashboardColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, CertificateRequestStatus newStatus, [String? rejectionReason]) async {
    final notifier = ref.read(certificateRequestManagementProvider.notifier);
    await notifier.updateStatus(requestId: request.id, status: newStatus, rejectionReason: rejectionReason);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to ${newStatus.displayName}')));
      context.pop();
    }
  }

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for rejecting this request.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (val) => val == null || val.trim().isEmpty ? 'Reason is required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DashboardColors.error, foregroundColor: Colors.white),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      _updateStatus(context, ref, CertificateRequestStatus.rejected, controller.text.trim());
    }
  }
}
