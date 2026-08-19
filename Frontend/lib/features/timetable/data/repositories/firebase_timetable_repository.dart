import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../domain/models/timetable_models.dart';
import 'timetable_repository.dart';
import '../../../../features/notifications/domain/services/notification_service.dart';

class FirebaseTimetableRepository implements TimetableRepository {
  final FirestoreService _firestoreService;
  final UserModel? _currentUser;
  final NotificationService? _notificationService;
  
  FirebaseTimetableRepository(
    this._firestoreService, {
    this._notificationService,
    this._currentUser,
  });

  void _debugLog(String operation, Map<String, dynamic> metadata) {
    if (kDebugMode) {
      final safeMetadata = Map<String, dynamic>.from(metadata)
        ..removeWhere((key, _) => key.toLowerCase().contains('password') || key.toLowerCase().contains('secret'));
      final formatted = safeMetadata.entries.map((e) => '${e.key}=${e.value}').join(', ');
      developer.log('[Timetable] $operation: $formatted', name: 'Acadex.Timetable');
    }
  }

  @override
  Stream<List<TimetableModel>> watchTimetable({
    required AppRole role,
    required String userId,
    String? collegeId,
    String? departmentId,
    String? sectionId,
  }) {
    final userCollegeId = (collegeId != null && collegeId.isNotEmpty)
        ? collegeId
        : (_currentUser?.collegeId ?? '');

    _debugLog('watchTimetable', {
      'role': role.name,
      'userId': userId,
      'collegeId': userCollegeId,
      'departmentId': departmentId,
      'sectionId': sectionId,
    });

    final filters = <String, dynamic>{};

    // Non-super-admin queries MUST be constrained by collegeId to pass Firestore security rules
    if (role != AppRole.superAdmin) {
      if (userCollegeId.isEmpty) {
        developer.log(
          '[Timetable] Missing collegeId for role ${role.name}. Returning empty stream to prevent permission-denied.',
          name: 'Acadex.Timetable',
        );
        return Stream.value([]);
      } else {
        filters['collegeId'] = userCollegeId;
      }
    } else if (userCollegeId.isNotEmpty) {
      filters['collegeId'] = userCollegeId;
    }

    switch (role) {
      case AppRole.student:
        if (sectionId != null && sectionId.isNotEmpty) {
          filters['sectionId'] = sectionId;
        } else {
          // If student has no assigned section, return empty stream safely
          return Stream.value([]);
        }
        break;
      case AppRole.faculty:
        filters['facultyId'] = userId;
        break;
      case AppRole.hod:
        final userDeptId = (departmentId != null && departmentId.isNotEmpty)
            ? departmentId
            : (_currentUser?.departmentId ?? '');
        if (userDeptId.isNotEmpty) {
          filters['departmentId'] = userDeptId;
        }
        break;
      case AppRole.collegeAdmin:
        // Already scoped by collegeId filter
        break;
      case AppRole.superAdmin:
        // Super admin sees all, or scoped by collegeId if provided
        break;
    }

    return _firestoreService.watchQuery('timetable', filters).map((docs) {
      return docs.map((doc) => TimetableModel.fromJson(doc)).toList();
    });
  }

  @override
  Future<List<TimetableModel>> getTimetable({
    required String collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? facultyId,
  }) async {
    final effectiveCollegeId = collegeId.isNotEmpty 
        ? collegeId 
        : (_currentUser?.collegeId ?? '');

    _debugLog('getTimetable', {
      'collegeId': effectiveCollegeId,
      'departmentId': departmentId,
      'courseId': courseId,
      'semesterId': semesterId,
      'sectionId': sectionId,
      'facultyId': facultyId,
    });

    final filters = <String, dynamic>{
      if (effectiveCollegeId.isNotEmpty) 'collegeId': effectiveCollegeId,
    };

    if (departmentId != null && departmentId.isNotEmpty) filters['departmentId'] = departmentId;
    if (courseId != null && courseId.isNotEmpty) filters['courseId'] = courseId;
    if (semesterId != null && semesterId.isNotEmpty) filters['semesterId'] = semesterId;
    if (sectionId != null && sectionId.isNotEmpty) filters['sectionId'] = sectionId;
    if (facultyId != null && facultyId.isNotEmpty) filters['facultyId'] = facultyId;

    final docs = await _firestoreService.queryCollection('timetable', filters);
    return docs.map((doc) => TimetableModel.fromJson(doc)).toList();
  }

  @override
  Future<void> checkConflicts(TimetableModel entry) async {
    final effectiveCollegeId = entry.collegeId.isNotEmpty
        ? entry.collegeId
        : (_currentUser?.collegeId ?? '');

    if (effectiveCollegeId.isEmpty && !FirebaseInitializer.shouldUseMock) {
      throw StateError("Cannot check timetable conflicts: Missing collegeId.");
    }

    _debugLog('checkConflicts', {
      'entryId': entry.id,
      'collegeId': effectiveCollegeId,
      'facultyId': entry.facultyId,
      'sectionId': entry.sectionId,
      'roomNumber': entry.roomNumber,
      'dayOfWeek': entry.dayOfWeek.name,
      'time': '${entry.startTime} - ${entry.endTime}',
    });

    // 1. Faculty Conflict Query (constrained by collegeId)
    final facultyFilters = <String, dynamic>{
      'facultyId': entry.facultyId,
      'dayOfWeek': entry.dayOfWeek.name,
      if (effectiveCollegeId.isNotEmpty) 'collegeId': effectiveCollegeId,
    };
    final facultyDocs = await _firestoreService.queryCollection('timetable', facultyFilters);
        
    for (var doc in facultyDocs) {
      final existing = TimetableModel.fromJson(doc);
      if (existing.id == entry.id) continue;
      if (existing.overlapsWith(entry)) {
        throw TimetableConflictException(
          "Faculty already has a class scheduled during this time (${existing.startTime} - ${existing.endTime}).",
          conflictingEntry: existing,
        );
      }
    }

    // 2. Section Conflict Query (constrained by collegeId)
    final sectionFilters = <String, dynamic>{
      'sectionId': entry.sectionId,
      'dayOfWeek': entry.dayOfWeek.name,
      if (effectiveCollegeId.isNotEmpty) 'collegeId': effectiveCollegeId,
    };
    final sectionDocs = await _firestoreService.queryCollection('timetable', sectionFilters);
        
    for (var doc in sectionDocs) {
      final existing = TimetableModel.fromJson(doc);
      if (existing.id == entry.id) continue;
      if (existing.overlapsWith(entry)) {
        throw TimetableConflictException(
          "This section already has a class scheduled during this time (${existing.startTime} - ${existing.endTime}).",
          conflictingEntry: existing,
        );
      }
    }

    // 3. Room Conflict Query (constrained by collegeId)
    if (entry.roomNumber.isNotEmpty) {
      final roomFilters = <String, dynamic>{
        'roomNumber': entry.roomNumber,
        if (entry.building != null && entry.building!.isNotEmpty) 'building': entry.building,
        'dayOfWeek': entry.dayOfWeek.name,
        if (effectiveCollegeId.isNotEmpty) 'collegeId': effectiveCollegeId,
      };
      final roomDocs = await _firestoreService.queryCollection('timetable', roomFilters);
          
      for (var doc in roomDocs) {
        final existing = TimetableModel.fromJson(doc);
        if (existing.id == entry.id) continue;
        if (existing.overlapsWith(entry)) {
          throw TimetableConflictException(
            "Room ${entry.roomNumber}${entry.building != null ? ' in ${entry.building}' : ''} is already occupied during this time (${existing.startTime} - ${existing.endTime}).",
            conflictingEntry: existing,
          );
        }
      }
    }
  }

  @override
  Future<void> createEntry(TimetableModel entry) async {
    final userCollegeId = _currentUser?.collegeId;
    final userDeptId = _currentUser?.departmentId;
    final userRole = _currentUser?.role;

    if (userRole != null) {
      if (userRole == AppRole.student || userRole == AppRole.faculty) {
        throw StateError("Unauthorized: Students and Faculty cannot create timetable entries.");
      }
      if (userRole == AppRole.collegeAdmin || userRole == AppRole.hod) {
        if (userCollegeId != null && userCollegeId.isNotEmpty && entry.collegeId != userCollegeId) {
          throw StateError("Tenant mismatch: Cannot create timetable entry for another college.");
        }
      }
      if (userRole == AppRole.hod) {
        if (userDeptId != null && userDeptId.isNotEmpty && entry.departmentId != userDeptId) {
          throw StateError("Tenant mismatch: Cannot create timetable entry for another department.");
        }
      }
    }

    await _validateFacultyAssignment(entry);
    await checkConflicts(entry);

    final id = entry.id.isNotEmpty ? entry.id : const Uuid().v4();
    final newEntry = entry.copyWith(
      id: id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _debugLog('createEntry', {'id': id, 'collegeId': newEntry.collegeId, 'sectionId': newEntry.sectionId});

    await _firestoreService.setDocument('timetable', id, newEntry.toJson());

    if (_notificationService != null) {
      try {
        await _notificationService.notifyTimetableUpdated(
          sectionId: newEntry.sectionId,
          subjectName: newEntry.subjectId,
        );
      } catch (e) {
        developer.log('[Timetable] notifyTimetableUpdated failed: $e', name: 'Acadex.Timetable');
      }
    }
  }

  @override
  Future<void> updateEntry(TimetableModel entry) async {
    final userCollegeId = _currentUser?.collegeId;
    final userDeptId = _currentUser?.departmentId;
    final userRole = _currentUser?.role;

    if (userRole != null) {
      if (userRole == AppRole.student || userRole == AppRole.faculty) {
        throw StateError("Unauthorized: Students and Faculty cannot update timetable entries.");
      }
      if (userRole == AppRole.collegeAdmin || userRole == AppRole.hod) {
        if (userCollegeId != null && userCollegeId.isNotEmpty && entry.collegeId != userCollegeId) {
          throw StateError("Tenant mismatch: Cannot update timetable entry for another college.");
        }
      }
      if (userRole == AppRole.hod) {
        if (userDeptId != null && userDeptId.isNotEmpty && entry.departmentId != userDeptId) {
          throw StateError("Tenant mismatch: Cannot update timetable entry for another department.");
        }
      }
    }

    await _validateFacultyAssignment(entry);
    await checkConflicts(entry);

    final updatedEntry = entry.copyWith(updatedAt: DateTime.now());
    
    _debugLog('updateEntry', {'id': updatedEntry.id, 'collegeId': updatedEntry.collegeId});

    await _firestoreService.setDocument('timetable', entry.id, updatedEntry.toJson());

    if (_notificationService != null) {
      try {
        await _notificationService.notifyTimetableUpdated(
          sectionId: updatedEntry.sectionId,
          subjectName: updatedEntry.subjectId,
        );
      } catch (e) {
        developer.log('[Timetable] notifyTimetableUpdated failed: $e', name: 'Acadex.Timetable');
      }
    }
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    final userRole = _currentUser?.role;
    if (userRole != null) {
      if (userRole == AppRole.student || userRole == AppRole.faculty) {
        throw StateError("Unauthorized: Students and Faculty cannot delete timetable entries.");
      }
    }

    _debugLog('deleteEntry', {'entryId': entryId});
    await _firestoreService.deleteDocument('timetable', entryId);
  }

  Future<void> _checkManagePermission(String collegeId, String departmentId) async {
    final userRole = _currentUser?.role;
    if (userRole == null) return;

    if (userRole == AppRole.student) {
      throw StateError("Unauthorized: Students cannot manage timetables.");
    }

    if (userRole == AppRole.faculty) {
      final userId = _currentUser?.id ?? '';
      final userDoc = await _firestoreService.getDocument('users', userId);
      final canManage = userDoc?['canManageTimetable'] == true ||
          userDoc?['isTimetableCoordinator'] == true ||
          userDoc?['delegatedTimetableManagement'] == true;
      final userCollege = userDoc?['collegeId'] ?? _currentUser?.collegeId;
      final userDept = userDoc?['departmentId'] ?? _currentUser?.departmentId;

      if (!canManage || userCollege != collegeId || userDept != departmentId) {
        throw StateError("Unauthorized: Faculty member is not authorized to design or manage timetables for this department.");
      }
    }

    if (userRole == AppRole.hod) {
      final userCollegeId = _currentUser?.collegeId;
      final userDeptId = _currentUser?.departmentId;
      if (userCollegeId != null && userCollegeId.isNotEmpty && collegeId != userCollegeId) {
        throw StateError("Tenant mismatch: Cannot manage timetable for another college.");
      }
      if (userDeptId != null && userDeptId.isNotEmpty && departmentId != userDeptId) {
        throw StateError("Tenant mismatch: Cannot manage timetable for another department.");
      }
    }

    if (userRole == AppRole.collegeAdmin) {
      final userCollegeId = _currentUser?.collegeId;
      if (userCollegeId != null && userCollegeId.isNotEmpty && collegeId != userCollegeId) {
        throw StateError("Tenant mismatch: Cannot manage timetable for another college.");
      }
    }
  }

  // =========================================================
  // AUTHORING ARCHITECTURE IMPLEMENTATION
  // =========================================================

  @override
  Future<void> createTimetableContainer(TimetableContainerModel container) async {
    await _checkManagePermission(container.collegeId, container.departmentId);
    container.validate();

    final id = container.id.isNotEmpty ? container.id : const Uuid().v4();
    final toSave = container.copyWith(
      id: id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _debugLog('createTimetableContainer', {'id': id, 'collegeId': toSave.collegeId, 'sectionId': toSave.sectionId});
    await _firestoreService.setDocument('timetables', id, toSave.toJson());
  }

  @override
  Future<void> updateTimetableContainer(TimetableContainerModel container) async {
    await _checkManagePermission(container.collegeId, container.departmentId);
    container.validate();

    final toSave = container.copyWith(updatedAt: DateTime.now());
    _debugLog('updateTimetableContainer', {'id': toSave.id, 'status': toSave.status.name});
    await _firestoreService.setDocument('timetables', toSave.id, toSave.toJson());
  }

  @override
  Future<void> deleteTimetableContainer(String timetableId) async {
    final container = await getTimetableContainer(timetableId);
    if (container != null) {
      await _checkManagePermission(container.collegeId, container.departmentId);
    }

    _debugLog('deleteTimetableContainer', {'id': timetableId});
    await _firestoreService.deleteDocument('timetables', timetableId);

    // Also unpublish and clean legacy projections if any exist
    try {
      final entries = await getGridEntries(timetableId);
      for (final entry in entries) {
        await _firestoreService.deleteDocument('timetable', 'pub_${timetableId}_${entry.id}');
      }
    } catch (e) {
      developer.log('[Timetable] Clean legacy projections on delete failed: $e', name: 'Acadex.Timetable');
    }
  }

  @override
  Future<TimetableContainerModel?> getTimetableContainer(String timetableId) async {
    final doc = await _firestoreService.getDocument('timetables', timetableId);
    return doc != null ? TimetableContainerModel.fromJson(doc) : null;
  }

  @override
  Stream<TimetableContainerModel?> watchTimetableContainer(String timetableId) {
    return _firestoreService.watchDocument('timetables', timetableId).map(
      (doc) => doc != null ? TimetableContainerModel.fromJson(doc) : null,
    );
  }

  @override
  Future<List<TimetableContainerModel>> getTimetableContainers({
    required String collegeId,
    String? departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    TimetableStatus? status,
  }) async {
    final effectiveCollegeId = collegeId.isNotEmpty ? collegeId : (_currentUser?.collegeId ?? '');
    final filters = <String, dynamic>{
      if (effectiveCollegeId.isNotEmpty) 'collegeId': effectiveCollegeId,
      if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
      if (courseId != null && courseId.isNotEmpty) 'courseId': courseId,
      if (academicYearId != null && academicYearId.isNotEmpty) 'academicYearId': academicYearId,
      if (semesterId != null && semesterId.isNotEmpty) 'semesterId': semesterId,
      if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
      if (status != null) 'status': status.name,
    };

    final docs = await _firestoreService.queryCollection('timetables', filters);
    return docs.map((doc) => TimetableContainerModel.fromJson(doc)).toList();
  }

  @override
  Stream<List<TimetableContainerModel>> watchTimetableContainers({
    required String collegeId,
    String? departmentId,
    String? sectionId,
    TimetableStatus? status,
  }) {
    final effectiveCollegeId = collegeId.isNotEmpty ? collegeId : (_currentUser?.collegeId ?? '');
    final filters = <String, dynamic>{
      if (effectiveCollegeId.isNotEmpty) 'collegeId': effectiveCollegeId,
      if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
      if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
      if (status != null) 'status': status.name,
    };

    return _firestoreService.watchQuery('timetables', filters).map(
      (docs) => docs.map((d) => TimetableContainerModel.fromJson(d)).toList(),
    );
  }

  // --- Periods Subcollection ---

  @override
  Future<void> savePeriod(String timetableId, TimetablePeriodModel period) async {
    period.validate();
    final id = period.id.isNotEmpty ? period.id : const Uuid().v4();
    final toSave = period.copyWith(id: id);
    await _firestoreService.setDocument('timetables/$timetableId/periods', id, toSave.toJson());
  }

  @override
  Future<void> savePeriodsBatch(String timetableId, List<TimetablePeriodModel> periods) async {
    final batchMap = <String, Map<String, dynamic>>{};
    for (final period in periods) {
      period.validate();
      final id = period.id.isNotEmpty ? period.id : const Uuid().v4();
      final toSave = period.copyWith(id: id);
      batchMap['timetables/$timetableId/periods/$id'] = toSave.toJson();
    }
    await _firestoreService.batchSetDocuments(batchMap);
  }

  @override
  Future<void> deletePeriod(String timetableId, String periodId) async {
    await _firestoreService.deleteDocument('timetables/$timetableId/periods', periodId);
  }

  @override
  Future<List<TimetablePeriodModel>> getPeriods(String timetableId) async {
    final docs = await _firestoreService.getCollection('timetables/$timetableId/periods');
    final periods = docs.map((d) => TimetablePeriodModel.fromJson(d)).toList();
    periods.sort((a, b) => a.index.compareTo(b.index));
    return periods;
  }

  @override
  Stream<List<TimetablePeriodModel>> watchPeriods(String timetableId) {
    return _firestoreService.watchCollection('timetables/$timetableId/periods').map((docs) {
      final periods = docs.map((d) => TimetablePeriodModel.fromJson(d)).toList();
      periods.sort((a, b) => a.index.compareTo(b.index));
      return periods;
    });
  }

  // --- Breaks Subcollection ---

  @override
  Future<void> saveBreak(String timetableId, TimetableBreakModel breakModel) async {
    breakModel.validate();
    final id = breakModel.id.isNotEmpty ? breakModel.id : const Uuid().v4();
    final toSave = breakModel.copyWith(id: id);
    await _firestoreService.setDocument('timetables/$timetableId/breaks', id, toSave.toJson());
  }

  @override
  Future<void> saveBreaksBatch(String timetableId, List<TimetableBreakModel> breaks) async {
    final batchMap = <String, Map<String, dynamic>>{};
    for (final b in breaks) {
      b.validate();
      final id = b.id.isNotEmpty ? b.id : const Uuid().v4();
      final toSave = b.copyWith(id: id);
      batchMap['timetables/$timetableId/breaks/$id'] = toSave.toJson();
    }
    await _firestoreService.batchSetDocuments(batchMap);
  }

  @override
  Future<void> deleteBreak(String timetableId, String breakId) async {
    await _firestoreService.deleteDocument('timetables/$timetableId/breaks', breakId);
  }

  @override
  Future<List<TimetableBreakModel>> getBreaks(String timetableId) async {
    final docs = await _firestoreService.getCollection('timetables/$timetableId/breaks');
    return docs.map((d) => TimetableBreakModel.fromJson(d)).toList();
  }

  @override
  Stream<List<TimetableBreakModel>> watchBreaks(String timetableId) {
    return _firestoreService.watchCollection('timetables/$timetableId/breaks').map(
      (docs) => docs.map((d) => TimetableBreakModel.fromJson(d)).toList(),
    );
  }

  // --- Grid Entries Subcollection ---

  @override
  Future<void> saveGridEntry(String timetableId, TimetableGridEntryModel entry) async {
    entry.validate();
    final id = entry.id.isNotEmpty ? entry.id : const Uuid().v4();
    final toSave = entry.copyWith(id: id);
    await _firestoreService.setDocument('timetables/$timetableId/entries', id, toSave.toJson());
  }

  @override
  Future<void> saveGridEntriesBatch(String timetableId, List<TimetableGridEntryModel> entries) async {
    final batchMap = <String, Map<String, dynamic>>{};
    for (final entry in entries) {
      entry.validate();
      final id = entry.id.isNotEmpty ? entry.id : const Uuid().v4();
      final toSave = entry.copyWith(id: id);
      batchMap['timetables/$timetableId/entries/$id'] = toSave.toJson();
    }
    await _firestoreService.batchSetDocuments(batchMap);
  }

  @override
  Future<void> deleteGridEntry(String timetableId, String entryId) async {
    await _firestoreService.deleteDocument('timetables/$timetableId/entries', entryId);
  }

  @override
  Future<List<TimetableGridEntryModel>> getGridEntries(String timetableId) async {
    final docs = await _firestoreService.getCollection('timetables/$timetableId/entries');
    return docs.map((d) => TimetableGridEntryModel.fromJson(d)).toList();
  }

  @override
  Stream<List<TimetableGridEntryModel>> watchGridEntries(String timetableId) {
    return _firestoreService.watchCollection('timetables/$timetableId/entries').map(
      (docs) => docs.map((d) => TimetableGridEntryModel.fromJson(d)).toList(),
    );
  }

  // --- Validation, Publishing & Backward-Compatible Projection ---

  @override
  Future<void> validateTimetableForPublishing(String timetableId) async {
    final container = await getTimetableContainer(timetableId);
    if (container == null) {
      throw Exception('Timetable container not found: $timetableId');
    }
    container.validate();

    final periods = await getPeriods(timetableId);
    final breaks = await getBreaks(timetableId);
    final entries = await getGridEntries(timetableId);

    if (periods.isEmpty) {
      throw ArgumentError('Cannot publish timetable without defined periods.');
    }

    for (final p in periods) {
      p.validate();
    }
    for (final b in breaks) {
      b.validate();
    }
    for (final e in entries) {
      e.validate();
    }

    // 1. Grid entries internal collisions (Same day horizontal overlap, Section, Faculty, Room)
    for (int i = 0; i < entries.length; i++) {
      for (int j = i + 1; j < entries.length; j++) {
        final e1 = entries[i];
        final e2 = entries[j];

        if (e1.dayOfWeek == e2.dayOfWeek) {
          final isHorizOverlap = e1.overlapsHorizontallyWith(e2);
          final isTimeOverlap = e1.overlapsTimeWith(e2);

          if (isHorizOverlap || isTimeOverlap) {
            // Section collision
            throw TimetableConflictException(
              "Section conflict: Multiple classes occupy the same timeslot on ${e1.dayOfWeek.displayName} (${e1.startTime}-${e1.endTime} and ${e2.startTime}-${e2.endTime}).",
            );
          }

          if (e1.facultyId == e2.facultyId && (isHorizOverlap || isTimeOverlap)) {
            throw TimetableConflictException(
              "Faculty conflict: Faculty already has a class scheduled on ${e1.dayOfWeek.displayName} during this timeslot.",
            );
          }

          if (e1.roomNumber.isNotEmpty && e1.roomNumber == e2.roomNumber && (isHorizOverlap || isTimeOverlap)) {
            throw TimetableConflictException(
              "Room conflict: Room ${e1.roomNumber} is already occupied on ${e1.dayOfWeek.displayName} during this timeslot.",
            );
          }
        }
      }
    }

    // 2. Entry vs Break collision checks
    for (final entry in entries) {
      for (final breakModel in breaks) {
        if (entry.conflictsWithBreak(breakModel)) {
          throw TimetableConflictException(
            "Break conflict: Class '${entry.subjectId}' on ${entry.dayOfWeek.displayName} overlaps with ${breakModel.name} (${breakModel.startTime} - ${breakModel.endTime}).",
          );
        }
      }
    }
  }

  @override
  Future<void> publishTimetable(String timetableId, {required String publishedBy}) async {
    final container = await getTimetableContainer(timetableId);
    if (container == null) {
      throw Exception('Timetable container not found: $timetableId');
    }

    await _checkManagePermission(container.collegeId, container.departmentId);
    await validateTimetableForPublishing(timetableId);

    final entries = await getGridEntries(timetableId);
    final now = DateTime.now();
    final batchMap = <String, Map<String, dynamic>>{};

    // 1. Update container status to published
    final publishedContainer = container.copyWith(
      status: TimetableStatus.published,
      publishedAt: now,
      publishedBy: publishedBy,
      version: container.version + 1,
      updatedAt: now,
    );
    batchMap['timetables/$timetableId'] = publishedContainer.toJson();

    // 2. Convert ONLY teaching entries into legacy-compatible /timetable projections (Breaks ignored)
    for (final entry in entries) {
      final projectedId = 'pub_${timetableId}_${entry.id}';
      final legacyModel = TimetableModel(
        id: projectedId,
        collegeId: container.collegeId,
        departmentId: container.departmentId,
        courseId: container.courseId,
        academicYearId: container.academicYearId,
        semesterId: container.semesterId,
        sectionId: container.sectionId,
        subjectId: entry.subjectId,
        facultyId: entry.facultyId,
        dayOfWeek: entry.dayOfWeek,
        startTime: entry.startTime,
        endTime: entry.endTime,
        roomNumber: entry.roomNumber,
        building: entry.building,
        sessionType: entry.sessionType,
        createdAt: container.createdAt,
        updatedAt: now,
      );
      batchMap['timetable/$projectedId'] = legacyModel.toJson();
    }

    // 3. Atomically commit batch
    await _firestoreService.batchSetDocuments(batchMap);

    _debugLog('publishTimetable', {
      'timetableId': timetableId,
      'version': publishedContainer.version,
      'publishedEntriesCount': entries.length,
    });

    if (_notificationService != null) {
      try {
        await _notificationService.notifyTimetableUpdated(
          sectionId: container.sectionId,
          subjectName: 'All Classes (Published Timetable v${publishedContainer.version})',
        );
      } catch (e) {
        developer.log('[Timetable] notifyTimetableUpdated failed on publish: $e', name: 'Acadex.Timetable');
      }
    }
  }

  @override
  Future<void> unpublishTimetable(String timetableId) async {
    final container = await getTimetableContainer(timetableId);
    if (container == null) return;

    await _checkManagePermission(container.collegeId, container.departmentId);

    final entries = await getGridEntries(timetableId);
    for (final entry in entries) {
      await _firestoreService.deleteDocument('timetable', 'pub_${timetableId}_${entry.id}');
    }

    final draftContainer = container.copyWith(
      status: TimetableStatus.draft,
      clearPublished: true,
      updatedAt: DateTime.now(),
    );
    await _firestoreService.setDocument('timetables', timetableId, draftContainer.toJson());
  }

  Future<void> _validateFacultyAssignment(TimetableModel entry) async {
    final userDoc = await _firestoreService.getDocument('users', entry.facultyId);
    if (userDoc == null) throw Exception('Faculty user not found');

    final roleStr = userDoc['role'] as String?;
    if (roleStr == null) throw Exception('User role missing');

    AppRole role;
    try {
      role = AppRoleExtension.fromValue(roleStr);
    } catch (_) {
      throw Exception('Invalid role for timetable faculty assignment');
    }

    if (role != AppRole.faculty && role != AppRole.superAdmin && role != AppRole.collegeAdmin && role != AppRole.hod) {
      throw Exception('Invalid role for timetable faculty assignment');
    }

    if (role == AppRole.faculty) {
      final subjectIds = List<String>.from(userDoc['subjectIds'] ?? userDoc['assignedSubjects'] ?? []);
      final sectionIds = List<String>.from(userDoc['sectionIds'] ?? userDoc['assignedClasses'] ?? []);
      
      if (subjectIds.isNotEmpty && !subjectIds.contains(entry.subjectId)) {
        throw Exception('Unauthorized: Faculty is not assigned to this subject.');
      }
      if (sectionIds.isNotEmpty && !sectionIds.contains(entry.sectionId)) {
        throw Exception('Unauthorized: Faculty is not assigned to this section.');
      }
    }
  }
}

