import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../providers/academic_providers.dart';
import '../providers/department_setup_provider.dart';

class DepartmentSetupScreen extends ConsumerStatefulWidget {
  final String? initialDepartmentId;

  const DepartmentSetupScreen({
    super.key,
    this.initialDepartmentId,
  });

  @override
  ConsumerState<DepartmentSetupScreen> createState() => _DepartmentSetupScreenState();
}

class _DepartmentSetupScreenState extends ConsumerState<DepartmentSetupScreen> {
  String? _selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    _selectedDepartmentId = widget.initialDepartmentId;
  }

  void _handleContinueSetup(BuildContext context, SetupMilestone? nextMilestone) {
    if (nextMilestone == null) return;

    if (nextMilestone.isWaitingOnAdmin) {
      _showNotifyAdminDialog(context, nextMilestone);
      return;
    }

    if (nextMilestone.actionRoute != null && nextMilestone.actionRoute!.isNotEmpty) {
      context.push(nextMilestone.actionRoute!);
    }
  }

  void _showNotifyAdminDialog(BuildContext context, SetupMilestone milestone) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusLg),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AcadexColors.warning.withValues(alpha: 0.15),
                borderRadius: AcadexRadius.borderRadiusSm,
              ),
              child: const Icon(LucideIcons.bellRing, size: 20, color: AcadexColors.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Waiting for College Setup',
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              milestone.adminMessage ?? 'Academic Year is managed institution-wide by College Administration.',
              style: AcadexTypography.body(
                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A notification will be dispatched to your College Administrator requesting configuration of the active academic calendar.',
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
            ),
            icon: const Icon(LucideIcons.send, size: 16),
            label: const Text('Send Reminder'),
            onPressed: () {
              Navigator.of(ctx).pop();
              AcadexSnackBar.showSuccess(
                context,
                'College Administrator notified to configure Academic Year.',
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final setupAsync = ref.watch(departmentSetupProvider(_selectedDepartmentId));
    final departmentsAsync = ref.watch(departmentsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AcadexPageContainer(
      onRefresh: () async {
        ref.invalidate(departmentSetupProvider(_selectedDepartmentId));
        ref.invalidate(coursesProvider);
        ref.invalidate(academicYearsProvider);
        ref.invalidate(semestersProvider);
        ref.invalidate(sectionsProvider);
        ref.invalidate(subjectsProvider);
        ref.invalidate(facultyAssignmentsProvider);
      },
      child: setupAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: AcadexLoadingState(message: 'Calculating department setup progress...'),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: AcadexErrorState(
              message: 'Failed to calculate department setup state: $err',
              onRetry: () => ref.refresh(departmentSetupProvider(_selectedDepartmentId)),
            ),
          ),
        ),
        data: (setupState) {
          final next = setupState.nextActionableMilestone;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Navigation / Header
              _buildTopBar(context, setupState, departmentsAsync.valueOrNull ?? [], isDark),
              const SizedBox(height: 16),

              // Progress Overview Card
              _buildProgressOverviewCard(context, setupState, isDark),
              const SizedBox(height: 16),

              // Multi-course context notification if any (when context is still in progress)
              if (setupState.multiContextNotice != null && !setupState.isCurrentContextComplete) ...[
                _buildMultiContextBanner(context, setupState.multiContextNotice!, isDark),
                const SizedBox(height: 16),
              ],

              // Next Action Banner (or Completion Banner)
              if (setupState.isComplete || setupState.isCurrentContextComplete)
                _buildCompletionBanner(context, setupState, isDark)
              else if (next != null)
                _buildNextActionBanner(context, next, isDark),
              const SizedBox(height: 24),

              // Section Heading for Milestones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Setup Milestones',
                      style: AcadexTypography.heading3(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${setupState.completedCount} of ${setupState.totalCount} Complete',
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 8 Authoritative Milestone Cards
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: setupState.milestones.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final milestone = setupState.milestones[index];
                  final isCurrent = next?.id == milestone.id;
                  return _buildMilestoneCard(context, milestone, isCurrent, isDark);
                },
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    DepartmentSetupState setupState,
    List<dynamic> allDepartments,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    LucideIcons.arrowLeft,
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    size: 20,
                  ),
                  tooltip: 'Back to Academics',
                  onPressed: () => context.safePop(fallbackRoute: '/academics'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Department Setup',
                            style: AcadexTypography.heading2(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                          ),
                          if (setupState.isHod)
                            const AcadexBadge(
                              label: 'YOUR DEPARTMENT',
                              variant: AcadexBadgeVariant.primary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        setupState.departmentName,
                        style: AcadexTypography.body(
                          color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                        ).copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isMobile) ...[
                  AcadexButton(
                    label: 'Academic Structure',
                    icon: LucideIcons.layoutGrid,
                    variant: AcadexButtonVariant.secondary,
                    size: AcadexButtonSize.sm,
                    onPressed: () => context.push('/academics'),
                  ),
                ],
              ],
            ),
            if (isMobile) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: AcadexButton(
                  label: 'View All Structure',
                  icon: LucideIcons.layoutGrid,
                  variant: AcadexButtonVariant.ghost,
                  size: AcadexButtonSize.sm,
                  onPressed: () => context.push('/academics'),
                ),
              ),
            ],
            // Department Selector for College Admin / Super Admin
            if (setupState.canSwitchDepartment && allDepartments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(
                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: setupState.departmentId.isNotEmpty ? setupState.departmentId : null,
                    hint: const Text('Switch Department Context'),
                    items: allDepartments.map<DropdownMenuItem<String>>((d) {
                      return DropdownMenuItem<String>(
                        value: d.id as String,
                        child: Text(
                          '${d.name} (${d.code})',
                          style: AcadexTypography.body(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDepartmentId = val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildProgressOverviewCard(
    BuildContext context,
    DepartmentSetupState setupState,
    bool isDark,
  ) {
    return AcadexCard(
      backgroundColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AcadexColors.primary.withValues(alpha: 0.12),
                        borderRadius: AcadexRadius.borderRadiusMd,
                      ),
                      child: const Icon(LucideIcons.compass, color: AcadexColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Setup Progress',
                            style: AcadexTypography.heading3(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${setupState.completedCount} / ${setupState.totalCount} complete',
                            style: AcadexTypography.caption(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AcadexBadge(
                label: setupState.isComplete ? 'READY' : '${setupState.percentage}%',
                variant: setupState.isComplete ? AcadexBadgeVariant.success : AcadexBadgeVariant.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: setupState.progressRatio,
              minHeight: 8,
              backgroundColor: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
              valueColor: AlwaysStoppedAnimation<Color>(
                setupState.isComplete ? AcadexColors.success : AcadexColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextActionBanner(
    BuildContext context,
    SetupMilestone nextMilestone,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: nextMilestone.isWaitingOnAdmin
            ? (isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight)
            : (isDark ? AcadexColors.primary.withValues(alpha: 0.15) : AcadexColors.primaryLight),
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: nextMilestone.isWaitingOnAdmin
              ? AcadexColors.warning
              : AcadexColors.primary.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                nextMilestone.isWaitingOnAdmin ? LucideIcons.clock : LucideIcons.sparkles,
                size: 18,
                color: nextMilestone.isWaitingOnAdmin ? AcadexColors.warning : AcadexColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                nextMilestone.isWaitingOnAdmin ? 'WAITING ON COLLEGE ADMIN' : 'NEXT STEP',
                style: AcadexTypography.eyebrow(
                  color: nextMilestone.isWaitingOnAdmin ? AcadexColors.warningDark : AcadexColors.primary,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            nextMilestone.isWaitingOnAdmin
                ? (nextMilestone.adminMessage ?? 'Waiting for college-wide academic calendar setup.')
                : 'Configure ${nextMilestone.title} to continue building your department foundation.',
            style: AcadexTypography.bodyMedium(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            nextMilestone.description,
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: nextMilestone.isWaitingOnAdmin ? AcadexColors.warning : AcadexColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
            ),
            icon: Icon(
              nextMilestone.isWaitingOnAdmin ? LucideIcons.bellRing : LucideIcons.arrowRight,
              size: 16,
            ),
            label: Text(
              nextMilestone.isWaitingOnAdmin ? 'Notify College Admin' : 'Continue Setup',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            onPressed: () => _handleContinueSetup(context, nextMilestone),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionBanner(
    BuildContext context,
    DepartmentSetupState setupState,
    bool isDark,
  ) {
    final hasMultiRemaining = setupState.isCurrentContextComplete && !setupState.isDepartmentFullyConfigured;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasMultiRemaining
            ? (isDark ? AcadexColors.info.withValues(alpha: 0.15) : AcadexColors.infoLight)
            : (isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight),
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: hasMultiRemaining
              ? AcadexColors.info.withValues(alpha: 0.5)
              : AcadexColors.success.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: hasMultiRemaining ? AcadexColors.info : AcadexColors.success,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasMultiRemaining ? LucideIcons.layers : LucideIcons.check,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                hasMultiRemaining
                    ? 'CURRENT CONTEXT READY • REMAINING DEPARTMENT WORK'
                    : 'DEPARTMENT SETUP COMPLETE',
                style: AcadexTypography.eyebrow(
                  color: hasMultiRemaining ? AcadexColors.info : AcadexColors.successDark,
                ).copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            setupState.departmentName,
            style: AcadexTypography.heading3(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasMultiRemaining
                ? (setupState.multiContextNotice ??
                    'Primary course setup is complete. Additional programs in this department still require setup before complete academic readiness.')
                : 'Your academic structure is ready. Faculty can manage classes, students can access schedules, and attendance can be conducted for published timetable periods.',
            style: AcadexTypography.body(
              color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AcadexColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                ),
                icon: const Icon(LucideIcons.layoutGrid, size: 16),
                label: const Text('View Academic Structure', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                onPressed: () => context.push('/academics'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  side: BorderSide(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                ),
                icon: const Icon(LucideIcons.calendarClock, size: 16),
                label: const Text('View Timetable', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                onPressed: () => context.push('/timetable'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMultiContextBanner(BuildContext context, String notice, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.info.withValues(alpha: 0.15) : AcadexColors.infoLight,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(color: AcadexColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, size: 16, color: AcadexColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notice,
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(
    BuildContext context,
    SetupMilestone milestone,
    bool isCurrent,
    bool isDark,
  ) {
    Color cardBg;
    Color borderCol;
    Widget statusBadge;

    switch (milestone.status) {
      case SetupMilestoneStatus.completed:
        cardBg = isDark ? AcadexColors.darkSurfaceCard : Colors.white;
        borderCol = AcadexColors.success.withValues(alpha: 0.35);
        statusBadge = const AcadexBadge(
          label: 'COMPLETED',
          variant: AcadexBadgeVariant.success,
        );
        break;
      case SetupMilestoneStatus.ready:
        cardBg = isDark ? AcadexColors.darkSurfaceCard : Colors.white;
        borderCol = isCurrent ? AcadexColors.primary : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline);
        statusBadge = AcadexBadge(
          label: isCurrent ? 'CURRENT' : 'READY',
          variant: AcadexBadgeVariant.primary,
        );
        break;
      case SetupMilestoneStatus.waitingOnAdmin:
        cardBg = isDark ? AcadexColors.warningDarkContainer.withValues(alpha: 0.3) : AcadexColors.warningLight.withValues(alpha: 0.5);
        borderCol = AcadexColors.warning.withValues(alpha: 0.5);
        statusBadge = const AcadexBadge(
          label: 'WAITING FOR COLLEGE ADMIN',
          variant: AcadexBadgeVariant.warning,
        );
        break;
      case SetupMilestoneStatus.blocked:
        cardBg = isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft;
        borderCol = isDark ? AcadexColors.darkHairline : AcadexColors.hairline;
        statusBadge = const AcadexBadge(
          label: 'BLOCKED',
          variant: AcadexBadgeVariant.neutral,
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(color: borderCol, width: isCurrent ? 1.5 : 1),
        boxShadow: isCurrent ? AcadexShadows.lightSm : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step number circle or checkmark
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: milestone.isCompleted
                      ? AcadexColors.success
                      : (isCurrent
                          ? AcadexColors.primary
                          : (isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft)),
                  shape: BoxShape.circle,
                ),
                child: milestone.isCompleted
                    ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                    : Text(
                        '${milestone.stepNumber}',
                        style: TextStyle(
                          color: isCurrent ? Colors.white : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          milestone.title,
                          style: AcadexTypography.bodyMedium(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ).copyWith(
                            fontWeight: isCurrent || milestone.isCompleted ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                        statusBadge,
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      milestone.description,
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),
                    if (milestone.summaryDetail != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(LucideIcons.checkCheck, size: 13, color: AcadexColors.success),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              milestone.summaryDetail!,
                              style: AcadexTypography.caption(
                                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                              ).copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (milestone.isWaitingOnAdmin && milestone.adminMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        milestone.adminMessage!,
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.warning : AcadexColors.warningDark,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                    if (milestone.isBlocked && milestone.decision != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        milestone.decision!.explanation,
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action Buttons row
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 6,
              children: [
                if (milestone.isCompleted) ...[
                  TextButton.icon(
                    icon: const Icon(LucideIcons.eye, size: 14),
                    label: Text(milestone.viewLabel),
                    onPressed: () => context.push(milestone.viewRoute),
                  ),
                ] else if (milestone.isWaitingOnAdmin) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AcadexColors.warning,
                      side: const BorderSide(color: AcadexColors.warning),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                    ),
                    icon: const Icon(LucideIcons.bellRing, size: 14),
                    label: const Text('Notify College Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    onPressed: () => _showNotifyAdminDialog(context, milestone),
                  ),
                ] else if (milestone.isReady) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrent ? AcadexColors.primary : AcadexColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                    ),
                    icon: const Icon(LucideIcons.plus, size: 14),
                    label: Text(milestone.actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      if (milestone.actionRoute != null) {
                        context.push(milestone.actionRoute!);
                      }
                    },
                  ),
                ] else if (milestone.isBlocked) ...[
                  if (milestone.decision != null &&
                      milestone.decision!.canCurrentUserAct &&
                      milestone.decision!.actionRoute != null &&
                      milestone.decision!.actionLabel != null)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AcadexColors.primary,
                        side: const BorderSide(color: AcadexColors.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                      ),
                      icon: const Icon(LucideIcons.arrowRight, size: 14),
                      label: Text(
                        milestone.decision!.actionLabel!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => context.push(milestone.decision!.actionRoute!),
                    )
                  else
                    Text(
                      milestone.decision?.waitingReason ?? 'Prerequisites required',
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
