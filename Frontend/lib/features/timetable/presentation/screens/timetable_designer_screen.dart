import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_lookup_providers.dart';
import '../providers/timetable_authoring_providers.dart';
import '../widgets/timetable_spreadsheet_grid.dart';

class TimetableDesignerScreen extends ConsumerStatefulWidget {
  final String timetableId;

  const TimetableDesignerScreen({
    super.key,
    required this.timetableId,
  });

  @override
  ConsumerState<TimetableDesignerScreen> createState() => _TimetableDesignerScreenState();
}

class _TimetableDesignerScreenState extends ConsumerState<TimetableDesignerScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);

    final authoringState = ref.watch(timetableAuthoringProvider(widget.timetableId));
    final permissions = ref.watch(timetableAuthoringPermissionsProvider(authoringState.container));

    // Lookups for descriptive context
    final deptMap = ref.watch(timetableDepartmentMapProvider);
    final courseMap = ref.watch(timetableCourseMapProvider);
    final sectionMap = ref.watch(timetableSectionMapProvider);

    // 1. Loading State
    if (authoringState.container == null && authoringState.errorMessage == null) {
      return Scaffold(
        backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 2. Error State (Failed initial load)
    if (authoringState.errorMessage != null && authoringState.container == null) {
      return Scaffold(
        backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertTriangle, size: 48, color: AcadexColors.error),
              const SizedBox(height: 16),
              Text(
                'Error Loading Timetable',
                style: AcadexTypography.heading2(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                authoringState.errorMessage!,
                style: AcadexTypography.bodySmall(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(timetableAuthoringProvider(widget.timetableId).notifier).loadTimetable(widget.timetableId),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final container = authoringState.container;
    if (container == null) {
      return Scaffold(
        backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        body: const Center(child: Text('Timetable not found.')),
      );
    }

    // Resolve context names
    final deptName = deptMap[container.departmentId]?.name ?? container.departmentId;
    final courseName = courseMap[container.courseId]?.name ?? container.courseId;
    final sectionName = sectionMap[container.sectionId]?.name ?? container.sectionId;
    final subtitle = '$deptName • $courseName • Sem ${container.semesterId} • Sec $sectionName • v${container.version}';

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // =============================================================
            // 1. PAGE HEADER & TIMETABLE CONTEXT
            // =============================================================
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 12 : 20,
                isMobile ? 16 : 24,
                0,
              ),
              child: AcadexPageHeader(
                title: container.name,
                subtitle: subtitle,
                onBack: () => Navigator.of(context).maybePop(),
                actions: [
                  // Status Badge
                  _buildStatusBadge(container.status, isDark),

                  // Actions only for authorized roles (College Admin, HOD, Delegated Faculty)
                  if (permissions.canEdit) ...[
                    // Save Draft Button
                    ElevatedButton.icon(
                      onPressed: authoringState.isSaving
                          ? null
                          : () async {
                              final success = await ref.read(timetableAuthoringProvider(widget.timetableId).notifier).saveDraft();
                              if (context.mounted && success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Timetable draft saved successfully!')),
                                );
                              }
                            },
                      icon: authoringState.isSaving
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(LucideIcons.save, size: 16, color: authoringState.isDirty ? AcadexColors.primary : AcadexColors.inkMuted),
                      label: Text(
                        authoringState.isSaving ? 'Saving...' : 'Save Draft',
                        style: AcadexTypography.bodySmall(
                          color: authoringState.isDirty ? AcadexColors.primary : (isDark ? AcadexColors.darkInk : AcadexColors.ink),
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                        side: BorderSide(
                          color: authoringState.isDirty ? AcadexColors.primary : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                          width: authoringState.isDirty ? 1.5 : 1.0,
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],

                  if (permissions.canPublish) ...[
                    // Publish Button
                    ElevatedButton.icon(
                      onPressed: authoringState.isPublishing
                          ? null
                          : () async {
                              final success = await ref.read(timetableAuthoringProvider(widget.timetableId).notifier).publish(publishedBy: 'current-user');
                              if (context.mounted && success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Timetable published to live schedule!')),
                                );
                              }
                            },
                      icon: authoringState.isPublishing
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(LucideIcons.send, size: 16, color: Colors.white),
                      label: Text(
                        authoringState.isPublishing ? 'Publishing...' : 'Publish',
                        style: AcadexTypography.bodySmall(color: Colors.white).copyWith(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AcadexColors.primary,
                        elevation: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // =============================================================
            // 2. GRID TOOLBAR & STATUS BANNERS
            // =============================================================
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 8,
              ),
              child: _buildGridToolbar(context, isDark: isDark, authoringState: authoringState, permissions: permissions),
            ),

            // Validation or Error Banner if present
            if (authoringState.validationErrors.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 4),
                child: _buildValidationBanner(authoringState.validationErrors, isDark),
              ),

            // =============================================================
            // 3. SPREADSHEET GRID BODY
            // =============================================================
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  8,
                  isMobile ? 16 : 24,
                  16,
                ),
                child: TimetableSpreadsheetGrid(
                  authoringState: authoringState,
                  permissions: permissions,
                  onCellTap: (day, periodIndex) {
                    ref.read(timetableAuthoringProvider(widget.timetableId).notifier).selectCell(day, periodIndex);
                  },
                  onEntryTap: (entry) {
                    ref.read(timetableAuthoringProvider(widget.timetableId).notifier).selectEntry(entry.id);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // STATUS BADGE WIDGET
  // =========================================================================
  Widget _buildStatusBadge(TimetableStatus status, bool isDark) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case TimetableStatus.draft:
        bg = isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight;
        fg = isDark ? AcadexColors.warning : AcadexColors.warningDark;
        icon = LucideIcons.fileEdit;
        break;
      case TimetableStatus.published:
        bg = isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight;
        fg = isDark ? AcadexColors.success : AcadexColors.successDark;
        icon = LucideIcons.checkCircle2;
        break;
      case TimetableStatus.archived:
        bg = isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft;
        fg = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;
        icon = LucideIcons.archive;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AcadexRadius.borderRadiusSm,
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            status.displayName.toUpperCase(),
            style: AcadexTypography.caption(color: fg).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // GRID TOOLBAR WIDGET
  // =========================================================================
  Widget _buildGridToolbar(
    BuildContext context, {
    required bool isDark,
    required TimetableAuthoringState authoringState,
    required TimetableAuthoringPermissions permissions,
  }) {
    final container = authoringState.container;
    final activeDaysCount = container?.activeDays.length ?? 0;
    final periodsCount = authoringState.periods.length;
    final timingModeName = container?.timingMode.displayName ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: View Mode & Context Badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                  borderRadius: AcadexRadius.borderRadiusXs,
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.table, size: 14, color: AcadexColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Spreadsheet Grid',
                      style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$activeDaysCount Days • $periodsCount Periods • $timingModeName',
                style: AcadexTypography.caption(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
            ],
          ),

          // Right: Unsaved changes indicator
          if (authoringState.isDirty)
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AcadexColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Unsaved Changes',
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.warning : AcadexColors.warningDark,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // VALIDATION BANNER WIDGET
  // =========================================================================
  Widget _buildValidationBanner(List<String> errors, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.errorDarkContainer : AcadexColors.errorLight,
        borderRadius: AcadexRadius.borderRadiusSm,
        border: Border.all(color: AcadexColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, size: 16, color: AcadexColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errors.first,
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInk : AcadexColors.errorDark,
              ).copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (errors.length > 1)
            Text(
              '+${errors.length - 1} more',
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.errorDark,
              ).copyWith(fontSize: 10),
            ),
        ],
      ),
    );
  }
}
