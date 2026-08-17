import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../domain/models/timetable_models.dart';
import 'timetable_repository.dart';

class FirebaseTimetableRepository implements TimetableRepository {
  final FirestoreService _firestoreService;
  
  FirebaseTimetableRepository(this._firestoreService);

  CollectionReference get _collection => FirebaseFirestore.instance.collection('timetable');

  @override
  Stream<List<TimetableModel>> watchTimetable({
    required AppRole role,
    required String userId,
    String? collegeId,
    String? departmentId,
    String? sectionId,
  }) {
    Query query = _collection;

    switch (role) {
      case AppRole.student:
        if (sectionId != null) {
          query = query.where('sectionId', isEqualTo: sectionId);
        }
        break;
      case AppRole.faculty:
        query = query.where('facultyId', isEqualTo: userId);
        break;
      case AppRole.hod:
        if (departmentId != null) {
          query = query.where('departmentId', isEqualTo: departmentId);
        }
        break;
      case AppRole.collegeAdmin:
        if (collegeId != null) {
          query = query.where('collegeId', isEqualTo: collegeId);
        }
        break;
      case AppRole.superAdmin:
        // Super admin sees all, or maybe we don't watch all?
        break;
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TimetableModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
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
    Query query = _collection.where('collegeId', isEqualTo: collegeId);

    if (departmentId != null) query = query.where('departmentId', isEqualTo: departmentId);
    if (courseId != null) query = query.where('courseId', isEqualTo: courseId);
    if (semesterId != null) query = query.where('semesterId', isEqualTo: semesterId);
    if (sectionId != null) query = query.where('sectionId', isEqualTo: sectionId);
    if (facultyId != null) query = query.where('facultyId', isEqualTo: facultyId);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => TimetableModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> checkConflicts(TimetableModel entry) async {
    // 1. Faculty Conflict
    final facultySnapshot = await _collection
        .where('facultyId', isEqualTo: entry.facultyId)
        .where('dayOfWeek', isEqualTo: entry.dayOfWeek.name)
        .get();
        
    for (var doc in facultySnapshot.docs) {
      final existing = TimetableModel.fromJson(doc.data() as Map<String, dynamic>);
      if (existing.id == entry.id) continue;
      if (existing.overlapsWith(entry)) {
        throw TimetableConflictException(
          "Faculty already has a class scheduled during this time.",
          conflictingEntry: existing,
        );
      }
    }

    // 2. Section Conflict
    final sectionSnapshot = await _collection
        .where('sectionId', isEqualTo: entry.sectionId)
        .where('dayOfWeek', isEqualTo: entry.dayOfWeek.name)
        .get();
        
    for (var doc in sectionSnapshot.docs) {
      final existing = TimetableModel.fromJson(doc.data() as Map<String, dynamic>);
      if (existing.id == entry.id) continue;
      if (existing.overlapsWith(entry)) {
        throw TimetableConflictException(
          "This section already has a class scheduled during this time.",
          conflictingEntry: existing,
        );
      }
    }

    // 3. Room Conflict
    final roomSnapshot = await _collection
        .where('roomNumber', isEqualTo: entry.roomNumber)
        .where('building', isEqualTo: entry.building)
        .where('dayOfWeek', isEqualTo: entry.dayOfWeek.name)
        .get();
        
    for (var doc in roomSnapshot.docs) {
      final existing = TimetableModel.fromJson(doc.data() as Map<String, dynamic>);
      if (existing.id == entry.id) continue;
      if (existing.overlapsWith(entry)) {
        throw TimetableConflictException(
          "Room ${entry.roomNumber} in ${entry.building ?? 'Main'} is already occupied during this time.",
          conflictingEntry: existing,
        );
      }
    }
  }

  @override
  Future<void> createEntry(TimetableModel entry) async {
    await checkConflicts(entry);

    final id = const Uuid().v4();
    final newEntry = entry.copyWith(
      id: id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _collection.doc(id).set(newEntry.toJson());
  }

  @override
  Future<void> updateEntry(TimetableModel entry) async {
    await checkConflicts(entry);

    final updatedEntry = entry.copyWith(updatedAt: DateTime.now());
    await _collection.doc(entry.id).update(updatedEntry.toJson());
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    await _collection.doc(entryId).delete();
  }
}
