import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../domain/models/attendance_alert.dart';
import '../../domain/repositories/attendance_alert_repository.dart';

/// Firebase Firestore implementation of AttendanceAlertRepository.
class FirebaseAttendanceAlertRepository implements AttendanceAlertRepository {
  static const String collectionName = 'attendance_alerts';

  final FirestoreService _firestoreService;

  FirebaseAttendanceAlertRepository(this._firestoreService);

  void _debugLog(String operation, Map<String, dynamic> metadata) {
    if (kDebugMode) {
      final safeMetadata = Map<String, dynamic>.from(metadata)
        ..removeWhere((key, _) => key.toLowerCase().contains('password') || key.toLowerCase().contains('secret'));
      final formatted = safeMetadata.entries.map((e) => '${e.key}=${e.value}').join(', ');
      developer.log('[AttendanceAlerts] $operation: $formatted', name: 'Acadex.AttendanceAlerts');
    }
  }

  /// Builds query filters enforcing role scoping and multi-tenant security
  Map<String, dynamic> _buildScopeFilters(UserModel user, AttendanceAlertFilter? filter) {
    final filters = <String, dynamic>{};

    // 1. Tenant Isolation
    if (user.role != AppRole.superAdmin) {
      if (user.collegeId != null && user.collegeId!.isNotEmpty) {
        filters['collegeId'] = user.collegeId;
      }
    }

    // 2. Role Scoping
    switch (user.role) {
      case AppRole.student:
        filters['studentId'] = user.id;
        break;
      case AppRole.faculty:
        // Scoped by facultyId
        filters['facultyId'] = user.id;
        break;
      case AppRole.hod:
        // Scoped to HOD's department
        if (user.departmentId != null && user.departmentId!.isNotEmpty) {
          filters['departmentId'] = user.departmentId;
        }
        break;
      case AppRole.collegeAdmin:
      case AppRole.superAdmin:
        // College scope already applied above
        break;
    }

    // 3. Optional Filter Parameters
    if (filter != null) {
      if (filter.severity != null) {
        filters['severity'] = filter.severity!.name;
      }
      if (filter.status != null) {
        filters['status'] = filter.status!.name;
      }
      if (filter.unreadOnly == true) {
        filters['isRead'] = false;
      }
      if (filter.alertType != null) {
        filters['alertType'] = filter.alertType!.name;
      }
      if (filter.sectionId != null && filter.sectionId!.isNotEmpty) {
        filters['sectionId'] = filter.sectionId;
      }
      if (filter.subjectId != null && filter.subjectId!.isNotEmpty) {
        filters['subjectId'] = filter.subjectId;
      }
    }

    return filters;
  }

  @override
  Future<List<AttendanceAlert>> getAlerts({
    required UserModel user,
    AttendanceAlertFilter? filter,
    String? searchQuery,
  }) async {
    final filters = _buildScopeFilters(user, filter);
    _debugLog('getAlerts', {
      'userId': user.id,
      'role': user.role.name,
      'collegeId': user.collegeId,
      'filters': filters,
      'searchQuery': searchQuery,
    });

    List<Map<String, dynamic>> rawDocs;
    if (filters.isNotEmpty) {
      rawDocs = await _firestoreService.queryCollection(collectionName, filters);
    } else {
      rawDocs = await _firestoreService.getCollection(collectionName);
    }

    var alerts = rawDocs.map((d) => AttendanceAlert.fromJson(d)).toList();

    // In-memory client search over authorized result set
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      alerts = alerts.where((a) {
        final studentMatch = a.studentName?.toLowerCase().contains(q) ?? false;
        final rollMatch = a.rollNumber?.toLowerCase().contains(q) ?? false;
        final subjectMatch = a.subjectName?.toLowerCase().contains(q) ?? false;
        final sectionMatch = a.sectionId?.toLowerCase().contains(q) ?? false;
        final titleMatch = a.title.toLowerCase().contains(q);
        final messageMatch = a.message.toLowerCase().contains(q);
        return studentMatch || rollMatch || subjectMatch || sectionMatch || titleMatch || messageMatch;
      }).toList();
    }

    // In-memory filter fallback for unread / status / severity if query was general
    if (filter != null) {
      if (filter.unreadOnly == true) {
        alerts = alerts.where((a) => a.isRead == false).toList();
      }
      if (filter.severity != null) {
        alerts = alerts.where((a) => a.severity == filter.severity).toList();
      }
      if (filter.status != null) {
        alerts = alerts.where((a) => a.status == filter.status).toList();
      }
    }

    // Sort: Critical severity first, then newest timestamp
    alerts.sort((a, b) {
      final severityWeightA = a.severity == AttendanceAlertSeverity.critical
          ? 2
          : (a.severity == AttendanceAlertSeverity.warning ? 1 : 0);
      final severityWeightB = b.severity == AttendanceAlertSeverity.critical
          ? 2
          : (b.severity == AttendanceAlertSeverity.warning ? 1 : 0);

      if (severityWeightA != severityWeightB) {
        return severityWeightB.compareTo(severityWeightA); // Higher severity first
      }
      return b.createdAt.compareTo(a.createdAt); // Newest first
    });

    return alerts;
  }

  @override
  Stream<List<AttendanceAlert>> streamAlerts({
    required UserModel user,
    AttendanceAlertFilter? filter,
    String? searchQuery,
  }) async* {
    final alerts = await getAlerts(user: user, filter: filter, searchQuery: searchQuery);
    yield alerts;
  }

  @override
  Future<AttendanceAlert?> getAlertById(String alertId) async {
    final doc = await _firestoreService.getDocument(collectionName, alertId);
    if (doc == null) return null;
    return AttendanceAlert.fromJson(doc);
  }

  @override
  Future<void> saveAlert(AttendanceAlert alert) async {
    _debugLog('saveAlert', {
      'id': alert.id,
      'type': alert.alertType.name,
      'severity': alert.severity.name,
      'studentId': alert.studentId,
    });
    await _firestoreService.setDocument(collectionName, alert.id, alert.toJson());
  }

  @override
  Future<void> saveAlerts(List<AttendanceAlert> alerts) async {
    if (alerts.isEmpty) return;
    _debugLog('saveAlerts', {'count': alerts.length});
    final batchMap = <String, Map<String, dynamic>>{};
    for (final a in alerts) {
      batchMap['$collectionName/${a.id}'] = a.toJson();
    }
    await _firestoreService.batchSetDocuments(batchMap);
  }

  @override
  Future<void> markAsRead(String alertId) async {
    final existing = await getAlertById(alertId);
    if (existing == null) return;
    final updated = existing.copyWith(
      isRead: true,
      readAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveAlert(updated);
  }

  @override
  Future<void> markAllAsRead({required UserModel user}) async {
    final alerts = await getAlerts(user: user, filter: const AttendanceAlertFilter(unreadOnly: true));
    final now = DateTime.now();
    final updatedList = alerts.map((a) => a.copyWith(
          isRead: true,
          readAt: now,
          updatedAt: now,
        )).toList();
    await saveAlerts(updatedList);
  }

  @override
  Future<void> acknowledgeAlert(String alertId) async {
    final existing = await getAlertById(alertId);
    if (existing == null) return;
    final updated = existing.copyWith(
      status: AttendanceAlertStatus.acknowledged,
      acknowledgedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isRead: true,
    );
    await saveAlert(updated);
  }

  @override
  Future<void> resolveAlert(String alertId) async {
    final existing = await getAlertById(alertId);
    if (existing == null) return;
    final updated = existing.copyWith(
      status: AttendanceAlertStatus.resolved,
      resolvedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveAlert(updated);
  }

  @override
  Future<AttendanceAlertSummary> getAlertSummary({required UserModel user}) async {
    final allScopedAlerts = await getAlerts(user: user);
    return AttendanceAlertSummary.fromAlerts(allScopedAlerts);
  }
}
