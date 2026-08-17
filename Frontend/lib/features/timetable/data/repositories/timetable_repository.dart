import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/timetable_models.dart';

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
  });

  /// Fetches timetable entries for a specific college/department (used by management screens).
  Future<List<TimetableModel>> getTimetable({
    required String collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? facultyId,
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
}
