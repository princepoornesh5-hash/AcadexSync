import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/notifications/domain/models/notification_models.dart';
import 'package:campus_management/features/notifications/data/repositories/notification_repository.dart';
import 'package:campus_management/core/firebase/firebase_services.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  final NotificationRepository _notificationRepository;
  final FirestoreService _firestoreService;

  NotificationService(this._notificationRepository, this._firestoreService);

  /// Helper to generate a standardized ID
  String _generateId() => const Uuid().v4();

  /// Fan-out personal notifications to a specific section
  Future<void> notifySection({
    required String sectionId,
    required String title,
    required String message,
    required NotificationCategory category,
    required NotificationPriority priority,
    String? relatedEntityId,
    String? relatedEntityType,
    String? navigationTarget,
  }) async {
    // 1. Fetch all student profiles in this section
    final profiles = await _firestoreService.queryCollection('user_profiles', {
      'sectionId': sectionId,
    });

    // 2. Fan-out personal notifications
    for (final profile in profiles) {
      final userId = profile['userId'];
      if (userId == null) continue;

      final n = NotificationModel(
        id: _generateId(),
        title: title,
        message: message,
        category: category,
        priority: priority,
        audienceType: NotificationAudienceType.personal,
        timestamp: DateTime.now(),
        recipientUserId: userId,
        recipientRole: AppRole.student,
        sectionId: sectionId,
        relatedEntityId: relatedEntityId,
        relatedEntityType: relatedEntityType,
        navigationTarget: navigationTarget,
      );

      await _notificationRepository.createPersonalNotification(n);
    }
  }

  /// Notify all students of a published note
  Future<void> notifyNotePublished({
    required String noteId,
    required String noteTitle,
    required String sectionId,
  }) async {
    await notifySection(
      sectionId: sectionId,
      title: 'New Note Available',
      message: 'A new note "$noteTitle" has been published to your section.',
      category: NotificationCategory.notes,
      priority: NotificationPriority.normal,
      relatedEntityId: noteId,
      relatedEntityType: 'note',
      navigationTarget: '/notes/$noteId',
    );
  }

  /// Notify students of a timetable change
  Future<void> notifyTimetableUpdated({
    required String sectionId,
    required String subjectName,
  }) async {
    await notifySection(
      sectionId: sectionId,
      title: 'Timetable Updated',
      message: 'The timetable for $subjectName has been updated.',
      category: NotificationCategory.timetable,
      priority: NotificationPriority.normal,
      relatedEntityType: 'timetable',
      navigationTarget: '/timetable',
    );
  }

  /// Notify students of an attendance submission
  Future<void> notifyAttendanceMarked({
    required String sectionId,
    required String subjectName,
    required DateTime sessionDate,
  }) async {
    // Format date simply
    final dateStr = '${sessionDate.year}-${sessionDate.month.toString().padLeft(2, '0')}-${sessionDate.day.toString().padLeft(2, '0')}';
    
    await notifySection(
      sectionId: sectionId,
      title: 'Attendance Recorded',
      message: 'Attendance for $subjectName on $dateStr has been recorded.',
      category: NotificationCategory.attendance,
      priority: NotificationPriority.low,
      relatedEntityType: 'attendance',
      navigationTarget: '/attendance',
    );
  }
}
