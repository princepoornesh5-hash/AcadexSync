import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_request_model.dart';
import 'package:campus_management/features/certificates/presentation/providers/certificate_request_providers.dart';

class CertificateRequestsDashboardScreen extends ConsumerWidget {
  const CertificateRequestsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final user = authState.user;
    final isStudent = user.role == AppRole.student;
    
    // Faculty don't generally handle certificate requests unless specified.
    // If they do, they see empty for now based on providers.
    if (user.role == AppRole.faculty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Certificates')),
        body: const Center(child: Text('No certificate workflows available for faculty at this time.')),
      );
    }

    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        title: Text(isStudent ? 'My Requests' : 'Certificate Requests', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
        backgroundColor: DashboardColors.surface,
        iconTheme: const IconThemeData(color: DashboardColors.textPrimary),
      ),
      floatingActionButton: isStudent
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/certificates/requests/new'),
              icon: const Icon(LucideIcons.filePlus2, color: Colors.white),
              label: Text('New Request', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
              backgroundColor: DashboardColors.primary,
            )
          : null,
      body: Column(
        children: [
          _buildFilters(context, ref, isStudent),
          Expanded(
            child: _RequestsList(isStudent: isStudent),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, bool isStudent) {
    final filters = ref.watch(certificateRequestFilterProvider);
    final typesAsync = ref.watch(certificateTypesProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      color: DashboardColors.surface,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: isStudent ? 'Search by certificate type...' : 'Search by student ID or type...',
              prefixIcon: const Icon(LucideIcons.search, size: 20, color: DashboardColors.textSecondary),
              filled: true,
              fillColor: DashboardColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              ref.read(certificateRequestFilterProvider.notifier).state = filters.copyWith(searchQuery: val);
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip<CertificateRequestStatus?>(
                  label: 'All Statuses',
                  value: filters.status,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Statuses')),
                    ...CertificateRequestStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))),
                  ],
                  onChanged: (val) {
                    ref.read(certificateRequestFilterProvider.notifier).state = filters.copyWith(status: val, clearStatus: val == null);
                  },
                ),
                const SizedBox(width: 8),
                typesAsync.maybeWhen(
                  data: (types) => _FilterChip<String?>(
                    label: 'All Types',
                    value: filters.certificateTypeId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Types')),
                      ...types.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                    ],
                    onChanged: (val) {
                      ref.read(certificateRequestFilterProvider.notifier).state = filters.copyWith(certificateTypeId: val, clearType: val == null);
                    },
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: DashboardColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(label, style: GoogleFonts.inter(fontSize: 13, color: DashboardColors.textSecondary)),
          items: items,
          onChanged: onChanged,
          icon: const Icon(LucideIcons.chevronDown, size: 16, color: DashboardColors.textSecondary),
          style: GoogleFonts.inter(fontSize: 13, color: DashboardColors.textPrimary),
          isDense: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
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
    final requestsAsync = ref.watch(filteredCertificateRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.inbox, size: 64, color: DashboardColors.textSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(
                  isStudent ? 'You haven\'t submitted any certificate requests.' : 'No certificate requests found.',
                  style: GoogleFonts.inter(fontSize: 16, color: DashboardColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16).copyWith(bottom: 80),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return _RequestCard(request: req, isStudent: isStudent);
          },
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final CertificateRequest request;
  final bool isStudent;

  const _RequestCard({required this.request, required this.isStudent});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: DashboardColors.border),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () => context.go('/certificates/requests/${request.id}', extra: request),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: DashboardColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.fileText, color: DashboardColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.certificateTypeName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: DashboardColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isStudent) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Student: ${request.studentId}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: DashboardColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${request.id.length > 8 ? request.id.substring(0,8) : request.id}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: DashboardColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(request.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.calendar, size: 14, color: DashboardColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Requested ${timeago.format(request.requestedAt)}',
                        style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.textMuted),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(LucideIcons.clock, size: 14, color: DashboardColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Updated ${timeago.format(request.updatedAt)}',
                        style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(CertificateRequestStatus status) {
    Color color;
    switch (status) {
      case CertificateRequestStatus.approved:
      case CertificateRequestStatus.ready:
      case CertificateRequestStatus.completed:
        color = DashboardColors.success;
        break;
      case CertificateRequestStatus.pending:
      case CertificateRequestStatus.underReview:
        color = DashboardColors.warning;
        break;
      case CertificateRequestStatus.rejected:
      case CertificateRequestStatus.cancelled:
        color = DashboardColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.displayName,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
