import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../features/auth/domain/models/auth_state.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/models/certificate.dart';
import '../../domain/models/certificate_status.dart';
import '../providers/certificate_providers.dart';
import '../widgets/certificate_type_badge.dart';
import '../widgets/file_preview_placeholder.dart';
import 'upload_certificate_screen.dart';

class CertificateDetailScreen extends ConsumerWidget {
  final String certificateId;
  const CertificateDetailScreen({super.key, required this.certificateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final certsAsync = ref.watch(studentCertificatesProvider);

    return certsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (certs) {
        final cert = certs.where((c) => c.id == certificateId).firstOrNull;
        if (cert == null) {
          return const Scaffold(body: Center(child: Text('Certificate not found')));
        }
        final user = authState is AuthAuthenticated ? authState.user : null;
        final isOwner = user != null && cert.studentUid == (user.firebaseUid ?? user.id);

        return Scaffold(
          backgroundColor: DashboardColors.background,
          appBar: AppBar(
            title: const Text('Certificate Details'),
            backgroundColor: DashboardColors.surface,
            foregroundColor: DashboardColors.textPrimary,
            elevation: 0,
            actions: [
              if (isOwner) ...[
                IconButton(
                  icon: const Icon(LucideIcons.edit3),
                  onPressed: () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => UploadCertificateScreen(existing: cert)),
                    );
                    if (updated == true) ref.invalidate(studentCertificatesProvider);
                  },
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: DashboardColors.error),
                  onPressed: () => _confirmDelete(context, ref, cert, user),
                ),
              ],
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: DashboardColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DashboardColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CertificateTypeBadge(type: cert.type),
                          const Spacer(),
                          if (cert.isVerified)
                            Row(children: [
                              const Icon(LucideIcons.badgeCheck, size: 16, color: DashboardColors.success),
                              const SizedBox(width: 4),
                              Text('Verified', style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.success, fontWeight: FontWeight.w600)),
                            ]),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(cert.title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary)),
                      const SizedBox(height: 6),
                      Text(cert.issuer, style: GoogleFonts.inter(fontSize: 14, color: DashboardColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // File Preview
                FilePreviewPlaceholder(
                  fileType: cert.fileType,
                  fileName: cert.fileName,
                  fileSize: cert.fileSizeDisplay,
                ),
                const SizedBox(height: 16),

                // Metadata
                _buildInfoCard([
                  _infoRow('Issue Date', DateFormat('MMMM d, yyyy').format(cert.issueDate), LucideIcons.calendar),
                  _infoRow('Status', cert.status.displayName, LucideIcons.activity),
                  if (cert.description != null && cert.description!.isNotEmpty)
                    _infoRow('Description', cert.description!, LucideIcons.fileText),
                  _infoRow('Uploaded', DateFormat('MMM d, yyyy').format(cert.uploadedAt), LucideIcons.upload),
                  _infoRow('File Type', cert.fileType.toUpperCase(), LucideIcons.file),
                  _infoRow('File Size', cert.fileSizeDisplay, LucideIcons.hardDrive),
                ]),
                const SizedBox(height: 16),

                // Verification info
                if (cert.isVerified && cert.verifiedAt != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DashboardColors.successLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      const Icon(LucideIcons.shieldCheck, color: DashboardColors.success),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Verified Certificate', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: DashboardColors.success)),
                        Text('On ${DateFormat('MMM d, yyyy').format(cert.verifiedAt!)}', style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.success)),
                      ]),
                    ]),
                  ),

                // Download action (mock)
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DashboardColors.primary,
                      side: const BorderSide(color: DashboardColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(LucideIcons.download),
                    label: const Text('Download / Open File'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Download: Mock mode — real download requires a connected storage provider.')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(List<Widget> rows) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: DashboardColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: DashboardColors.border),
    ),
    child: Column(children: rows),
  );

  Widget _infoRow(String label, String value, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: DashboardColors.textSecondary),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: DashboardColors.textMuted)),
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: DashboardColors.textPrimary)),
      ])),
    ]),
  );

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Certificate cert, UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Certificate'),
        content: Text('Remove "${cert.title}"? This can be recovered by an admin.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DashboardColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(certificateRepositoryProvider).deleteCertificate(cert.id, user.firebaseUid ?? user.id);
      ref.invalidate(studentCertificatesProvider);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}
