import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/core/presentation/widgets/acadex_feedback.dart';
import 'package:campus_management/core/presentation/widgets/acadex_page_header.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_request_model.dart';
import 'package:campus_management/features/certificates/presentation/providers/certificate_request_providers.dart';

class CertificateRequestsDashboardScreen extends ConsumerWidget {
  const CertificateRequestsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final user = authState.user;
    final isStudent = user.role == AppRole.student;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: CustomScrollView(
            slivers: [
              // Page Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: AcadexPageHeader(
                    title: isStudent ? 'Official Certificate Requests' : 'Student Certificate Requests',
                    subtitle: isStudent
                        ? 'Request official institutional documents such as Bonafide, Study, and Transfer certificates'
                        : 'Review, approve, and track institutional certificate requests submitted by students',
                    actions: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          side: BorderSide(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                        ),
                        icon: const Icon(LucideIcons.award, size: 16),
                        label: Text(
                          'Certificates Portfolio',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ),
                        ),
                        onPressed: () => context.go('/certificates'),
                      ),
                      if (isStudent) ...[
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AcadexColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                            elevation: 0,
                          ),
                          icon: const Icon(LucideIcons.filePlus2, size: 16),
                          label: Text('New Request', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          onPressed: () => context.go('/certificates/requests/new'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Filter toolbar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: _RequestsFilterBar(isStudent: isStudent),
                ),
              ),

              // Requests List
              _RequestsList(isStudent: isStudent),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestsFilterBar extends ConsumerWidget {
  final bool isStudent;
  const _RequestsFilterBar({required this.isStudent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filters = ref.watch(certificateRequestFilterProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: BorderRadius.circular(AcadexRadius.lg),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: isStudent
                  ? 'Search by certificate type, purpose, or reason...'
                  : 'Search by student ID or certificate type...',
              prefixIcon: Icon(
                LucideIcons.search,
                size: 18,
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
              filled: true,
              fillColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvasSoft,
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
              suffixIcon: filters.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () => ref.read(certificateRequestFilterProvider.notifier).state =
                          filters.copyWith(searchQuery: ''),
                    )
                  : null,
            ),
            onChanged: (val) {
              ref.read(certificateRequestFilterProvider.notifier).state =
                  filters.copyWith(searchQuery: val);
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusFilterChip(
                  label: 'All Statuses',
                  isSelected: filters.status == null,
                  onTap: () => ref.read(certificateRequestFilterProvider.notifier).state =
                      filters.copyWith(clearStatus: true),
                ),
                const SizedBox(width: 8),
                ...CertificateRequestStatus.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _StatusFilterChip(
                        label: s.displayName,
                        isSelected: filters.status == s,
                        onTap: () => ref.read(certificateRequestFilterProvider.notifier).state =
                            filters.copyWith(status: filters.status == s ? null : s, clearStatus: filters.status == s),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusFilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AcadexColors.primary
              : (isDark ? AcadexColors.darkSurface : Colors.white),
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

class _RequestsList extends ConsumerWidget {
  final bool isStudent;
  const _RequestsList({required this.isStudent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final requestsAsync = ref.watch(filteredCertificateRequestsProvider);

    return requestsAsync.when(
      loading: () => const SliverFillRemaining(
        child: AcadexLoadingState(message: 'Loading certificate requests...'),
      ),
      error: (err, _) => SliverFillRemaining(
        child: AcadexErrorState(
          title: 'Failed to load requests',
          message: err.toString(),
          onRetry: () => ref.invalidate(filteredCertificateRequestsProvider),
        ),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return SliverFillRemaining(
            child: AcadexEmptyState(
              icon: LucideIcons.fileClock,
              title: isStudent ? 'No requests submitted' : 'No certificate requests',
              subtitle: isStudent
                  ? 'You have not submitted any official certificate requests. Click "New Request" to get started.'
                  : 'There are currently no student requests matching your search or filters.',
              actionLabel: isStudent ? 'Submit Request' : null,
              onActionTap: isStudent ? () => context.go('/certificates/requests/new') : null,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final req = requests[index];
                return _RequestItemCard(request: req, isStudent: isStudent, isDark: isDark);
              },
              childCount: requests.length,
            ),
          ),
        );
      },
    );
  }
}

class _RequestItemCard extends StatelessWidget {
  final CertificateRequest request;
  final bool isStudent;
  final bool isDark;

  const _RequestItemCard({
    required this.request,
    required this.isStudent,
    required this.isDark,
  });

  Color _statusColor(CertificateRequestStatus s) {
    switch (s) {
      case CertificateRequestStatus.pending:
        return AcadexColors.warning;
      case CertificateRequestStatus.underReview:
        return AcadexColors.info;
      case CertificateRequestStatus.approved:
        return AcadexColors.primary;
      case CertificateRequestStatus.rejected:
        return AcadexColors.error;
      case CertificateRequestStatus.ready:
        return AcadexColors.accentPurple;
      case CertificateRequestStatus.completed:
        return AcadexColors.success;
      case CertificateRequestStatus.cancelled:
        return AcadexColors.inkMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(request.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AcadexRadius.lg),
        child: InkWell(
          onTap: () => context.go('/certificates/requests/${request.id}', extra: request),
          borderRadius: BorderRadius.circular(AcadexRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.certificateTypeName,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                          ),
                          if (!isStudent) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Student ID: ${request.studentId}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? statusColor.withValues(alpha: 0.2) : statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AcadexRadius.full),
                        border: Border.all(
                          color: isDark ? statusColor.withValues(alpha: 0.4) : statusColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        request.status.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (request.purpose != null && request.purpose!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Purpose: ${request.purpose}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 13,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Requested ${timeago.format(request.requestedAt)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
