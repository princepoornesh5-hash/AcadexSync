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

  TimetableAuthoringNotifier({
    required this.repository,
    this.currentUser,
  }) : super(const TimetableAuthoringState());

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

      state = TimetableAuthoringState(
        container: container,
        periods: periods,
        breaks: breaks,
        entries: entries,
        isDirty: false,
        isLoading: false,
        lastSavedAt: container.updatedAt,
      );
    } catch (e, st) {
      developer.log('[TimetableAuthoring] loadTimetable failed: $e\n$st', name: 'Acadex.Timetable');
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
    final newId = entry.id.isNotEmpty ? entry.id : const Uuid().v4();
    final toAdd = entry.copyWith(id: newId);

    final updated = List<TimetableGridEntryModel>.from(state.entries)..add(toAdd);
    state = state.copyWith(
      entries: updated,
      selectedEntryId: newId,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Updates an existing teaching entry in the local grid.
  void updateEntry(TimetableGridEntryModel entry) {
    entry.validate();
    final index = state.entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;

    final updated = List<TimetableGridEntryModel>.from(state.entries);
    updated[index] = entry;

    state = state.copyWith(
      entries: updated,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Deletes a teaching entry from the local grid.
  void deleteEntry(String entryId) {
    final updated = List<TimetableGridEntryModel>.from(state.entries)
      ..removeWhere((e) => e.id == entryId);

    state = state.copyWith(
      entries: updated,
      clearSelectedEntryId: state.selectedEntryId == entryId,
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
      isDirty: true,
    );
    validateLocalState();
  }

  // --- Period Operations ---

  /// Adds a new period definition.
  void addPeriod(TimetablePeriodModel period) {
    period.validate();
    final updated = List<TimetablePeriodModel>.from(state.periods)..add(period);
    updated.sort((a, b) => a.index.compareTo(b.index));

    state = state.copyWith(
      periods: updated,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Updates an existing period definition.
  void updatePeriod(TimetablePeriodModel period) {
    period.validate();
    final index = state.periods.indexWhere((p) => p.id == period.id);
    if (index == -1) return;

    final updated = List<TimetablePeriodModel>.from(state.periods);
    updated[index] = period;
    updated.sort((a, b) => a.index.compareTo(b.index));

    state = state.copyWith(
      periods: updated,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Deletes a period definition.
  void deletePeriod(String periodId) {
    final updated = List<TimetablePeriodModel>.from(state.periods)
      ..removeWhere((p) => p.id == periodId);

    state = state.copyWith(
      periods: updated,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Reorders and updates the indices of periods.
  void reorderPeriods(List<TimetablePeriodModel> newPeriods) {
    final reindexed = <TimetablePeriodModel>[];
    for (int i = 0; i < newPeriods.length; i++) {
      reindexed.add(newPeriods[i].copyWith(index: i + 1));
    }

    state = state.copyWith(
      periods: reindexed,
      isDirty: true,
    );
    validateLocalState();
  }

  // --- Break Operations ---

  /// Adds a new break definition.
  void addBreak(TimetableBreakModel breakModel) {
    breakModel.validate();
    final updated = List<TimetableBreakModel>.from(state.breaks)..add(breakModel);

    state = state.copyWith(
      breaks: updated,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Updates an existing break definition.
  void updateBreak(TimetableBreakModel breakModel) {
    breakModel.validate();
    final index = state.breaks.indexWhere((b) => b.id == breakModel.id);
    if (index == -1) return;

    final updated = List<TimetableBreakModel>.from(state.breaks);
    updated[index] = breakModel;

    state = state.copyWith(
      breaks: updated,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Deletes a break definition.
  void deleteBreak(String breakId) {
    final updated = List<TimetableBreakModel>.from(state.breaks)
      ..removeWhere((b) => b.id == breakId);

    state = state.copyWith(
      breaks: updated,
      isDirty: true,
    );
    validateLocalState();
  }

  // --- Container Metadata Operations ---

  /// Updates the active days for the timetable.
  void changeActiveDays(List<TimetableDay> activeDays) {
    if (state.container == null) return;
    final updated = state.container!.copyWith(activeDays: activeDays);
    state = state.copyWith(
      container: updated,
      isDirty: true,
    );
    validateLocalState();
  }

  /// Changes the timing mode (sameEveryDay vs differentPerDay).
  void changeTimingMode(TimetableTimingMode mode) {
    if (state.container == null) return;
    final updated = state.container!.copyWith(timingMode: mode);
    state = state.copyWith(
      container: updated,
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
  );

  // Trigger initial load
  notifier.loadTimetable(timetableId);
  return notifier;
});
