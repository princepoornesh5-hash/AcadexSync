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
import '../../domain/models/certificate_type.dart';
import '../providers/certificate_providers.dart';
import '../widgets/certificate_type_badge.dart';
import '../widgets/file_preview_placeholder.dart';

class FacultyCertificateDetailScreen extends ConsumerStatefulWidget {
  final String certificateId;
  const FacultyCertificateDetailScreen({super.key, required this.certificateId});

  @override
  ConsumerState<FacultyCertificateDetailScreen> createState() => _FacultyCertificateDetailScreenState();
}

class _FacultyCertificateDetailScreenState extends ConsumerState<FacultyCertificateDetailScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _titleCtrl;
  late TextEditingController _issuerCtrl;
  late TextEditingController _descCtrl;
  CertificateType? _editType;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _issuerCtrl = TextEditingController();
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _issuerCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _startEdit(Certificate cert) {
    _titleCtrl.text = cert.title;
    _issuerCtrl.text = cert.issuer;
    _descCtrl.text = cert.description ?? '';
    _editType = cert.type;
    setState(() => _isEditing = true);
  }

  Future<void> _saveEdit(Certificate cert, UserModel user) async {
    setState(() => _isSaving = true);
    try {
      final updated = cert.copyWith(
        title: _titleCtrl.text.trim(),
        issuer: _issuerCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        type: _editType,
        updatedAt: DateTime.now(),
        updatedBy: user.firebaseUid ?? user.id,
      );
      await ref.read(certificateRepositoryProvider).updateCertificate(updated);
      ref.invalidate(facultyCertificatesProvider);
      setState(() { _isEditing = false; _isSaving = false; });
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<void> _verify(Certificate cert, UserModel user) async {
    // Security: faculty cannot verify their own student's cert if they are the student
    if (cert.studentUid == (user.firebaseUid ?? user.id)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Students cannot verify their own certificates.')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Verify Certificate'),
        content: Text('Mark "${cert.title}" as verified?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DashboardColors.success),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(certificateRepositoryProvider).verifyCertificate(
        certificateId: cert.id,
        verifierUid: user.firebaseUid ?? user.id,
        verifierName: user.name,
      );
      ref.invalidate(facultyCertificatesProvider);
    }
  }

  Future<void> _archive(Certificate cert, UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Archive Certificate'),
        content: Text('Archive "${cert.title}"? This preserves the record.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DashboardColors.warning),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(certificateRepositoryProvider).updateCertificate(cert.copyWith(
        status: CertificateStatus.archived,
        updatedAt: DateTime.now(),
        updatedBy: user.firebaseUid ?? user.id,
      ));
      ref.invalidate(facultyCertificatesProvider);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return const Scaffold(body: Center(child: Text('Not authenticated')));
    final user = authState.user;

    final certsAsync = ref.watch(facultyCertificatesProvider);
    return certsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (certs) {
        final cert = certs.where((c) => c.id == widget.certificateId).firstOrNull;
        if (cert == null) return const Scaffold(body: Center(child: Text('Certificate not found in your scope')));

        return Scaffold(
          backgroundColor: DashboardColors.background,
          appBar: AppBar(
            title: const Text('Certificate Details'),
            backgroundColor: DashboardColors.surface,
            foregroundColor: DashboardColors.textPrimary,
            elevation: 0,
            actions: [
              if (!_isEditing) ...[
                IconButton(icon: const Icon(LucideIcons.edit3), onPressed: () => _startEdit(cert), tooltip: 'Edit metadata'),
                if (!cert.isVerified)
                  IconButton(icon: const Icon(LucideIcons.badgeCheck, color: DashboardColors.success), onPressed: () => _verify(cert, user), tooltip: 'Verify'),
                IconButton(icon: const Icon(LucideIcons.archive, color: DashboardColors.warning), onPressed: () => _archive(cert, user), tooltip: 'Archive'),
              ],
              if (_isEditing) ...[
                TextButton(onPressed: () => setState(() => _isEditing = false), child: const Text('Cancel')),
                TextButton(onPressed: _isSaving ? null : () => _saveEdit(cert, user), child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Student info (read-only — always)
              _buildStudentCard(cert),
              const SizedBox(height: 16),

              // Certificate info (editable)
              _isEditing ? _buildEditForm(cert) : _buildReadView(cert),
              const SizedBox(height: 16),

              // File preview
              FilePreviewPlaceholder(fileType: cert.fileType, fileName: cert.fileName, fileSize: cert.fileSizeDisplay),
              const SizedBox(height: 16),

              // Verification badge
              if (cert.isVerified && cert.verifiedAt != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: DashboardColors.successLight, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    const Icon(LucideIcons.shieldCheck, color: DashboardColors.success),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Verified Certificate', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: DashboardColors.success)),
                      Text('On ${DateFormat('MMM d, yyyy').format(cert.verifiedAt!)}', style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.success)),
                    ]),
                  ]),
                ),

              // Download (mock)
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
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mock mode — real download requires connected storage provider.')),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildStudentCard(Certificate cert) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: DashboardColors.purpleLight,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      const Icon(LucideIcons.user, color: DashboardColors.purple),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(cert.studentName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: DashboardColors.purple)),
        Text('Student ID: ${cert.studentId}', style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.purple.withValues(alpha: 0.8))),
      ]),
    ]),
  );

  Widget _buildReadView(Certificate cert) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: DashboardColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: DashboardColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CertificateTypeBadge(type: cert.type),
        const Spacer(),
        if (cert.isVerified) const Icon(LucideIcons.badgeCheck, color: DashboardColors.success),
      ]),
      const SizedBox(height: 12),
      Text(cert.title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary)),
      Text(cert.issuer, style: GoogleFonts.inter(fontSize: 13, color: DashboardColors.textSecondary)),
      if (cert.description != null && cert.description!.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(cert.description!, style: GoogleFonts.inter(fontSize: 13, color: DashboardColors.textSecondary)),
      ],
      const SizedBox(height: 12),
      Text('Issued: ${DateFormat('MMMM d, yyyy').format(cert.issueDate)}', style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.textMuted)),
    ]),
  );

  Widget _buildEditForm(Certificate cert) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: DashboardColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: DashboardColors.primary.withValues(alpha: 0.3)),
    ),
    child: Column(children: [
      TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
      const SizedBox(height: 12),
      DropdownButtonFormField<CertificateType>(
        initialValue: _editType,
        decoration: const InputDecoration(labelText: 'Type'),
        items: CertificateType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
        onChanged: (v) => setState(() => _editType = v),
      ),
      const SizedBox(height: 12),
      TextFormField(controller: _issuerCtrl, decoration: const InputDecoration(labelText: 'Issuer')),
      const SizedBox(height: 12),
      TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
      const SizedBox(height: 8),
      Text('Note: Ownership fields (studentId, uploadedBy, etc.) cannot be changed.', style: GoogleFonts.inter(fontSize: 11, color: DashboardColors.textMuted)),
    ]),
  );
}
