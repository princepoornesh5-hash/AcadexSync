import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../features/auth/domain/models/auth_state.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/models/certificate_type.dart';
import '../providers/certificate_providers.dart';
import '../widgets/certificate_card.dart';
import 'certificate_detail_screen.dart';
import 'upload_certificate_screen.dart';

class StudentCertificateDashboard extends ConsumerWidget {
  const StudentCertificateDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certsAsync = ref.watch(filteredStudentCertificatesProvider);
    final allCertsAsync = ref.watch(studentCertificatesProvider);
    final query = ref.watch(certificateSearchQueryProvider);
    final filter = ref.watch(certificateFilterProvider);

    return Scaffold(
      backgroundColor: DashboardColors.background,
      body: CustomScrollView(
        slivers: [
          // Stats header
          SliverToBoxAdapter(child: allCertsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (certs) => _StatsHeader(certs: certs),
          )),

          // Search & filter bar
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search certificates...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  filled: true,
                  fillColor: DashboardColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DashboardColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DashboardColors.border)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: query.isNotEmpty
                    ? IconButton(icon: const Icon(LucideIcons.x, size: 16), onPressed: () => ref.read(certificateSearchQueryProvider.notifier).state = '')
                    : null,
                ),
                onChanged: (v) => ref.read(certificateSearchQueryProvider.notifier).state = v,
              ),
              const SizedBox(height: 8),
              _FilterChips(filter: filter, onChanged: (f) => ref.read(certificateFilterProvider.notifier).state = f),
            ]),
          )),

          // Certificate list
          certsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (certs) {
              if (certs.isEmpty) {
                return SliverFillRemaining(child: _EmptyState(hasFilter: filter.isActive || query.isNotEmpty));
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final c = certs[i];
                      return CertificateCard(
                        certificate: c,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => CertificateDetailScreen(certificateId: c.id),
                        )).then((_) => ref.invalidate(studentCertificatesProvider)),
                        onEdit: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => UploadCertificateScreen(existing: c),
                        )).then((_) => ref.invalidate(studentCertificatesProvider)),
                        onDelete: () async {
                          final authState = ref.read(authProvider);
                          if (authState is! AuthAuthenticated) return;
                          final user = authState.user;
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Remove Certificate'),
                              content: Text('Remove "${c.title}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: DashboardColors.error),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await ref.read(certificateRepositoryProvider).deleteCertificate(c.id, user.firebaseUid ?? user.id);
                            ref.invalidate(studentCertificatesProvider);
                          }
                        },
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DashboardColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Upload Certificate'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UploadCertificateScreen()),
        ).then((_) => ref.invalidate(studentCertificatesProvider)),
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final List certs;
  const _StatsHeader({required this.certs});

  @override
  Widget build(BuildContext context) {
    final total = certs.length;
    final verified = certs.where((c) => c.isVerified == true).length;
    final pending = certs.where((c) => !c.isVerified).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Certificates', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _Stat('Total', '$total', DashboardColors.primary, DashboardColors.primaryLight)),
            const SizedBox(width: 12),
            Expanded(child: _Stat('Verified', '$verified', DashboardColors.success, DashboardColors.successLight)),
            const SizedBox(width: 12),
            Expanded(child: _Stat('Pending', '$pending', DashboardColors.warning, DashboardColors.warningLight)),
          ]),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  const _Stat(this.label, this.value, this.color, this.bg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.inter(fontSize: 12, color: color.withValues(alpha: 0.8))),
    ]),
  );
}

class _FilterChips extends StatelessWidget {
  final CertificateFilter filter;
  final void Function(CertificateFilter) onChanged;
  const _FilterChips({required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _chip('All', filter.type == null && filter.isVerified == null, () => onChanged(const CertificateFilter())),
        ...CertificateType.values.map((t) => _chip(t.displayName, filter.type == t,
          () => onChanged(CertificateFilter(type: filter.type == t ? null : t)))),
        _chip('Verified ✓', filter.isVerified == true,
          () => onChanged(CertificateFilter(type: filter.type, isVerified: filter.isVerified == true ? null : true))),
      ]),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? DashboardColors.primary : DashboardColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? DashboardColors.primary : DashboardColors.border),
        ),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : DashboardColors.textSecondary,
        )),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(hasFilter ? LucideIcons.searchX : LucideIcons.award, size: 64, color: DashboardColors.textMuted),
        const SizedBox(height: 16),
        Text(
          hasFilter ? 'No certificates match your filters' : 'No certificates yet',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          hasFilter ? 'Try adjusting your search or filters.' : 'Upload your first certificate to get started.',
          style: GoogleFonts.inter(fontSize: 14, color: DashboardColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ]),
    ),
  );
}
