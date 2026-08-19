import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_lookup_providers.dart';
import '../providers/timetable_authoring_providers.dart';
import 'timetable_widgets.dart';

/// Layout tokens for deterministic spreadsheet grid rendering.
class TimetableGridTokens {
  static const double dayColumnWidth = 140.0;
  static const double dayColumnWidthCompact = 110.0;
  static const double periodColumnWidth = 180.0;
  static const double periodColumnWidthCompact = 150.0;
  static const double cellHeight = 88.0;
  static const double cellHeightCompact = 78.0;
  static const double headerHeight = 72.0;
  static const double hairlineWidth = 1.0;
}

/// Primary reusable coordinate-based spreadsheet grid for Timetable authoring and inspection.
class TimetableSpreadsheetGrid extends ConsumerWidget {
  final TimetableAuthoringState authoringState;
  final TimetableAuthoringPermissions permissions;
  final Function(TimetableDay day, int periodIndex)? onCellTap;
  final Function(TimetableGridEntryModel entry)? onEntryTap;

  const TimetableSpreadsheetGrid({
    super.key,
    required this.authoringState,
    required this.permissions,
    this.onCellTap,
    this.onEntryTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompact = MediaQuery.of(context).size.width < 1024;

    final container = authoringState.container;
    final periods = authoringState.periods;

    if (container == null) {
      return const SizedBox.shrink();
    }

    final activeDays = container.activeDays;
    if (activeDays.isEmpty || periods.isEmpty) {
      return _buildEmptyGridState(context, isDark);
    }

    final dayColWidth = isCompact
        ? TimetableGridTokens.dayColumnWidthCompact
        : TimetableGridTokens.dayColumnWidth;
    final periodColWidth = isCompact
        ? TimetableGridTokens.periodColumnWidthCompact
        : TimetableGridTokens.periodColumnWidth;
    final rowHeight = isCompact
        ? TimetableGridTokens.cellHeightCompact
        : TimetableGridTokens.cellHeight;

    // Total content width calculation (including borders)
    final totalWidth = dayColWidth + (periods.length * periodColWidth) + (TimetableGridTokens.hairlineWidth * 2);

    // Lookups
    final subjectMap = ref.watch(timetableSubjectMapProvider);
    final facultyMap = ref.watch(timetableFacultyMapProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Container(
          width: totalWidth,
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
            borderRadius: AcadexRadius.borderRadiusLg,
            border: Border.all(
              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
              width: TimetableGridTokens.hairlineWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // =============================================================
              // 1. TOP HEADER ROW (DAY / PERIOD + PERIOD HEADERS)
              // =============================================================
              _buildHeaderRow(
                context,
                isDark: isDark,
                periods: periods,
                dayColWidth: dayColWidth,
                periodColWidth: periodColWidth,
              ),

              // =============================================================
              // 2. DATA ROWS (ONE ROW PER ACTIVE DAY)
              // =============================================================
              for (int dayIdx = 0; dayIdx < activeDays.length; dayIdx++) ...[
                Divider(
                  height: TimetableGridTokens.hairlineWidth,
                  thickness: TimetableGridTokens.hairlineWidth,
                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                ),
                _buildDayRow(
                  context,
                  isDark: isDark,
                  day: activeDays[dayIdx],
                  periods: periods,
                  dayColWidth: dayColWidth,
                  periodColWidth: periodColWidth,
                  rowHeight: rowHeight,
                  subjectMap: subjectMap,
                  facultyMap: facultyMap,
                ),
              ],
            ],
          ),
        );

        // Horizontal scroll container to support narrow screens and mobile viewports cleanly
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: content,
          ),
        );
      },
    );
  }

  // =========================================================================
  // HEADER ROW BUILDER
  // =========================================================================
  Widget _buildHeaderRow(
    BuildContext context, {
    required bool isDark,
    required List<TimetablePeriodModel> periods,
    required double dayColWidth,
    required double periodColWidth,
  }) {
    return Container(
      height: TimetableGridTokens.headerHeight,
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AcadexRadius.lg - 1)),
      ),
      child: Row(
        children: [
          // Top-Left Corner (DAY / PERIOD Label)
          Container(
            width: dayColWidth,
            height: TimetableGridTokens.headerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                  width: TimetableGridTokens.hairlineWidth,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.calendarDays,
                  size: 16,
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'DAY / PERIOD',
                    style: AcadexTypography.eyebrow(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Period Columns Header
          for (int i = 0; i < periods.length; i++) ...[
            Container(
              width: periodColWidth,
              height: TimetableGridTokens.headerHeight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    width: i < periods.length - 1 ? TimetableGridTokens.hairlineWidth : 0,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    periods[i].name,
                    style: AcadexTypography.bodyMedium(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ).copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 11,
                        color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${periods[i].startTime} - ${periods[i].endTime}',
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // DAY ROW BUILDER
  // =========================================================================
  Widget _buildDayRow(
    BuildContext context, {
    required bool isDark,
    required TimetableDay day,
    required List<TimetablePeriodModel> periods,
    required double dayColWidth,
    required double periodColWidth,
    required double rowHeight,
    required Map<String, dynamic> subjectMap,
    required Map<String, dynamic> facultyMap,
  }) {
    return SizedBox(
      height: rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Day Column Cell
          Container(
            width: dayColWidth,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkCanvasSoft.withValues(alpha: 0.6) : AcadexColors.canvasSoft.withValues(alpha: 0.5),
              border: Border(
                right: BorderSide(
                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                  width: TimetableGridTokens.hairlineWidth,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AcadexColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    day.displayName.toUpperCase(),
                    style: AcadexTypography.eyebrow(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ).copyWith(letterSpacing: 0.8),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // 2. Period Cells for this Day
          for (int pIdx = 0; pIdx < periods.length; pIdx++) ...[
            _buildCellAt(
              context,
              isDark: isDark,
              day: day,
              period: periods[pIdx],
              periods: periods,
              periodIndex: periods[pIdx].index,
              periodColWidth: periodColWidth,
              isLastPeriod: pIdx == periods.length - 1,
              subjectMap: subjectMap,
              facultyMap: facultyMap,
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // INDIVIDUAL CELL RENDERER (COORDINATE BASED)
  // =========================================================================
  Widget _buildCellAt(
    BuildContext context, {
    required bool isDark,
    required TimetableDay day,
    required TimetablePeriodModel period,
    required List<TimetablePeriodModel> periods,
    required int periodIndex,
    required double periodColWidth,
    required bool isLastPeriod,
    required Map<String, dynamic> subjectMap,
    required Map<String, dynamic> facultyMap,
  }) {
    // 1. Check for Breaks applying to this Day and Timeslot
    final breakModel = authoringState.getBreakAtCell(day, period.startTime, period.endTime);
    if (breakModel != null) {
      return _buildBreakCell(
        context,
        isDark: isDark,
        breakModel: breakModel,
        width: periodColWidth,
        isLastPeriod: isLastPeriod,
      );
    }

    // 2. Check for Teaching Entry occupying this Cell
    final entry = authoringState.getEntryAtCell(day, periodIndex);
    if (entry != null) {
      // If this cell is the origin (startPeriodIndex == periodIndex), render the full (possibly merged) entry
      if (entry.startPeriodIndex == periodIndex) {
        final totalWidth = entry.periodSpan * periodColWidth;
        return _buildOccupiedCell(
          context,
          isDark: isDark,
          entry: entry,
          width: totalWidth,
          isLastPeriod: isLastPeriod,
          subjectMap: subjectMap,
          facultyMap: facultyMap,
        );
      } else {
        // Absorbed by merged span starting earlier in the row
        return const SizedBox.shrink();
      }
    }

    // 3. Render Empty Cell
    return _buildEmptyCell(
      context,
      isDark: isDark,
      day: day,
      periodIndex: periodIndex,
      width: periodColWidth,
      isLastPeriod: isLastPeriod,
    );
  }

  // =========================================================================
  // POPULATED TEACHING ENTRY CELL
  // =========================================================================
  Widget _buildOccupiedCell(
    BuildContext context, {
    required bool isDark,
    required TimetableGridEntryModel entry,
    required double width,
    required bool isLastPeriod,
    required Map<String, dynamic> subjectMap,
    required Map<String, dynamic> facultyMap,
  }) {
    final isSelected = authoringState.selectedEntryId == entry.id ||
        (authoringState.selectedCell != null &&
            authoringState.selectedCell!.day == entry.dayOfWeek &&
            entry.occupiesPeriod(authoringState.selectedCell!.periodIndex));

    final sessionColor = getSessionTypeColor(entry.sessionType);

    // Resolve human-readable names
    final subjectObj = subjectMap[entry.subjectId];
    final subjectName = subjectObj?.name ?? entry.subjectId;

    final facultyObj = facultyMap[entry.facultyId];
    final facultyName = facultyObj?.name ?? entry.facultyId;

    return InkWell(
      onTap: () {
        if (onEntryTap != null) {
          onEntryTap!(entry);
        } else if (onCellTap != null) {
          onCellTap!(entry.dayOfWeek, entry.startPeriodIndex);
        }
      },
      borderRadius: BorderRadius.zero,
      child: AnimatedContainer(
        duration: AcadexMotion.resolveDuration(context, AcadexMotion.micro),
        curve: AcadexMotion.curveStandard,
        width: width,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AcadexColors.primary.withValues(alpha: 0.25) : AcadexColors.primaryLight)
              : (isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface),
          border: Border(
            right: BorderSide(
              color: isSelected
                  ? AcadexColors.primary
                  : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
              width: TimetableGridTokens.hairlineWidth,
            ),
            left: isSelected
                ? const BorderSide(color: AcadexColors.primary, width: 2)
                : BorderSide(color: sessionColor, width: 3),
            top: isSelected ? const BorderSide(color: AcadexColors.primary, width: 1.5) : BorderSide.none,
            bottom: isSelected ? const BorderSide(color: AcadexColors.primary, width: 1.5) : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: Subject Name & Session Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    subjectName,
                    style: AcadexTypography.bodyMedium(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ).copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: sessionColor.withValues(alpha: 0.15),
                    borderRadius: AcadexRadius.borderRadiusXs,
                  ),
                  child: Text(
                    entry.sessionType.name.toUpperCase(),
                    style: AcadexTypography.caption(
                      color: sessionColor,
                    ).copyWith(fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            // Middle: Faculty Name
            Row(
              children: [
                Icon(
                  LucideIcons.user,
                  size: 11,
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    facultyName,
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Bottom: Room / Building Info
            Row(
              children: [
                Icon(
                  LucideIcons.mapPin,
                  size: 11,
                  color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${entry.roomNumber}${entry.building != null && entry.building!.isNotEmpty ? ' (${entry.building})' : ''}',
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                    ).copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (entry.isMergedHorizontal) ...[
                  Icon(
                    LucideIcons.arrowRightLeft,
                    size: 11,
                    color: sessionColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // EMPTY GRID CELL
  // =========================================================================
  Widget _buildEmptyCell(
    BuildContext context, {
    required bool isDark,
    required TimetableDay day,
    required int periodIndex,
    required double width,
    required bool isLastPeriod,
  }) {
    final isSelected = authoringState.selectedCell != null &&
        authoringState.selectedCell!.day == day &&
        authoringState.selectedCell!.periodIndex == periodIndex;

    return InkWell(
      onTap: () {
        if (onCellTap != null) {
          onCellTap!(day, periodIndex);
        }
      },
      hoverColor: isDark
          ? AcadexColors.darkSurfaceHover.withValues(alpha: 0.5)
          : AcadexColors.canvasSoft,
      child: AnimatedContainer(
        duration: AcadexMotion.resolveDuration(context, AcadexMotion.micro),
        curve: AcadexMotion.curveStandard,
        width: width,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight.withValues(alpha: 0.8))
              : Colors.transparent,
          border: Border(
            right: BorderSide(
              color: isSelected
                  ? AcadexColors.primary
                  : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
              width: TimetableGridTokens.hairlineWidth,
            ),
            top: isSelected ? const BorderSide(color: AcadexColors.primary, width: 1.5) : BorderSide.none,
            bottom: isSelected ? const BorderSide(color: AcadexColors.primary, width: 1.5) : BorderSide.none,
            left: isSelected ? const BorderSide(color: AcadexColors.primary, width: 1.5) : BorderSide.none,
          ),
        ),
        child: Center(
          child: permissions.canEdit
              ? Icon(
                  LucideIcons.plus,
                  size: 14,
                  color: isSelected
                      ? AcadexColors.primary
                      : (isDark ? AcadexColors.darkInkFaint.withValues(alpha: 0.3) : AcadexColors.inkFaint.withValues(alpha: 0.3)),
                )
              : null,
        ),
      ),
    );
  }

  IconData _getBreakIcon(TimetableBreakType type) {
    switch (type) {
      case TimetableBreakType.lunch:
        return LucideIcons.utensils;
      case TimetableBreakType.tea:
        return LucideIcons.coffee;
      case TimetableBreakType.assembly:
        return LucideIcons.users;
      case TimetableBreakType.custom:
        return LucideIcons.clock;
    }
  }

  // =========================================================================
  // BREAK CELL RENDERER
  // =========================================================================
  Widget _buildBreakCell(
    BuildContext context, {
    required bool isDark,
    required TimetableBreakModel breakModel,
    required double width,
    required bool isLastPeriod,
  }) {
    final icon = _getBreakIcon(breakModel.breakType);

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF231F17) // Subtle dark amber tint
            : const Color(0xFFFFFBEB), // Soft amber 50
        border: Border(
          right: BorderSide(
            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
            width: TimetableGridTokens.hairlineWidth,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? AcadexColors.warning : AcadexColors.warningDark,
          ),
          const SizedBox(height: 4),
          Text(
            breakModel.name,
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.warning : AcadexColors.warningDark,
            ).copyWith(fontWeight: FontWeight.w600, fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${breakModel.startTime} - ${breakModel.endTime}',
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ).copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // EMPTY TIMETABLE STATE
  // =========================================================================
  Widget _buildEmptyGridState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: TimetableGridTokens.hairlineWidth,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.calendarX,
            size: 40,
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No Periods Configured',
            style: AcadexTypography.heading3(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Configure bell schedule periods and active days to render the spreadsheet grid.',
            style: AcadexTypography.bodySmall(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
