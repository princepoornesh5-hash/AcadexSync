import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/official_certificate_models.dart';
import '../providers/official_certificate_providers.dart';
import '../widgets/official_certificate_widgets.dart';

class OfficialCertificateSubmissionDetailScreen extends ConsumerStatefulWidget {
  final String submissionId;
  final OfficialCertificate? submission;

  const OfficialCertificateSubmissionDetailScreen({
    super.key,
    required this.submissionId,
    this.submission,
  });

  @override
  ConsumerState<OfficialCertificateSubmissionDetailScreen> createState() =>
      _OfficialCertificateSubmissionDetailScreenState();
}

class _OfficialCertificateSubmissionDetailScreenState
    extends ConsumerState<OfficialCertificateSubmissionDetailScreen> {
  final _reasonController = TextEditingController();
  OfficialCertificate? _resolvedSubmission;
  bool _isLoading = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _resolvedSubmission = widget.submission;
    if (_resolvedSubmission == null) {
      _loadSubmission();
    } else {
      _reasonController.text = _resolvedSubmission?.rejectionReason ?? '';
    }
  }

  Future<void> _loadSubmission() async {
    setState(() => _isLoading = true);
    final repo = ref.read(officialCertificateRepositoryProvider);
    final sub = await repo.getSubmissionById(widget.submissionId);
    if (mounted) {
      setState(() {
        _resolvedSubmission = sub;
        _reasonController.text = sub?.rejectionReason ?? '';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(OfficialCertificateStatus status) async {
    if ((status == OfficialCertificateStatus.rejected ||
            status == OfficialCertificateStatus.resubmissionRequired) &&
        _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A reason is mandatory when rejecting or requesting re-upload.'),
          backgroundColor: AcadexColors.error,
        ),
      );
      return;
    }

    final authState = ref.read(authProvider);
    final verifierName = authState is AuthAuthenticated ? authState.user.name : 'Admin';

    setState(() => _isProcessing = true);

    try {
      final repo = ref.read(officialCertificateRepositoryProvider);
      await repo.verifySubmission(
        submissionId: widget.submissionId,
        verifiedBy: verifierName,
        status: status,
        rejectionReason: _reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : null,
      );

      await _loadSubmission();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission status updated to: ${status.displayName}'),
            backgroundColor: AcadexColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: AcadexColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sub = _resolvedSubmission;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (sub == null) {
      return Scaffold(
        backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Submission not found'),
              const SizedBox(height: 16),
              AcadexButton(label: 'Back', onPressed: () => context.pop()),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        maxWidth: 900,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AcadexSpacing.space48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AcadexPageHeader(
                title: 'Review Submission: ${sub.certificateName}',
                subtitle: 'Verify document authenticity and update review status.',
                actions: [
                  AcadexButton(
                    label: 'Back to List',
                    icon: LucideIcons.arrowLeft,
                    variant: AcadexButtonVariant.secondary,
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
              const SizedBox(height: AcadexSpacing.space16),

              // Student & Document Details Card
              AcadexCard(
                padding: const EdgeInsets.all(AcadexSpacing.space24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Student Information',
                          style: AcadexTypography.heading3(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                        ),
                        OfficialCertificateStatusBadge(submissionStatus: sub.status),
                      ],
                    ),
                    const SizedBox(height: AcadexSpacing.space16),
                    _infoRow('Student Name', sub.studentName, isDark),
                    _infoRow('Roll Number / ID', sub.studentId, isDark),
                    _infoRow('Department', sub.departmentId.toUpperCase(), isDark),
                    _infoRow('Course / Sem / Sec', 'Course: ${sub.courseId} • Sem: ${sub.semesterId} • Sec: ${sub.sectionId}', isDark),
                    const SizedBox(height: AcadexSpacing.space24),
                    const Divider(),
                    const SizedBox(height: AcadexSpacing.space16),

                    Text(
                      'Document Details',
                      style: AcadexTypography.heading3(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                    ),
                    const SizedBox(height: AcadexSpacing.space16),
                    _infoRow('Requirement Name', sub.certificateName, isDark),
                    if (sub.description != null && sub.description!.isNotEmpty)
                      _infoRow('Student Notes', sub.description!, isDark),
                    _infoRow('File Name', sub.fileName, isDark),
                    _infoRow('File Size', sub.fileSizeDisplay, isDark),
                    _infoRow('Uploaded At', sub.uploadedAt.toString().substring(0, 16), isDark),
                    if (sub.verifiedBy != null) ...[
                      _infoRow('Verified By', sub.verifiedBy!, isDark),
                      _infoRow('Verified At', sub.verifiedAt?.toString().substring(0, 16) ?? 'N/A', isDark),
                    ],

                    const SizedBox(height: AcadexSpacing.space24),
                    const Divider(),
                    const SizedBox(height: AcadexSpacing.space16),

                    // Feedback / Rejection Field
                    Text(
                      'Review Feedback / Rejection Reason',
                      style: AcadexTypography.title(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                    ),
                    const SizedBox(height: AcadexSpacing.space8),
                    TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter reason if rejecting or requesting re-upload (mandatory for re-upload/reject)...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                      ),
                    ),
                    const SizedBox(height: AcadexSpacing.space24),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AcadexButton(
                          label: 'Request Re-upload',
                          icon: LucideIcons.alertTriangle,
                          variant: AcadexButtonVariant.secondary,
                          size: AcadexButtonSize.sm,
                          onPressed: _isProcessing
                              ? null
                              : () => _updateStatus(OfficialCertificateStatus.resubmissionRequired),
                        ),
                        const SizedBox(width: AcadexSpacing.space8),
                        AcadexButton(
                          label: 'Reject',
                          icon: LucideIcons.xCircle,
                          variant: AcadexButtonVariant.secondary,
                          size: AcadexButtonSize.sm,
                          onPressed: _isProcessing
                              ? null
                              : () => _updateStatus(OfficialCertificateStatus.rejected),
                        ),
                        const SizedBox(width: AcadexSpacing.space8),
                        AcadexButton(
                          label: 'Approve & Verify',
                          icon: LucideIcons.checkCircle2,
                          variant: AcadexButtonVariant.primary,
                          size: AcadexButtonSize.sm,
                          onPressed: _isProcessing
                              ? null
                              : () => _updateStatus(OfficialCertificateStatus.verified),
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
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AcadexTypography.bodyMedium(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
