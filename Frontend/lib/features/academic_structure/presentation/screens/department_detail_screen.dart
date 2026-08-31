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

class DepartmentDetailScreen extends ConsumerWidget {
  final String departmentId;

  const DepartmentDetailScreen({super.key, required this.departmentId});

  void _confirmStatusToggle(BuildContext context, WidgetRef ref, String departmentName, bool isCurrentlyActive) {
    final action = isCurrentlyActive ? 'Deactivate' : 'Activate';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Department?'),
        content: Text(
          isCurrentlyActive
              ? 'Are you sure you want to deactivate $departmentName? Faculty assignments and course operations may be restricted while inactive.'
              : 'Are you sure you want to activate $departmentName?',
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
                await ref.read(departmentsProvider.notifier).toggleDepartmentStatus(departmentId, !isCurrentlyActive);
                ref.invalidate(departmentByIdProvider(departmentId));
                ref.invalidate(departmentSummaryProvider(departmentId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Department $action successful!'),
                      backgroundColor: AcadexColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update status: $e'),
                      backgroundColor: AcadexColors.error,
                    ),
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
    final deptAsync = ref.watch(departmentByIdProvider(departmentId));
    final summaryAsync = ref.watch(departmentSummaryProvider(departmentId));
    final hodAsync = ref.watch(departmentHodProvider(departmentId));
    final hasEnclosingScaffold = Scaffold.maybeOf(context) != null;

    final bodyContent = deptAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.circleAlert, color: AcadexColors.error, size: 36),
            const SizedBox(height: 12),
            Text('Error loading department: $err', style: const TextStyle(color: AcadexColors.error)),
            const SizedBox(height: 12),
            AcadexButton(
              label: 'Retry',
              onPressed: () => ref.invalidate(departmentByIdProvider(departmentId)),
            ),
          ],
        ),
      ),
      data: (dept) {
        return AcadexPageContainer(
          backgroundColor: Colors.transparent,
          maxWidth: 1080,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Header Card ──────────────────────────────────────
              _buildHeroCard(context, ref, isDark, isMobile, dept),
              const SizedBox(height: 20),

                // ── Summary Metrics Grid ──────────────────────────────────
                _buildSummarySection(isDark, isMobile, summaryAsync),
                const SizedBox(height: 24),

                // ── Information & HOD Row ─────────────────────────────────
                if (isMobile) ...[
                  _buildDetailsCard(context, isDark, dept, summaryAsync),
                  const SizedBox(height: 20),
                  _buildHodCard(context, isDark, hodAsync),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildDetailsCard(context, isDark, dept, summaryAsync)),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: _buildHodCard(context, isDark, hodAsync)),
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/academics/departments'),
        ),
        title: Text(
          'Department Overview',
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontSize: 18),
        ),
      ),
      body: bodyContent,
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    bool isMobile,
    dynamic dept,
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
                child: const Icon(LucideIcons.layers, color: AcadexColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dept.name,
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
                            'CODE: ${dept.code}',
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
                            color: dept.isActive ? AcadexColors.successLight : AcadexColors.errorLight,
                            borderRadius: AcadexRadius.borderRadiusFull,
                          ),
                          child: Text(
                            dept.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: dept.isActive ? AcadexColors.success : AcadexColors.error,
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
          // Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AcadexButton(
                label: 'Edit Department',
                icon: LucideIcons.edit,
                variant: AcadexButtonVariant.primary,
                onPressed: () => context.push('/academics/departments/edit/$departmentId'),
              ),
              AcadexButton(
                label: dept.isActive ? 'Deactivate' : 'Activate',
                icon: dept.isActive ? LucideIcons.powerOff : LucideIcons.power,
                variant: AcadexButtonVariant.secondary,
                onPressed: () => _confirmStatusToggle(context, ref, dept.name, dept.isActive),
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
        height: 70,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        if (summary.isEmpty) return const SizedBox.shrink();

        final items = [
          ('Faculty', summary['facultyCount']?.toString() ?? '0', LucideIcons.users, AcadexColors.primary),
          ('Students', summary['studentCount']?.toString() ?? '0', LucideIcons.graduationCap, AcadexColors.success),
          ('Courses', summary['courseCount']?.toString() ?? '0', LucideIcons.bookOpen, AcadexColors.accentPurple),
          ('Active Users', summary['activeUserCount']?.toString() ?? '0', LucideIcons.checkCircle, AcadexColors.info),
        ];

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 2 : 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: isMobile ? 1.7 : 1.9,
          ),
          itemBuilder: (_, i) {
            final item = items[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                borderRadius: AcadexRadius.borderRadiusMd,
                border: Border.all(
                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.$4.withValues(alpha: 0.12),
                      borderRadius: AcadexRadius.borderRadiusSm,
                    ),
                    child: Icon(item.$3, size: 18, color: item.$4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                        ),
                        Text(
                          item.$1,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailsCard(
    BuildContext context,
    bool isDark,
    dynamic dept,
    AsyncValue<Map<String, dynamic>> summaryAsync,
  ) {
    final collegeName = summaryAsync.valueOrNull?['college']?['name']?.toString() ?? '';

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
                'Department Details',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(isDark, LucideIcons.tag, 'Code', dept.code),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.layers, 'Name', dept.name),
          if (collegeName.isNotEmpty) ...[
            const Divider(height: 16),
            _infoRow(isDark, LucideIcons.building, 'College', collegeName),
          ],
          const Divider(height: 16),
          _infoRow(
            isDark,
            LucideIcons.fileText,
            'Description',
            dept.description.isNotEmpty ? dept.description : 'No description provided.',
          ),
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
          width: 80,
          child: Text(
            label,
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ).copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AcadexTypography.body(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ).copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildHodCard(
    BuildContext context,
    bool isDark,
    AsyncValue<Map<String, dynamic>?> hodAsync,
  ) {
    return AcadexCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.shieldCheck, size: 16, color: AcadexColors.accentPurple),
              const SizedBox(width: 8),
              Text(
                'Head of Department (HOD)',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          hodAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Error loading HOD: $err', style: const TextStyle(color: AcadexColors.error, fontSize: 12)),
            ),
            data: (hod) {
              if (hod == null) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(LucideIcons.userX, size: 28, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                      const SizedBox(height: 8),
                      Text(
                        'No HOD Assigned',
                        style: AcadexTypography.body(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'An HOD can be provisioned to lead this academic department.',
                        textAlign: TextAlign.center,
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ).copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(LucideIcons.userPlus, size: 15),
                        label: const Text('Provision HOD', style: TextStyle(fontSize: 12)),
                        onPressed: () => context.push('/academics/hods/provision'),
                      ),
                    ],
                  ),
                );
              }

              final name = hod['name']?.toString() ?? 'HOD';
              final instituteId = hod['instituteId']?.toString() ?? '';
              final email = hod['email']?.toString() ?? '';
              final phone = hod['phone']?.toString() ?? '';
              final status = hod['accountStatus']?.toString() ?? 'active';
              final isActive = status.toUpperCase() == 'ACTIVE';
              final hodId = hod['id']?.toString() ?? hod['_id']?.toString() ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AcadexColors.accentPurple.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'H',
                            style: const TextStyle(
                              color: AcadexColors.accentPurple,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AcadexTypography.body(
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ).copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (instituteId.isNotEmpty)
                              Text(
                                'PIN: $instituteId',
                                style: AcadexTypography.caption(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  ),
                  if (email.isNotEmpty || phone.isNotEmpty) ...[
                    const Divider(height: 20),
                    if (email.isNotEmpty)
                      _infoRow(isDark, LucideIcons.mail, 'Email', email),
                    if (email.isNotEmpty && phone.isNotEmpty)
                      const SizedBox(height: 8),
                    if (phone.isNotEmpty)
                      _infoRow(isDark, LucideIcons.phone, 'Phone', phone),
                  ],
                  if (hodId.isNotEmpty) ...[
                    const Divider(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(LucideIcons.arrowRight, size: 14),
                        label: const Text('View HOD Profile', style: TextStyle(fontSize: 12)),
                        onPressed: () => context.push('/academics/hods/$hodId'),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
