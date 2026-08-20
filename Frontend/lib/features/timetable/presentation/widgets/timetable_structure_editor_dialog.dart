import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_authoring_providers.dart';

/// Clean, responsive modal dialog for managing timetable structure: periods, timings, and breaks.
/// Supports both uniform schedules ("Same timing every day") and per-day schedules ("Different timing per day").
class TimetableStructureEditorDialog extends ConsumerStatefulWidget {
  final String timetableId;

  const TimetableStructureEditorDialog({
    super.key,
    required this.timetableId,
  });

  @override
  ConsumerState<TimetableStructureEditorDialog> createState() => _TimetableStructureEditorDialogState();
}

class _TimetableStructureEditorDialogState extends ConsumerState<TimetableStructureEditorDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TimetableDay _selectedDayForTiming = TimetableDay.monday;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;

    final authoringState = ref.watch(timetableAuthoringProvider(widget.timetableId));
    final container = authoringState.container;
    final timingMode = container?.timingMode ?? TimetableTimingMode.sameEveryDay;
    final activeDays = container?.activeDays ?? [
      TimetableDay.monday,
      TimetableDay.tuesday,
      TimetableDay.wednesday,
      TimetableDay.thursday,
      TimetableDay.friday,
    ];

    if (!activeDays.contains(_selectedDayForTiming) && activeDays.isNotEmpty) {
      _selectedDayForTiming = activeDays.first;
    }

    final permissions = ref.watch(timetableAuthoringPermissionsProvider(container));

    return Dialog(
      backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusLg),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32,
        vertical: isMobile ? 16 : 32,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 780),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =============================================================
              // 1. DIALOG HEADER
              // =============================================================
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                      borderRadius: AcadexRadius.borderRadiusMd,
                    ),
                    child: const Icon(LucideIcons.calendarClock, size: 22, color: AcadexColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Timetable Structure & Timing',
                          style: AcadexTypography.heading2(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Configure period slots, timings, and common/day-specific breaks',
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      size: 20,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // =============================================================
              // 2. TAB SELECTOR (PERIODS VS BREAKS)
              // =============================================================
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                  borderRadius: AcadexRadius.borderRadiusSm,
                  border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AcadexColors.primary,
                    borderRadius: AcadexRadius.borderRadiusSm,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  tabs: [
                    Tab(
                      icon: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.clock, size: 16),
                          const SizedBox(width: 8),
                          Text('Periods & Timing (${authoringState.periods.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      icon: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.coffee, size: 16),
                          const SizedBox(width: 8),
                          Text('Breaks (${authoringState.breaks.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // =============================================================
              // 3. TAB CONTENT VIEWS
              // =============================================================
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // --- TAB 1: PERIODS ---
                    _buildPeriodsTab(
                      context,
                      isDark: isDark,
                      isMobile: isMobile,
                      authoringState: authoringState,
                      timingMode: timingMode,
                      activeDays: activeDays,
                      canEdit: permissions.canEdit,
                    ),

                    // --- TAB 2: BREAKS ---
                    _buildBreaksTab(
                      context,
                      isDark: isDark,
                      isMobile: isMobile,
                      authoringState: authoringState,
                      activeDays: activeDays,
                      canEdit: permissions.canEdit,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Divider(height: 1, color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
              const SizedBox(height: 12),

              // =============================================================
              // 4. FOOTER
              // =============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    authoringState.isDirty ? 'Unsaved changes in draft' : 'All changes saved in draft',
                    style: AcadexTypography.caption(
                      color: authoringState.isDirty ? AcadexColors.warning : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcadexColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusSm),
                    ),
                    child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1: PERIODS DESIGNER
  // =========================================================================
  Widget _buildPeriodsTab(
    BuildContext context, {
    required bool isDark,
    required bool isMobile,
    required TimetableAuthoringState authoringState,
    required TimetableTimingMode timingMode,
    required List<TimetableDay> activeDays,
    required bool canEdit,
  }) {
    final notifier = ref.read(timetableAuthoringProvider(widget.timetableId).notifier);
    final targetDay = timingMode == TimetableTimingMode.differentPerDay ? _selectedDayForTiming : null;
    final currentPeriods = authoringState.getPeriodsForDay(_selectedDayForTiming);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Toolbar: Timing Mode & Add Button
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            // Timing Mode Switcher
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Text(
                  'Timing Mode:',
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                ChoiceChip(
                  label: const Text('Same Timing Every Day'),
                  selected: timingMode == TimetableTimingMode.sameEveryDay,
                  onSelected: canEdit
                      ? (selected) {
                          if (selected) notifier.changeTimingMode(TimetableTimingMode.sameEveryDay);
                        }
                      : null,
                ),
                ChoiceChip(
                  label: const Text('Different Per Day'),
                  selected: timingMode == TimetableTimingMode.differentPerDay,
                  onSelected: canEdit
                      ? (selected) {
                          if (selected) notifier.changeTimingMode(TimetableTimingMode.differentPerDay);
                        }
                      : null,
                ),
              ],
            ),

            // Add Period Button
            if (canEdit)
              ElevatedButton.icon(
                onPressed: () => _showAddEditPeriodDialog(
                  context,
                  isDark: isDark,
                  dayOfWeek: targetDay,
                  existingPeriods: currentPeriods,
                ),
                icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                label: const Text('Add Period', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AcadexColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusSm),
                ),
              ),
          ],
        ),

        // Day Selector for DifferentPerDay mode
        if (timingMode == TimetableTimingMode.differentPerDay) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: activeDays.map((day) {
                final isSelected = day == _selectedDayForTiming;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(day.displayName),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedDayForTiming = day;
                        });
                      }
                    },
                    selectedColor: AcadexColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AcadexColors.primary,
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Period Items List
        Expanded(
          child: currentPeriods.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.clock, size: 40, color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint),
                      const SizedBox(height: 8),
                      Text(
                        'No periods configured for ${timingMode == TimetableTimingMode.differentPerDay ? _selectedDayForTiming.displayName : 'this timetable'}',
                        style: AcadexTypography.bodySmall(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: currentPeriods.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final period = currentPeriods[index];
                    final isUsed = authoringState.isPeriodUsed(period);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                        borderRadius: AcadexRadius.borderRadiusSm,
                        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                      ),
                      child: Row(
                        children: [
                          // Index Badge
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                              borderRadius: AcadexRadius.borderRadiusSm,
                            ),
                            child: Text(
                              'P${period.index}',
                              style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Name & Timing Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  period.name,
                                  style: AcadexTypography.bodyMedium(
                                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${period.startTime} – ${period.endTime} (${period.durationInMinutes} mins)${period.dayOfWeek != null ? ' • ${period.dayOfWeek!.displayName}' : ''}',
                                  style: AcadexTypography.caption(
                                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Reorder Up / Down
                          if (canEdit) ...[
                            IconButton(
                              icon: const Icon(LucideIcons.arrowUp, size: 16),
                              onPressed: index > 0
                                  ? () {
                                      final reordered = List<TimetablePeriodModel>.from(currentPeriods);
                                      final item = reordered.removeAt(index);
                                      reordered.insert(index - 1, item);
                                      notifier.reorderPeriods(reordered);
                                    }
                                  : null,
                              tooltip: 'Move Up',
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.arrowDown, size: 16),
                              onPressed: index < currentPeriods.length - 1
                                  ? () {
                                      final reordered = List<TimetablePeriodModel>.from(currentPeriods);
                                      final item = reordered.removeAt(index);
                                      reordered.insert(index + 1, item);
                                      notifier.reorderPeriods(reordered);
                                    }
                                  : null,
                              tooltip: 'Move Down',
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.pencil, size: 16, color: AcadexColors.primary),
                              onPressed: () => _showAddEditPeriodDialog(
                                context,
                                isDark: isDark,
                                existingPeriod: period,
                                dayOfWeek: targetDay,
                                existingPeriods: currentPeriods,
                              ),
                              tooltip: 'Edit Period',
                            ),
                            IconButton(
                              icon: Icon(
                                LucideIcons.trash2,
                                size: 16,
                                color: isUsed ? (isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint) : AcadexColors.error,
                              ),
                              onPressed: isUsed
                                  ? () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Cannot delete Period ${period.name}: currently occupied by scheduled classes.'),
                                          backgroundColor: AcadexColors.error,
                                        ),
                                      );
                                    }
                                  : () => notifier.deletePeriod(period.id),
                              tooltip: isUsed ? 'Occupied by class' : 'Delete Period',
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 2: BREAKS DESIGNER
  // =========================================================================
  Widget _buildBreaksTab(
    BuildContext context, {
    required bool isDark,
    required bool isMobile,
    required TimetableAuthoringState authoringState,
    required List<TimetableDay> activeDays,
    required bool canEdit,
  }) {
    final notifier = ref.read(timetableAuthoringProvider(widget.timetableId).notifier);
    final breaks = authoringState.breaks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Toolbar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Configured Breaks (${breaks.length})',
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            if (canEdit)
              ElevatedButton.icon(
                onPressed: () => _showAddEditBreakDialog(
                  context,
                  isDark: isDark,
                  activeDays: activeDays,
                  authoringState: authoringState,
                ),
                icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                label: const Text('Add Break', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AcadexColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusSm),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Breaks List
        Expanded(
          child: breaks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.coffee, size: 40, color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint),
                      const SizedBox(height: 8),
                      Text(
                        'No breaks configured yet (e.g. Lunch Break, Tea Break)',
                        style: AcadexTypography.bodySmall(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: breaks.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final breakItem = breaks[index];
                    final isCommon = breakItem.appliesToDays.length >= activeDays.length;

                    IconData breakIcon;
                    switch (breakItem.breakType) {
                      case TimetableBreakType.lunch:
                        breakIcon = LucideIcons.utensils;
                        break;
                      case TimetableBreakType.tea:
                        breakIcon = LucideIcons.coffee;
                        break;
                      case TimetableBreakType.assembly:
                        breakIcon = LucideIcons.users;
                        break;
                      case TimetableBreakType.custom:
                        breakIcon = LucideIcons.clock;
                        break;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                        borderRadius: AcadexRadius.borderRadiusSm,
                        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight,
                              borderRadius: AcadexRadius.borderRadiusSm,
                            ),
                            child: Icon(breakIcon, size: 18, color: AcadexColors.warningDark),
                          ),
                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      breakItem.name,
                                      style: AcadexTypography.bodyMedium(
                                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                      ).copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isCommon
                                            ? (isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight)
                                            : (isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft),
                                        borderRadius: AcadexRadius.borderRadiusXs,
                                      ),
                                      child: Text(
                                        isCommon ? 'Common Break' : 'Day-Specific',
                                        style: AcadexTypography.caption(
                                          color: isCommon ? AcadexColors.primary : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                        ).copyWith(fontSize: 10),
                                      ),
                                    ),
                                    if (breakItem.isVerticalSpan)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight,
                                          borderRadius: AcadexRadius.borderRadiusXs,
                                        ),
                                        child: Text(
                                          'Vertical Span',
                                          style: AcadexTypography.caption(color: AcadexColors.warningDark).copyWith(fontSize: 10),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${breakItem.startTime} – ${breakItem.endTime} (${breakItem.durationInMinutes} mins) • ${breakItem.appliesToDays.map((d) => d.displayName.substring(0, 3)).join(', ')}',
                                  style: AcadexTypography.caption(
                                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (canEdit) ...[
                            IconButton(
                              icon: const Icon(LucideIcons.pencil, size: 16, color: AcadexColors.primary),
                              onPressed: () => _showAddEditBreakDialog(
                                context,
                                isDark: isDark,
                                existingBreak: breakItem,
                                activeDays: activeDays,
                                authoringState: authoringState,
                              ),
                              tooltip: 'Edit Break',
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, size: 16, color: AcadexColors.error),
                              onPressed: () => notifier.deleteBreak(breakItem.id),
                              tooltip: 'Delete Break',
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // =========================================================================
  // MODAL: ADD / EDIT PERIOD DIALOG
  // =========================================================================
  void _showAddEditPeriodDialog(
    BuildContext context, {
    required bool isDark,
    TimetablePeriodModel? existingPeriod,
    TimetableDay? dayOfWeek,
    required List<TimetablePeriodModel> existingPeriods,
  }) {
    final isEditing = existingPeriod != null;
    final nameCtrl = TextEditingController(text: existingPeriod?.name ?? 'Period ${existingPeriods.length + 1}');
    final startCtrl = TextEditingController(
      text: existingPeriod?.startTime ?? (existingPeriods.isNotEmpty ? existingPeriods.last.endTime : '09:00'),
    );
    final endCtrl = TextEditingController(
      text: existingPeriod?.endTime ?? '10:00',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            String? errorMsg;
            final sTime = startCtrl.text.trim();
            final eTime = endCtrl.text.trim();

            if (nameCtrl.text.trim().isEmpty) {
              errorMsg = 'Period name cannot be empty';
            } else if (sTime.length != 5 || !sTime.contains(':') || eTime.length != 5 || !eTime.contains(':')) {
              errorMsg = 'Time must be in HH:mm format (e.g. 09:00)';
            } else if (sTime.compareTo(eTime) >= 0) {
              errorMsg = 'Start time must be strictly before end time';
            } else {
              // Check overlaps with other periods
              for (final other in existingPeriods) {
                if (other.id == existingPeriod?.id) continue;
                if (sTime.compareTo(other.endTime) < 0 && eTime.compareTo(other.startTime) > 0) {
                  errorMsg = 'Overlaps with "${other.name}" (${other.startTime}-${other.endTime})';
                  break;
                }
              }
            }

            return AlertDialog(
              backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
              title: Text(
                isEditing ? 'Edit Period' : 'Add Period',
                style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
              ),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Period Name *'),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startCtrl,
                            decoration: const InputDecoration(labelText: 'Start Time (HH:mm) *'),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endCtrl,
                            decoration: const InputDecoration(labelText: 'End Time (HH:mm) *'),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                      ],
                    ),
                    if (errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(LucideIcons.alertCircle, size: 14, color: AcadexColors.error),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(errorMsg, style: const TextStyle(color: AcadexColors.error, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: errorMsg == null
                      ? () {
                          final notifier = ref.read(timetableAuthoringProvider(widget.timetableId).notifier);
                          if (isEditing) {
                            final updated = existingPeriod.copyWith(
                              name: nameCtrl.text.trim(),
                              startTime: sTime,
                              endTime: eTime,
                            );
                            notifier.updatePeriod(updated);
                          } else {
                            final newPeriod = TimetablePeriodModel(
                              id: const Uuid().v4(),
                              index: existingPeriods.length + 1,
                              name: nameCtrl.text.trim(),
                              startTime: sTime,
                              endTime: eTime,
                              dayOfWeek: dayOfWeek,
                            );
                            notifier.addPeriod(newPeriod);
                          }
                          Navigator.of(ctx).pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
                  child: Text(isEditing ? 'Save' : 'Add', style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // MODAL: ADD / EDIT BREAK DIALOG
  // =========================================================================
  void _showAddEditBreakDialog(
    BuildContext context, {
    required bool isDark,
    TimetableBreakModel? existingBreak,
    required List<TimetableDay> activeDays,
    required TimetableAuthoringState authoringState,
  }) {
    final isEditing = existingBreak != null;
    final nameCtrl = TextEditingController(text: existingBreak?.name ?? 'Lunch Break');
    final startCtrl = TextEditingController(text: existingBreak?.startTime ?? '13:00');
    final endCtrl = TextEditingController(text: existingBreak?.endTime ?? '14:00');
    var breakType = existingBreak?.breakType ?? TimetableBreakType.lunch;
    var isVerticalSpan = existingBreak?.isVerticalSpan ?? true;
    var selectedDays = List<TimetableDay>.from(existingBreak?.appliesToDays ?? activeDays);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            String? errorMsg;
            final sTime = startCtrl.text.trim();
            final eTime = endCtrl.text.trim();

            if (nameCtrl.text.trim().isEmpty) {
              errorMsg = 'Break name cannot be empty';
            } else if (selectedDays.isEmpty) {
              errorMsg = 'Break must apply to at least one active day';
            } else if (sTime.length != 5 || !sTime.contains(':') || eTime.length != 5 || !eTime.contains(':')) {
              errorMsg = 'Time must be in HH:mm format (e.g. 13:00)';
            } else if (sTime.compareTo(eTime) >= 0) {
              errorMsg = 'Start time must be strictly before end time';
            } else {
              // Check class conflicts
              for (final entry in authoringState.entries) {
                if (selectedDays.contains(entry.dayOfWeek)) {
                  if (sTime.compareTo(entry.endTime) < 0 && eTime.compareTo(entry.startTime) > 0) {
                    errorMsg = 'Conflicts with class on ${entry.dayOfWeek.displayName} (${entry.startTime}-${entry.endTime})';
                    break;
                  }
                }
              }
            }

            return AlertDialog(
              backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
              title: Text(
                isEditing ? 'Edit Break' : 'Add Break',
                style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Break Name *'),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<TimetableBreakType>(
                        value: breakType,
                        decoration: const InputDecoration(labelText: 'Break Type'),
                        items: TimetableBreakType.values.map((t) {
                          return DropdownMenuItem(value: t, child: Text(t.displayName));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              breakType = val;
                              if (nameCtrl.text.isEmpty || nameCtrl.text.endsWith('Break')) {
                                nameCtrl.text = val.displayName;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: startCtrl,
                              decoration: const InputDecoration(labelText: 'Start Time (HH:mm) *'),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: endCtrl,
                              decoration: const InputDecoration(labelText: 'End Time (HH:mm) *'),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Applicable Days *', style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: activeDays.map((d) {
                          final isSelected = selectedDays.contains(d);
                          return FilterChip(
                            label: Text(d.displayName.substring(0, 3)),
                            selected: isSelected,
                            onSelected: (val) {
                              setDialogState(() {
                                if (val) {
                                  selectedDays.add(d);
                                } else {
                                  selectedDays.remove(d);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Vertical Span in Grid', style: TextStyle(fontSize: 14)),
                        subtitle: const Text('Render as a continuous vertical block across columns', style: TextStyle(fontSize: 11)),
                        value: isVerticalSpan,
                        onChanged: (val) => setDialogState(() => isVerticalSpan = val),
                      ),
                      if (errorMsg != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(LucideIcons.alertCircle, size: 14, color: AcadexColors.error),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(errorMsg, style: const TextStyle(color: AcadexColors.error, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: errorMsg == null
                      ? () {
                          final notifier = ref.read(timetableAuthoringProvider(widget.timetableId).notifier);
                          if (isEditing) {
                            final updated = existingBreak.copyWith(
                              name: nameCtrl.text.trim(),
                              startTime: sTime,
                              endTime: eTime,
                              breakType: breakType,
                              appliesToDays: selectedDays,
                              isVerticalSpan: isVerticalSpan,
                            );
                            notifier.updateBreak(updated);
                          } else {
                            final newBreak = TimetableBreakModel(
                              id: const Uuid().v4(),
                              name: nameCtrl.text.trim(),
                              startTime: sTime,
                              endTime: eTime,
                              breakType: breakType,
                              appliesToDays: selectedDays,
                              isVerticalSpan: isVerticalSpan,
                            );
                            notifier.addBreak(newBreak);
                          }
                          Navigator.of(ctx).pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
                  child: Text(isEditing ? 'Save' : 'Add', style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Helper function to open the structure editor dialog.
Future<void> showTimetableStructureEditorDialog({
  required BuildContext context,
  required String timetableId,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => TimetableStructureEditorDialog(timetableId: timetableId),
  );
}
