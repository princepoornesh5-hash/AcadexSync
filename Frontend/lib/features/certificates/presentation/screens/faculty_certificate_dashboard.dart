import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../features/auth/domain/models/auth_state.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/models/certificate_status.dart';
import '../../domain/models/certificate_type.dart';
import '../providers/certificate_providers.dart';
import '../widgets/certificate_card.dart';
import 'faculty_certificate_detail_screen.dart';

class FacultyCertificateDashboard extends ConsumerWidget {
  const FacultyCertificateDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final certsAsync = ref.watch(filteredFacultyCertificatesProvider);
    final allCertsAsync = ref.watch(facultyCertificatesProvider);
    final query = ref.watch(certificateSearchQueryProvider);
    final filter = ref.watch(certificateFilterProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }
    final user = authState.user;

    return Scaffold(
      backgroundColor: DashboardColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: allCertsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (certs) => _FacultyHeader(certs: certs, user: user),
          )),

          // Search & filter
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by student name, certificate title, issuer...',
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _chip(ref, 'All', filter.type == null && filter.isVerified == null, () => ref.read(certificateFilterProvider.notifier).state = const CertificateFilter()),
                  _chip(ref, 'Verified ✓', filter.isVerified == true, () => ref.read(certificateFilterProvider.notifier).state = CertificateFilter(type: filter.type, isVerified: filter.isVerified == true ? null : true)),
                  _chip(ref, 'Pending', filter.status == CertificateStatus.active, () => ref.read(certificateFilterProvider.notifier).state = CertificateFilter(status: filter.status == CertificateStatus.active ? null : CertificateStatus.active)),
                  ...CertificateType.values.map((t) => _chip(ref, t.displayName, filter.type == t, () => ref.read(certificateFilterProvider.notifier).state = CertificateFilter(type: filter.type == t ? null : t, isVerified: filter.isVerified))),
                ]),
              ),
            ]),
          )),

          // Certificate list
          certsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (certs) {
              if (certs.isEmpty) {
                return SliverFillRemaining(child: _FacultyEmptyState(hasFilter: filter.isActive || query.isNotEmpty));
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final c = certs[i];
                      return CertificateCard(
                        certificate: c,
                        showStudentName: true,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => FacultyCertificateDetailScreen(certificateId: c.id),
                        )).then((_) => ref.invalidate(facultyCertificatesProvider)),
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
    );
  }

  Widget _chip(WidgetRef ref, String label, bool selected, VoidCallback onTap) => Padding(
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
          fontSize: 12, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : DashboardColors.textSecondary,
        )),
      ),
    ),
  );
}

class _FacultyHeader extends StatelessWidget {
  final List certs;
  final UserModel user;
  const _FacultyHeader({required this.certs, required this.user});

  @override
  Widget build(BuildContext context) {
    final total = certs.length;
    final verified = certs.where((c) => c.isVerified == true).length;
    final pending = total - verified;
    final studentIds = certs.map((c) => c.studentId).toSet().length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Student Certificates', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary)),
        Text('Your authorized department scope', style: GoogleFonts.inter(fontSize: 13, color: DashboardColors.textSecondary)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _S('Students', '$studentIds', DashboardColors.purple, DashboardColors.purpleLight)),
          const SizedBox(width: 10),
          Expanded(child: _S('Total', '$total', DashboardColors.primary, DashboardColors.primaryLight)),
          const SizedBox(width: 10),
          Expanded(child: _S('Verified', '$verified', DashboardColors.success, DashboardColors.successLight)),
          const SizedBox(width: 10),
          Expanded(child: _S('Pending', '$pending', DashboardColors.warning, DashboardColors.warningLight)),
        ]),
      ]),
    );
  }
}

class _S extends StatelessWidget {
  final String label, value;
  final Color color, bg;
  const _S(this.label, this.value, this.color, this.bg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
    child: Column(children: [
      Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: GoogleFonts.inter(fontSize: 10, color: color.withValues(alpha: 0.8))),
    ]),
  );
}

class _FacultyEmptyState extends StatelessWidget {
  final bool hasFilter;
  const _FacultyEmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(hasFilter ? LucideIcons.searchX : LucideIcons.folder, size: 64, color: DashboardColors.textMuted),
      const SizedBox(height: 16),
      Text(
        hasFilter ? 'No certificates match your filters' : 'No student certificates in your scope',
        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary),
        textAlign: TextAlign.center,
      ),
    ]),
  );
}
