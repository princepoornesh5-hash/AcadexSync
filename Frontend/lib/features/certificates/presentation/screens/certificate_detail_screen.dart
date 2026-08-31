import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../features/auth/domain/models/auth_state.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../storage/presentation/providers/storage_providers.dart';
import '../../domain/models/certificate.dart';
import '../../domain/models/certificate_status.dart';
import '../providers/certificate_providers.dart';
import '../widgets/certificate_type_badge.dart';
import '../widgets/file_preview_placeholder.dart';

final certificateByIdProvider = FutureProvider.family<Certificate?, String>((ref, certificateId) async {
  final repo = ref.watch(certificateRepositoryProvider);
  return repo.getCertificate(certificateId);
});

class CertificateDetailScreen extends ConsumerStatefulWidget {
  final String certificateId;
  const CertificateDetailScreen({super.key, required this.certificateId});

  @override
  ConsumerState<CertificateDetailScreen> createState() => _CertificateDetailScreenState();
}

class _CertificateDetailScreenState extends ConsumerState<CertificateDetailScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final certAsync = ref.watch(certificateByIdProvider(widget.certificateId));

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }
    final user = authState.user;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        title: Text(
          'Certificate Details',
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
          onPressed: () => context.safePop(fallbackRoute: '/certificates'),
        ),
      ),
      body: certAsync.when(
        loading: () => const Center(
          child: AcadexLoadingState(message: 'Loading certificate details...'),
        ),
        error: (e, _) => Center(
          child: AcadexErrorState(
            title: 'Failed to load certificate',
            message: e.toString(),
            onRetry: () => ref.invalidate(certificateByIdProvider(widget.certificateId)),
          ),
        ),
        data: (cert) {
          if (cert == null) {
            return Center(
              child: AcadexEmptyState(
                icon: LucideIcons.fileX,
                title: 'Certificate Not Found',
                subtitle: 'The requested certificate record could not be located or has been deleted.',
                actionLabel: 'Return',
                onActionTap: () => context.safePop(fallbackRoute: '/certificates'),
              ),
            );
          }

          final isOwner = cert.studentUid == (user.firebaseUid ?? user.id);
          final canVerify = (user.role == AppRole.faculty ||
                  user.role == AppRole.hod ||
                  user.role == AppRole.collegeAdmin ||
                  user.role == AppRole.superAdmin) &&
              !isOwner;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card
                    _buildHeaderCard(cert, isDark, isOwner, canVerify, user),
                    const SizedBox(height: 20),

                    // Verification Banner
                    if (cert.isVerified)
                      _buildVerifiedBanner(cert, isDark)
                    else if (canVerify)
                      _buildVerificationActionCard(cert, user, isDark),
                    const SizedBox(height: 20),

                    // Document Preview Card
                    FilePreviewPlaceholder(
                      fileType: cert.fileType,
                      fileName: cert.fileName,
                      fileSize: cert.fileSizeDisplay,
                    ),
                    const SizedBox(height: 20),

                    // Metadata Details Card
                    _buildMetadataCard(cert, isDark),
                    const SizedBox(height: 24),

                    // Download / Open file action
                    _buildFileActions(cert, isDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(Certificate cert, bool isDark, bool isOwner, bool canVerify, UserModel user) {
    return Container(
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
              CertificateTypeBadge(type: cert.type),
              const Spacer(),
              if (isOwner) ...[
                IconButton(
                  icon: const Icon(LucideIcons.pencil, size: 18),
                  tooltip: 'Edit Certificate',
                  onPressed: () => context.go('/certificates/edit/${cert.id}', extra: cert),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 18, color: AcadexColors.error),
                  tooltip: 'Remove',
                  onPressed: () => _confirmDelete(context, ref, cert, user),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            cert.title,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(LucideIcons.building, size: 15, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  cert.issuer,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (cert.studentName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(LucideIcons.user, size: 15, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                const SizedBox(width: 6),
                Text(
                  'Submitted by ${cert.studentName} (${cert.studentId})',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerifiedBanner(Certificate cert, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.success.withValues(alpha: 0.15) : AcadexColors.successLight,
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        border: Border.all(
          color: isDark ? AcadexColors.success.withValues(alpha: 0.35) : AcadexColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AcadexColors.success.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.shieldCheck, color: AcadexColors.success, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verified Institutional Credential',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? AcadexColors.success : AcadexColors.successDark,
                  ),
                ),
                if (cert.verifiedAt != null)
                  Text(
                    'Verified on ${DateFormat('dd MMMM yyyy').format(cert.verifiedAt!)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? AcadexColors.success.withValues(alpha: 0.8) : AcadexColors.successDark,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationActionCard(Certificate cert, UserModel user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Faculty Review',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
                Text(
                  'Verify this credential after checking document authenticity.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.success,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
            ),
            onPressed: _isProcessing ? null : () => _verifyCertificate(cert, user),
            icon: const Icon(LucideIcons.badgeCheck, size: 16),
            label: _isProcessing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Verify Credential'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard(Certificate cert, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: BorderRadius.circular(AcadexRadius.lg),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Credential Information',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          _detailRow('Issue Date', DateFormat('dd MMMM yyyy').format(cert.issueDate), LucideIcons.calendar, isDark),
          _detailRow('Status', cert.isVerified ? 'Verified' : cert.status.displayName, LucideIcons.activity, isDark),
          if (cert.description != null && cert.description!.isNotEmpty)
            _detailRow('Description', cert.description!, LucideIcons.fileText, isDark),
          _detailRow('Upload Timestamp', DateFormat('dd MMM yyyy, hh:mm a').format(cert.uploadedAt), LucideIcons.clock, isDark),
          _detailRow('File Format', cert.fileType.toUpperCase(), LucideIcons.file, isDark),
          _detailRow('File Size', cert.fileSizeDisplay, LucideIcons.hardDrive, isDark),
        ],
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
            width: 130,
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

  Widget _buildFileActions(Certificate cert, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
              elevation: 0,
            ),
            onPressed: () => _openFile(cert),
            icon: const Icon(LucideIcons.externalLink, size: 16),
            label: Text('Open / Download Document (${cert.fileSizeDisplay})', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Future<void> _openFile(Certificate cert) async {
    if (cert.storagePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No storage file attached.')),
      );
      return;
    }
    try {
      final storageRepo = ref.read(fileStorageRepositoryProvider);
      final downloadUrl = await storageRepo.getDownloadUrl(cert.storagePath);
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open download link.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
    }
  }

  Future<void> _verifyCertificate(Certificate cert, UserModel user) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(certificateRepositoryProvider).verifyCertificate(
            certificateId: cert.id,
            verifierUid: user.firebaseUid ?? user.id,
            verifierName: user.name,
          );
      ref.invalidate(certificateByIdProvider(widget.certificateId));
      ref.invalidate(facultyCertificatesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate successfully verified.'),
            backgroundColor: AcadexColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Certificate cert, UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Certificate'),
        content: Text('Remove "${cert.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(certificateRepositoryProvider).deleteCertificate(cert.id, user.firebaseUid ?? user.id);
      if (mounted) context.safePop(fallbackRoute: '/certificates');
    }
  }
}
