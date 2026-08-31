import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_lookup_providers.dart';
import '../providers/timetable_authoring_providers.dart';
import '../widgets/timetable_spreadsheet_grid.dart';
import '../widgets/timetable_class_editor_dialog.dart';
import '../widgets/timetable_structure_editor_dialog.dart';

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
  final FocusNode _gridFocusNode = FocusNode();

  @override
  void dispose() {
    _gridFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyNavigation(int deltaDay, int deltaPeriod) {
    final authoringNotifier = ref.read(timetableAuthoringProvider(widget.timetableId).notifier);
    final state = ref.read(timetableAuthoringProvider(widget.timetableId));
    final container = state.container;
    if (container == null || container.activeDays.isEmpty) return;

    final currentCoord = state.selectedCell ??
        TimetableCellCoordinate(
          day: container.activeDays.first,
          periodIndex: state.periods.isNotEmpty ? state.periods.first.index : 1,
        );

    final nextCoord = state.moveSelection(currentCoord, deltaDay, deltaPeriod);
    if (nextCoord != null) {
      authoringNotifier.selectCell(nextCoord.day, nextCoord.periodIndex);
    }
  }

  void _handleKeyAction() {
    final state = ref.read(timetableAuthoringProvider(widget.timetableId));
    final permissions = ref.read(timetableAuthoringPermissionsProvider(state.container));
    if (!permissions.canEdit) return;

    if (state.selectedCell != null) {
      final existing = state.getEntryAtCell(state.selectedCell!.day, state.selectedCell!.periodIndex);
      showTimetableClassEditorDialog(
        context: context,
        timetableId: widget.timetableId,
        day: state.selectedCell!.day,
        startPeriodIndex: existing?.startPeriodIndex ?? state.selectedCell!.periodIndex,
        existingEntry: existing,
      );
    }
  }

  void _handleKeyDelete() {
    final state = ref.read(timetableAuthoringProvider(widget.timetableId));
    final permissions = ref.read(timetableAuthoringPermissionsProvider(state.container));
    if (!permissions.canEdit) return;

    if (state.selectedEntryId != null) {
      ref.read(timetableAuthoringProvider(widget.timetableId).notifier).deleteEntry(state.selectedEntryId!);
    }
  }

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
              const Icon(LucideIcons.alertTriangle, size: 48, color: AcadexColors.error),
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

    return PopScope(
      canPop: !authoringState.isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _showExitConfirmationDialog(context, ref, authoringState);
      },
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.arrowUp): () => _handleKeyNavigation(-1, 0),
          const SingleActivator(LogicalKeyboardKey.arrowDown): () => _handleKeyNavigation(1, 0),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _handleKeyNavigation(0, -1),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => _handleKeyNavigation(0, 1),
          const SingleActivator(LogicalKeyboardKey.enter): _handleKeyAction,
          const SingleActivator(LogicalKeyboardKey.delete): _handleKeyDelete,
          const SingleActivator(LogicalKeyboardKey.backspace): _handleKeyDelete,
          const SingleActivator(LogicalKeyboardKey.escape): () {
            ref.read(timetableAuthoringProvider(widget.timetableId).notifier).clearSelection();
          },
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
            ref.read(timetableAuthoringProvider(widget.timetableId).notifier).undo();
          },
          const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
            ref.read(timetableAuthoringProvider(widget.timetableId).notifier).undo();
          },
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): () {
            ref.read(timetableAuthoringProvider(widget.timetableId).notifier).redo();
          },
          const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true): () {
            ref.read(timetableAuthoringProvider(widget.timetableId).notifier).redo();
          },
          const SingleActivator(LogicalKeyboardKey.keyY, control: true): () {
            ref.read(timetableAuthoringProvider(widget.timetableId).notifier).redo();
          },
        },
        child: Focus(
          focusNode: _gridFocusNode,
          autofocus: true,
          child: Scaffold(
            backgroundColor: Colors.transparent,
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
                      onBack: () {
                        if (authoringState.isDirty) {
                          _showExitConfirmationDialog(context, ref, authoringState);
                        } else {
                          Navigator.of(context).maybePop();
                        }
                      },
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
                                        const SnackBar(content: Text('Timetable draft saved successfully!'), backgroundColor: AcadexColors.success),
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
                          // Publish Button with Confirmation Summary Dialog
                          ElevatedButton.icon(
                            onPressed: authoringState.isPublishing
                                ? null
                                : () => _showPublishConfirmationDialog(context, ref, authoringState, subtitle),
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
                    child: _buildGridToolbar(context, ref, isDark: isDark, authoringState: authoringState, permissions: permissions),
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
                          if (permissions.canEdit) {
                            showTimetableClassEditorDialog(
                              context: context,
                              timetableId: widget.timetableId,
                              day: day,
                              startPeriodIndex: periodIndex,
                            );
                          }
                        },
                        onEntryTap: (entry) {
                          ref.read(timetableAuthoringProvider(widget.timetableId).notifier).selectEntry(entry.id);
                          if (permissions.canEdit) {
                            showTimetableClassEditorDialog(
                              context: context,
                              timetableId: widget.timetableId,
                              day: entry.dayOfWeek,
                              startPeriodIndex: entry.startPeriodIndex,
                              existingEntry: entry,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
  // GRID TOOLBAR WIDGET WITH UNDO / REDO & ACTIONS
  // =========================================================================
  Widget _buildGridToolbar(
    BuildContext context,
    WidgetRef ref, {
    required bool isDark,
    required TimetableAuthoringState authoringState,
    required TimetableAuthoringPermissions permissions,
  }) {
    final container = authoringState.container;
    final activeDaysCount = container?.activeDays.length ?? 0;
    final periodsCount = authoringState.periods.length;
    final timingModeName = container?.timingMode.displayName ?? '';
    final notifier = ref.read(timetableAuthoringProvider(widget.timetableId).notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: View Mode & Context Badges
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                    borderRadius: AcadexRadius.borderRadiusXs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
            const SizedBox(width: 24),

            // Right: Undo/Redo + Structure & Timing + Unsaved indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
              if (permissions.canEdit) ...[
                // Undo Button
                IconButton(
                  tooltip: 'Undo (Ctrl+Z)',
                  icon: const Icon(LucideIcons.undo2, size: 16),
                  onPressed: authoringState.canUndo ? () => notifier.undo() : null,
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  disabledColor: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                ),
                // Redo Button
                IconButton(
                  tooltip: 'Redo (Ctrl+Shift+Z)',
                  icon: const Icon(LucideIcons.redo2, size: 16),
                  onPressed: authoringState.canRedo ? () => notifier.redo() : null,
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  disabledColor: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => showTimetableStructureEditorDialog(
                    context: context,
                    timetableId: widget.timetableId,
                  ),
                  icon: const Icon(LucideIcons.calendarClock, size: 14, color: AcadexColors.primary),
                  label: Text(
                    'Structure & Timing',
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    side: BorderSide(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                    shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusSm),
                  ),
                ),
                const SizedBox(width: 12),
              ],
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
        ],
      ),
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
          const Icon(LucideIcons.alertCircle, size: 16, color: AcadexColors.error),
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

  // =========================================================================
  // NAVIGATION GUARD (UNSAVED CHANGES MODAL)
  // =========================================================================
  void _showExitConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    TimetableAuthoringState authoringState,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.alertCircle, color: AcadexColors.warning),
            SizedBox(width: 8),
            Text('Unsaved Changes'),
          ],
        ),
        content: const Text('You have unsaved changes in this timetable draft. Do you want to save before leaving?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(timetableAuthoringProvider(widget.timetableId).notifier).discardUnsavedChanges();
              Navigator.of(context).pop();
            },
            child: const Text('Discard Changes', style: TextStyle(color: AcadexColors.error)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref.read(timetableAuthoringProvider(widget.timetableId).notifier).saveDraft();
              if (success && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save & Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PUBLISH CONFIRMATION SUMMARY MODAL
  // =========================================================================
  void _showPublishConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    TimetableAuthoringState authoringState,
    String subtitle,
  ) {
    final validationErrors = authoringState.validate();
    final hasErrors = validationErrors.isNotEmpty;
    final container = authoringState.container;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(LucideIcons.send, color: AcadexColors.primary, size: 22),
              const SizedBox(width: 10),
              Text('Publish Timetable Schedule', style: AcadexTypography.heading3()),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  container?.name ?? 'Master Timetable',
                  style: AcadexTypography.bodyMedium().copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Statistics Grid
                Row(
                  children: [
                    _buildStatCard('Teaching Classes', '${authoringState.entries.length}', LucideIcons.bookOpen, isDark),
                    const SizedBox(width: 8),
                    _buildStatCard('Working Days', '${container?.activeDays.length ?? 0}', LucideIcons.calendar, isDark),
                    const SizedBox(width: 8),
                    _buildStatCard('Breaks', '${authoringState.breaks.length}', LucideIcons.coffee, isDark),
                  ],
                ),
                const SizedBox(height: 16),

                if (hasErrors) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AcadexColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AcadexColors.error),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.alertTriangle, size: 16, color: AcadexColors.error),
                            SizedBox(width: 6),
                            Text('Cannot publish due to conflicts:', style: TextStyle(fontWeight: FontWeight.bold, color: AcadexColors.errorDark)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        for (final err in validationErrors.take(3))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text('• $err', style: const TextStyle(fontSize: 12, color: AcadexColors.errorDark)),
                          ),
                        if (validationErrors.length > 3)
                          Text('+${validationErrors.length - 3} more issues', style: const TextStyle(fontSize: 11, color: AcadexColors.errorDark)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  Text(
                    'Publishing will atomic-project all teaching classes into the live /timetable collection. Students, faculty, and the Attendance module will immediately receive this published version (v${container?.version ?? 1}).',
                    style: AcadexTypography.bodySmall(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
              onPressed: hasErrors
                  ? null
                  : () async {
                      Navigator.of(dialogCtx).pop();
                      final auth = ref.read(authProvider);
                      final user = auth is AuthAuthenticated ? auth.user : null;
                      final success = await ref.read(timetableAuthoringProvider(widget.timetableId).notifier).publish(
                            publishedBy: user?.id ?? 'user',
                          );
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Timetable published to live schedule successfully!'), backgroundColor: AcadexColors.success),
                        );
                      }
                    },
              child: const Text('Confirm & Publish', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
          borderRadius: AcadexRadius.borderRadiusSm,
          border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AcadexColors.primary),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
