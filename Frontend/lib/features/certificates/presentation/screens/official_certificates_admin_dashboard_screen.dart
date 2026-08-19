import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/official_certificate_models.dart';
import '../providers/official_certificate_providers.dart';
import '../widgets/official_certificate_widgets.dart';

class OfficialCertificatesAdminDashboardScreen extends ConsumerStatefulWidget {
  const OfficialCertificatesAdminDashboardScreen({super.key});

  @override
  ConsumerState<OfficialCertificatesAdminDashboardScreen> createState() =>
      _OfficialCertificatesAdminDashboardScreenState();
}

class _OfficialCertificatesAdminDashboardScreenState
    extends ConsumerState<OfficialCertificatesAdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final metrics = ref.watch(adminOfficialCertificateMetricsProvider);
    final authState = ref.watch(authProvider);
    final isHod = authState is AuthAuthenticated && authState.user.role == AppRole.hod;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        maxWidth: 1600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            AcadexPageHeader(
              title: 'Official Certificates',
              subtitle: isHod
                  ? 'Manage required department documents and verify student submissions.'
                  : 'Manage required college documents and verify student submissions across departments.',
              actions: [
                AcadexButton(
                  label: 'New Requirement',
                  icon: LucideIcons.plus,
                  variant: AcadexButtonVariant.primary,
                  onPressed: () => context.push('/official-certificates/requirements/new'),
                ),
              ],
            ),
            const SizedBox(height: AcadexSpacing.space16),

            // Summary Metric Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 900;
                if (isNarrow) {
                  return Wrap(
                    spacing: AcadexSpacing.space16,
                    runSpacing: AcadexSpacing.space16,
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth - AcadexSpacing.space16) / 2,
                        child: OfficialCertificateMetricCard(
                          label: 'Required Documents',
                          value: '${metrics.totalRequirements}',
                          icon: LucideIcons.fileText,
                          color: AcadexColors.primary,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - AcadexSpacing.space16) / 2,
                        child: OfficialCertificateMetricCard(
                          label: 'Pending Verification',
                          value: '${metrics.pendingVerification}',
                          icon: LucideIcons.clock,
                          color: AcadexColors.warning,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - AcadexSpacing.space16) / 2,
                        child: OfficialCertificateMetricCard(
                          label: 'Verified Submissions',
                          value: '${metrics.verified}',
                          icon: LucideIcons.checkCircle2,
                          color: AcadexColors.success,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - AcadexSpacing.space16) / 2,
                        child: OfficialCertificateMetricCard(
                          label: 'Resubmission Req.',
                          value: '${metrics.resubmissionRequired}',
                          icon: LucideIcons.alertTriangle,
                          color: AcadexColors.error,
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: OfficialCertificateMetricCard(
                        label: 'Required Documents',
                        value: '${metrics.totalRequirements}',
                        icon: LucideIcons.fileText,
                        color: AcadexColors.primary,
                      ),
                    ),
                    const SizedBox(width: AcadexSpacing.space16),
                    Expanded(
                      child: OfficialCertificateMetricCard(
                        label: 'Pending Verification',
                        value: '${metrics.pendingVerification}',
                        icon: LucideIcons.clock,
                        color: AcadexColors.warning,
                      ),
                    ),
                    const SizedBox(width: AcadexSpacing.space16),
                    Expanded(
                      child: OfficialCertificateMetricCard(
                        label: 'Verified Submissions',
                        value: '${metrics.verified}',
                        icon: LucideIcons.checkCircle2,
                        color: AcadexColors.success,
                      ),
                    ),
                    const SizedBox(width: AcadexSpacing.space16),
                    Expanded(
                      child: OfficialCertificateMetricCard(
                        label: 'Resubmission Required',
                        value: '${metrics.resubmissionRequired}',
                        icon: LucideIcons.alertTriangle,
                        color: AcadexColors.error,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AcadexSpacing.space24),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AcadexColors.primary,
                labelColor: AcadexColors.primary,
                unselectedLabelColor: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                tabs: const [
                  Tab(text: 'Requirements'),
                  Tab(text: 'Submissions Queue'),
                ],
              ),
            ),
            const SizedBox(height: AcadexSpacing.space16),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRequirementsTab(context),
                  _buildSubmissionsTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: REQUIREMENTS ---
  Widget _buildRequirementsTab(BuildContext context) {
    final asyncReqs = ref.watch(officialCertificateRequirementsListProvider);

    return asyncReqs.when(
      loading: () => const Center(child: AcadexLoadingState()),
      error: (err, _) => Center(
        child: AcadexErrorState(
          title: 'Error loading requirements',
          message: err.toString(),
          onRetry: () => ref.invalidate(officialCertificateRequirementsListProvider),
        ),
      ),
      data: (reqs) {
        if (reqs.isEmpty) {
          return Center(
            child: AcadexEmptyState(
              title: 'No Requirements Defined',
              subtitle: 'Create official document requirements that students must upload for verification.',
              icon: LucideIcons.fileCheck2,
              actionLabel: 'Create First Requirement',
              onActionTap: () => context.push('/official-certificates/requirements/new'),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: AcadexSpacing.space48),
          itemCount: reqs.length,
          separatorBuilder: (_, __) => const SizedBox(height: AcadexSpacing.space16),
          itemBuilder: (context, index) {
            final req = reqs[index];
            return _buildRequirementAdminCard(context, req);
          },
        );
      },
    );
  }

  Widget _buildRequirementAdminCard(BuildContext context, OfficialCertificateRequirement req) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AcadexCard(
      padding: const EdgeInsets.all(AcadexSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AcadexColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AcadexRadius.md),
                ),
                child: const Icon(LucideIcons.fileCheck2, color: AcadexColors.primary, size: 22),
              ),
              const SizedBox(width: AcadexSpacing.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
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
                            color: req.isActive
                                ? AcadexColors.success.withValues(alpha: 0.1)
                                : (isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft),
                            borderRadius: BorderRadius.circular(AcadexRadius.xs),
                          ),
                          child: Text(
                            req.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: req.isActive ? AcadexColors.success : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Applicable To: ${req.targetScopeDisplay}  •  Category: ${req.category}  •  ${req.required ? 'Mandatory' : 'Optional'}',
                      style: AcadexTypography.bodySmall(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (req.description.isNotEmpty) ...[
            const SizedBox(height: AcadexSpacing.space8),
            Text(
              req.description,
              style: AcadexTypography.body(
                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
              ),
            ),
          ],
          const SizedBox(height: AcadexSpacing.space16),
          const Divider(height: 1),
          const SizedBox(height: AcadexSpacing.space8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Allowed: ${req.allowedFileTypes.join(', ').toUpperCase()} (Max ${(req.maxFileSizeBytes / (1024 * 1024)).toStringAsFixed(0)}MB)',
                style: AcadexTypography.bodySmall(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              Row(
                children: [
                  AcadexButton(
                    label: req.isActive ? 'Disable' : 'Enable',
                    variant: AcadexButtonVariant.secondary,
                    size: AcadexButtonSize.sm,
                    onPressed: () async {
                      final updated = req.copyWith(
                        status: req.isActive ? RequirementStatus.inactive : RequirementStatus.active,
                      );
                      await ref.read(officialCertificateRepositoryProvider).updateRequirement(updated);
                    },
                  ),
                  const SizedBox(width: 8),
                  AcadexButton(
                    label: 'Edit',
                    icon: LucideIcons.pencil,
                    variant: AcadexButtonVariant.secondary,
                    size: AcadexButtonSize.sm,
                    onPressed: () => context.push('/official-certificates/requirements/${req.id}/edit', extra: req),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 2: SUBMISSIONS ---
  Widget _buildSubmissionsTab(BuildContext context) {
    final filter = ref.watch(officialCertificateFilterProvider);
    final submissions = ref.watch(filteredOfficialSubmissionsProvider);

    return Column(
      children: [
        // Search & Filters Row
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by student name, roll number, or document...',
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                ),
                onChanged: (val) {
                  ref.read(officialCertificateFilterProvider.notifier).state = filter.copyWith(searchQuery: val);
                },
              ),
            ),
            const SizedBox(width: AcadexSpacing.space16),
            _statusFilterDropdown(context, filter),
          ],
        ),
        const SizedBox(height: AcadexSpacing.space16),

        // Submissions Table / List
        Expanded(
          child: submissions.isEmpty
              ? const Center(
                  child: AcadexEmptyState(
                    title: 'No Submissions Found',
                    subtitle: 'No student certificate submissions match the selected filters.',
                    icon: LucideIcons.inbox,
                  ),
                )
              : AcadexDataTable(
                  columns: const [
                    'Student',
                    'Roll No',
                    'Department',
                    'Document Name',
                    'Uploaded',
                    'Status',
                    'Action',
                  ],
                  rows: submissions.map((sub) {
                    return DataRow(
                      cells: [
                        DataCell(Text(sub.studentName, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(sub.studentId)),
                        DataCell(Text(sub.departmentId.toUpperCase())),
                        DataCell(Text(sub.certificateName)),
                        DataCell(Text(sub.uploadedAt.toString().substring(0, 10))),
                        DataCell(OfficialCertificateStatusBadge(submissionStatus: sub.status)),
                        DataCell(
                          AcadexButton(
                            label: 'Review',
                            icon: LucideIcons.eye,
                            variant: AcadexButtonVariant.primary,
                            size: AcadexButtonSize.sm,
                            onPressed: () => _openReviewDialog(context, sub),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _statusFilterDropdown(BuildContext context, OfficialCertificateFilter filter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AcadexSpacing.space16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<OfficialCertificateStatus?>(
          value: filter.statusFilter,
          hint: const Text('All Statuses'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Statuses')),
            ...OfficialCertificateStatus.values.map((s) {
              return DropdownMenuItem(value: s, child: Text(s.displayName));
            }),
          ],
          onChanged: (val) {
            ref.read(officialCertificateFilterProvider.notifier).state =
                val == null ? filter.copyWith(clearStatus: true) : filter.copyWith(statusFilter: val);
          },
        ),
      ),
    );
  }

  void _openReviewDialog(BuildContext context, OfficialCertificate submission) {
    showDialog(
      context: context,
      builder: (ctx) => _ReviewSubmissionDialog(submission: submission),
    );
  }
}

class _ReviewSubmissionDialog extends ConsumerStatefulWidget {
  final OfficialCertificate submission;

  const _ReviewSubmissionDialog({required this.submission});

  @override
  ConsumerState<_ReviewSubmissionDialog> createState() => _ReviewSubmissionDialogState();
}

class _ReviewSubmissionDialogState extends ConsumerState<_ReviewSubmissionDialog> {
  final _reasonController = TextEditingController();
  bool _isProcessing = false;

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
        submissionId: widget.submission.id,
        verifiedBy: verifierName,
        status: status,
        rejectionReason: _reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document updated to: ${status.displayName}'),
            backgroundColor: AcadexColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AcadexColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sub = widget.submission;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.lg)),
      title: Row(
        children: [
          const Icon(LucideIcons.fileCheck2, color: AcadexColors.primary),
          const SizedBox(width: AcadexSpacing.space8),
          Expanded(child: Text('Review: ${sub.certificateName}')),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Student Name', sub.studentName, isDark),
              _infoRow('Roll Number', sub.studentId, isDark),
              _infoRow('Academic Placement', 'Dept: ${sub.departmentId.toUpperCase()} • Sem: ${sub.semesterId} • Sec: ${sub.sectionId}', isDark),
              _infoRow('File Attached', '${sub.fileName} (${sub.fileSizeDisplay})', isDark),
              _infoRow('Uploaded Date', sub.uploadedAt.toString().substring(0, 16), isDark),
              _infoRow('Current Status', sub.status.displayName, isDark),
              const SizedBox(height: AcadexSpacing.space16),
              const Divider(),
              const SizedBox(height: AcadexSpacing.space8),
              Text(
                'Feedback / Rejection Reason',
                style: AcadexTypography.title(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
              ),
              const SizedBox(height: AcadexSpacing.space4),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. Document is blurry. Please upload a clearer scan.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AcadexButton(
          label: 'Request Re-upload',
          icon: LucideIcons.alertTriangle,
          variant: AcadexButtonVariant.secondary,
          size: AcadexButtonSize.sm,
          onPressed: _isProcessing ? null : () => _updateStatus(OfficialCertificateStatus.resubmissionRequired),
        ),
        AcadexButton(
          label: 'Reject',
          icon: LucideIcons.xCircle,
          variant: AcadexButtonVariant.secondary,
          size: AcadexButtonSize.sm,
          onPressed: _isProcessing ? null : () => _updateStatus(OfficialCertificateStatus.rejected),
        ),
        AcadexButton(
          label: 'Approve',
          icon: LucideIcons.checkCircle2,
          variant: AcadexButtonVariant.primary,
          size: AcadexButtonSize.sm,
          onPressed: _isProcessing ? null : () => _updateStatus(OfficialCertificateStatus.verified),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
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
