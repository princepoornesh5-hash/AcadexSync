import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../providers/department_setup_provider.dart';

class DepartmentSetupCard extends ConsumerWidget {
  final String? departmentId;

  const DepartmentSetupCard({
    super.key,
    this.departmentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupAsync = ref.watch(departmentSetupProvider(departmentId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return setupAsync.when(
      loading: () => AcadexCard(
        backgroundColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AcadexColors.primary.withValues(alpha: 0.1),
                    borderRadius: AcadexRadius.borderRadiusMd,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 10,
              width: 140,
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (setupState) {
        final next = setupState.nextActionableMilestone;

        return AcadexCard(
          backgroundColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
          borderColor: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AcadexColors.primary.withValues(alpha: 0.12),
                          borderRadius: AcadexRadius.borderRadiusMd,
                        ),
                        child: const Icon(LucideIcons.compass, color: AcadexColors.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DEPARTMENT SETUP',
                            style: AcadexTypography.eyebrow(color: AcadexColors.primary).copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            setupState.departmentName,
                            style: AcadexTypography.bodyMedium(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ).copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                  AcadexBadge(
                    label: setupState.isComplete ? 'SETUP READY' : '${setupState.completedCount} / ${setupState.totalCount}',
                    variant: setupState.isComplete ? AcadexBadgeVariant.success : AcadexBadgeVariant.primary,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: setupState.progressRatio,
                  minHeight: 6,
                  backgroundColor: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    setupState.isComplete ? AcadexColors.success : AcadexColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Status and Next Step text
              if (setupState.isComplete) ...[
                Row(
                  children: [
                    const Icon(LucideIcons.checkCheck, size: 16, color: AcadexColors.success),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Academic structure ready. All 8 setup milestones active.',
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ] else if (next != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      next.isWaitingOnAdmin ? LucideIcons.clock : LucideIcons.arrowRightCircle,
                      size: 16,
                      color: next.isWaitingOnAdmin ? AcadexColors.warning : AcadexColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            next.isWaitingOnAdmin ? 'Waiting: College-wide Academic Year' : 'Next: ${next.actionLabel}',
                            style: AcadexTypography.caption(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            next.description,
                            style: AcadexTypography.caption(
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
              ],
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AcadexColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                      ),
                      icon: Icon(
                        setupState.isComplete ? LucideIcons.eye : LucideIcons.arrowRight,
                        size: 16,
                      ),
                      label: Text(
                        setupState.isComplete ? 'View Setup Details' : 'Continue Setup',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      onPressed: () {
                        context.push('/academics/setup${departmentId != null ? "?departmentId=$departmentId" : ""}');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
