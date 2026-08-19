import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../domain/models/official_certificate_models.dart';
import '../providers/official_certificate_providers.dart';
import '../widgets/official_certificate_widgets.dart';

class StudentOfficialCertificatesScreen extends ConsumerWidget {
  const StudentOfficialCertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final asyncReqWithSubs = ref.watch(studentOfficialRequirementsWithSubmissionsProvider);
    final metrics = ref.watch(studentOfficialCertificateMetricsProvider);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        maxWidth: 1600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            const AcadexPageHeader(
              title: 'Official Certificates',
              subtitle: 'Keep your college documents organized and verified.',
            ),
            const SizedBox(height: AcadexSpacing.space16),

            // Summary Metrics Strip
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 768;
                if (isCompact) {
                  return Wrap(
                    spacing: AcadexSpacing.space12,
                    runSpacing: AcadexSpacing.space12,
                    children: [
                      _metricBox('Required', '${metrics.totalRequired}', AcadexColors.primary, isDark),
                      _metricBox('Submitted', '${metrics.totalSubmitted}', AcadexColors.info, isDark),
                      _metricBox('Verified', '${metrics.totalVerified}', AcadexColors.success, isDark),
                      _metricBox('Pending', '${metrics.totalPending}', AcadexColors.warning, isDark),
                      if (metrics.totalResubmissionRequired > 0)
                        _metricBox('Resubmit', '${metrics.totalResubmissionRequired}', AcadexColors.error, isDark),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: _metricBox('Required Documents', '${metrics.totalRequired}', AcadexColors.primary, isDark)),
                    const SizedBox(width: AcadexSpacing.space12),
                    Expanded(child: _metricBox('Submitted', '${metrics.totalSubmitted}', AcadexColors.info, isDark)),
                    const SizedBox(width: AcadexSpacing.space12),
                    Expanded(child: _metricBox('Verified', '${metrics.totalVerified}', AcadexColors.success, isDark)),
                    const SizedBox(width: AcadexSpacing.space12),
                    Expanded(child: _metricBox('Pending Verification', '${metrics.totalPending}', AcadexColors.warning, isDark)),
                    if (metrics.totalResubmissionRequired > 0) ...[
                      const SizedBox(width: AcadexSpacing.space12),
                      Expanded(
                        child: _metricBox(
                          'Resubmission Req.',
                          '${metrics.totalResubmissionRequired}',
                          AcadexColors.error,
                          isDark,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: AcadexSpacing.space24),

            // Content Area
            Expanded(
              child: asyncReqWithSubs.when(
                loading: () => const Center(child: AcadexLoadingState()),
                error: (err, stack) => Center(
                  child: AcadexErrorState(
                    title: 'Failed to load official certificates',
                    message: err.toString(),
                    onRetry: () => ref.invalidate(studentOfficialRequirementsWithSubmissionsProvider),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(
                      child: AcadexEmptyState(
                        title: 'No Required Documents',
                        subtitle: 'Your college or department has not requested any official certificates at this time.',
                        icon: LucideIcons.fileCheck2,
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: AcadexSpacing.space48),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AcadexSpacing.space16),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return OfficialRequirementCard(
                        item: item,
                        onUpload: () {
                          context.push('/official-certificates/upload/${item.requirement.id}', extra: item.requirement);
                        },
                        onUploadAgain: () {
                          context.push('/official-certificates/upload/${item.requirement.id}', extra: item.requirement);
                        },
                        onView: () {
                          if (item.submission != null) {
                            _showDocumentDetailsDialog(context, item.submission!, item.requirement);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBox(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AcadexSpacing.space16, vertical: AcadexSpacing.space12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AcadexSpacing.space8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
              ),
              Text(
                label,
                style: AcadexTypography.caption(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDocumentDetailsDialog(
    BuildContext context,
    OfficialCertificate submission,
    OfficialCertificateRequirement requirement,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.lg)),
          title: Row(
            children: [
              const Icon(LucideIcons.fileCheck2, color: AcadexColors.primary),
              const SizedBox(width: AcadexSpacing.space8),
              Expanded(child: Text(requirement.name)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('File Name', submission.fileName, isDark),
                _detailRow('File Size', submission.fileSizeDisplay, isDark),
                _detailRow('Uploaded At', submission.uploadedAt.toString().substring(0, 16), isDark),
                _detailRow('Status', submission.status.displayName, isDark),
                if (submission.verifiedBy != null) ...[
                  _detailRow('Verified By', submission.verifiedBy!, isDark),
                  _detailRow('Verified At', submission.verifiedAt?.toString().substring(0, 16) ?? 'N/A', isDark),
                ],
                if (submission.rejectionReason != null && submission.rejectionReason!.isNotEmpty)
                  _detailRow('Feedback / Reason', submission.rejectionReason!, isDark),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AcadexTypography.bodySmall(
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
