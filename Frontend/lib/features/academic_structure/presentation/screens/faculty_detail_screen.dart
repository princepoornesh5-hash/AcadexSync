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
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/academic_providers.dart';
import '../../domain/models/academic_models.dart';

class FacultyDetailScreen extends ConsumerWidget {
  final String facultyId;

  const FacultyDetailScreen({super.key, required this.facultyId});

  void _showTransferDialog(BuildContext context, WidgetRef ref, Faculty faculty, List<Department> allDepts) {
    final availableDepts = allDepts.where((d) => d.isActive && d.id != faculty.departmentId).toList();

    if (availableDepts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other active departments available to transfer this faculty member to.'),
          backgroundColor: AcadexColors.warning,
        ),
      );
      return;
    }

    String? selectedDeptId = availableDepts.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Transfer Faculty to Another Department'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select the destination department for ${faculty.name}.',
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
                  await ref.read(apiAcademicRepositoryProvider).transferFacultyDepartment(facultyId, selectedDeptId!);
                  ref.invalidate(facultyByIdProvider(facultyId));
                  ref.invalidate(facultySummaryProvider(facultyId));
                  ref.invalidate(facultyProvider(null));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Faculty successfully transferred to new department!'),
                        backgroundColor: AcadexColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceFirst('Exception: ', '')),
                        backgroundColor: AcadexColors.error,
                      ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);
    final facultyAsync = ref.watch(facultyByIdProvider(facultyId));
    final summaryAsync = ref.watch(facultySummaryProvider(facultyId));
    final deptsAsync = ref.watch(departmentsProvider);
    final authState = ref.watch(authProvider);

    AppRole userRole = AppRole.faculty;
    if (authState is AuthAuthenticated) {
      userRole = authState.user.role;
    }
    final canTransfer = userRole == AppRole.collegeAdmin || userRole == AppRole.superAdmin;

    final dateFormat = DateFormat('MMMM d, yyyy');
    final deptsList = deptsAsync.valueOrNull ?? <Department>[];
    final deptsMap = {for (final d in deptsList) d.id: d};
    final hasEnclosingScaffold = Scaffold.maybeOf(context) != null;

    final bodyContent = facultyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.circleAlert, color: AcadexColors.error, size: 36),
            const SizedBox(height: 12),
            Text('Error loading faculty profile: $err', style: const TextStyle(color: AcadexColors.error)),
            const SizedBox(height: 12),
            AcadexButton(
              label: 'Retry',
              onPressed: () => ref.invalidate(facultyByIdProvider(facultyId)),
            ),
          ],
        ),
      ),
      data: (faculty) {
        if (faculty == null) {
          return const Center(child: Text('Faculty profile not found'));
        }

        final dept = deptsMap[faculty.departmentId];
        final isPending = faculty.accountStatus == AccountStatus.pendingActivation;

        return AcadexPageContainer(
          backgroundColor: Colors.transparent,
          maxWidth: 960,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Header Card ──────────────────────────────────────
              _buildHeroCard(context, ref, isDark, isMobile, faculty, isPending, canTransfer, deptsList),
              const SizedBox(height: 20),

              // ── Department & Leadership Card ──────────────────────────
              _buildDepartmentCard(context, ref, isDark, faculty, dept, canTransfer, deptsList),
              const SizedBox(height: 20),

              // ── Professional Academic Details Card ────────────────────
              _buildProfessionalCard(isDark, faculty, dateFormat),
              const SizedBox(height: 20),

              // ── Contact & Account Details Card ────────────────────────
              _buildContactCard(isDark, faculty, isPending),
              const SizedBox(height: 20),

              // ── Summary Metrics Card ──────────────────────────────────
              _buildMetricsCard(isDark, summaryAsync),
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
          onPressed: () => context.safePop(fallbackRoute: '/academics/faculty'),
        ),
        title: Text(
          'Faculty Profile',
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
    Faculty faculty,
    bool isPending,
    bool canTransfer,
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
                  child: Icon(LucideIcons.graduationCap, color: AcadexColors.primary, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      faculty.name,
                      style: AcadexTypography.heading1(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (faculty.employeeId.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AcadexColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              faculty.employeeId,
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
                            faculty.designation ?? 'Assistant Professor',
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
                onPressed: () => context.push('/academics/faculty/edit/$facultyId'),
              ),
              if (canTransfer)
                AcadexButton(
                  label: 'Transfer Department',
                  icon: LucideIcons.arrowRightLeft,
                  variant: AcadexButtonVariant.secondary,
                  onPressed: () => _showTransferDialog(context, ref, faculty, allDepts),
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
    Faculty faculty,
    Department? dept,
    bool canTransfer,
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
              if (canTransfer)
                TextButton.icon(
                  icon: const Icon(LucideIcons.arrowRightLeft, size: 14),
                  label: const Text('Transfer', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showTransferDialog(context, ref, faculty, allDepts),
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

  Widget _buildProfessionalCard(
    bool isDark,
    Faculty faculty,
    DateFormat dateFormat,
  ) {
    return AcadexCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.briefcase, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              const SizedBox(width: 8),
              Text(
                'Academic & Professional Profile',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(isDark, LucideIcons.badgeCheck, 'Designation', faculty.designation ?? 'Assistant Professor'),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.bookMarked, 'Qualification', faculty.qualification?.isNotEmpty == true ? faculty.qualification! : 'Not specified'),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.sparkles, 'Specialization', faculty.specialization?.isNotEmpty == true ? faculty.specialization! : 'Not specified'),
          if (faculty.joiningDate != null) ...[
            const Divider(height: 16),
            _infoRow(isDark, LucideIcons.calendar, 'Joining Date', dateFormat.format(faculty.joiningDate!)),
          ],
        ],
      ),
    );
  }

  Widget _buildContactCard(
    bool isDark,
    Faculty faculty,
    bool isPending,
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
          _infoRow(isDark, LucideIcons.mail, 'Official Email', faculty.email),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.phone, 'Phone Number', faculty.phone.isNotEmpty ? faculty.phone : 'Not configured'),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.shieldCheck, 'Access Role', 'Faculty Member'),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.userCheck, 'Account Status', isPending ? 'Pending Activation' : 'Active'),
        ],
      ),
    );
  }

  Widget _buildMetricsCard(
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
                'Faculty Teaching Metrics',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          summaryAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
            error: (e, _) => Text('Metrics unavailable: $e', style: const TextStyle(color: AcadexColors.error)),
            data: (summary) {
              final sectionCount = summary['sectionCount'] ?? 0;
              final subjectCount = summary['subjectCount'] ?? 0;
              final assignmentCount = summary['assignmentCount'] ?? 0;

              return Row(
                children: [
                  Expanded(
                    child: _metricBox(isDark, LucideIcons.layers, "$sectionCount", "Enrolled Sections"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricBox(isDark, LucideIcons.bookOpen, "$subjectCount", "Assigned Subjects"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricBox(isDark, LucideIcons.calendarCheck, "$assignmentCount", "Active Allocations"),
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
