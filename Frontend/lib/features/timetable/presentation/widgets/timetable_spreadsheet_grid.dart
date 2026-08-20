import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_lookup_providers.dart';
import '../providers/timetable_authoring_providers.dart';
import 'timetable_widgets.dart';
import 'timetable_class_editor_dialog.dart';

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
  final Function(TimetableBreakModel breakModel)? onBreakTap;

  const TimetableSpreadsheetGrid({
    super.key,
    required this.authoringState,
    required this.permissions,
    this.onCellTap,
    this.onEntryTap,
    this.onBreakTap,
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
                  ref,
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

        // 2D scroll container (vertical and horizontal) to support all screen viewports cleanly
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: content,
            ),
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
    final totalWidth = dayColWidth + (periods.length * periodColWidth) + (TimetableGridTokens.hairlineWidth * 2);
    return Container(
      width: totalWidth,
      height: TimetableGridTokens.headerHeight,
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Left Day/Period Header
          Container(
            width: dayColWidth,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                  width: TimetableGridTokens.hairlineWidth,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'DAY / PERIOD',
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  'Schedule',
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                  ).copyWith(fontSize: 10),
                ),
              ],
            ),
          ),

          // Period Columns
          for (int i = 0; i < periods.length; i++) ...[
            Container(
              width: periodColWidth,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    width: TimetableGridTokens.hairlineWidth,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                      borderRadius: AcadexRadius.borderRadiusXs,
                      border: Border.all(
                        color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                      ),
                    ),
                    child: Text(
                      periods[i].name,
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${periods[i].startTime} - ${periods[i].endTime}',
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ).copyWith(fontSize: 10),
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
    BuildContext context,
    WidgetRef ref, {
    required bool isDark,
    required TimetableDay day,
    required List<TimetablePeriodModel> periods,
    required double dayColWidth,
    required double periodColWidth,
    required double rowHeight,
    required Map<String, dynamic> subjectMap,
    required Map<String, dynamic> facultyMap,
  }) {
    final totalWidth = dayColWidth + (periods.length * periodColWidth) + (TimetableGridTokens.hairlineWidth * 2);
    return SizedBox(
      width: totalWidth,
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
              ref,
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
    BuildContext context,
    WidgetRef ref, {
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
        ref,
        isDark: isDark,
        day: day,
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
          ref,
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
      ref,
      isDark: isDark,
      day: day,
      periodIndex: periodIndex,
      width: periodColWidth,
      isLastPeriod: isLastPeriod,
    );
  }

  // =========================================================================
  // POPULATED TEACHING ENTRY CELL WITH DRAGGABLE & CONTEXT MENU
  // =========================================================================
  Widget _buildOccupiedCell(
    BuildContext context,
    WidgetRef ref, {
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

    final cardContent = Container(
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

          // Bottom: Room / Building Info & Actions
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
    );

    Widget interactiveWidget = GestureDetector(
      onTap: () {
        if (onEntryTap != null) {
          onEntryTap!(entry);
        } else if (onCellTap != null) {
          onCellTap!(entry.dayOfWeek, entry.startPeriodIndex);
        }
      },
      onSecondaryTapUp: (details) {
        _showEntryContextMenu(context, ref, entry, details.globalPosition);
      },
      onLongPressStart: (details) {
        _showEntryContextMenu(context, ref, entry, details.globalPosition);
      },
      child: cardContent,
    );

    if (permissions.canEdit) {
      return LongPressDraggable<TimetableGridEntryModel>(
        data: entry,
        feedback: Material(
          elevation: 6,
          borderRadius: AcadexRadius.borderRadiusSm,
          child: Container(
            width: width.clamp(140, 240),
            height: TimetableGridTokens.cellHeight - 10,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
              borderRadius: AcadexRadius.borderRadiusSm,
              border: Border.all(color: AcadexColors.primary, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(subjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                Text(facultyName, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: cardContent),
        child: interactiveWidget,
      );
    }

    return interactiveWidget;
  }

  // =========================================================================
  // EMPTY GRID CELL WITH DRAG TARGET & CONTEXT MENU
  // =========================================================================
  Widget _buildEmptyCell(
    BuildContext context,
    WidgetRef ref, {
    required bool isDark,
    required TimetableDay day,
    required int periodIndex,
    required double width,
    required bool isLastPeriod,
  }) {
    final isSelected = authoringState.selectedCell != null &&
        authoringState.selectedCell!.day == day &&
        authoringState.selectedCell!.periodIndex == periodIndex;

    Widget cellBody(bool isDragOver) => Container(
      width: width,
      decoration: BoxDecoration(
        color: isDragOver
            ? AcadexColors.primaryLight.withValues(alpha: 0.5)
            : (isSelected
                ? (isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight.withValues(alpha: 0.8))
                : Colors.transparent),
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
    );

    if (permissions.canEdit) {
      return DragTarget<TimetableGridEntryModel>(
        onWillAcceptWithDetails: (details) => !authoringState.isCellOccupied(day, periodIndex),
        onAcceptWithDetails: (details) {
          final dropped = details.data;
          try {
            ref.read(timetableAuthoringProvider(authoringState.container!.id).notifier).moveEntry(
              entryId: dropped.id,
              targetDay: day,
              targetStartPeriodIndex: periodIndex,
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cannot move class: $e'), backgroundColor: AcadexColors.error),
            );
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isDragOver = candidateData.isNotEmpty;
          return GestureDetector(
            onTap: () {
              if (onCellTap != null) {
                onCellTap!(day, periodIndex);
              }
            },
            onSecondaryTapUp: (details) {
              _showEmptyCellContextMenu(context, ref, day, periodIndex, details.globalPosition);
            },
            onLongPressStart: (details) {
              _showEmptyCellContextMenu(context, ref, day, periodIndex, details.globalPosition);
            },
            child: cellBody(isDragOver),
          );
        },
      );
    }

    return GestureDetector(
      onTap: () {
        if (onCellTap != null) {
          onCellTap!(day, periodIndex);
        }
      },
      child: cellBody(false),
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
  // BREAK CELL RENDERER WITH GESTURES & CONTEXT MENU
  // =========================================================================
  Widget _buildBreakCell(
    BuildContext context,
    WidgetRef ref, {
    required bool isDark,
    required TimetableDay day,
    required TimetableBreakModel breakModel,
    required double width,
    required bool isLastPeriod,
  }) {
    final icon = _getBreakIcon(breakModel.breakType);

    final content = Container(
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

    return GestureDetector(
      onTap: () {
        if (onBreakTap != null) {
          onBreakTap!(breakModel);
        } else if (permissions.canEdit) {
          _showQuickBreakDialog(context, ref, existingBreak: breakModel);
        }
      },
      onSecondaryTapUp: (details) {
        _showBreakContextMenu(context, ref, breakModel, details.globalPosition);
      },
      onLongPressStart: (details) {
        _showBreakContextMenu(context, ref, breakModel, details.globalPosition);
      },
      child: content,
    );
  }

  // =========================================================================
  // CONTEXT MENUS (ENTRY, EMPTY CELL, BREAK)
  // =========================================================================
  void _showEntryContextMenu(
    BuildContext context,
    WidgetRef ref,
    TimetableGridEntryModel entry,
    Offset position,
  ) async {
    if (!permissions.canEdit) return;

    final canMerge = authoringState.canMergeRight(entry.id);
    final canSplit = authoringState.canSplit(entry.id);

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(LucideIcons.edit3, size: 16),
              SizedBox(width: 8),
              Text('Edit Class'),
            ],
          ),
        ),
        if (canMerge)
          const PopupMenuItem(
            value: 'merge',
            child: Row(
              children: [
                Icon(LucideIcons.arrowRight, size: 16, color: AcadexColors.primary),
                SizedBox(width: 8),
                Text('Merge Right (+1 Period)'),
              ],
            ),
          ),
        if (canSplit)
          const PopupMenuItem(
            value: 'split',
            child: Row(
              children: [
                Icon(LucideIcons.split, size: 16, color: AcadexColors.warningDark),
                SizedBox(width: 8),
                Text('Split into 1-Period Slots'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'move',
          child: Row(
            children: [
              Icon(LucideIcons.move, size: 16),
              SizedBox(width: 8),
              Text('Move Class...'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(LucideIcons.trash2, size: 16, color: AcadexColors.error),
              SizedBox(width: 8),
              Text('Delete Class', style: TextStyle(color: AcadexColors.error)),
            ],
          ),
        ),
      ],
    );

    if (selected == null) return;
    final notifier = ref.read(timetableAuthoringProvider(authoringState.container!.id).notifier);

    switch (selected) {
      case 'edit':
        if (context.mounted) {
          showTimetableClassEditorDialog(
            context: context,
            timetableId: authoringState.container!.id,
            day: entry.dayOfWeek,
            startPeriodIndex: entry.startPeriodIndex,
            existingEntry: entry,
          );
        }
        break;
      case 'merge':
        notifier.mergeEntryRight(entry.id);
        break;
      case 'split':
        notifier.splitEntry(entry.id);
        break;
      case 'move':
        if (context.mounted) {
          _showMoveClassDialog(context, ref, entry);
        }
        break;
      case 'delete':
        notifier.deleteEntry(entry.id);
        break;
    }
  }

  void _showEmptyCellContextMenu(
    BuildContext context,
    WidgetRef ref,
    TimetableDay day,
    int periodIndex,
    Offset position,
  ) async {
    if (!permissions.canEdit) return;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: const [
        PopupMenuItem(
          value: 'add_class',
          child: Row(
            children: [
              Icon(LucideIcons.plus, size: 16, color: AcadexColors.primary),
              SizedBox(width: 8),
              Text('Add Class'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'add_break',
          child: Row(
            children: [
              Icon(LucideIcons.coffee, size: 16, color: AcadexColors.warningDark),
              SizedBox(width: 8),
              Text('Add Break at this Slot'),
            ],
          ),
        ),
      ],
    );

    if (selected == null) return;
    if (selected == 'add_class') {
      if (context.mounted) {
        showTimetableClassEditorDialog(
          context: context,
          timetableId: authoringState.container!.id,
          day: day,
          startPeriodIndex: periodIndex,
        );
      }
    } else if (selected == 'add_break') {
      if (context.mounted) {
        _showQuickBreakDialog(context, ref, day: day, periodIndex: periodIndex);
      }
    }
  }

  void _showBreakContextMenu(
    BuildContext context,
    WidgetRef ref,
    TimetableBreakModel breakModel,
    Offset position,
  ) async {
    if (!permissions.canEdit) return;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: const [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(LucideIcons.edit3, size: 16),
              SizedBox(width: 8),
              Text('Edit Break'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(LucideIcons.trash2, size: 16, color: AcadexColors.error),
              SizedBox(width: 8),
              Text('Delete Break', style: TextStyle(color: AcadexColors.error)),
            ],
          ),
        ),
      ],
    );

    if (selected == null) return;
    if (selected == 'edit') {
      if (context.mounted) {
        _showQuickBreakDialog(context, ref, existingBreak: breakModel);
      }
    } else if (selected == 'delete') {
      ref.read(timetableAuthoringProvider(authoringState.container!.id).notifier).deleteBreak(breakModel.id);
    }
  }

  void _showMoveClassDialog(BuildContext context, WidgetRef ref, TimetableGridEntryModel entry) {
    showDialog<void>(
      context: context,
      builder: (_) => MoveClassDialog(
        timetableId: authoringState.container!.id,
        entry: entry,
      ),
    );
  }

  void _showQuickBreakDialog(
    BuildContext context,
    WidgetRef ref, {
    TimetableDay? day,
    int? periodIndex,
    TimetableBreakModel? existingBreak,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => TimetableQuickBreakDialog(
        timetableId: authoringState.container!.id,
        day: day,
        periodIndex: periodIndex,
        existingBreak: existingBreak,
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

// ===========================================================================
// MOVE CLASS DIALOG
// ===========================================================================
class MoveClassDialog extends ConsumerStatefulWidget {
  final String timetableId;
  final TimetableGridEntryModel entry;

  const MoveClassDialog({
    super.key,
    required this.timetableId,
    required this.entry,
  });

  @override
  ConsumerState<MoveClassDialog> createState() => _MoveClassDialogState();
}

class _MoveClassDialogState extends ConsumerState<MoveClassDialog> {
  late TimetableDay _targetDay;
  late int _targetPeriodIndex;
  String? _conflictError;

  @override
  void initState() {
    super.initState();
    _targetDay = widget.entry.dayOfWeek;
    _targetPeriodIndex = widget.entry.startPeriodIndex;
  }

  void _validateTarget(TimetableAuthoringState state) {
    final targetPeriods = state.getPeriodsForDay(_targetDay);
    final startPeriod = targetPeriods.where((p) => p.index == _targetPeriodIndex).firstOrNull;
    final endPeriodIndex = _targetPeriodIndex + widget.entry.periodSpan - 1;
    final endPeriod = targetPeriods.where((p) => p.index == endPeriodIndex).firstOrNull;

    if (startPeriod == null || endPeriod == null) {
      _conflictError = 'Target periods do not exist on ${_targetDay.displayName}.';
      return;
    }

    for (int pIdx = _targetPeriodIndex; pIdx <= endPeriodIndex; pIdx++) {
      final occ = state.getEntryAtCell(_targetDay, pIdx);
      if (occ != null && occ.id != widget.entry.id) {
        _conflictError = 'Period $pIdx is already occupied on ${_targetDay.displayName}.';
        return;
      }
    }

    final breakAtTarget = state.getBreakAtCell(_targetDay, startPeriod.startTime, endPeriod.endTime);
    if (breakAtTarget != null) {
      _conflictError = 'Overlaps with break "${breakAtTarget.name}".';
      return;
    }

    _conflictError = null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetableAuthoringProvider(widget.timetableId));
    final activeDays = state.container?.activeDays ?? [];
    final periods = state.getPeriodsForDay(_targetDay);

    _validateTarget(state);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(LucideIcons.move, size: 20, color: AcadexColors.primary),
          SizedBox(width: 8),
          Text('Move Class Slot'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select destination day and starting period:', style: AcadexTypography.bodySmall()),
          const SizedBox(height: 16),
          // Day Dropdown
          DropdownButtonFormField<TimetableDay>(
            value: _targetDay,
            decoration: const InputDecoration(labelText: 'Target Day', prefixIcon: Icon(LucideIcons.calendar)),
            items: activeDays.map((d) => DropdownMenuItem(value: d, child: Text(d.displayName))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _targetDay = val;
                  final newPeriods = state.getPeriodsForDay(val);
                  if (newPeriods.isNotEmpty && !newPeriods.any((p) => p.index == _targetPeriodIndex)) {
                    _targetPeriodIndex = newPeriods.first.index;
                  }
                });
              }
            },
          ),
          const SizedBox(height: 12),
          // Period Dropdown
          DropdownButtonFormField<int>(
            value: periods.any((p) => p.index == _targetPeriodIndex) ? _targetPeriodIndex : (periods.isNotEmpty ? periods.first.index : null),
            decoration: const InputDecoration(labelText: 'Starting Period', prefixIcon: Icon(LucideIcons.clock)),
            items: periods.map((p) => DropdownMenuItem(value: p.index, child: Text('${p.name} (${p.startTime}–${p.endTime})'))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _targetPeriodIndex = val);
            },
          ),
          if (_conflictError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AcadexColors.errorLight, borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, size: 16, color: AcadexColors.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_conflictError!, style: const TextStyle(color: AcadexColors.errorDark, fontSize: 12))),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
          onPressed: _conflictError != null
              ? null
              : () {
                  Navigator.of(context).pop();
                  ref.read(timetableAuthoringProvider(widget.timetableId).notifier).moveEntry(
                    entryId: widget.entry.id,
                    targetDay: _targetDay,
                    targetStartPeriodIndex: _targetPeriodIndex,
                  );
                },
          child: const Text('Move Class', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ===========================================================================
// QUICK BREAK EDITOR DIALOG
// ===========================================================================
class TimetableQuickBreakDialog extends ConsumerStatefulWidget {
  final String timetableId;
  final TimetableDay? day;
  final int? periodIndex;
  final TimetableBreakModel? existingBreak;

  const TimetableQuickBreakDialog({
    super.key,
    required this.timetableId,
    this.day,
    this.periodIndex,
    this.existingBreak,
  });

  @override
  ConsumerState<TimetableQuickBreakDialog> createState() => _TimetableQuickBreakDialogState();
}

class _TimetableQuickBreakDialogState extends ConsumerState<TimetableQuickBreakDialog> {
  late TextEditingController _nameController;
  late TimetableBreakType _breakType;
  late String _startTime;
  late String _endTime;
  late List<TimetableDay> _appliesToDays;

  bool get _isEditing => widget.existingBreak != null;

  @override
  void initState() {
    super.initState();
    final b = widget.existingBreak;
    _nameController = TextEditingController(text: b?.name ?? 'Lunch Break');
    _breakType = b?.breakType ?? TimetableBreakType.lunch;
    _startTime = b?.startTime ?? '12:00';
    _endTime = b?.endTime ?? '13:00';
    _appliesToDays = b != null ? List.from(b.appliesToDays) : (widget.day != null ? [widget.day!] : [TimetableDay.monday, TimetableDay.tuesday, TimetableDay.wednesday, TimetableDay.thursday, TimetableDay.friday]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetableAuthoringProvider(widget.timetableId));
    final activeDays = state.container?.activeDays ?? [];

    return AlertDialog(
      title: Row(
        children: [
          const Icon(LucideIcons.coffee, size: 20, color: AcadexColors.warningDark),
          const SizedBox(width: 8),
          Text(_isEditing ? 'Edit Break' : 'Add Break'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Break Name *', prefixIcon: Icon(LucideIcons.tag)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TimetableBreakType>(
              value: _breakType,
              decoration: const InputDecoration(labelText: 'Break Type', prefixIcon: Icon(LucideIcons.layoutGrid)),
              items: TimetableBreakType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _breakType = val);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _startTime,
                    decoration: const InputDecoration(labelText: 'Start Time (HH:MM)'),
                    onChanged: (val) => _startTime = val.trim(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: _endTime,
                    decoration: const InputDecoration(labelText: 'End Time (HH:MM)'),
                    onChanged: (val) => _endTime = val.trim(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Applicable Days:', style: AcadexTypography.caption().copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: activeDays.map((d) {
                final isSelected = _appliesToDays.contains(d);
                return FilterChip(
                  label: Text(d.shortName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _appliesToDays.add(d);
                      } else {
                        _appliesToDays.remove(d);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        if (_isEditing)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(timetableAuthoringProvider(widget.timetableId).notifier).deleteBreak(widget.existingBreak!.id);
            },
            child: const Text('Delete Break', style: TextStyle(color: AcadexColors.error)),
          ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
          onPressed: () {
            if (_nameController.text.trim().isEmpty || _appliesToDays.isEmpty) return;
            Navigator.of(context).pop();
            final notifier = ref.read(timetableAuthoringProvider(widget.timetableId).notifier);
            if (_isEditing) {
              notifier.updateBreak(widget.existingBreak!.copyWith(
                name: _nameController.text.trim(),
                breakType: _breakType,
                startTime: _startTime,
                endTime: _endTime,
                appliesToDays: _appliesToDays,
              ));
            } else {
              notifier.addBreak(TimetableBreakModel(
                id: const Uuid().v4(),
                name: _nameController.text.trim(),
                breakType: _breakType,
                startTime: _startTime,
                endTime: _endTime,
                appliesToDays: _appliesToDays,
              ));
            }
          },
          child: Text(_isEditing ? 'Save Changes' : 'Add Break', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
