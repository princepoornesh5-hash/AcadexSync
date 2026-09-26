import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../providers/academic_providers.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';

class CollegeDetailScreen extends ConsumerWidget {
  final String collegeId;

  const CollegeDetailScreen({super.key, required this.collegeId});

  void _confirmStatusToggle(BuildContext context, WidgetRef ref, String collegeName, bool isCurrentlyActive) {
    final action = isCurrentlyActive ? 'Deactivate' : 'Activate';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action College?'),
        content: Text(
          isCurrentlyActive
              ? 'Are you sure you want to deactivate $collegeName? All administrators, faculty, and students will temporarily lose platform access.'
              : 'Are you sure you want to activate $collegeName? Users will regain platform access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyActive ? AcadexColors.error : AcadexColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(collegesProvider.notifier).toggleCollegeStatus(collegeId, !isCurrentlyActive);
                ref.invalidate(collegeByIdProvider(collegeId));
                ref.invalidate(collegeSummaryProvider(collegeId));
                if (context.mounted) {
                  AcadexSnackBar.showSuccess(
                    context,
                    'College $action successful!',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  AcadexSnackBar.showError(
                    context,
                    e,
                    fallbackMessage: 'Failed to update college status',
                  );
                }
              }
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);
    final collegeAsync = ref.watch(collegeByIdProvider(collegeId));
    final summaryAsync = ref.watch(collegeSummaryProvider(collegeId));
    final adminsAsync = ref.watch(collegeAdminsProvider(collegeId));

    final hasEnclosingScaffold = Scaffold.maybeOf(context) != null;

    final bodyContent = collegeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => AcadexErrorState.fromError(
        error: err,
        title: "Unable to load college details",
        onRetry: () => ref.invalidate(collegeByIdProvider(collegeId)),
      ),
      data: (college) {
        return AcadexPageContainer(
          maxWidth: 1080,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Header Card ──────────────────────────────────────
              _buildHeroCard(context, ref, isDark, isMobile, college),
              const SizedBox(height: 20),

              // ── Summary Metrics Grid ──────────────────────────────────
              _buildSummarySection(isDark, isMobile, summaryAsync),
              const SizedBox(height: 24),

              // ── Information & Administrators Row ──────────────────────
              if (isMobile) ...[
                _buildDetailsCard(context, isDark, college),
                const SizedBox(height: 20),
                _buildAdminsCard(context, ref, isDark, adminsAsync, college.name),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildDetailsCard(context, isDark, college)),
                    const SizedBox(width: 20),
                    Expanded(flex: 3, child: _buildAdminsCard(context, ref, isDark, adminsAsync, college.name)),
                  ],
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );

    if (hasEnclosingScaffold) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : Colors.white),
          onPressed: () => context.safePop(fallbackRoute: '/academics/colleges'),
        ),
        title: Text(
          'College Overview',
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : Colors.white,
          ).copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refreshCw, size: 18, color: isDark ? AcadexColors.darkInkMuted : const Color(0xFFCCE6FF)),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(collegeByIdProvider(collegeId));
              ref.invalidate(collegeSummaryProvider(collegeId));
              ref.invalidate(collegeAdminsProvider(collegeId));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    bool isMobile,
    dynamic college,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AcadexColors.primary.withValues(alpha: 0.12),
                  borderRadius: AcadexRadius.borderRadiusMd,
                ),
                child: const Icon(LucideIcons.building, color: AcadexColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      college.name,
                      style: AcadexTypography.heading1(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                            borderRadius: AcadexRadius.borderRadiusSm,
                          ),
                          child: Text(
                            'CODE: ${college.code}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: college.isActive ? AcadexColors.successLight : AcadexColors.errorLight,
                            borderRadius: AcadexRadius.borderRadiusFull,
                          ),
                          child: Text(
                            college.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: college.isActive ? AcadexColors.success : AcadexColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Action Buttons Bar
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AcadexButton(
                label: 'Add College Admin',
                icon: LucideIcons.userPlus,
                variant: AcadexButtonVariant.primary,
                onPressed: () => context.push('/academics/colleges/$collegeId/provision-admin'),
              ),
              AcadexButton(
                label: 'Edit Details',
                icon: LucideIcons.edit,
                variant: AcadexButtonVariant.secondary,
                onPressed: () => context.push('/academics/colleges/edit/$collegeId'),
              ),
              AcadexButton(
                label: college.isActive ? 'Deactivate' : 'Activate',
                icon: college.isActive ? LucideIcons.powerOff : LucideIcons.power,
                variant: AcadexButtonVariant.secondary,
                onPressed: () => _confirmStatusToggle(context, ref, college.name, college.isActive),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(
    bool isDark,
    bool isMobile,
    AsyncValue<Map<String, dynamic>> summaryAsync,
  ) {
    return summaryAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        if (summary.isEmpty) return const SizedBox.shrink();

        final items = [
          ('Departments', summary['departmentCount']?.toString() ?? '0', LucideIcons.layers, AcadexColors.primary),
          ('Admins', summary['collegeAdminCount']?.toString() ?? '0', LucideIcons.userCheck, AcadexColors.accentPurple),
          ('Faculty', summary['facultyCount']?.toString() ?? '0', LucideIcons.users, AcadexColors.accentTeal),
          ('Students', summary['studentCount']?.toString() ?? '0', LucideIcons.graduationCap, AcadexColors.success),
          ('Active Users', summary['activeUserCount']?.toString() ?? '0', LucideIcons.checkCircle, AcadexColors.info),
          ('Pending Invites', summary['pendingInvitationCount']?.toString() ?? '0', LucideIcons.clock, AcadexColors.accentOrange),
        ];

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 3 : 6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: isMobile ? 1.05 : 1.25,
          ),
          itemBuilder: (_, i) {
            final item = items[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                borderRadius: AcadexRadius.borderRadiusMd,
                border: Border.all(
                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.$3, size: 16, color: item.$4),
                  const SizedBox(height: 4),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                  Text(
                    item.$1,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailsCard(BuildContext context, bool isDark, dynamic college) {
    return AcadexCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.info, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              const SizedBox(width: 8),
              Text(
                'Campus Information',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(isDark, LucideIcons.user, 'Principal', college.principal),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.mail, 'Email', college.email),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.phone, 'Phone', college.phone),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.mapPin, 'Address', college.address),
        ],
      ),
    );
  }

  Widget _infoRow(bool isDark, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ).copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: AcadexTypography.body(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ).copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminsCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    AsyncValue<List<Map<String, dynamic>>> adminsAsync,
    String collegeName,
  ) {
    return AcadexCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.shieldCheck, size: 16, color: AcadexColors.accentPurple),
                  const SizedBox(width: 8),
                  Text(
                    'College Administrators',
                    style: AcadexTypography.body(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              TextButton.icon(
                icon: const Icon(LucideIcons.userPlus, size: 14),
                label: const Text('Add Admin', style: TextStyle(fontSize: 12)),
                onPressed: () => context.push('/academics/colleges/$collegeId/provision-admin'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          adminsAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: Row(
                children: [
                  const Icon(LucideIcons.circleAlert, size: 16, color: AcadexColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Failed to load administrators.',
                      style: AcadexTypography.caption(color: AcadexColors.error),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(collegeAdminsProvider(collegeId)),
                    child: const Text('Retry', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            data: (admins) {
              if (admins.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(LucideIcons.userX, size: 28, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                      const SizedBox(height: 8),
                      Text(
                        'No Administrators Provisioned',
                        style: AcadexTypography.body(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Provision an administrator to delegate academic management.',
                        textAlign: TextAlign.center,
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ).copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      AcadexButton(
                        label: 'Provision Admin',
                        icon: LucideIcons.userPlus,
                        variant: AcadexButtonVariant.secondary,
                        onPressed: () => context.push('/academics/colleges/$collegeId/provision-admin'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: admins.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, idx) {
                  final admin = admins[idx];
                  final name = admin['name']?.toString() ?? 'Administrator';
                  final instituteId = admin['instituteId']?.toString() ?? '';
                  final email = admin['email']?.toString() ?? '';
                  final status = admin['accountStatus']?.toString() ?? 'active';
                  final isActive = status.toUpperCase() == 'ACTIVE';

                  return Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AcadexColors.accentPurple.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'A',
                            style: const TextStyle(
                              color: AcadexColors.accentPurple,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AcadexTypography.body(
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'PIN: $instituteId${email.isNotEmpty ? ' • $email' : ''}',
                              style: AcadexTypography.caption(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ).copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? AcadexColors.successLight : AcadexColors.accentOrangeLight,
                          borderRadius: AcadexRadius.borderRadiusFull,
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Pending',
                          style: TextStyle(
                            color: isActive ? AcadexColors.success : AcadexColors.accentOrange,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
