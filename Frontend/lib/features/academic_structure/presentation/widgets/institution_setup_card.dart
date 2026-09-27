import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../providers/academic_providers.dart';

class InstitutionSetupCard extends ConsumerWidget {
  const InstitutionSetupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final academicYearsAsync = ref.watch(academicYearsProvider);
    final departmentsAsync = ref.watch(departmentsProvider);
    final hodsAsync = ref.watch(hodsProvider);

    final academicYears = academicYearsAsync.valueOrNull ?? [];
    final departments = departmentsAsync.valueOrNull ?? [];
    final hods = hodsAsync.valueOrNull ?? [];

    final activeAy = academicYears.where((ay) => ay.isCurrent && ay.isActive).firstOrNull ??
        academicYears.where((ay) => ay.status == 'active' && ay.isActive).firstOrNull;

    final hasActiveAy = activeAy != null;
    final hasDepartments = departments.isNotEmpty;
    final hasHods = hods.isNotEmpty;

    final completedCount = (hasActiveAy ? 1 : 0) + (hasDepartments ? 1 : 0) + (hasHods ? 1 : 0);

    return AcadexCard(
      backgroundColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AcadexColors.primary.withValues(alpha: 0.1),
                  borderRadius: AcadexRadius.borderRadiusMd,
                ),
                child: const Icon(LucideIcons.building2, size: 20, color: AcadexColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Core Institution Setup',
                      style: AcadexTypography.heading3(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                    ),
                    Text(
                      'Foundational institution configuration: Academic Year, Departments, and HOD Leadership.',
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              AcadexBadge(
                label: '$completedCount / 3 COMPLETE',
                variant: completedCount == 3 ? AcadexBadgeVariant.success : AcadexBadgeVariant.neutral,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completedCount / 3.0,
              backgroundColor: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
              valueColor: AlwaysStoppedAnimation<Color>(
                completedCount == 3 ? AcadexColors.success : AcadexColors.primary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          // Step 1: Academic Year
          _buildSetupStep(
            context: context,
            isDark: isDark,
            stepNumber: 1,
            title: '1. Academic Year',
            subtitle: hasActiveAy
                ? 'Current operating period: ${activeAy.name}'
                : 'No active academic year configured',
            isComplete: hasActiveAy,
            actionLabel: hasActiveAy ? 'Manage' : 'Create & Activate',
            onAction: () => context.go('/academics/academic-years'),
          ),
          const Divider(height: 16, color: AcadexColors.hairline),
          // Step 2: Departments
          _buildSetupStep(
            context: context,
            isDark: isDark,
            stepNumber: 2,
            title: '2. Departments',
            subtitle: hasDepartments
                ? '${departments.length} department${departments.length == 1 ? '' : 's'} configured'
                : 'No departments created yet',
            isComplete: hasDepartments,
            actionLabel: hasDepartments ? 'Manage' : 'Create Department',
            onAction: () => context.go('/academics/departments'),
          ),
          const Divider(height: 16, color: AcadexColors.hairline),
          // Step 3: Assign HODs
          _buildSetupStep(
            context: context,
            isDark: isDark,
            stepNumber: 3,
            title: '3. Assign HODs',
            subtitle: hasHods
                ? '${hods.length} department head${hods.length == 1 ? '' : 's'} assigned'
                : 'Assign academic owners to lead each department',
            isComplete: hasHods,
            actionLabel: hasHods ? 'Manage' : 'Assign HODs',
            onAction: () => context.go('/academics/hods'),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkCanvas : AcadexColors.canvasSoft,
              borderRadius: AcadexRadius.borderRadiusSm,
              border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.info, size: 14, color: AcadexColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'After HODs are assigned, they own and manage their department\'s courses, faculty assignments, student enrollments, and timetables directly.',
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupStep({
    required BuildContext context,
    required bool isDark,
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isComplete,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isComplete ? LucideIcons.checkCircle2 : LucideIcons.circle,
            size: 20,
            color: isComplete ? AcadexColors.success : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AcadexTypography.body(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 32),
              side: BorderSide(
                color: isComplete ? AcadexColors.hairline : AcadexColors.primary,
              ),
            ),
            child: Text(
              actionLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isComplete
                    ? (isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary)
                    : AcadexColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
