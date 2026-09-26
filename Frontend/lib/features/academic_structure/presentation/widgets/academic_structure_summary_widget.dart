import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/academic_providers.dart';

class AcademicStructureSummaryWidget extends ConsumerWidget {
  final String? departmentId;
  const AcademicStructureSummaryWidget({super.key, this.departmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentYear = ref.watch(currentAcademicYearProvider);
    final sections = ref.watch(sectionsProvider).valueOrNull ?? [];
    final semesters = ref.watch(semestersProvider).valueOrNull ?? [];
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isHod = user?.role == AppRole.hod;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeSections = sections.where((s) {
      if (departmentId != null && departmentId!.isNotEmpty && s.departmentId != departmentId) return false;
      return s.isActive;
    }).toList();

    final activeSemesters = semesters.where((s) {
      if (departmentId != null && departmentId!.isNotEmpty && s.departmentId != departmentId) return false;
      return s.isCurrent || s.status == 'active';
    }).toList();

    final totalCapacity = activeSections.fold<int>(0, (sum, s) => sum + s.capacity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: BorderRadius.circular(AcadexRadius.lg),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AcadexColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AcadexRadius.md),
                ),
                child: const Icon(LucideIcons.calendarDays, color: AcadexColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Academic Calendar & Structure",
                      style: AcadexTypography.heading3(color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentYear != null ? "Active Academic Year: ${currentYear.name}" : "No Active Academic Year Configured",
                      style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              if (currentYear != null) ...[
                const AcadexBadge(label: "ACTIVE SESSION", variant: AcadexBadgeVariant.success),
                const SizedBox(width: 8),
              ],
              if (isHod) ...[
                AcadexButton(
                  label: 'Department Setup',
                  icon: LucideIcons.compass,
                  size: AcadexButtonSize.sm,
                  variant: AcadexButtonVariant.secondary,
                  onPressed: () => context.push('/academics/setup'),
                ),
              ] else ...[
                AcadexButton(
                  label: 'Add Academic Year',
                  icon: LucideIcons.calendarPlus,
                  size: AcadexButtonSize.sm,
                  variant: currentYear == null ? AcadexButtonVariant.primary : AcadexButtonVariant.secondary,
                  onPressed: () => context.push('/academics/academic_years/new'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 550;
              if (isMobile) {
                return Column(
                  children: [
                    _buildMetricTile(
                      theme,
                      "Active Semesters",
                      "${activeSemesters.length} Semesters",
                      LucideIcons.calendarClock,
                      AcadexColors.secondary,
                    ),
                    const SizedBox(height: 8),
                    _buildMetricTile(
                      theme,
                      "Active Sections",
                      "${activeSections.length} Sections",
                      LucideIcons.users,
                      AcadexColors.primary,
                    ),
                    const SizedBox(height: 8),
                    _buildMetricTile(
                      theme,
                      "Seating Capacity",
                      "$totalCapacity Seats",
                      LucideIcons.layers,
                      AcadexColors.info,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      theme,
                      "Active Semesters",
                      "${activeSemesters.length} Semesters",
                      LucideIcons.calendarClock,
                      AcadexColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      theme,
                      "Active Sections",
                      "${activeSections.length} Sections",
                      LucideIcons.users,
                      AcadexColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      theme,
                      "Seating Capacity",
                      "$totalCapacity Seats",
                      LucideIcons.layers,
                      AcadexColors.info,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 2),
                Text(value, style: AcadexTypography.body(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
