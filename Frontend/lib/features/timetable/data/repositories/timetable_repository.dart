import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/timetable_models.dart';
import '../../domain/models/calendar_override.dart';
import '../../domain/models/teacher_substitution.dart';

class TimetableConflictException implements Exception {
  final String message;
  final TimetableModel? conflictingEntry;

  TimetableConflictException(this.message, {this.conflictingEntry});

  @override
  String toString() => message;
}

abstract class TimetableRepository {
  /// Fetches timetable entries for a specific role/context.
  /// Uses the user's properties to filter correctly (e.g., student sees their section, HOD sees department).
  Stream<List<TimetableModel>> watchTimetable({
    required AppRole role,
    required String userId,
    String? collegeId,
    String? departmentId,
    String? sectionId,
    String? date,
  });

  /// Fetches timetable entries for a specific college/department (used by management screens).
  Future<List<TimetableModel>> getTimetable({
    required String collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? facultyId,
    String? date,
    AppRole? role,
  });

  /// Creates a new timetable entry. Validates for conflicts before creating.
  Future<void> createEntry(TimetableModel entry);

  /// Updates an existing timetable entry. Validates for conflicts (excluding itself) before updating.
  Future<void> updateEntry(TimetableModel entry);

  /// Deletes a timetable entry.
  Future<void> deleteEntry(String entryId);

  /// Checks if the proposed entry conflicts with any existing entries.
  /// Throws [TimetableConflictException] if a conflict is found.
  Future<void> checkConflicts(TimetableModel entry);

  // =========================================================
  // AUTHORING ARCHITECTURE: CONTAINERS & SPREADSHEET PLANE
  // =========================================================

  /// Creates a new timetable container in draft status and returns the server-generated timetable ID.
  Future<String> createTimetableContainer(TimetableContainerModel container);

  /// Updates an existing timetable container metadata.
  Future<void> updateTimetableContainer(TimetableContainerModel container);

  /// Deletes a timetable container and its associated projections.
  Future<void> deleteTimetableContainer(String timetableId);

  /// Archives a timetable container (soft archive preserving historical attendance).
  Future<void> archiveTimetableContainer(String timetableId);

  /// Fetches a single timetable container by ID.
  Future<TimetableContainerModel?> getTimetableContainer(String timetableId);

  /// Watches a single timetable container by ID in real-time.
  Stream<TimetableContainerModel?> watchTimetableContainer(String timetableId);

  /// Queries timetable containers matching given academic filters.
  Future<List<TimetableContainerModel>> getTimetableContainers({
    required String collegeId,
    String? departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    TimetableStatus? status,
  });

  /// Watches timetable containers matching given filters in real-time.
  Stream<List<TimetableContainerModel>> watchTimetableContainers({
    required String collegeId,
    String? departmentId,
    String? sectionId,
    TimetableStatus? status,
  });

  // --- Periods Subcollection ---

  /// Saves a single period definition.
  Future<void> savePeriod(String timetableId, TimetablePeriodModel period);

  /// Saves multiple period definitions atomically in batch.
  Future<void> savePeriodsBatch(String timetableId, List<TimetablePeriodModel> periods);

  /// Deletes a period definition.
  Future<void> deletePeriod(String timetableId, String periodId);

  /// Fetches all period definitions for a timetable container.
  Future<List<TimetablePeriodModel>> getPeriods(String timetableId);

  /// Watches all period definitions for a timetable container.
  Stream<List<TimetablePeriodModel>> watchPeriods(String timetableId);

  // --- Breaks Subcollection ---

  /// Saves a single break definition.
  Future<void> saveBreak(String timetableId, TimetableBreakModel breakModel);

  /// Saves multiple break definitions atomically in batch.
  Future<void> saveBreaksBatch(String timetableId, List<TimetableBreakModel> breaks);

  /// Deletes a break definition.
  Future<void> deleteBreak(String timetableId, String breakId);

  /// Fetches all break definitions for a timetable container.
  Future<List<TimetableBreakModel>> getBreaks(String timetableId);

  /// Watches all break definitions for a timetable container.
  Stream<List<TimetableBreakModel>> watchBreaks(String timetableId);

  // --- Grid Entries Subcollection ---

  /// Saves a single teaching grid entry.
  Future<void> saveGridEntry(String timetableId, TimetableGridEntryModel entry);

  /// Saves multiple teaching grid entries atomically in batch.
  Future<void> saveGridEntriesBatch(String timetableId, List<TimetableGridEntryModel> entries);

  /// Deletes a teaching grid entry.
  Future<void> deleteGridEntry(String timetableId, String entryId);

  /// Fetches all teaching grid entries for a timetable container.
  Future<List<TimetableGridEntryModel>> getGridEntries(String timetableId);

  /// Watches all teaching grid entries for a timetable container.
  Stream<List<TimetableGridEntryModel>> watchGridEntries(String timetableId);

  // --- Validation, Publishing & Backward-Compatible Projection ---

  /// Validates all periods, breaks, grid entries and detects internal/break conflicts.
  /// Throws [TimetableConflictException] or [ArgumentError] if invalid.
  Future<void> validateTimetableForPublishing(String timetableId);

  /// Atomically validates, projects teaching entries into `/timetable`, and marks status `published`.
  Future<void> publishTimetable(String timetableId, {required String publishedBy});

  /// Reverts a published timetable back to draft and removes legacy `/timetable` projection.
  Future<void> unpublishTimetable(String timetableId);

  // --- Calendar Overrides & Exceptions ---

  /// Fetches active calendar overrides (holidays / cancellations).
  Future<List<CalendarOverride>> getCalendarOverrides({String? date, String? from, String? to});

  /// Creates a calendar override.
  Future<CalendarOverride> createCalendarOverride(CalendarOverride override);

  /// Deletes a calendar override.
  Future<void> deleteCalendarOverride(String id);

  // --- Teacher Substitutions ---

  /// Fetches date-specific teacher substitutions.
  Future<List<TeacherSubstitution>> getTeacherSubstitutions({
    String? date,
    String? timetableId,
    String? departmentId,
  });

  /// Creates a date-specific teacher substitution.
  Future<TeacherSubstitution> createTeacherSubstitution(TeacherSubstitution substitution);

  /// Deletes a teacher substitution, restoring the operational teacher to original faculty.
  Future<void> deleteTeacherSubstitution(String id);
}

