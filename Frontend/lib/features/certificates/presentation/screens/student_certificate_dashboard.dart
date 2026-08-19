import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../features/auth/domain/models/auth_state.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/models/certificate.dart';
import '../../domain/models/certificate_status.dart';
import '../../domain/models/certificate_type.dart';
import '../providers/certificate_providers.dart';
import '../widgets/certificate_card.dart';

class StudentCertificateDashboard extends ConsumerWidget {
  const StudentCertificateDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final certsAsync = ref.watch(filteredStudentCertificatesProvider);
    final allCertsAsync = ref.watch(studentCertificatesProvider);
    final query = ref.watch(certificateSearchQueryProvider);
    final filter = ref.watch(certificateFilterProvider);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: CustomScrollView(
            slivers: [
              // Acadex Page Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: AcadexPageHeader(
                    title: 'My Certificates',
                    subtitle: 'Manage your portfolio of academic achievements, credentials, and institutional requests',
                    actions: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          side: BorderSide(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                        ),
                        icon: const Icon(LucideIcons.fileClock, size: 16),
                        label: Text(
                          'Official Requests',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ),
                        ),
                        onPressed: () => context.go('/certificates/requests'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AcadexColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                          elevation: 0,
                        ),
                        icon: const Icon(LucideIcons.uploadCloud, size: 16),
                        label: Text('Upload Certificate', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        onPressed: () => context.go('/certificates/upload'),
                      ),
                    ],
                  ),
                ),
              ),

              // Summary Metrics Area
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: allCertsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (certs) => _SummaryCards(certs: certs),
                  ),
                ),
              ),

              // Search & Filter Toolbar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search certificates by title, issuer, or category...',
                                prefixIcon: Icon(
                                  LucideIcons.search,
                                  size: 18,
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ),
                                filled: true,
                                fillColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                suffixIcon: query.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(LucideIcons.x, size: 16),
                                        onPressed: () => ref.read(certificateSearchQueryProvider.notifier).state = '',
                                      )
                                    : null,
                              ),
                              onChanged: (v) => ref.read(certificateSearchQueryProvider.notifier).state = v,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _FilterChipsBar(
                        filter: filter,
                        onChanged: (f) => ref.read(certificateFilterProvider.notifier).state = f,
                      ),
                    ],
                  ),
                ),
              ),

              // Content List / Empty / Loading / Error
              certsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: AcadexLoadingState(message: 'Loading your certificate portfolio...'),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: AcadexErrorState(
                    title: 'Failed to load certificates',
                    message: e.toString(),
                    onRetry: () => ref.invalidate(studentCertificatesProvider),
                  ),
                ),
                data: (certs) {
                  if (certs.isEmpty) {
                    final hasFilter = filter.isActive || query.isNotEmpty;
                    return SliverFillRemaining(
                      child: AcadexEmptyState(
                        icon: hasFilter ? LucideIcons.filterX : LucideIcons.award,
                        title: hasFilter ? 'No matching certificates' : 'No certificates uploaded yet',
                        subtitle: hasFilter
                            ? 'Try clearing your search query or adjusting your category filters.'
                            : 'Upload your external certifications, course achievements, and workshop credentials to build your verified portfolio.',
                        actionLabel: hasFilter ? 'Reset Filters' : 'Upload First Certificate',
                        onActionTap: hasFilter
                            ? () {
                                ref.read(certificateSearchQueryProvider.notifier).state = '';
                                ref.read(certificateFilterProvider.notifier).state = const CertificateFilter();
                              }
                            : () => context.go('/certificates/upload'),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final c = certs[i];
                          return CertificateCard(
                            certificate: c,
                            onTap: () => context.go('/certificates/detail/${c.id}'),
                            onEdit: () => context.go('/certificates/edit/${c.id}', extra: c),
                            onDelete: () => _confirmDelete(context, ref, c),
                          );
                        },
                        childCount: certs.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Certificate cert) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final user = authState.user;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.lg)),
        title: Text('Remove Certificate', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to remove "${cert.title}"? This will permanently delete the certificate and its physical file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(certificateRepositoryProvider).deleteCertificate(cert.id, user.firebaseUid ?? user.id);
    }
  }
}

class _SummaryCards extends StatelessWidget {
  final List<Certificate> certs;
  const _SummaryCards({required this.certs});

  @override
  Widget build(BuildContext context) {
    final total = certs.length;
    final verified = certs.where((c) => c.isVerified || c.status == CertificateStatus.verified).length;
    final pending = certs.where((c) => !c.isVerified && c.status != CertificateStatus.archived).length;
    final archived = certs.where((c) => c.status == CertificateStatus.archived).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;
        if (isMobile) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _MetricCard(label: 'Total', value: total.toString(), icon: LucideIcons.award, color: AcadexColors.primary),
              _MetricCard(label: 'Verified', value: verified.toString(), icon: LucideIcons.badgeCheck, color: AcadexColors.success),
              _MetricCard(label: 'Pending', value: pending.toString(), icon: LucideIcons.clock, color: AcadexColors.warning),
              _MetricCard(label: 'Archived', value: archived.toString(), icon: LucideIcons.archive, color: AcadexColors.inkMuted),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _MetricCard(label: 'Total Certificates', value: total.toString(), icon: LucideIcons.award, color: AcadexColors.primary)),
            const SizedBox(width: 14),
            Expanded(child: _MetricCard(label: 'Verified Credentials', value: verified.toString(), icon: LucideIcons.badgeCheck, color: AcadexColors.success)),
            const SizedBox(width: 14),
            Expanded(child: _MetricCard(label: 'Pending Verification', value: pending.toString(), icon: LucideIcons.clock, color: AcadexColors.warning)),
            const SizedBox(width: 14),
            Expanded(child: _MetricCard(label: 'Archived Records', value: archived.toString(), icon: LucideIcons.archive, color: AcadexColors.inkMuted)),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: BorderRadius.circular(AcadexRadius.lg),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(AcadexRadius.md),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
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

class _FilterChipsBar extends StatelessWidget {
  final CertificateFilter filter;
  final ValueChanged<CertificateFilter> onChanged;

  const _FilterChipsBar({required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'All Certificates',
            isSelected: filter.type == null && filter.isVerified == null,
            onTap: () => onChanged(const CertificateFilter()),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Verified ✓',
            isSelected: filter.isVerified == true,
            onTap: () => onChanged(filter.copyWith(isVerified: filter.isVerified == true ? null : true)),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Pending',
            isSelected: filter.isVerified == false,
            onTap: () => onChanged(filter.copyWith(isVerified: filter.isVerified == false ? null : false)),
          ),
          const SizedBox(width: 8),
          ...CertificateType.values.map((t) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Chip(
                  label: t.displayName,
                  isSelected: filter.type == t,
                  onTap: () => onChanged(filter.copyWith(type: filter.type == t ? null : t)),
                ),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AcadexRadius.full),
      child: AnimatedContainer(
        duration: AcadexMotion.micro,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AcadexColors.primary
              : (isDark ? AcadexColors.darkSurface : AcadexColors.surface),
          borderRadius: BorderRadius.circular(AcadexRadius.full),
          border: Border.all(
            color: isSelected
                ? AcadexColors.primary
                : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary),
          ),
        ),
      ),
    );
  }
}
