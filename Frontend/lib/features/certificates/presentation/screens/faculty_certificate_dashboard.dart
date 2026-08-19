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

class FacultyCertificateDashboard extends ConsumerWidget {
  const FacultyCertificateDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final certsAsync = ref.watch(filteredFacultyCertificatesProvider);
    final allCertsAsync = ref.watch(facultyCertificatesProvider);
    final query = ref.watch(certificateSearchQueryProvider);
    final filter = ref.watch(certificateFilterProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

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
                    title: 'Department Certificates',
                    subtitle: 'Review, verify, and audit student credentials, awards, and certifications',
                    actions: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AcadexColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                          elevation: 0,
                        ),
                        icon: const Icon(LucideIcons.fileCheck, size: 16),
                        label: Text('Review Requests', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        onPressed: () => context.go('/certificates/requests'),
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
                    data: (certs) => _FacultySummaryCards(certs: certs),
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
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by student name, roll number, title, or issuer...',
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
                      const SizedBox(height: 12),
                      _FacultyFilterChips(
                        filter: filter,
                        onChanged: (f) => ref.read(certificateFilterProvider.notifier).state = f,
                      ),
                    ],
                  ),
                ),
              ),

              // Certificate List
              certsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: AcadexLoadingState(message: 'Loading departmental certificates...'),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: AcadexErrorState(
                    title: 'Failed to load department certificates',
                    message: e.toString(),
                    onRetry: () => ref.invalidate(facultyCertificatesProvider),
                  ),
                ),
                data: (certs) {
                  if (certs.isEmpty) {
                    final hasFilter = filter.isActive || query.isNotEmpty;
                    return SliverFillRemaining(
                      child: AcadexEmptyState(
                        icon: hasFilter ? LucideIcons.filterX : LucideIcons.award,
                        title: hasFilter ? 'No matching certificates' : 'No student certificates found',
                        subtitle: hasFilter
                            ? 'No student submissions matched your search or category filters.'
                            : 'Students in your department have not uploaded any certificates yet.',
                        actionLabel: hasFilter ? 'Clear Filters' : null,
                        onActionTap: hasFilter
                            ? () {
                                ref.read(certificateSearchQueryProvider.notifier).state = '';
                                ref.read(certificateFilterProvider.notifier).state = const CertificateFilter();
                              }
                            : null,
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 60),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final c = certs[i];
                          return CertificateCard(
                            certificate: c,
                            showStudentName: true,
                            onTap: () => context.go('/certificates/detail/${c.id}'),
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
}

class _FacultySummaryCards extends StatelessWidget {
  final List<Certificate> certs;
  const _FacultySummaryCards({required this.certs});

  @override
  Widget build(BuildContext context) {
    final total = certs.length;
    final verified = certs.where((c) => c.isVerified || c.status == CertificateStatus.verified).length;
    final pending = certs.where((c) => !c.isVerified && c.status != CertificateStatus.archived).length;
    final studentCount = certs.map((c) => c.studentId).toSet().length;

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
              _MetricCard(label: 'Total Submissions', value: total.toString(), icon: LucideIcons.files, color: AcadexColors.primary),
              _MetricCard(label: 'Pending Review', value: pending.toString(), icon: LucideIcons.clock, color: AcadexColors.warning),
              _MetricCard(label: 'Verified Records', value: verified.toString(), icon: LucideIcons.badgeCheck, color: AcadexColors.success),
              _MetricCard(label: 'Students Active', value: studentCount.toString(), icon: LucideIcons.users, color: AcadexColors.accentPurple),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _MetricCard(label: 'Total Submissions', value: total.toString(), icon: LucideIcons.files, color: AcadexColors.primary)),
            const SizedBox(width: 14),
            Expanded(child: _MetricCard(label: 'Pending Review', value: pending.toString(), icon: LucideIcons.clock, color: AcadexColors.warning)),
            const SizedBox(width: 14),
            Expanded(child: _MetricCard(label: 'Verified Records', value: verified.toString(), icon: LucideIcons.badgeCheck, color: AcadexColors.success)),
            const SizedBox(width: 14),
            Expanded(child: _MetricCard(label: 'Unique Students', value: studentCount.toString(), icon: LucideIcons.users, color: AcadexColors.accentPurple)),
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

class _FacultyFilterChips extends StatelessWidget {
  final CertificateFilter filter;
  final ValueChanged<CertificateFilter> onChanged;

  const _FacultyFilterChips({required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FacultyChip(
            label: 'All',
            isSelected: filter.type == null && filter.isVerified == null,
            onTap: () => onChanged(const CertificateFilter()),
          ),
          const SizedBox(width: 8),
          _FacultyChip(
            label: 'Pending Verification',
            isSelected: filter.isVerified == false,
            onTap: () => onChanged(filter.copyWith(isVerified: filter.isVerified == false ? null : false)),
          ),
          const SizedBox(width: 8),
          _FacultyChip(
            label: 'Verified ✓',
            isSelected: filter.isVerified == true,
            onTap: () => onChanged(filter.copyWith(isVerified: filter.isVerified == true ? null : true)),
          ),
          const SizedBox(width: 8),
          ...CertificateType.values.map((t) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FacultyChip(
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

class _FacultyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FacultyChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AcadexRadius.full),
      child: AnimatedContainer(
        duration: AcadexMotion.micro,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AcadexColors.primary
              : (Theme.of(context).brightness == Brightness.dark ? AcadexColors.darkSurface : AcadexColors.surface),
          borderRadius: BorderRadius.circular(AcadexRadius.full),
          border: Border.all(
            color: isSelected
                ? AcadexColors.primary
                : (Theme.of(context).brightness == Brightness.dark ? AcadexColors.darkHairline : AcadexColors.hairline),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (Theme.of(context).brightness == Brightness.dark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary),
          ),
        ),
      ),
    );
  }
}
