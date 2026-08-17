import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../features/auth/domain/models/auth_state.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/storage/domain/models/file_category.dart';
import '../../../../features/storage/presentation/providers/storage_providers.dart';
import '../../domain/models/certificate.dart';
import '../../domain/models/certificate_file_config.dart';
import '../../domain/models/certificate_status.dart';
import '../../domain/models/certificate_type.dart';
import '../providers/certificate_providers.dart';

class UploadCertificateScreen extends ConsumerStatefulWidget {
  final Certificate? existing; // non-null = edit mode / replace-file mode
  const UploadCertificateScreen({super.key, this.existing});

  @override
  ConsumerState<UploadCertificateScreen> createState() => _UploadCertificateScreenState();
}

class _UploadCertificateScreenState extends ConsumerState<UploadCertificateScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _issuerCtrl;
  late TextEditingController _descCtrl;
  CertificateType _type = CertificateType.academic;
  DateTime _issueDate = DateTime.now();

  // File selection state
  PlatformFile? _selectedFile;
  Uint8List? _selectedBytes;
  String? _fileError;
  UploadStage _stage = UploadStage.idle;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _issuerCtrl = TextEditingController(text: e?.issuer ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    if (e != null) {
      _type = e.type;
      _issueDate = e.issueDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _issuerCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() { _stage = UploadStage.selecting; _fileError = null; });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: CertificateFileConfig.allowedExtensions,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() { _stage = UploadStage.idle; });
        return;
      }
      final file = result.files.first;
      setState(() { _stage = UploadStage.validating; });
      await Future.delayed(const Duration(milliseconds: 300));
      final err = validateCertificateFile(
        fileName: file.name,
        fileSizeBytes: file.size,
        mimeType: file.extension != null ? 'application/${file.extension}' : null,
      );
      if (err != null) {
        setState(() { _fileError = err; _stage = UploadStage.idle; });
        return;
      }
      setState(() {
        _selectedFile = file;
        _selectedBytes = file.bytes;
        _stage = UploadStage.idle;
      });
    } catch (e) {
      setState(() { _fileError = 'Failed to pick file: $e'; _stage = UploadStage.idle; });
    }
  }

  Future<void> _submit(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null && widget.existing == null) {
      setState(() { _fileError = 'Please select a certificate file.'; });
      return;
    }

    setState(() { _stage = UploadStage.uploading; _errorMsg = null; });

    try {
      StoredFileRef? fileRef;
      if (_selectedBytes != null && _selectedFile != null) {
        setState(() { _stage = UploadStage.uploading; });
        final storageRepo = ref.read(fileStorageRepositoryProvider);
        final storedFile = await storageRepo.uploadFile(
          bytes: _selectedBytes!,
          fileName: _selectedFile!.name,
          contentType: _mimeTypeForExt(_selectedFile!.extension ?? 'pdf'),
          category: FileCategory.certificate,
          ownerUid: user.firebaseUid ?? user.id,
          collegeId: user.collegeId,
          departmentId: user.departmentId,
          studentId: user.id,
        );
        fileRef = StoredFileRef(
          fileId: storedFile.id,
          path: storedFile.storagePath,
          name: _selectedFile!.name,
          ext: _selectedFile!.extension ?? 'pdf',
          sizeBytes: _selectedFile!.size,
        );
      }

      setState(() { _stage = UploadStage.saving; });
      await Future.delayed(const Duration(milliseconds: 200));

      final certRepo = ref.read(certificateRepositoryProvider);
      final now = DateTime.now();
      final existing = widget.existing;

      final Certificate cert;
      if (existing != null) {
        cert = existing.copyWith(
          title: _titleCtrl.text.trim(),
          type: _type,
          issuer: _issuerCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          issueDate: _issueDate,
          updatedAt: now,
          updatedBy: user.firebaseUid ?? user.id,
          // Update file reference only if a new file was selected
          fileName: fileRef?.name ?? existing.fileName,
          fileType: fileRef?.ext ?? existing.fileType,
          fileSizeBytes: fileRef?.sizeBytes ?? existing.fileSizeBytes,
          storageFileId: fileRef?.fileId ?? existing.storageFileId,
          storagePath: fileRef?.path ?? existing.storagePath,
        );
        await certRepo.updateCertificate(cert);
      } else {
        cert = Certificate(
          id: const Uuid().v4(),
          studentId: user.id,
          studentUid: user.firebaseUid ?? user.id,
          studentName: user.name,
          collegeId: user.collegeId,
          departmentId: user.departmentId,
          title: _titleCtrl.text.trim(),
          type: _type,
          issuer: _issuerCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          issueDate: _issueDate,
          fileName: fileRef!.name,
          fileType: fileRef.ext,
          fileSizeBytes: fileRef.sizeBytes,
          storageFileId: fileRef.fileId,
          storagePath: fileRef.path,
          status: CertificateStatus.active,
          uploadedAt: now,
          updatedAt: now,
          uploadedBy: user.firebaseUid ?? user.id,
          isVerified: false,
        );
        await certRepo.createCertificate(cert);
      }

      // Invalidate caches
      ref.invalidate(studentCertificatesProvider);

      setState(() { _stage = UploadStage.completed; });
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() { _stage = UploadStage.failed; _errorMsg = e.toString(); });
    }
  }

  String _mimeTypeForExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default: return 'application/octet-stream';
    }
  }

  bool get _isLoading => _stage == UploadStage.uploading || _stage == UploadStage.saving || _stage == UploadStage.completed;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }
    final user = authState.user;
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Certificate' : 'Upload Certificate'),
        backgroundColor: DashboardColors.surface,
        foregroundColor: DashboardColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator during upload
              if (_isLoading) ...[
                _buildProgressBanner(),
                const SizedBox(height: 16),
              ],

              // Error message
              if (_errorMsg != null) ...[
                _buildErrorBanner(_errorMsg!),
                const SizedBox(height: 16),
              ],

              // Auto-populated identity (read-only)
              _buildReadOnlyCard(user),
              const SizedBox(height: 20),

              // Certificate metadata form
              _buildSectionTitle('Certificate Details'),
              const SizedBox(height: 12),
              _buildFormCard([
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Certificate Title *', prefixIcon: Icon(LucideIcons.award)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CertificateType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Certificate Type *', prefixIcon: Icon(LucideIcons.tag)),
                  items: CertificateType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.displayName),
                  )).toList(),
                  onChanged: _isLoading ? null : (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _issuerCtrl,
                  decoration: const InputDecoration(labelText: 'Issuing Organization *', prefixIcon: Icon(LucideIcons.building)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Issuer is required' : null,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _isLoading ? null : () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _issueDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _issueDate = picked);
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Issue Date *', prefixIcon: Icon(LucideIcons.calendar)),
                      controller: TextEditingController(text: DateFormat('MMMM d, yyyy').format(_issueDate)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Description (optional)', prefixIcon: Icon(LucideIcons.fileText)),
                  maxLines: 3,
                  enabled: !_isLoading,
                ),
              ]),
              const SizedBox(height: 20),

              // File picker
              _buildSectionTitle(isEdit ? 'Replace File (optional)' : 'Certificate File *'),
              const SizedBox(height: 12),
              _buildFilePicker(),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashboardColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : () => _submit(user),
                  child: Text(isEdit ? 'Save Changes' : 'Upload Certificate'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBanner() {
    final labels = {
      UploadStage.uploading: 'Uploading file...',
      UploadStage.saving: 'Saving certificate...',
      UploadStage.completed: '✓ Certificate saved!',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DashboardColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (_stage != UploadStage.completed)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          if (_stage == UploadStage.completed)
            const Icon(LucideIcons.checkCircle, size: 18, color: DashboardColors.success),
          const SizedBox(width: 12),
          Text(labels[_stage] ?? '...', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String msg) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: DashboardColors.errorLight, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(LucideIcons.alertCircle, size: 18, color: DashboardColors.error),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: GoogleFonts.inter(fontSize: 13, color: DashboardColors.error))),
    ]),
  );

  Widget _buildReadOnlyCard(UserModel user) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: DashboardColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: DashboardColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Associated Student', style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.textSecondary)),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(LucideIcons.user, size: 16, color: DashboardColors.primary),
          const SizedBox(width: 8),
          Text(user.name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(LucideIcons.mail, size: 14, color: DashboardColors.textSecondary),
          const SizedBox(width: 8),
          Text(user.email, style: GoogleFonts.inter(fontSize: 13, color: DashboardColors.textSecondary)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(LucideIcons.lock, size: 14, color: DashboardColors.textSecondary),
          const SizedBox(width: 8),
          Text('Identity auto-populated from your account', style: GoogleFonts.inter(fontSize: 11, color: DashboardColors.textMuted)),
        ]),
      ],
    ),
  );

  Widget _buildSectionTitle(String title) => Text(title,
    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary));

  Widget _buildFormCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: DashboardColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: DashboardColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _buildFilePicker() {
    final hasFile = _selectedFile != null;
    final existingFile = widget.existing;
    return Column(
      children: [
        GestureDetector(
          onTap: _isLoading ? null : _pickFile,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DashboardColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _fileError != null ? DashboardColors.error : DashboardColors.border,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  hasFile ? LucideIcons.fileCheck : LucideIcons.upload,
                  size: 36,
                  color: hasFile ? DashboardColors.success : DashboardColors.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  hasFile
                    ? _selectedFile!.name
                    : (existingFile != null ? 'Tap to replace file' : 'Tap to select file'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasFile ? DashboardColors.success : DashboardColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (hasFile) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB · ${_selectedFile!.extension?.toUpperCase()}',
                    style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'PDF, JPG, PNG, DOC, DOCX · Max 10MB',
                  style: GoogleFonts.inter(fontSize: 11, color: DashboardColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        if (_fileError != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(LucideIcons.alertCircle, size: 14, color: DashboardColors.error),
            const SizedBox(width: 6),
            Text(_fileError!, style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.error)),
          ]),
        ],
      ],
    );
  }
}

class StoredFileRef {
  final String fileId;
  final String path;
  final String name;
  final String ext;
  final int sizeBytes;
  StoredFileRef({required this.fileId, required this.path, required this.name, required this.ext, required this.sizeBytes});
}
