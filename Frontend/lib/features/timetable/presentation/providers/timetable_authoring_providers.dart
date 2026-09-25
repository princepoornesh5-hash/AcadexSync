import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/timetable_models.dart';
import '../../data/repositories/timetable_repository.dart';
import 'timetable_providers.dart';

export 'timetable_authoring_state.dart';

// =========================================================================
// REAL-TIME STREAM PROVIDERS (AUTHORING PLANE)
// =========================================================================

/// Real-time stream for a single timetable container.
final timetableContainerStreamProvider = StreamProvider.family<TimetableContainerModel?, String>((ref, timetableId) {
  final repository = ref.watch(timetableRepositoryProvider);
  return repository.watchTimetableContainer(timetableId);
});

/// Real-time stream of period definitions for a timetable container.
final timetablePeriodsStreamProvider = StreamProvider.family<List<TimetablePeriodModel>, String>((ref, timetableId) {
  final repository = ref.watch(timetableRepositoryProvider);
  return repository.watchPeriods(timetableId);
});

/// Real-time stream of break definitions for a timetable container.
final timetableBreaksStreamProvider = StreamProvider.family<List<TimetableBreakModel>, String>((ref, timetableId) {
  final repository = ref.watch(timetableRepositoryProvider);
  return repository.watchBreaks(timetableId);
});

/// Real-time stream of grid entries for a timetable container.
final timetableGridEntriesStreamProvider = StreamProvider.family<List<TimetableGridEntryModel>, String>((ref, timetableId) {
  final repository = ref.watch(timetableRepositoryProvider);
  return repository.watchGridEntries(timetableId);
});

/// Queries timetable containers matching specific academic filters.
final timetableContainersListProvider = StreamProvider.family<List<TimetableContainerModel>, Map<String, dynamic>>((ref, filters) {
  final repository = ref.watch(timetableRepositoryProvider);
  final collegeId = filters['collegeId'] as String? ?? '';
  final departmentId = filters['departmentId'] as String?;
  final sectionId = filters['sectionId'] as String?;
  final status = filters['status'] as TimetableStatus?;

  return repository.watchTimetableContainers(
    collegeId: collegeId,
    departmentId: departmentId,
    sectionId: sectionId,
    status: status,
  );
});

// =========================================================================
// ROLE-BASED AUTHORING PERMISSIONS PROVIDER
// =========================================================================

/// Determines the authoring capabilities for the currently authenticated user.
final timetableAuthoringPermissionsProvider = Provider.family<TimetableAuthoringPermissions, TimetableContainerModel?>((ref, container) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return const TimetableAuthoringPermissions.none();

  switch (currentUser.role) {
    case AppRole.superAdmin:
      return const TimetableAuthoringPermissions.full();

    case AppRole.collegeAdmin:
      if (container == null || container.collegeId == currentUser.collegeId) {
        return const TimetableAuthoringPermissions.full();
      }
      return const TimetableAuthoringPermissions.none();

    case AppRole.hod:
      if (container == null ||
          (container.collegeId == currentUser.collegeId && container.departmentId == currentUser.departmentId)) {
        return const TimetableAuthoringPermissions.full();
      }
      return const TimetableAuthoringPermissions.none();

    case AppRole.faculty:
      final isDelegated = ref.watch(isFacultyTimetableCoordinatorProvider);
      if (isDelegated) {
        if (container == null ||
            (container.collegeId == currentUser.collegeId && container.departmentId == currentUser.departmentId)) {
          return const TimetableAuthoringPermissions.full();
        }
      }
      return const TimetableAuthoringPermissions.readOnly();

    case AppRole.student:
      return const TimetableAuthoringPermissions.readOnly();
  }
});

/// Helper provider checking whether the current faculty user is authorized as a Timetable Coordinator.
final isFacultyTimetableCoordinatorProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.role != AppRole.faculty) return false;
  // Delegated permissions check
  return false; // Can be overridden in test containers or bound to user attributes
});

// =========================================================================
// AUTHORING STATE NOTIFIER & CONTROLLER
// =========================================================================

class TimetableAuthoringNotifier extends StateNotifier<TimetableAuthoringState> {
  final TimetableRepository repository;
  final UserModel? currentUser;
  final Ref? ref;

  final List<TimetableAuthoringState> _undoStack = [];
  final List<TimetableAuthoringState> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  TimetableAuthoringNotifier({
    required this.repository,
    this.currentUser,
    this.ref,
  }) : super(const TimetableAuthoringState());

  void _invalidateConsumerProviders() {
    if (ref == null) return;
    ref!.invalidate(weeklyTimetableProvider);
    ref!.invalidate(todayScheduleProvider);
    ref!.invalidate(dateScheduleProvider);
  }

  void _recordHistory() {
    _undoStack.add(state);
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  /// Reverts the most recent local grid modification.
  void undo() {
    if (_undoStack.isEmpty) return;
    final prev = _undoStack.removeLast();
    _redoStack.add(state);
    state = prev.copyWith(
      isDirty: true,
      canUndo: _undoStack.isNotEmpty,
      canRedo: _redoStack.isNotEmpty,
    );
    validateLocalState();
  }

  /// Re-applies a previously undone local grid modification.
  void redo() {
    if (_redoStack.isEmpty) return;
    final next = _redoStack.removeLast();
    _undoStack.add(state);
    state = next.copyWith(
      isDirty: true,
      canUndo: _undoStack.isNotEmpty,
      canRedo: _redoStack.isNotEmpty,
    );
    validateLocalState();
  }

  /// Loads full timetable data into the local editable authoring state.
  Future<void> loadTimetable(String timetableId) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final container = await repository.getTimetableContainer(timetableId);
      if (container == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Timetable not found: $timetableId',
        );
        return;
      }

      final periods = await repository.getPeriods(timetableId);
      final breaks = await repository.getBreaks(timetableId);
      final entries = await repository.getGridEntries(timetableId);

      _undoStack.clear();
      _redoStack.clear();

      if (!mounted) return;
      state = TimetableAuthoringState(
        container: container,
        periods: periods,
        breaks: breaks,
        entries: entries,
        canUndo: false,
        canRedo: false,
        isDirty: false,
        isLoading: false,
        lastSavedAt: container.updatedAt,
      );
    } catch (e, st) {
      developer.log('[TimetableAuthoring] loadTimetable failed: $e\n$st', name: 'Acadex.Timetable');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load timetable: $e',
      );
    }
  }

  /// Selects a grid cell by coordinate.
  void selectCell(TimetableDay day, int periodIndex) {
    final coord = TimetableCellCoordinate(day: day, periodIndex: periodIndex);
    final entry = state.getEntryAtCell(day, periodIndex);

    state = state.copyWith(
      selectedCell: coord,
      selectedEntryId: entry?.id,
      clearSelectedEntryId: entry == null,
    );
  }

  /// Clears current cell selection.
  void clearSelection() {
    state = state.copyWith(
      clearSelectedCell: true,
      clearSelectedEntryId: true,
    );
  }

  /// Selects an entry explicitly.
  void selectEntry(String? entryId) {
    if (entryId == null) {
      clearSelection();
      return;
    }
    try {
      final entry = state.entries.firstWhere((e) => e.id == entryId);
      state = state.copyWith(
        selectedEntryId: entry.id,
        selectedCell: TimetableCellCoordinate(day: entry.dayOfWeek, periodIndex: entry.startPeriodIndex),
      );
    } catch (_) {
      state = state.copyWith(clearSelectedEntryId: true);
    }
  }

  // --- Grid Entry Operations ---

  /// Adds a new teaching entry to the local grid.
  void createEntry(TimetableGridEntryModel entry) {
    entry.validate();
    _recordHistory();

    final newId = entry.id.isNotEmpty ? entry.id : const Uuid().v4();
    final toAdd = entry.copyWith(id: newId);

    final updated = List<TimetableGridEntryModel>.from(state.entries)..add(toAdd);
    state = state.copyWith(
      entries: updated,
      selectedEntryId: newId,
      canUndo: canUndo,
      canRedo: canRedo,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Updates an existing teaching entry in the local grid.
  void updateEntry(TimetableGridEntryModel entry) {
    entry.validate();
    final index = state.entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;

    _recordHistory();
    final updated = List<TimetableGridEntryModel>.from(state.entries);
    updated[index] = entry;

    state = state.copyWith(
      entries: updated,
      canUndo: canUndo,
      canRedo: canRedo,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Deletes a teaching entry from the local grid.
  void deleteEntry(String entryId) {
    _recordHistory();
    final updated = List<TimetableGridEntryModel>.from(state.entries)
      ..removeWhere((e) => e.id == entryId);

    state = state.copyWith(
      entries: updated,
      clearSelectedEntryId: state.selectedEntryId == entryId,
      canUndo: canUndo,
      canRedo: canRedo,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Authoritatively deletes a single entry from the container on the server via container PUT,
  /// updating local state only upon a successful server response.
  Future<void> deleteEntryAuthoritatively(String entryId) async {
    final container = state.container;
    if (container == null) {
      throw StateError('Cannot delete entry: No timetable container loaded.');
    }
    if (container.status == TimetableStatus.published) {
      throw StateError('Cannot modify entries in a published timetable. Please unpublish or revise first.');
    }

    state = state.copyWith(isSaving: true, clearErrorMessage: true);
    try {
      await repository.deleteGridEntry(container.id, entryId);

      _recordHistory();
      final updated = List<TimetableGridEntryModel>.from(state.entries)
        ..removeWhere((e) => e.id == entryId);

      state = state.copyWith(
        entries: updated,
        clearSelectedEntryId: state.selectedEntryId == entryId,
        isSaving: false,
        isDirty: false,
        canUndo: canUndo,
        canRedo: canRedo,
      );
      validateLocalState();
    } catch (e) {
      if (!mounted) rethrow;
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Merges an existing entry into the next consecutive period to its right.
  void mergeEntryRight(String entryId) {
    final entry = state.entries.where((e) => e.id == entryId).firstOrNull;
    if (entry == null) return;
    if (!state.canMergeRight(entryId)) {
      throw StateError('Cannot merge right: Target period is either occupied, a break, or does not exist.');
    }

    _recordHistory();
    final nextPeriodIndex = entry.startPeriodIndex + entry.periodSpan;
    final dayPeriods = state.getPeriodsForDay(entry.dayOfWeek);
    final nextPeriod = dayPeriods.firstWhere((p) => p.index == nextPeriodIndex);

    final updatedEntry = entry.copyWith(
      periodSpan: entry.periodSpan + 1,
      endTime: nextPeriod.endTime,
    );

    final updated = List<TimetableGridEntryModel>.from(state.entries);
    final idx = updated.indexWhere((e) => e.id == entryId);
    updated[idx] = updatedEntry;

    state = state.copyWith(
      entries: updated,
      selectedEntryId: entryId,
      canUndo: canUndo,
      canRedo: canRedo,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Moves a class from its current day/period to [targetDay] and [targetStartPeriodIndex].
  void moveEntry({
    required String entryId,
    required TimetableDay targetDay,
    required int targetStartPeriodIndex,
  }) {
    final entry = state.entries.where((e) => e.id == entryId).firstOrNull;
    if (entry == null) return;

    final targetPeriods = state.getPeriodsForDay(targetDay);
    final startPeriod = targetPeriods.where((p) => p.index == targetStartPeriodIndex).firstOrNull;
    final endPeriodIndex = targetStartPeriodIndex + entry.periodSpan - 1;
    final endPeriod = targetPeriods.where((p) => p.index == endPeriodIndex).firstOrNull;

    if (startPeriod == null || endPeriod == null) {
      throw ArgumentError('Target period slot does not exist on ${targetDay.displayName}.');
    }

    final newStartTime = startPeriod.startTime;
    final newEndTime = endPeriod.endTime;

    // Check if occupied by another class
    for (int pIdx = targetStartPeriodIndex; pIdx <= endPeriodIndex; pIdx++) {
      final occ = state.getEntryAtCell(targetDay, pIdx);
      if (occ != null && occ.id != entryId) {
        throw TimetableConflictException(
          'Target period $pIdx on ${targetDay.displayName} is already occupied.',
          conflictingEntry: TimetableModel(
            id: occ.id,
            collegeId: state.container?.collegeId ?? '',
            departmentId: state.container?.departmentId ?? '',
            academicYearId: state.container?.academicYearId ?? '',
            semesterId: state.container?.semesterId ?? '',
            courseId: state.container?.courseId ?? '',
            sectionId: state.container?.sectionId ?? '',
            subjectId: occ.subjectId,
            facultyId: occ.facultyId,
            dayOfWeek: targetDay,
            startTime: occ.startTime,
            endTime: occ.endTime,
            roomNumber: occ.roomNumber,
            sessionType: occ.sessionType,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
    }

    // Check break overlap
    final breakAtTarget = state.getBreakAtCell(targetDay, newStartTime, newEndTime);
    if (breakAtTarget != null) {
      throw TimetableConflictException(
        'Target slot on ${targetDay.displayName} overlaps with break "${breakAtTarget.name}".',
      );
    }

    _recordHistory();

    final moved = entry.copyWith(
      dayOfWeek: targetDay,
      startPeriodIndex: targetStartPeriodIndex,
      startTime: newStartTime,
      endTime: newEndTime,
    );

    final updated = List<TimetableGridEntryModel>.from(state.entries);
    final idx = updated.indexWhere((e) => e.id == entryId);
    updated[idx] = moved;

    state = state.copyWith(
      entries: updated,
      selectedEntryId: entryId,
      selectedCell: TimetableCellCoordinate(day: targetDay, periodIndex: targetStartPeriodIndex),
      canUndo: canUndo,
      canRedo: canRedo,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Merges multiple consecutive periods into a single multi-period class.
  void mergePeriods({
    required TimetableDay day,
    required int startPeriodIndex,
    required int periodSpan,
    required String subjectId,
    required String facultyId,
    required String roomNumber,
    String? building,
    required String startTime,
    required String endTime,
    TimetableSessionType sessionType = TimetableSessionType.lab,
  }) {
    if (periodSpan < 1) throw ArgumentError('periodSpan must be >= 1');

    _recordHistory();

    // Remove any existing entries that fall within the merged span
    final endPeriodIndex = startPeriodIndex + periodSpan - 1;
    final updated = List<TimetableGridEntryModel>.from(state.entries)
      ..removeWhere((e) =>
          e.dayOfWeek == day &&
          e.startPeriodIndex <= endPeriodIndex &&
          e.endPeriodIndex >= startPeriodIndex);

    final mergedEntry = TimetableGridEntryModel(
      id: const Uuid().v4(),
      dayOfWeek: day,
      startPeriodIndex: startPeriodIndex,
      periodSpan: periodSpan,
      startTime: startTime,
      endTime: endTime,
      subjectId: subjectId,
      facultyId: facultyId,
      roomNumber: roomNumber,
      building: building,
      sessionType: sessionType,
    );

    updated.add(mergedEntry);
    state = state.copyWith(
      entries: updated,
      selectedEntryId: mergedEntry.id,
      canUndo: canUndo,
      canRedo: canRedo,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Splits a merged multi-period entry into 1-period unit classes.
  void splitEntry(String entryId) {
    final index = state.entries.indexWhere((e) => e.id == entryId);
    if (index == -1) return;

    final entry = state.entries[index];
    if (entry.periodSpan <= 1) return;

    _recordHistory();

    final updated = List<TimetableGridEntryModel>.from(state.entries);
    updated.removeAt(index);

    // Split into individual 1-period slots
    final dayPeriods = state.getPeriodsForDay(entry.dayOfWeek);
    for (int i = 0; i < entry.periodSpan; i++) {
      final pIndex = entry.startPeriodIndex + i;
      final matchingPeriod = dayPeriods.firstWhere(
        (p) => p.index == pIndex,
        orElse: () => TimetablePeriodModel(
          id: 'temp-$pIndex',
          index: pIndex,
          name: 'P$pIndex',
          startTime: entry.startTime,
          endTime: entry.endTime,
        ),
      );

      updated.add(TimetableGridEntryModel(
        id: const Uuid().v4(),
        dayOfWeek: entry.dayOfWeek,
        startPeriodIndex: pIndex,
        periodSpan: 1,
        startTime: matchingPeriod.startTime,
        endTime: matchingPeriod.endTime,
        subjectId: entry.subjectId,
        facultyId: entry.facultyId,
        roomNumber: entry.roomNumber,
        building: entry.building,
        sessionType: entry.sessionType,
      ));
    }

    state = state.copyWith(
      entries: updated,
      clearSelectedEntryId: true,
      canUndo: canUndo,
      canRedo: canRedo,
      isDirty: true,
    );
    validateLocalState();
  }

  // --- Period Operations ---

  /// Adds a new period definition.
  void addPeriod(TimetablePeriodModel period) {
    period.validate();
    _recordHistory();
    final updated = List<TimetablePeriodModel>.from(state.periods)..add(period);
    updated.sort((a, b) => a.index.compareTo(b.index));

    state = state.copyWith(
      periods: updated,
      canUndo: canUndo,
      canRedo: canRedo,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Updates an existing period definition.
  void updatePeriod(TimetablePeriodModel period) {
    period.validate();
    final index = state.periods.indexWhere((p) => p.id == period.id);
    if (index == -1) return;

    _recordHistory();
    final updated = List<TimetablePeriodModel>.from(state.periods);
    updated[index] = period;
    updated.sort((a, b) => a.index.compareTo(b.index));

    state = state.copyWith(
      periods: updated,
      canUndo: canUndo,
      canRedo: canRedo,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Deletes a period definition if not occupied by classes, and recalculates period indexes.
  void deletePeriod(String periodId) {
    final periodToDelete = state.periods.where((p) => p.id == periodId).firstOrNull;
    if (periodToDelete != null && state.isPeriodUsed(periodToDelete)) {
      throw StateError('Cannot delete period "${periodToDelete.name}" because it is currently occupied by classes.');
    }

    _recordHistory();
    final remaining = List<TimetablePeriodModel>.from(state.periods)..removeWhere((p) => p.id == periodId);

    // Re-index remaining periods to maintain contiguous 1..N indices
    final reindexed = <TimetablePeriodModel>[];
    int sharedIdx = 1;
    final dayIndices = <TimetableDay, int>{};

    remaining.sort((a, b) => a.index.compareTo(b.index));

    for (final p in remaining) {
      if (p.dayOfWeek == null) {
        reindexed.add(p.copyWith(index: sharedIdx++));
      } else {
        final currentIdx = (dayIndices[p.dayOfWeek!] ?? 0) + 1;
        dayIndices[p.dayOfWeek!] = currentIdx;
        reindexed.add(p.copyWith(index: currentIdx));
      }
    }

    state = state.copyWith(
      periods: reindexed,
      canUndo: canUndo,
      canRedo: canRedo,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Reorders and updates the indices of periods.
  void reorderPeriods(List<TimetablePeriodModel> newPeriods) {
    final targetDay = newPeriods.isNotEmpty ? newPeriods.first.dayOfWeek : null;
    final otherPeriods = state.periods.where((p) => p.dayOfWeek != targetDay).toList();

    _recordHistory();
    final reindexed = <TimetablePeriodModel>[];
    for (int i = 0; i < newPeriods.length; i++) {
      reindexed.add(newPeriods[i].copyWith(index: i + 1));
    }

    final combined = [...otherPeriods, ...reindexed];
    combined.sort((a, b) => a.index.compareTo(b.index));

    state = state.copyWith(
      periods: combined,
      canUndo: canUndo,
      canRedo: canRedo,
      isDirty: true,
    );
    validateLocalState();
  }

  // --- Break Operations ---

  /// Adds a new break definition.
  void addBreak(TimetableBreakModel breakModel) {
    breakModel.validate();
    _recordHistory();
    final updated = List<TimetableBreakModel>.from(state.breaks)..add(breakModel);

    state = state.copyWith(
      breaks: updated,
      canUndo: canUndo,
      canRedo: canRedo,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Updates an existing break definition.
  void updateBreak(TimetableBreakModel breakModel) {
    breakModel.validate();
    final index = state.breaks.indexWhere((b) => b.id == breakModel.id);
    if (index == -1) return;

    _recordHistory();
    final updated = List<TimetableBreakModel>.from(state.breaks);
    updated[index] = breakModel;

    state = state.copyWith(
      breaks: updated,
      canUndo: canUndo,
      canRedo: canRedo,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Deletes a break definition.
  void deleteBreak(String breakId) {
    _recordHistory();
    final updated = List<TimetableBreakModel>.from(state.breaks)
      ..removeWhere((b) => b.id == breakId);

    state = state.copyWith(
      breaks: updated,
      canUndo: canUndo,
      canRedo: canRedo,
      isDirty: true,
    );
    validateLocalState();
  }

  // --- Container Metadata Operations ---

  /// Updates the active days for the timetable.
  void changeActiveDays(List<TimetableDay> activeDays) {
    if (state.container == null) return;
    _recordHistory();
    final updated = state.container!.copyWith(activeDays: activeDays);
    state = state.copyWith(
      container: updated,
      canUndo: canUndo,
      canRedo: canRedo,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Changes the timing mode (sameEveryDay vs differentPerDay).
  void changeTimingMode(TimetableTimingMode mode) {
    if (state.container == null) return;
    final currentMode = state.container!.timingMode;
    if (currentMode == mode) return;

    _recordHistory();
    final updatedContainer = state.container!.copyWith(timingMode: mode);
    List<TimetablePeriodModel> updatedPeriods = List.from(state.periods);

    if (mode == TimetableTimingMode.differentPerDay) {
      final sharedPeriods = state.periods.where((p) => p.dayOfWeek == null).toList();
      if (sharedPeriods.isNotEmpty) {
        final dayPeriods = <TimetablePeriodModel>[];
        for (final day in updatedContainer.activeDays) {
          for (final p in sharedPeriods) {
            dayPeriods.add(p.copyWith(
              id: '${p.id}-${day.name}',
              dayOfWeek: day,
            ));
          }
        }
        updatedPeriods = dayPeriods;
      }
    } else if (mode == TimetableTimingMode.sameEveryDay) {
      final activeDays = updatedContainer.activeDays;
      final firstDay = activeDays.isNotEmpty ? activeDays.first : TimetableDay.monday;
      final firstDayPeriods = state.getPeriodsForDay(firstDay);

      if (firstDayPeriods.isNotEmpty) {
        final sharedPeriods = <TimetablePeriodModel>[];
        for (final p in firstDayPeriods) {
          sharedPeriods.add(p.copyWith(
            id: p.id.split('-').first,
            clearDayOfWeek: true,
          ));
        }
        updatedPeriods = sharedPeriods;
      }
    }

    state = state.copyWith(
      container: updatedContainer,
      periods: updatedPeriods,
      isDirty: true,
    );
    validateLocalState();
  }

  // --- Validation, Save, Publish & Discard Workflows ---

  /// Computes and stores local validation errors.
  List<String> validateLocalState() {
    final errors = state.validate();
    state = state.copyWith(validationErrors: errors);
    return errors;
  }

  /// Persists the current in-memory draft authoring state to Firebase.
  Future<bool> saveDraft() async {
    if (state.container == null) return false;
    final errors = validateLocalState();
    if (errors.isNotEmpty) {
      state = state.copyWith(errorMessage: 'Cannot save: ${errors.first}');
      return false;
    }

    state = state.copyWith(isSaving: true, clearErrorMessage: true);
    try {
      final ttId = state.container!.id;

      // 1. Save container metadata
      await repository.updateTimetableContainer(state.container!);

      // 2. Save periods, breaks, and grid entries batch
      await repository.savePeriodsBatch(ttId, state.periods);
      await repository.saveBreaksBatch(ttId, state.breaks);
      await repository.saveGridEntriesBatch(ttId, state.entries);

      final now = DateTime.now();
      state = state.copyWith(
        isSaving: false,
        isDirty: false,
        lastSavedAt: now,
      );
      return true;
    } catch (e, st) {
      developer.log('[TimetableAuthoring] saveDraft error: $e\n$st', name: 'Acadex.Timetable');
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save draft: $e',
      );
      return false;
    }
  }

  /// Publishes the timetable container, projecting entries into `/timetable`.
  Future<bool> publish({required String publishedBy}) async {
    if (state.container == null) return false;

    // Save any pending changes before publishing
    if (state.isDirty) {
      final saved = await saveDraft();
      if (!saved) return false;
    }

    state = state.copyWith(isPublishing: true, clearErrorMessage: true);
    try {
      final ttId = state.container!.id;
      await repository.publishTimetable(ttId, publishedBy: publishedBy);

      final updatedContainer = await repository.getTimetableContainer(ttId);
      state = state.copyWith(
        container: updatedContainer,
        isPublishing: false,
        isDirty: false,
      );
      _invalidateConsumerProviders();
      return true;
    } catch (e, st) {
      developer.log('[TimetableAuthoring] publish error: $e\n$st', name: 'Acadex.Timetable');
      state = state.copyWith(
        isPublishing: false,
        errorMessage: 'Failed to publish: $e',
      );
      return false;
    }
  }

  /// Reverts a published timetable back to draft status.
  Future<bool> unpublish() async {
    if (state.container == null) return false;

    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final ttId = state.container!.id;
      await repository.unpublishTimetable(ttId);

      final updatedContainer = await repository.getTimetableContainer(ttId);
      state = state.copyWith(
        container: updatedContainer,
        isLoading: false,
        isDirty: false,
      );
      _invalidateConsumerProviders();
      return true;
    } catch (e, st) {
      developer.log('[TimetableAuthoring] unpublish error: $e\n$st', name: 'Acadex.Timetable');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to unpublish: $e',
      );
      return false;
    }
  }

  /// Discards unsaved local changes and reloads from Firestore.
  Future<void> discardUnsavedChanges() async {
    if (state.container == null) return;
    await loadTimetable(state.container!.id);
  }
}

// =========================================================
// MAIN AUTHORING CONTROLLER PROVIDER
// =========================================================

final timetableAuthoringProvider = StateNotifierProvider.autoDispose.family<TimetableAuthoringNotifier, TimetableAuthoringState, String>((ref, timetableId) {
  final repository = ref.watch(timetableRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);

  final notifier = TimetableAuthoringNotifier(
    repository: repository,
    currentUser: currentUser,
    ref: ref,
  );

  // Trigger initial load
  notifier.loadTimetable(timetableId);
  return notifier;
});
