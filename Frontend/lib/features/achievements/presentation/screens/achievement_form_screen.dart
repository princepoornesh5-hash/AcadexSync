import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/achievement_models.dart';
import '../providers/achievement_providers.dart';

class AchievementFormScreen extends ConsumerStatefulWidget {
  final String? achievementId;
  final Achievement? achievement;

  const AchievementFormScreen({
    super.key,
    this.achievementId,
    this.achievement,
  });

  @override
  ConsumerState<AchievementFormScreen> createState() => _AchievementFormScreenState();
}

class _AchievementFormScreenState extends ConsumerState<AchievementFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _issuerController;
  late TextEditingController _descController;
  late TextEditingController _skillInputController;

  AchievementCategory _category = AchievementCategory.technical;
  DateTime _achievementDate = DateTime.now();
  final List<String> _skills = [];
  bool _requestVerification = false;

  PlatformFile? _selectedFile;
  Uint8List? _fileBytes;
  String? _existingFileName;
  String? _existingStoragePath;
  String? _existingFileUrl;
  int _existingFileSizeBytes = 0;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final a = widget.achievement;

    _titleController = TextEditingController(text: a?.title ?? '');
    _issuerController = TextEditingController(text: a?.issuer ?? '');
    _descController = TextEditingController(text: a?.description ?? '');
    _skillInputController = TextEditingController();

    if (a != null) {
      _category = a.category;
      _achievementDate = a.achievementDate;
      _skills.addAll(a.skills);
      _requestVerification = a.isVerificationRequested;
      _existingFileName = a.fileName;
      _existingStoragePath = a.storagePath;
      _existingFileUrl = a.fileUrl;
      _existingFileSizeBytes = a.fileSizeBytes;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _issuerController.dispose();
    _descController.dispose();
    _skillInputController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _achievementDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _achievementDate = picked);
    }
  }

  void _addSkill() {
    final text = _skillInputController.text.trim();
    if (text.isNotEmpty && !_skills.contains(text)) {
      setState(() {
        _skills.add(text);
        _skillInputController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  Future<void> _pickFile() async {
    setState(() => _errorMessage = null);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 10 * 1024 * 1024) {
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
      setState(() => _errorMessage = 'Error picking file: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) {
      setState(() => _errorMessage = 'You must be logged in to save an achievement.');
      return;
    }

    final user = authState.user;
    final isEditing = widget.achievement != null;
    final achievementId = isEditing ? widget.achievement!.id : const Uuid().v4();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(achievementRepositoryProvider);

      String? storageFileName;
      String? storagePath;
      String? fileUrl;
      String? fileType;
      int fileSizeBytes = 0;

      if (_selectedFile != null) {
        storageFileName = '${achievementId}_${_selectedFile!.name}';
        storagePath = '/colleges/${user.collegeId ?? 'default'}/students/${user.id}/achievements/$storageFileName';
        fileUrl = 'https://firebasestorage.googleapis.com/mock$storagePath';
        fileType = _selectedFile!.extension ?? 'pdf';
        fileSizeBytes = _selectedFile!.size;
      } else if (isEditing) {
        storageFileName = _existingFileName;
        storagePath = _existingStoragePath;
        fileUrl = _existingFileUrl;
        fileType = widget.achievement!.fileType;
        fileSizeBytes = _existingFileSizeBytes;
      }

      final achievement = Achievement(
        id: achievementId,
        studentUid: isEditing ? widget.achievement!.studentUid : user.id,
        studentId: isEditing ? widget.achievement!.studentId : user.id,
        studentName: isEditing ? widget.achievement!.studentName : user.name,
        collegeId: isEditing ? widget.achievement!.collegeId : (user.collegeId ?? 'default'),
        departmentId: isEditing ? widget.achievement!.departmentId : (user.departmentId ?? ''),
        courseId: isEditing ? widget.achievement!.courseId : (user.semesterId ?? ''),
        semesterId: isEditing ? widget.achievement!.semesterId : (user.semesterId ?? ''),
        sectionId: isEditing ? widget.achievement!.sectionId : (user.sectionId ?? ''),
        academicYearId: isEditing ? widget.achievement!.academicYearId : '',
        category: _category,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        issuer: _issuerController.text.trim(),
        achievementDate: _achievementDate,
        skills: List.from(_skills),
        fileName: _selectedFile?.name ?? _existingFileName,
        fileType: fileType,
        fileSizeBytes: fileSizeBytes,
        storagePath: storagePath,
        fileUrl: fileUrl,
        status: isEditing ? widget.achievement!.status : AchievementStatus.active,
        createdAt: isEditing ? widget.achievement!.createdAt : DateTime.now(),
        updatedAt: isEditing ? DateTime.now() : null,
        createdBy: isEditing ? widget.achievement!.createdBy : user.name,
        isVerificationRequested: _requestVerification,
        verificationStatus: isEditing
            ? (_requestVerification && widget.achievement!.isUnverified
                ? AchievementVerificationStatus.pending
                : widget.achievement!.verificationStatus)
            : (_requestVerification
                ? AchievementVerificationStatus.pending
                : AchievementVerificationStatus.unverified),
        verifiedBy: isEditing ? widget.achievement!.verifiedBy : null,
        verifiedAt: isEditing ? widget.achievement!.verifiedAt : null,
        verificationNote: isEditing ? widget.achievement!.verificationNote : null,
      );

      if (isEditing) {
        await repo.updateAchievement(
          achievement: achievement,
          newFileBytes: _fileBytes,
          oldStoragePath: _selectedFile != null ? _existingStoragePath : null,
        );
      } else {
        await repo.createAchievement(
          achievement: achievement,
          fileBytes: _fileBytes,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Achievement updated!' : 'Achievement added successfully!'),
            backgroundColor: AcadexColors.success,
          ),
        );
        context.safePop(fallbackRoute: '/achievements');
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
    final isEditing = widget.achievement != null;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        maxWidth: 900,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AcadexSpacing.space48),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                AcadexPageHeader(
                  title: isEditing ? 'Edit Achievement' : 'Add Achievement',
                  subtitle: 'Showcase your accomplishments, awards, projects, and skills.',
                ),
                const SizedBox(height: AcadexSpacing.space16),

                // Error Banner
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

                // Form Card
                AcadexCard(
                  padding: const EdgeInsets.all(AcadexSpacing.space24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Selector
                      Text(
                        'Achievement Category *',
                        style: AcadexTypography.title(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: AcadexSpacing.space8),
                      DropdownButtonFormField<AchievementCategory>(
                        value: _category,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                        ),
                        items: AchievementCategory.values.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(cat.icon, size: 16, color: AcadexColors.primary),
                                const SizedBox(width: 8),
                                Text(cat.displayName),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                      const SizedBox(height: AcadexSpacing.space20),

                      // Title
                      Text(
                        'Achievement Title *',
                        style: AcadexTypography.title(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: AcadexSpacing.space8),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g. National Hackathon Winner, AWS Solutions Architect',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                      ),
                      const SizedBox(height: AcadexSpacing.space20),

                      // Issuer / Organization & Date
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Issuer / Organization *',
                                  style: AcadexTypography.title(
                                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                  ),
                                ),
                                const SizedBox(height: AcadexSpacing.space8),
                                TextFormField(
                                  controller: _issuerController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. IEEE, Google, State University',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                                  ),
                                  validator: (val) =>
                                      val == null || val.trim().isEmpty ? 'Issuer is required' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AcadexSpacing.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date of Achievement *',
                                  style: AcadexTypography.title(
                                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                  ),
                                ),
                                const SizedBox(height: AcadexSpacing.space8),
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(AcadexRadius.md),
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                      ),
                                      borderRadius: BorderRadius.circular(AcadexRadius.md),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${_achievementDate.day}/${_achievementDate.month}/${_achievementDate.year}',
                                          style: AcadexTypography.bodyMedium(
                                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                          ),
                                        ),
                                        const Icon(LucideIcons.calendar, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AcadexSpacing.space20),

                      // Description
                      Text(
                        'Description',
                        style: AcadexTypography.title(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: AcadexSpacing.space8),
                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Describe your role, accomplishment, project details, or impact...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                        ),
                      ),
                      const SizedBox(height: AcadexSpacing.space20),

                      // Skills / Tags
                      Text(
                        'Skills & Tags (Optional)',
                        style: AcadexTypography.title(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: AcadexSpacing.space8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _skillInputController,
                              decoration: InputDecoration(
                                hintText: 'Type a skill (e.g. Flutter, Machine Learning) and click Add',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              onSubmitted: (_) => _addSkill(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AcadexButton(
                            label: 'Add Tag',
                            icon: LucideIcons.plus,
                            variant: AcadexButtonVariant.secondary,
                            size: AcadexButtonSize.md,
                            onPressed: _addSkill,
                          ),
                        ],
                      ),
                      if (_skills.isNotEmpty) ...[
                        const SizedBox(height: AcadexSpacing.space12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _skills.map((skill) {
                            return Chip(
                              label: Text(skill),
                              deleteIcon: const Icon(LucideIcons.x, size: 14),
                              onDeleted: () => _removeSkill(skill),
                              backgroundColor: AcadexColors.primary.withValues(alpha: 0.1),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: AcadexSpacing.space24),

                      // Certificate / Proof Upload
                      Text(
                        'Certificate / Proof Document (Optional)',
                        style: AcadexTypography.title(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: AcadexSpacing.space8),

                      if (_selectedFile == null && _existingFileName == null)
                        InkWell(
                          onTap: _pickFile,
                          borderRadius: BorderRadius.circular(AcadexRadius.md),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                            decoration: BoxDecoration(
                              color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft,
                              borderRadius: BorderRadius.circular(AcadexRadius.md),
                              border: Border.all(
                                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(LucideIcons.uploadCloud, color: AcadexColors.primary, size: 28),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload proof document (PDF, JPG, PNG, DOC, DOCX)',
                                  style: AcadexTypography.bodyMedium(
                                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Maximum file size: 10 MB',
                                  style: AcadexTypography.caption(
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
                              const Icon(LucideIcons.fileCheck, color: AcadexColors.success, size: 22),
                              const SizedBox(width: AcadexSpacing.space12),
                              Expanded(
                                child: Text(
                                  _selectedFile?.name ?? _existingFileName ?? 'Document',
                                  style: AcadexTypography.bodyMedium(
                                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                  ),
                                ),
                              ),
                              AcadexButton(
                                label: 'Replace File',
                                icon: LucideIcons.refreshCw,
                                variant: AcadexButtonVariant.secondary,
                                size: AcadexButtonSize.sm,
                                onPressed: _pickFile,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AcadexSpacing.space24),

                      // Verification Request Switch
                      CheckboxListTile(
                        value: _requestVerification,
                        title: const Text('Request Verification from Faculty / HOD'),
                        subtitle: const Text(
                          'Submits this achievement for official institutional review and badge verification.',
                        ),
                        activeColor: AcadexColors.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _requestVerification = val ?? false),
                      ),
                      const SizedBox(height: AcadexSpacing.space32),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AcadexButton(
                            label: 'Cancel',
                            variant: AcadexButtonVariant.secondary,
                            onPressed: _isSubmitting ? null : () => context.safePop(fallbackRoute: '/achievements'),
                          ),
                          const SizedBox(width: AcadexSpacing.space16),
                          AcadexButton(
                            label: _isSubmitting
                                ? 'Saving...'
                                : (isEditing ? 'Update Achievement' : 'Save Achievement'),
                            icon: LucideIcons.check,
                            variant: AcadexButtonVariant.primary,
                            onPressed: _isSubmitting ? null : _save,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
