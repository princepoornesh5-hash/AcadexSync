import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../../core/services/imagekit_uploader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/assignment_models.dart';
import '../providers/assignments_providers.dart';
import '../../../institution_config/presentation/providers/institution_config_providers.dart';

class AssignmentDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  ConsumerState<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends ConsumerState<AssignmentDetailScreen> {
  bool _isProcessing = false;
  final _textResponseController = TextEditingController();
  List<SubmissionAttachmentModel> _attachments = [];
  bool _isUploadingFile = false;
  double _uploadProgress = 0.0;
  String? _uploadError;
  bool _isInitializedFromSubmission = false;
  bool _isResubmissionMode = false;
  PlatformFile? _lastFailedFile;

  @override
  void dispose() {
    _textResponseController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadFile() async {
    setState(() {
      _uploadError = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'jpg', 'jpeg', 'png', 'zip', 'txt'],
      withData: true,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    if (file.size > 25 * 1024 * 1024) {
      if (mounted) {
        AcadexSnackBar.showError(context, 'File size must be under 25MB');
      }
      return;
    }

    await _uploadSelectedFile(file);
  }

  Future<void> _uploadSelectedFile(PlatformFile file) async {
    if (file.bytes == null) {
      setState(() => _uploadError = 'Could not read file data. Please try again.');
      return;
    }

    setState(() {
      _isUploadingFile = true;
      _uploadProgress = 0.05;
      _uploadError = null;
      _lastFailedFile = null;
    });

    try {
      final repo = ref.read(assignmentsRepositoryProvider);
      final uploadAuth = await repo.getSubmissionUploadAuth(
        assignmentId: widget.assignmentId,
        fileName: file.name,
        fileType: file.extension ?? 'bin',
      );

      final imageKitAuth = ImageKitUploadAuth(
        token: uploadAuth.token,
        expire: uploadAuth.expire,
        signature: uploadAuth.signature,
        publicKey: uploadAuth.publicKey,
        urlEndpoint: 'https://ik.imagekit.io/acadex',
        folder: uploadAuth.folder,
        fileName: uploadAuth.fileName,
      );

      final uploader = ImageKitUploader();
      final uploadResult = await uploader.uploadFile(
        fileBytes: file.bytes!,
        fileName: uploadAuth.fileName,
        auth: imageKitAuth,
        onProgress: (sent, total) {
          if (total > 0 && mounted) {
            setState(() {
              _uploadProgress = sent / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _attachments.add(SubmissionAttachmentModel(
            fileId: uploadResult.fileId,
            name: file.name,
            url: uploadResult.url,
            fileSize: uploadResult.size,
            fileType: file.extension,
            uploadedAt: DateTime.now().toIso8601String(),
          ));
          _isUploadingFile = false;
          _uploadProgress = 0.0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingFile = false;
          _uploadError = 'File upload failed. Please retry.';
          _lastFailedFile = file;
        });
      }
    }
  }

  Future<void> _handleDownloadFile(String submissionId, String fileId) async {
    try {
      final repo = ref.read(assignmentsRepositoryProvider);
      final url = await repo.getSubmissionFileDownloadUrl(
        submissionId: submissionId,
        fileId: fileId,
      );
      if (url.isNotEmpty) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (mounted) {
        AcadexSnackBar.showError(context, 'Could not access file: ${e.toString()}');
      }
    }
  }

  Future<void> _handleSaveDraft() async {
    setState(() => _isProcessing = true);
    final notifier = ref.read(assignmentActionProvider.notifier);
    final text = _textResponseController.text.trim();
    final res = await notifier.saveDraftSubmission(
      assignmentId: widget.assignmentId,
      textResponse: text.isNotEmpty ? text : null,
      attachments: _attachments,
    );
    if (mounted) {
      setState(() => _isProcessing = false);
      if (res != null) {
        AcadexSnackBar.showSuccess(context, 'Draft saved.');
      } else {
        AcadexSnackBar.showError(context, "Couldn't save draft. Please try again.");
      }
    }
  }

  Future<void> _handleSubmitAssignment(AssignmentModel asgn) async {
    final text = _textResponseController.text.trim();
    if (text.isEmpty && _attachments.isEmpty) {
      AcadexSnackBar.showError(context, 'Please enter a response or attach a file before submitting.');
      return;
    }

    final isPastDue = asgn.isPastDue;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Assignment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assignment: ${asgn.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Due Date: ${asgn.dueDate} at ${asgn.dueTime}'),
            if (isPastDue) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, size: 16, color: Color(0xFFDC2626)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'This assignment is past its due date. It will be recorded as late.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Attachments: ${_attachments.length} file(s)${text.isNotEmpty ? " • Text response included" : ""}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    final notifier = ref.read(assignmentActionProvider.notifier);
    final res = await notifier.submitAssignment(
      assignmentId: widget.assignmentId,
      textResponse: text.isNotEmpty ? text : null,
      attachments: _attachments,
    );
    if (mounted) {
      setState(() {
        _isProcessing = false;
        if (res != null) {
          _isResubmissionMode = false;
        }
      });
      if (res != null) {
        AcadexSnackBar.showSuccess(context, 'Assignment submitted successfully!');
      } else {
        AcadexSnackBar.showError(context, "Submission failed. Please try again.");
      }
    }
  }



  Future<void> _handlePublish(AssignmentModel asgn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish this assignment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${asgn.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Context: ${asgn.subjectName ?? "Subject"}${asgn.sectionName != null ? " • Section ${asgn.sectionName}" : ""}'),
            const SizedBox(height: 6),
            Text('Due Date: ${asgn.dueDate} at ${asgn.dueTime}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Publish Now'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    final notifier = ref.read(assignmentActionProvider.notifier);
    final success = await notifier.publishAssignment(widget.assignmentId);
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        AcadexSnackBar.showSuccess(context, 'Assignment published successfully.');
      } else {
        AcadexSnackBar.showError(context, "Couldn't publish assignment. Please try again.");
      }
    }
  }

  Future<void> _handleClose() async {
    setState(() => _isProcessing = true);
    final notifier = ref.read(assignmentActionProvider.notifier);
    final success = await notifier.closeAssignment(widget.assignmentId);
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        AcadexSnackBar.showSuccess(context, 'Assignment closed.');
      } else {
        AcadexSnackBar.showError(context, "Couldn't close assignment. Please try again.");
      }
    }
  }

  Future<void> _handleArchive(AssignmentModel asgn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive this assignment?'),
        content: Text(
          'Archiving "${asgn.title}" will remove it from active lists while preserving historical submissions and marks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    final notifier = ref.read(assignmentActionProvider.notifier);
    final success = await notifier.archiveAssignment(widget.assignmentId);
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        AcadexSnackBar.showSuccess(context, 'Assignment archived successfully.');
        context.safePop(fallbackRoute: '/assignments');
      } else {
        AcadexSnackBar.showError(context, "Couldn't archive assignment. Please try again.");
      }
    }
  }

  Future<void> _handleDeleteDraft(AssignmentModel asgn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete draft assignment?'),
        content: Text('Are you sure you want to permanently delete draft "${asgn.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Draft'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    final notifier = ref.read(assignmentActionProvider.notifier);
    final success = await notifier.deleteAssignment(widget.assignmentId);
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        AcadexSnackBar.showSuccess(context, 'Draft assignment deleted.');
        context.safePop(fallbackRoute: '/assignments');
      } else {
        AcadexSnackBar.showError(context, "Couldn't delete draft assignment. Please try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assignmentAsync = ref.watch(assignmentDetailProvider(widget.assignmentId));
    final authState = ref.watch(authProvider);
    final terminology = ref.watch(terminologyProvider);

    final isStudent = authState is AuthAuthenticated && authState.user.role == AppRole.student;
    final isFacultyOrAdmin = authState is AuthAuthenticated &&
        (authState.user.role == AppRole.faculty ||
            authState.user.role == AppRole.hod ||
            authState.user.role == AppRole.collegeAdmin);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/assignments'),
        ),
        title: Text(
          'Assignment Detail',
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
      ),
      body: assignmentAsync.when(
        loading: () => const AcadexLoadingState(message: 'Loading assignment...'),
        error: (err, stack) => Center(
          child: AcadexErrorState(
            message: "This item is no longer available.",
            retryLabel: 'Retry',
            onRetry: () => ref.refresh(assignmentDetailProvider(widget.assignmentId)),
          ),
        ),
        data: (asgn) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  asgn.title,
                  style: AcadexTypography.heading1(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  terminology.formatCompactContext(
                    subjectName: asgn.subjectName,
                    sectionName: asgn.sectionName,
                  ),
                  style: AcadexTypography.bodyMedium(
                    color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                  ),
                ),

                const SizedBox(height: 18),

                // Due & Max Marks info card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DUE DATE & TIME',
                              style: AcadexTypography.eyebrow(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${asgn.dueDate}, ${asgn.dueTime}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MAXIMUM MARKS',
                              style: AcadexTypography.eyebrow(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${asgn.maximumMarks} Marks',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Student Submission / Results Card
                if (isStudent) _buildStudentSubmissionSection(asgn, isDark),

                // Description
                Text(
                  'INSTRUCTIONS / DESCRIPTION',
                  style: AcadexTypography.eyebrow(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  asgn.description,
                  style: AcadexTypography.body(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),

                const SizedBox(height: 20),

                // Questions
                if (asgn.questions.isNotEmpty) ...[
                  Text(
                    'QUESTIONS',
                    style: AcadexTypography.eyebrow(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...asgn.questions.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final qText = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$idx. ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              qText,
                              style: AcadexTypography.body(
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // Attachments
                if (asgn.attachments.isNotEmpty) ...[
                  Text(
                    'ATTACHMENTS',
                    style: AcadexTypography.eyebrow(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...asgn.attachments.map((att) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                        borderRadius: AcadexRadius.borderRadiusMd,
                        border: Border.all(
                          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.paperclip, size: 16, color: AcadexColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              att.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],



                if (isFacultyOrAdmin) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: AcadexButton(
                      label: 'View Activity & Record Marks',
                      icon: LucideIcons.users,
                      onPressed: () => context.push('/assignments/${asgn.id}/activity'),
                    ),
                  ),
                  if (asgn.status == AssignmentStatus.draft) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : () => _handlePublish(asgn),
                        icon: const Icon(LucideIcons.send, size: 16),
                        label: const Text('Publish Assignment'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: _isProcessing ? null : () => _handleDeleteDraft(asgn),
                        icon: const Icon(LucideIcons.trash2, size: 16),
                        label: const Text('Delete Draft'),
                      ),
                    ),
                  ],
                  if (asgn.status == AssignmentStatus.published) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _handleClose,
                        icon: const Icon(LucideIcons.lock, size: 16),
                        label: const Text('Close Assignment'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : () => _handleArchive(asgn),
                        icon: const Icon(LucideIcons.archive, size: 16),
                        label: const Text('Archive Assignment'),
                      ),
                    ),
                  ],
                  if (asgn.status == AssignmentStatus.closed) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : () => _handleArchive(asgn),
                        icon: const Icon(LucideIcons.archive, size: 16),
                        label: const Text('Archive Assignment'),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentSubmissionSection(AssignmentModel asgn, bool isDark) {
    final submissionAsync = ref.watch(mySubmissionProvider(widget.assignmentId));

    return submissionAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: AcadexLoadingState(message: 'Loading your submission...'),
      ),
      error: (err, stack) => const SizedBox.shrink(),
      data: (submission) {
        if (!_isInitializedFromSubmission && submission != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _textResponseController.text = submission.textResponse ?? '';
                _attachments = List.from(submission.attachments);
                _isInitializedFromSubmission = true;
              });
            }
          });
        }

        final isSubmitted = submission != null &&
            (submission.status == StudentTaskStatus.submitted ||
                submission.status == StudentTaskStatus.resubmitted ||
                submission.status == StudentTaskStatus.completed) &&
            !_isResubmissionMode;

        if (isSubmitted) {
          return _buildSubmittedView(asgn, submission, isDark);
        } else {
          return _buildSubmissionForm(asgn, submission, isDark);
        }
      },
    );
  }

  Widget _buildSubmittedView(AssignmentModel asgn, SubmissionModel submission, bool isDark) {
    final isReviewed = submission.reviewStatus == FacultyReviewStatus.reviewed;
    final marks = submission.marks ?? asgn.marks;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isReviewed
              ? const Color(0xFFBBF7D0)
              : (submission.isLate ? const Color(0xFFFECACA) : AcadexColors.primaryLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isReviewed ? LucideIcons.award : LucideIcons.checkCircle2,
                size: 22,
                color: isReviewed
                    ? const Color(0xFF15803D)
                    : (submission.isLate ? const Color(0xFFDC2626) : AcadexColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          submission.status.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isReviewed
                                ? const Color(0xFF15803D)
                                : (submission.isLate ? const Color(0xFFDC2626) : AcadexColors.primary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Version ${submission.version}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                            ),
                          ),
                        ),
                        if (submission.isLate)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LATE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (submission.submittedAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Submitted: ${submission.submittedAt!.toLocal().toString().substring(0, 16)}',
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Late warning explanation if late
          if (submission.isLate) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Recorded as late (submitted after deadline: ${asgn.dueDate} at ${asgn.dueTime}).',
                style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
              ),
            ),
          ],

          // Review & Marks Card
          if (isReviewed) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: AcadexRadius.borderRadiusMd,
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'FACULTY REVIEW & MARKS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                      Text(
                        '${marks ?? 0} / ${asgn.maximumMarks} Marks',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                  if (submission.feedback != null && submission.feedback!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Feedback: "${submission.feedback}"',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF166534), fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Your submission has been received. Faculty review is pending.',
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
              ),
            ),
          ],

          // Submitted response text
          if (submission.textResponse != null && submission.textResponse!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'YOUR RESPONSE',
              style: AcadexTypography.eyebrow(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                borderRadius: AcadexRadius.borderRadiusMd,
                border: Border.all(
                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                ),
              ),
              child: Text(
                submission.textResponse!,
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
              ),
            ),
          ],

          // Submitted Attachments
          if (submission.attachments.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'ATTACHED FILES (${submission.attachments.length})',
              style: AcadexTypography.eyebrow(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
            ),
            const SizedBox(height: 4),
            ...submission.attachments.map((att) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(
                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.paperclip, size: 16, color: AcadexColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        att.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => _handleDownloadFile(submission.id, att.fileId),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.download, size: 13, color: AcadexColors.primary),
                            SizedBox(width: 3),
                            Text(
                              'Download',
                              style: TextStyle(fontSize: 11, color: AcadexColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Previous Versions history (if any)
          if (submission.submissionHistory.isNotEmpty) ...[
            const SizedBox(height: 14),
            ExpansionTile(
              title: Text(
                'Submission History (${submission.submissionHistory.length} earlier version(s))',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              tilePadding: EdgeInsets.zero,
              children: submission.submissionHistory.map((hist) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.history, size: 14, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('v${hist.version} • ${hist.submittedAt?.toLocal().toString().substring(0, 16) ?? ""}',
                          style: const TextStyle(fontSize: 11)),
                      if (hist.isLate) ...[
                        const SizedBox(width: 6),
                        const Text('(Late)', style: TextStyle(fontSize: 10, color: Colors.red)),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // Resubmit option (if assignment is still active)
          if (asgn.status == AssignmentStatus.published) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isResubmissionMode = true;
                  });
                },
                icon: const Icon(LucideIcons.refreshCw, size: 15),
                label: const Text('Resubmit Assignment'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmissionForm(AssignmentModel asgn, SubmissionModel? submission, bool isDark) {
    final isDraft = submission?.status == StudentTaskStatus.draft;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _isResubmissionMode
                      ? 'RESUBMIT ASSIGNMENT'
                      : (isDraft ? 'DRAFT SUBMISSION' : 'YOUR SUBMISSION'),
                  style: AcadexTypography.heading2(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isDraft) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AcadexColors.primaryTint,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Draft',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AcadexColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),

          if (asgn.isPastDue) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This assignment is past its due date (${asgn.dueDate}, ${asgn.dueTime}). You can still submit, but it will be recorded as late.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Text Response input
          Text(
            'WRITTEN RESPONSE',
            style: AcadexTypography.eyebrow(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _textResponseController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter your answers or comments here...',
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: AcadexRadius.borderRadiusMd,
                borderSide: BorderSide(
                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // File Attachments
          Row(
            children: [
              Expanded(
                child: Text(
                  'ATTACHED FILES (${_attachments.length})',
                  style: AcadexTypography.eyebrow(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
              ),
              InkWell(
                onTap: _isUploadingFile ? null : _pickAndUploadFile,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.paperclip, size: 14, color: AcadexColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Attach File',
                        style: TextStyle(fontSize: 12, color: AcadexColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_isUploadingFile) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _uploadProgress > 0 ? _uploadProgress : null,
              backgroundColor: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
              color: AcadexColors.primary,
            ),
            const SizedBox(height: 4),
            Text(
              'Uploading file... ${(_uploadProgress * 100).toInt()}%',
              style: const TextStyle(fontSize: 11, color: AcadexColors.primary),
            ),
          ],

          if (_uploadError != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _uploadError!,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
                if (_lastFailedFile != null)
                  TextButton(
                    onPressed: () => _uploadSelectedFile(_lastFailedFile!),
                    child: const Text('Retry', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ],

          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._attachments.asMap().entries.map((entry) {
              final idx = entry.key;
              final att = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(
                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.file, size: 16, color: AcadexColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        att.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 16, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _attachments.removeAt(idx);
                        });
                      },
                      tooltip: 'Remove',
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 18),

          // Submit / Draft Actions
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 44,
                child: AcadexButton(
                  label: _isProcessing ? 'Submitting...' : 'Submit',
                  icon: LucideIcons.send,
                  onPressed: _isProcessing ? null : () => _handleSubmitAssignment(asgn),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_isResubmissionMode) ...[
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isResubmissionMode = false;
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _handleSaveDraft,
                        icon: const Icon(LucideIcons.save, size: 14),
                        label: const Text('Save Draft'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
