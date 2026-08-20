import 'package:flutter/foundation.dart';
import '../../domain/models/timetable_models.dart';

/// Lightweight grid coordinate representing a cell in the spreadsheet designer.
@immutable
class TimetableCellCoordinate {
  final TimetableDay day;
  final int periodIndex;

  const TimetableCellCoordinate({
    required this.day,
    required this.periodIndex,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableCellCoordinate &&
          runtimeType == other.runtimeType &&
          day == other.day &&
          periodIndex == other.periodIndex;

  @override
  int get hashCode => day.hashCode ^ periodIndex.hashCode;

  @override
  String toString() => '${day.displayName}: Period $periodIndex';
}

/// Permissions model describing capabilities for the current user in authoring context.
@immutable
class TimetableAuthoringPermissions {
  final bool canView;
  final bool canEdit;
  final bool canPublish;
  final bool canDelete;

  const TimetableAuthoringPermissions({
    this.canView = false,
    this.canEdit = false,
    this.canPublish = false,
    this.canDelete = false,
  });

  const TimetableAuthoringPermissions.readOnly()
      : canView = true,
        canEdit = false,
        canPublish = false,
        canDelete = false;

  const TimetableAuthoringPermissions.full()
      : canView = true,
        canEdit = true,
        canPublish = true,
        canDelete = true;

  const TimetableAuthoringPermissions.none()
      : canView = false,
        canEdit = false,
        canPublish = false,
        canDelete = false;
}

/// Comprehensive immutable state for the Timetable Spreadsheet Designer authoring workflow.
@immutable
class TimetableAuthoringState {
  final TimetableContainerModel? container;
  final List<TimetablePeriodModel> periods;
  final List<TimetableBreakModel> breaks;
  final List<TimetableGridEntryModel> entries;
  final TimetableCellCoordinate? selectedCell;
  final String? selectedEntryId;
  final bool canUndo;
  final bool canRedo;
  final bool isDirty;
  final bool isLoading;
  final bool isSaving;
  final bool isPublishing;
  final List<String> validationErrors;
  final DateTime? lastSavedAt;
  final String? errorMessage;

  const TimetableAuthoringState({
    this.container,
    this.periods = const [],
    this.breaks = const [],
    this.entries = const [],
    this.selectedCell,
    this.selectedEntryId,
    this.canUndo = false,
    this.canRedo = false,
    this.isDirty = false,
    this.isLoading = false,
    this.isSaving = false,
    this.isPublishing = false,
    this.validationErrors = const [],
    this.lastSavedAt,
    this.errorMessage,
  });

  // =========================================================================
  // QUERY & COMPUTED HELPERS
  // =========================================================================

  /// Currently selected grid entry, if any.
  TimetableGridEntryModel? get selectedEntry {
    if (selectedEntryId == null) return null;
    try {
      return entries.firstWhere((e) => e.id == selectedEntryId);
    } catch (_) {
      return null;
    }
  }

  /// Whether a specific day and period index is occupied by any teaching entry.
  bool isCellOccupied(TimetableDay day, int periodIndex) {
    return entries.any((e) => e.dayOfWeek == day && e.occupiesPeriod(periodIndex));
  }

  /// Retrieves the teaching entry that occupies the given cell, if one exists.
  TimetableGridEntryModel? getEntryAtCell(TimetableDay day, int periodIndex) {
    try {
      return entries.firstWhere((e) => e.dayOfWeek == day && e.occupiesPeriod(periodIndex));
    } catch (_) {
      return null;
    }
  }

  /// Checks if the given cell is the top/start origin of an entry (startPeriodIndex == periodIndex).
  bool isCellOrigin(TimetableDay day, int periodIndex) {
    final entry = getEntryAtCell(day, periodIndex);
    return entry != null && entry.startPeriodIndex == periodIndex;
  }

  /// Checks if the cell belongs to a multi-period merged class.
  bool isCellMerged(TimetableDay day, int periodIndex) {
    final entry = getEntryAtCell(day, periodIndex);
    return entry != null && entry.isMergedHorizontal;
  }

  /// Checks if an entry can be merged rightward into the next consecutive period.
  bool canMergeRight(String entryId) {
    final entry = entries.where((e) => e.id == entryId).firstOrNull;
    if (entry == null) return false;

    final nextPeriodIndex = entry.startPeriodIndex + entry.periodSpan;
    final dayPeriods = getPeriodsForDay(entry.dayOfWeek);
    final nextPeriod = dayPeriods.where((p) => p.index == nextPeriodIndex).firstOrNull;
    if (nextPeriod == null) return false;

    // Verify next period is not occupied by another class
    final isOccupied = entries.any((e) =>
        e.id != entry.id &&
        e.dayOfWeek == entry.dayOfWeek &&
        e.occupiesPeriod(nextPeriodIndex));
    if (isOccupied) return false;

    // Verify next period is not a break
    final breakOnNext = getBreakAtCell(entry.dayOfWeek, nextPeriod.startTime, nextPeriod.endTime);
    if (breakOnNext != null) return false;

    return true;
  }

  /// Checks if an entry can be split into individual periods (span > 1).
  bool canSplit(String entryId) {
    final entry = entries.where((e) => e.id == entryId).firstOrNull;
    return entry != null && entry.periodSpan > 1;
  }

  /// Calculates a new cell coordinate offset by [deltaDay] and [deltaPeriod] from [current].
  TimetableCellCoordinate? moveSelection(TimetableCellCoordinate current, int deltaDay, int deltaPeriod) {
    final activeDays = container?.activeDays ?? [];
    if (activeDays.isEmpty) return current;

    final currentDayIdx = activeDays.indexOf(current.day);
    if (currentDayIdx == -1) return current;

    final targetDayIdx = (currentDayIdx + deltaDay).clamp(0, activeDays.length - 1);
    final targetDay = activeDays[targetDayIdx];

    final dayPeriods = getPeriodsForDay(targetDay);
    if (dayPeriods.isEmpty) return current;

    final maxPeriodIdx = dayPeriods.map((p) => p.index).reduce((a, b) => a > b ? a : b);
    final minPeriodIdx = dayPeriods.map((p) => p.index).reduce((a, b) => a < b ? a : b);

    final targetPeriodIdx = (current.periodIndex + deltaPeriod).clamp(minPeriodIdx, maxPeriodIdx);
    return TimetableCellCoordinate(day: targetDay, periodIndex: targetPeriodIdx);
  }

  /// Finds any defined break applicable to the given day and overlapping with time.
  TimetableBreakModel? getBreakAtCell(TimetableDay day, String startTime, String endTime) {
    try {
      return breaks.firstWhere(
        (b) => b.appliesTo(day) && b.overlapsWithTime(startTime, endTime),
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns breaks applying to the specified day.
  List<TimetableBreakModel> getBreaksForDay(TimetableDay day) {
    return breaks.where((b) => b.appliesTo(day)).toList();
  }

  /// Returns periods applicable to the specified day (taking timingMode into account).
  List<TimetablePeriodModel> getPeriodsForDay(TimetableDay day) {
    if (container?.timingMode == TimetableTimingMode.differentPerDay) {
      final dayPeriods = periods.where((p) => p.dayOfWeek == day).toList();
      if (dayPeriods.isNotEmpty) {
        dayPeriods.sort((a, b) => a.index.compareTo(b.index));
        return dayPeriods;
      }
    }
    final sharedPeriods = periods.where((p) => p.dayOfWeek == null).toList();
    sharedPeriods.sort((a, b) => a.index.compareTo(b.index));
    return sharedPeriods;
  }

  /// List of all occupied cell coordinates in the grid.
  List<TimetableCellCoordinate> get occupiedCells {
    final list = <TimetableCellCoordinate>[];
    for (final entry in entries) {
      for (final pIdx in entry.occupiedPeriodIndexes) {
        list.add(TimetableCellCoordinate(day: entry.dayOfWeek, periodIndex: pIdx));
      }
    }
    return list;
  }

  /// Checks if a period is currently occupied by any scheduled teaching class.
  bool isPeriodUsed(TimetablePeriodModel period) {
    return entries.any((e) {
      if (period.dayOfWeek != null && e.dayOfWeek != period.dayOfWeek) {
        return false;
      }
      return e.occupiesPeriod(period.index);
    });
  }

  // =========================================================================
  // LOCAL VALIDATION ENGINE
  // =========================================================================

  /// Performs pure domain validation on the current local authoring state and returns human-readable error messages.
  List<String> validate() {
    final errors = <String>[];

    if (container == null) {
      errors.add('No timetable container loaded.');
      return errors;
    }

    if (container!.activeDays.isEmpty) {
      errors.add('Timetable must have at least one active day configured.');
    }

    if (periods.isEmpty) {
      errors.add('Timetable must have at least one period defined.');
    }

    // Validate individual periods
    for (final p in periods) {
      if (p.index < 1) {
        errors.add('Period "${p.name}" has an invalid index (${p.index}). Index must be >= 1.');
      }
      if (p.name.trim().isEmpty) {
        errors.add('Period index ${p.index} must have a name.');
      }
      if (p.startTime.compareTo(p.endTime) >= 0) {
        errors.add('Period "${p.name}" start time (${p.startTime}) must be earlier than end time (${p.endTime}).');
      }
    }

    // Validate period overlaps
    for (int i = 0; i < periods.length; i++) {
      for (int j = i + 1; j < periods.length; j++) {
        final p1 = periods[i];
        final p2 = periods[j];
        if (p1.dayOfWeek == p2.dayOfWeek) {
          final isTimeOverlap = p1.startTime.compareTo(p2.endTime) < 0 && p1.endTime.compareTo(p2.startTime) > 0;
          if (isTimeOverlap) {
            errors.add('Period collision: "${p1.name}" (${p1.startTime}-${p1.endTime}) overlaps with "${p2.name}" (${p2.startTime}-${p2.endTime}).');
          }
        }
      }
    }

    // Validate breaks
    for (final b in breaks) {
      if (b.name.trim().isEmpty) {
        errors.add('Break must have a name.');
      }
      if (b.appliesToDays.isEmpty) {
        errors.add('Break "${b.name}" must apply to at least one day.');
      }
      if (b.startTime.compareTo(b.endTime) >= 0) {
        errors.add('Break "${b.name}" start time (${b.startTime}) must be earlier than end time (${b.endTime}).');
      }
    }

    // Validate entries
    for (final e in entries) {
      if (e.subjectId.trim().isEmpty) {
        errors.add('Class on ${e.dayOfWeek.displayName} Period ${e.startPeriodIndex} is missing a Subject.');
      }
      if (e.facultyId.trim().isEmpty) {
        errors.add('Class on ${e.dayOfWeek.displayName} Period ${e.startPeriodIndex} is missing a Faculty assignment.');
      }
      if (e.startPeriodIndex < 1) {
        errors.add('Class on ${e.dayOfWeek.displayName} has an invalid start period index (${e.startPeriodIndex}).');
      }
      if (e.periodSpan < 1) {
        errors.add('Class on ${e.dayOfWeek.displayName} has an invalid period span (${e.periodSpan}).');
      }
    }

    // Intra-grid collisions (Section, Faculty, Room)
    for (int i = 0; i < entries.length; i++) {
      for (int j = i + 1; j < entries.length; j++) {
        final e1 = entries[i];
        final e2 = entries[j];

        if (e1.dayOfWeek == e2.dayOfWeek) {
          final isHorizOverlap = e1.overlapsHorizontallyWith(e2);
          final isTimeOverlap = e1.overlapsTimeWith(e2);

          if (isHorizOverlap || isTimeOverlap) {
            errors.add(
              'Section collision: Multiple classes scheduled at the same time on ${e1.dayOfWeek.displayName} (${e1.startTime}-${e1.endTime} and ${e2.startTime}-${e2.endTime}).',
            );
          }

          if (e1.facultyId.isNotEmpty && e1.facultyId == e2.facultyId && (isHorizOverlap || isTimeOverlap)) {
            errors.add(
              'Faculty collision: Faculty is scheduled for multiple classes on ${e1.dayOfWeek.displayName} (${e1.startTime}-${e1.endTime}).',
            );
          }

          if (e1.roomNumber.isNotEmpty && e1.roomNumber == e2.roomNumber && (isHorizOverlap || isTimeOverlap)) {
            errors.add(
              'Room collision: Room ${e1.roomNumber} is double-booked on ${e1.dayOfWeek.displayName} (${e1.startTime}-${e1.endTime}).',
            );
          }
        }
      }
    }

    // Entry vs Break collisions
    for (final e in entries) {
      for (final b in breaks) {
        if (e.conflictsWithBreak(b)) {
          errors.add(
            'Break collision: Class on ${e.dayOfWeek.displayName} (${e.startTime}-${e.endTime}) overlaps with ${b.name} (${b.startTime}-${b.endTime}).',
          );
        }
      }
    }

    return errors;
  }

  // =========================================================================
  // COPY WITH
  // =========================================================================

  TimetableAuthoringState copyWith({
    TimetableContainerModel? container,
    List<TimetablePeriodModel>? periods,
    List<TimetableBreakModel>? breaks,
    List<TimetableGridEntryModel>? entries,
    TimetableCellCoordinate? selectedCell,
    bool clearSelectedCell = false,
    String? selectedEntryId,
    bool clearSelectedEntryId = false,
    bool? canUndo,
    bool? canRedo,
    bool? isDirty,
    bool? isLoading,
    bool? isSaving,
    bool? isPublishing,
    List<String>? validationErrors,
    DateTime? lastSavedAt,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return TimetableAuthoringState(
      container: container ?? this.container,
      periods: periods ?? this.periods,
      breaks: breaks ?? this.breaks,
      entries: entries ?? this.entries,
      selectedCell: clearSelectedCell ? null : (selectedCell ?? this.selectedCell),
      selectedEntryId: clearSelectedEntryId ? null : (selectedEntryId ?? this.selectedEntryId),
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      isDirty: isDirty ?? this.isDirty,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isPublishing: isPublishing ?? this.isPublishing,
      validationErrors: validationErrors ?? this.validationErrors,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
