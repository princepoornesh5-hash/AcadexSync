import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/official_certificate_models.dart';
import '../providers/official_certificate_providers.dart';

class OfficialCertificateUploadScreen extends ConsumerStatefulWidget {
  final String requirementId;
  final OfficialCertificateRequirement? requirement;

  const OfficialCertificateUploadScreen({
    super.key,
    required this.requirementId,
    this.requirement,
  });

  @override
  ConsumerState<OfficialCertificateUploadScreen> createState() => _OfficialCertificateUploadScreenState();
}

class _OfficialCertificateUploadScreenState extends ConsumerState<OfficialCertificateUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();

  PlatformFile? _selectedFile;
  Uint8List? _fileBytes;
  bool _isSubmitting = false;
  String? _errorMessage;

  OfficialCertificateRequirement? _resolvedRequirement;

  @override
  void initState() {
    super.initState();
    _resolvedRequirement = widget.requirement;
    if (_resolvedRequirement == null) {
      _loadRequirement();
    }
  }

  Future<void> _loadRequirement() async {
    final repo = ref.read(officialCertificateRepositoryProvider);
    final req = await repo.getRequirementById(widget.requirementId);
    if (mounted) {
      setState(() {
        _resolvedRequirement = req;
      });
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _errorMessage = null);
    try {
      final allowedExtensions = _resolvedRequirement?.allowedFileTypes ?? ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];
      final maxBytes = _resolvedRequirement?.maxFileSizeBytes ?? 10 * 1024 * 1024;

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.size > maxBytes) {
          setState(() {
            _errorMessage = 'Selected file is too large (${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB). Maximum allowed size is 10 MB.';
          });
          return;
        }

        setState(() {
          _selectedFile = file;
          _fileBytes = file.bytes;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting file: $e';
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedFile == null) {
      setState(() => _errorMessage = 'Please choose a document to upload.');
      return;
    }

    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) {
      setState(() => _errorMessage = 'User is not authenticated.');
      return;
    }

    final student = authState.user;
    final req = _resolvedRequirement;
    if (req == null) {
      setState(() => _errorMessage = 'Requirement metadata not loaded.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(officialCertificateRepositoryProvider);
      final certId = const Uuid().v4();
      final storageFileName = '${certId}_${_selectedFile!.name}';
      final storagePath = '/colleges/${student.collegeId ?? 'default'}/students/${student.id}/official-certificates/$storageFileName';

      final submission = OfficialCertificate(
        id: certId,
        studentUid: student.id,
        studentId: student.id,
        studentName: student.name,
        collegeId: student.collegeId ?? req.collegeId,
        departmentId: student.departmentId ?? req.departmentId ?? '',
        courseId: req.courseId ?? '',
        semesterId: student.semesterId ?? req.semesterId ?? '',
        sectionId: student.sectionId ?? req.sectionId ?? '',
        academicYearId: req.academicYearId ?? '',
        requirementId: req.id,
        certificateName: req.name,
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        fileName: _selectedFile!.name,
        fileType: _selectedFile!.extension ?? 'pdf',
        fileSizeBytes: _selectedFile!.size,
        storagePath: storagePath,
        fileUrl: 'https://firebasestorage.googleapis.com/mock$storagePath',
        status: OfficialCertificateStatus.pending,
        uploadedAt: DateTime.now(),
      );

      await repo.submitCertificate(
        certificate: submission,
        fileBytes: _fileBytes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document submitted successfully! Status: Pending Verification'),
            backgroundColor: AcadexColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final req = _resolvedRequirement;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        maxWidth: 900,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AcadexSpacing.space48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AcadexPageHeader(
                title: 'Upload Official Certificate',
                subtitle: 'Submit verified documents required by your institution.',
              ),
              const SizedBox(height: AcadexSpacing.space16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AcadexSpacing.space16),
                  decoration: BoxDecoration(
                    color: AcadexColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AcadexRadius.md),
                    border: Border.all(color: AcadexColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: AcadexColors.error, size: 20),
                      const SizedBox(width: AcadexSpacing.space8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AcadexTypography.bodyMedium(color: AcadexColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AcadexSpacing.space16),
              ],

              AcadexCard(
                padding: const EdgeInsets.all(AcadexSpacing.space24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Requirement Details Banner
                      if (req != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AcadexSpacing.space16),
                          decoration: BoxDecoration(
                            color: AcadexColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(AcadexRadius.md),
                            border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.fileCheck2, color: AcadexColors.primary, size: 22),
                                  const SizedBox(width: AcadexSpacing.space8),
                                  Expanded(
                                    child: Text(
                                      req.name,
                                      style: AcadexTypography.heading3(
                                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: req.required
                                          ? AcadexColors.error.withValues(alpha: 0.1)
                                          : (isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft),
                                      borderRadius: BorderRadius.circular(AcadexRadius.xs),
                                    ),
                                    child: Text(
                                      req.required ? 'Mandatory' : 'Optional',
                                      style: TextStyle(
                                        color: req.required
                                            ? AcadexColors.error
                                            : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (req.description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  req.description,
                                  style: AcadexTypography.bodySmall(
                                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                'Accepted formats: ${req.allowedFileTypes.join(', ').toUpperCase()} • Max size: ${(req.maxFileSizeBytes / (1024 * 1024)).toStringAsFixed(0)}MB',
                                style: AcadexTypography.caption(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AcadexSpacing.space24),
                      ],

                      // Optional Description Field
                      Text(
                        'Document Description (Optional)',
                        style: AcadexTypography.title(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: AcadexSpacing.space8),
                      TextFormField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'e.g. Scanned copy of original transfer certificate',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                        ),
                      ),
                      const SizedBox(height: AcadexSpacing.space24),

                      // File Picker Section
                      Text(
                        'Upload Document File *',
                        style: AcadexTypography.title(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: AcadexSpacing.space8),

                      if (_selectedFile == null)
                        InkWell(
                          onTap: _pickFile,
                          borderRadius: BorderRadius.circular(AcadexRadius.lg),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                            decoration: BoxDecoration(
                              color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft,
                              borderRadius: BorderRadius.circular(AcadexRadius.lg),
                              border: Border.all(
                                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AcadexColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(LucideIcons.uploadCloud, color: AcadexColors.primary, size: 28),
                                ),
                                const SizedBox(height: AcadexSpacing.space16),
                                Text(
                                  'Choose a file or click to browse',
                                  style: AcadexTypography.heading3(
                                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Accepted formats: PDF, JPG, JPEG, PNG, DOC, DOCX (Max 10MB)',
                                  style: AcadexTypography.bodySmall(
                                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(AcadexSpacing.space16),
                          decoration: BoxDecoration(
                            color: AcadexColors.success.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(AcadexRadius.md),
                            border: Border.all(color: AcadexColors.success.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AcadexColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AcadexRadius.sm),
                                ),
                                child: const Icon(LucideIcons.fileCheck, color: AcadexColors.success, size: 24),
                              ),
                              const SizedBox(width: AcadexSpacing.space16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedFile!.name,
                                      style: AcadexTypography.bodyMedium(
                                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                      ),
                                    ),
                                    Text(
                                      '${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                                      style: AcadexTypography.caption(
                                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AcadexButton(
                                label: 'Replace',
                                icon: LucideIcons.refreshCw,
                                variant: AcadexButtonVariant.secondary,
                                size: AcadexButtonSize.sm,
                                onPressed: _pickFile,
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: AcadexSpacing.space32),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AcadexButton(
                            label: 'Cancel',
                            variant: AcadexButtonVariant.secondary,
                            onPressed: _isSubmitting ? null : () => context.pop(),
                          ),
                          const SizedBox(width: AcadexSpacing.space16),
                          AcadexButton(
                            label: _isSubmitting ? 'Submitting...' : 'Submit Document',
                            icon: LucideIcons.send,
                            variant: AcadexButtonVariant.primary,
                            onPressed: _isSubmitting ? null : _submit,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
