import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../auth/domain/models/user_model.dart';
import '../providers/academic_providers.dart';
import '../../domain/models/academic_models.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';

class HodDetailScreen extends ConsumerWidget {
  final String hodId;

  const HodDetailScreen({super.key, required this.hodId});

  void _showTransferDialog(BuildContext context, WidgetRef ref, UserModel hod, List<Department> allDepts) {
    final availableDepts = allDepts.where((d) => d.isActive && d.id != hod.departmentId).toList();

    if (availableDepts.isEmpty) {
      AcadexSnackBar.showWarning(
        context,
        'No other active departments available to transfer this HOD to.',
      );
      return;
    }

    String? selectedDeptId = availableDepts.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Transfer HOD to Another Department'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select the destination department for ${hod.name}. The destination department must not already have an active HOD.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedDeptId,
                decoration: const InputDecoration(labelText: 'Destination Department'),
                items: availableDepts
                    .map((d) => DropdownMenuItem(value: d.id, child: Text("${d.name} (${d.code})")))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedDeptId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AcadexColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (selectedDeptId == null) return;
                Navigator.of(ctx).pop();
                try {
                  await ref.read(hodsProvider.notifier).transferDepartment(hodId, selectedDeptId!);
                  ref.invalidate(hodByIdProvider(hodId));
                  ref.invalidate(hodSummaryProvider(hodId));
                  if (context.mounted) {
                    AcadexSnackBar.showSuccess(
                      context,
                      'HOD successfully transferred to new department!',
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    AcadexSnackBar.showError(
                      context,
                      e,
                      fallbackMessage: 'Failed to transfer HOD',
                    );
                  }
                }
              },
              child: const Text('Transfer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeactivateOrActivateDialog(BuildContext context, WidgetRef ref, UserModel hod) {
    final isActive = hod.accountStatus == AccountStatus.active;
    final actionText = isActive ? 'Deactivate' : 'Activate';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionText Department Head'),
        content: Text(
          isActive
              ? 'Are you sure you want to deactivate ${hod.name}? Deactivating will revoke active sessions, prevent login, and suspend administrative duties while safely preserving all historical academic records.'
              : 'Reactivate ${hod.name} as active Head of Department? This will allow them to login and manage department academics.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? AcadexColors.error : AcadexColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final newStatus = isActive ? 'DEACTIVATED' : 'ACTIVE';
                await ref.read(hodsProvider.notifier).updateStatus(hodId, newStatus);
                ref.invalidate(hodByIdProvider(hodId));
                ref.invalidate(hodSummaryProvider(hodId));
                if (context.mounted) {
                  AcadexSnackBar.showSuccess(
                    context,
                    'HOD account successfully ${isActive ? "deactivated" : "reactivated"}!',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  AcadexSnackBar.showError(
                    context,
                    e,
                    fallbackMessage: 'Failed to update HOD status',
                  );
                }
              }
            },
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  void _showUnassignDialog(BuildContext context, WidgetRef ref, UserModel hod) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove HOD Role'),
        content: Text(
          'Are you sure you want to remove ${hod.name} from the HOD role? They will be reassigned as Faculty and removed from department leadership. Historical attendance and records will remain completely intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(hodsProvider.notifier).unassignHod(hodId, newRole: 'FACULTY');
                if (context.mounted) {
                  AcadexSnackBar.showSuccess(
                    context,
                    'HOD assignment removed successfully. User reassigned to Faculty.',
                  );
                  context.safePop(fallbackRoute: '/academics/hods');
                }
              } catch (e) {
                if (context.mounted) {
                  AcadexSnackBar.showError(
                    context,
                    e,
                    fallbackMessage: 'Failed to remove HOD assignment',
                  );
                }
              }
            },
            child: const Text('Remove Assignment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);
    final hodAsync = ref.watch(hodByIdProvider(hodId));
    final summaryAsync = ref.watch(hodSummaryProvider(hodId));
    final deptsAsync = ref.watch(departmentsProvider);
    final dateFormat = DateFormat('MMMM d, yyyy');

    final deptsList = deptsAsync.valueOrNull ?? <Department>[];
    final deptsMap = {for (final d in deptsList) d.id: d};
    final hasEnclosingScaffold = Scaffold.maybeOf(context) != null;

    final bodyContent = hodAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => AcadexErrorState.fromError(
        error: err,
        title: "Unable to load HOD profile",
        onRetry: () => ref.invalidate(hodByIdProvider(hodId)),
      ),
      data: (hod) {
        final dept = deptsMap[hod.departmentId ?? ''];
        final isPending = hod.accountStatus == AccountStatus.pendingActivation;

        return AcadexPageContainer(
          backgroundColor: Colors.white,
          maxWidth: 960,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Header Card ──────────────────────────────────────
              _buildHeroCard(context, ref, isDark, isMobile, hod, isPending, deptsList),
              const SizedBox(height: 20),

              // ── Department & Leadership Card ──────────────────────────
              _buildDepartmentCard(context, ref, isDark, hod, dept, deptsList),
              const SizedBox(height: 20),

              // ── Contact & Account Details Card ────────────────────────
              _buildContactCard(isDark, hod, dateFormat),
              const SizedBox(height: 20),

              // ── Summary Metrics Card ──────────────────────────────────
              _buildMetricsCard(ref, isDark, summaryAsync),
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
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/academics/hods'),
        ),
        title: Text(
          'Department Head (HOD) Profile',
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
    UserModel hod,
    bool isPending,
    List<Department> allDepts,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AcadexColors.primary.withValues(alpha: 0.12),
                  borderRadius: AcadexRadius.borderRadiusMd,
                ),
                child: const Center(
                  child: Icon(LucideIcons.userCheck, color: AcadexColors.primary, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hod.name,
                      style: AcadexTypography.heading1(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AcadexColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            hod.instituteId ?? 'HOD',
                            style: const TextStyle(
                              color: AcadexColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "Head of Department",
                            style: TextStyle(
                              color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPending ? AcadexColors.warningLight : AcadexColors.successLight,
                            borderRadius: AcadexRadius.borderRadiusFull,
                          ),
                          child: Text(
                            isPending ? 'Pending Activation' : 'Active Account',
                            style: TextStyle(
                              color: isPending ? AcadexColors.warning : AcadexColors.success,
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
                label: 'Edit Profile',
                icon: LucideIcons.edit,
                variant: AcadexButtonVariant.primary,
                onPressed: () => context.push('/academics/hods/edit/$hodId'),
              ),
              AcadexButton(
                label: 'Transfer Department',
                icon: LucideIcons.arrowRightLeft,
                variant: AcadexButtonVariant.secondary,
                onPressed: () => _showTransferDialog(context, ref, hod, allDepts),
              ),
              AcadexButton(
                label: hod.accountStatus == AccountStatus.active ? 'Deactivate HOD' : 'Activate HOD',
                icon: hod.accountStatus == AccountStatus.active ? LucideIcons.userX : LucideIcons.userCheck,
                variant: hod.accountStatus == AccountStatus.active ? AcadexButtonVariant.danger : AcadexButtonVariant.secondary,
                onPressed: () => _showDeactivateOrActivateDialog(context, ref, hod),
              ),
              AcadexButton(
                label: 'Remove HOD Role',
                icon: LucideIcons.userMinus,
                variant: AcadexButtonVariant.secondary,
                onPressed: () => _showUnassignDialog(context, ref, hod),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    UserModel hod,
    Department? dept,
    List<Department> allDepts,
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
                  Icon(LucideIcons.building2, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                  const SizedBox(width: 8),
                  Text(
                    'Assigned Academic Department',
                    style: AcadexTypography.body(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              TextButton.icon(
                icon: const Icon(LucideIcons.arrowRightLeft, size: 14),
                label: const Text('Transfer', style: TextStyle(fontSize: 12)),
                onPressed: () => _showTransferDialog(context, ref, hod, allDepts),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow(
            isDark,
            LucideIcons.building2,
            'Department Name',
            dept != null ? "${dept.name} (${dept.code})" : "Unassigned Department",
          ),
          if (dept?.description.isNotEmpty == true) ...[
            const Divider(height: 16),
            _infoRow(
              isDark,
              LucideIcons.alignLeft,
              'Description',
              dept!.description,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactCard(
    bool isDark,
    UserModel hod,
    DateFormat dateFormat,
  ) {
    return AcadexCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.idCard, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              const SizedBox(width: 8),
              Text(
                'Contact & Account Credentials',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(isDark, LucideIcons.mail, 'Email Address', hod.email),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.phone, 'Phone Number', hod.phone ?? 'Not configured'),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.shieldCheck, 'Access Role', 'HOD (Head of Department)'),
          if (hod.createdAt != null) ...[
            const Divider(height: 16),
            _infoRow(isDark, LucideIcons.clock, 'Provisioned On', dateFormat.format(hod.createdAt!)),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsCard(
    WidgetRef ref,
    bool isDark,
    AsyncValue<Map<String, dynamic>> summaryAsync,
  ) {
    return AcadexCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.barChart2, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              const SizedBox(width: 8),
              Text(
                'Department Leadership Metrics',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          summaryAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(LucideIcons.circleAlert, size: 16, color: AcadexColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Department metrics are currently unavailable.',
                      style: AcadexTypography.caption(color: AcadexColors.error),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(hodSummaryProvider(hodId)),
                    child: const Text('Retry', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            data: (summary) {
              final facultyCount = summary['facultyCount'] ?? 0;
              final studentCount = summary['studentCount'] ?? 0;
              final subjectCount = summary['subjectCount'] ?? 0;

              return Row(
                children: [
                  Expanded(
                    child: _metricBox(isDark, LucideIcons.users, "$facultyCount", "Faculty Members"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricBox(isDark, LucideIcons.graduationCap, "$studentCount", "Enrolled Students"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricBox(isDark, LucideIcons.bookOpen, "$subjectCount", "Curriculum Courses"),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _metricBox(bool isDark, IconData icon, String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AcadexColors.primary),
          const SizedBox(height: 6),
          Text(
            count,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AcadexColors.inkMuted),
            textAlign: TextAlign.center,
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
          width: 140,
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
}
