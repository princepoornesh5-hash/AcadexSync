import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
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
import '../providers/certificate_lookup_providers.dart';

class UploadCertificateScreen extends ConsumerStatefulWidget {
  final Certificate? existing;
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
    setState(() {
      _stage = UploadStage.selecting;
      _fileError = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: CertificateFileConfig.allowedExtensions,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() {
          _stage = UploadStage.idle;
        });
        return;
      }
      final file = result.files.first;
      setState(() {
        _stage = UploadStage.validating;
      });
      await Future.delayed(const Duration(milliseconds: 200));
      final err = validateCertificateFile(
        fileName: file.name,
        fileSizeBytes: file.size,
        mimeType: file.extension != null ? _mimeTypeForExt(file.extension!) : null,
      );
      if (err != null) {
        setState(() {
          _fileError = err;
          _stage = UploadStage.idle;
        });
        return;
      }
      setState(() {
        _selectedFile = file;
        _selectedBytes = file.bytes;
        _stage = UploadStage.idle;
      });
    } catch (e) {
      setState(() {
        _fileError = 'Failed to select file: $e';
        _stage = UploadStage.idle;
      });
    }
  }

  Future<void> _submit(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null && widget.existing == null) {
      setState(() {
        _fileError = 'Please select a certificate document.';
      });
      return;
    }

    setState(() {
      _stage = UploadStage.uploading;
      _errorMsg = null;
    });

    final storageRepo = ref.read(fileStorageRepositoryProvider);
    StoredFileRef? fileRef;

    try {
      if (_selectedBytes != null && _selectedFile != null) {
        setState(() {
          _stage = UploadStage.uploading;
        });
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

      setState(() {
        _stage = UploadStage.saving;
      });
      await Future.delayed(const Duration(milliseconds: 200));

      final certRepo = ref.read(certificateRepositoryProvider);
      final now = DateTime.now();
      final existing = widget.existing;

      final Certificate cert;
      if (existing != null) {
        final oldStoragePath = existing.storagePath;
        cert = existing.copyWith(
          title: _titleCtrl.text.trim(),
          type: _type,
          issuer: _issuerCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          issueDate: _issueDate,
          updatedAt: now,
          updatedBy: user.firebaseUid ?? user.id,
          fileName: fileRef?.name ?? existing.fileName,
          fileType: fileRef?.ext ?? existing.fileType,
          fileSizeBytes: fileRef?.sizeBytes ?? existing.fileSizeBytes,
          storageFileId: fileRef?.fileId ?? existing.storageFileId,
          storagePath: fileRef?.path ?? existing.storagePath,
        );
        await certRepo.updateCertificate(cert);

        // Clean up previous storage file if a new file was uploaded
        if (fileRef != null && oldStoragePath.isNotEmpty && oldStoragePath != fileRef.path) {
          try {
            await storageRepo.deleteFile(oldStoragePath);
          } catch (_) {}
        }
      } else {
        cert = Certificate(
          id: const Uuid().v4(),
          studentId: user.id,
          studentUid: user.firebaseUid ?? user.id,
          studentName: user.name,
          collegeId: user.collegeId,
          departmentId: user.departmentId,
          sectionId: user.sectionId,
          semesterId: user.semesterId,
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

      setState(() {
        _stage = UploadStage.completed;
      });
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existing != null ? 'Certificate updated successfully.' : 'Certificate uploaded successfully.'),
            backgroundColor: AcadexColors.success,
          ),
        );
        context.safePop(fallbackRoute: '/certificates');
      }
    } catch (e) {
      // Rollback newly uploaded storage file if Firestore write failed
      if (fileRef != null && fileRef.path.isNotEmpty) {
        try {
          await storageRepo.deleteFile(fileRef.path);
        } catch (_) {}
      }
      setState(() {
        _stage = UploadStage.failed;
        _errorMsg = e.toString();
      });
    }
  }

  String _mimeTypeForExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  bool get _isLoading =>
      _stage == UploadStage.uploading || _stage == UploadStage.saving || _stage == UploadStage.completed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }
    final user = authState.user;
    final isEdit = widget.existing != null;

    final deptMap = ref.watch(certificateDepartmentMapProvider);
    final courseMap = ref.watch(certificateCourseMapProvider);

    final departmentName = user.departmentId != null ? deptMap[user.departmentId]?.name ?? user.departmentId : 'General';
    final courseName = courseMap.values.firstOrNull?.name ?? 'Academic Program';

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Certificate' : 'Upload Certificate',
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stage Progress Banner
                  if (_isLoading || _stage == UploadStage.failed) ...[
                    _buildProgressBanner(isDark),
                    const SizedBox(height: 24),
                  ],

                  // SECTION 1: Certificate Info
                  _buildSectionHeader('1. Certificate Information', isDark),
                  const SizedBox(height: 14),
                  _buildCard(
                    isDark,
                    children: [
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: _inputDecoration('Certificate Title *', isDark, hintText: 'e.g. AWS Certified Solutions Architect'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<CertificateType>(
                        initialValue: _type,
                        decoration: _inputDecoration('Certificate Category *', isDark),
                        dropdownColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                        items: CertificateType.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t.displayName, style: GoogleFonts.inter()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _type = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _issuerCtrl,
                        decoration: _inputDecoration('Issuing Authority *', isDark, hintText: 'e.g. Amazon Web Services, IEEE, Harvard Online'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Issuer is required' : null,
                      ),
                      const SizedBox(height: 16),
                      // Issue Date Picker
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _issueDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _issueDate = picked);
                        },
                        child: InputDecorator(
                          decoration: _inputDecoration('Issue Date *', isDark),
                          child: Row(
                            children: [
                              Icon(LucideIcons.calendar, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                              const SizedBox(width: 8),
                              Text(DateFormat('dd MMMM yyyy').format(_issueDate), style: GoogleFonts.inter()),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descCtrl,
                        decoration: _inputDecoration('Description / Learnings (Optional)', isDark, hintText: 'Key skills acquired, score/grade achieved, or project details...'),
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // SECTION 2: Academic Context
                  _buildSectionHeader('2. Academic Context', isDark),
                  const SizedBox(height: 14),
                  _buildCard(
                    isDark,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ContextItem(
                              label: 'Department',
                              value: departmentName ?? 'General',
                              icon: LucideIcons.building2,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _ContextItem(
                              label: 'Program',
                              value: courseName,
                              icon: LucideIcons.graduationCap,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ContextItem(
                              label: 'Student Name',
                              value: user.name,
                              icon: LucideIcons.user,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _ContextItem(
                              label: 'Student ID',
                              value: user.id,
                              icon: LucideIcons.hash,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // SECTION 3: Document Upload
                  _buildSectionHeader('3. Document Attachment', isDark),
                  const SizedBox(height: 14),
                  _buildDocumentSection(isDark),
                  const SizedBox(height: 32),

                  // SECTION 4: Submission Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                          ),
                          onPressed: _isLoading ? null : () => context.safePop(fallbackRoute: '/certificates'),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AcadexColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : () => _submit(user),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                )
                              : Text(
                                  isEdit ? 'Save Changes' : 'Upload Certificate',
                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
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

  Widget _buildDocumentSection(bool isDark) {
    final existing = widget.existing;
    final selected = _selectedFile;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: BorderRadius.circular(AcadexRadius.lg),
        border: Border.all(
          color: _fileError != null
              ? AcadexColors.error
              : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
        ),
      ),
      child: Column(
        children: [
          if (selected != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.primary.withValues(alpha: 0.15) : AcadexColors.primaryLight,
                borderRadius: BorderRadius.circular(AcadexRadius.md),
                border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.fileCheck2, color: AcadexColors.primary, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${(selected.size / 1024).toStringAsFixed(1)} KB · Ready to upload',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(LucideIcons.refreshCw, size: 14),
                    label: const Text('Change'),
                  ),
                ],
              ),
            ),
          ] else if (existing != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : AcadexColors.secondaryLight,
                borderRadius: BorderRadius.circular(AcadexRadius.md),
                border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.fileText, color: AcadexColors.primary, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          existing.fileName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${existing.fileSizeDisplay} · Existing file',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcadexColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: _pickFile,
                    icon: const Icon(LucideIcons.upload, size: 14),
                    label: const Text('Replace File'),
                  ),
                ],
              ),
            ),
          ] else ...[
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(AcadexRadius.md),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.02) : AcadexColors.canvasSoft,
                  borderRadius: BorderRadius.circular(AcadexRadius.md),
                  border: Border.all(
                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AcadexColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.uploadCloud, size: 28, color: AcadexColors.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Click to select certificate file',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDF, JPG, PNG, DOC, DOCX up to 10 MB',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_fileError != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(LucideIcons.alertCircle, size: 14, color: AcadexColors.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _fileError!,
                    style: GoogleFonts.inter(fontSize: 12, color: AcadexColors.error, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBanner(bool isDark) {
    String text = 'Processing...';
    Color color = AcadexColors.primary;
    if (_stage == UploadStage.uploading) text = 'Uploading certificate document to secure storage...';
    if (_stage == UploadStage.saving) text = 'Persisting certificate metadata to academic record...';
    if (_stage == UploadStage.completed) text = 'Certificate uploaded successfully!';
    if (_stage == UploadStage.failed) {
      text = _errorMsg ?? 'Upload failed. Please try again.';
      color = AcadexColors.error;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (_isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: color, strokeWidth: 2),
            )
          else
            Icon(
              _stage == UploadStage.completed ? LucideIcons.checkCircle : LucideIcons.alertCircle,
              color: color,
              size: 18,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, bool isDark, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: isDark ? AcadexColors.darkCanvas : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        borderSide: BorderSide(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        borderSide: BorderSide(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _ContextItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _ContextItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkCanvas : AcadexColors.canvasSoft,
        borderRadius: BorderRadius.circular(AcadexRadius.sm),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 10, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StoredFileRef {
  final String fileId;
  final String path;
  final String name;
  final String ext;
  final int sizeBytes;

  StoredFileRef({
    required this.fileId,
    required this.path,
    required this.name,
    required this.ext,
    required this.sizeBytes,
  });
}
