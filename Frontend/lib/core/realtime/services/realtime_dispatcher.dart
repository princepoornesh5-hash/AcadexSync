import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/realtime_event.dart';

// Providers for Invalidation
import '../../../../features/notifications/presentation/providers/notification_providers.dart';
import '../../../../features/dashboard/presentation/providers/dashboard_providers.dart';
import '../../../../features/requests/presentation/providers/requests_providers.dart';
import '../../../../features/timetable/presentation/providers/timetable_providers.dart';
import '../../../../features/academic_structure/presentation/providers/academic_providers.dart';
import '../../../../features/assignments/presentation/providers/assignments_providers.dart';
import '../../../../features/practicals/presentation/providers/practicals_providers.dart';
import '../../../../features/academic_records/presentation/providers/academic_records_providers.dart';
import '../../../../features/assessments/presentation/providers/assessment_providers.dart';
import '../../../../features/academic_results/presentation/providers/academic_result_providers.dart';
import '../../../../features/calendar/presentation/providers/calendar_providers.dart';
import '../../../../features/profile/presentation/providers/profile_providers.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/domain/models/auth_state.dart';

class RealtimeDispatcher {
  final Ref _ref;
  StreamSubscription<RealtimeEvent>? _subscription;

  // Domain debounce timers to coalesce burst events
  final Map<String, Timer> _debounceTimers = {};
  static const Duration _debounceWindow = Duration(milliseconds: 300);

  RealtimeDispatcher(this._ref);

  void start(Stream<RealtimeEvent> stream) {
    _subscription?.cancel();
    _subscription = stream.listen(_dispatch);
    debugPrint('[Realtime Dispatcher] Started listening to event stream.');
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }

  void _dispatch(RealtimeEvent event) {
    debugPrint('[Realtime Dispatcher] Processing event: ${event.eventType} (${event.eventId})');

    final domain = event.eventType.split('.').first;

    // Route event with burst debouncing to prevent network storms
    switch (domain) {
      case 'notification':
        _debounceAndExecute('notification', () {
          _ref.invalidate(notificationsProvider);
          _ref.invalidate(unreadNotificationCountProvider);
          _ref.invalidate(homeDashboardProvider);
        });
        break;

      case 'announcement':
        _debounceAndExecute('announcement', () {
          _ref.invalidate(announcementsProvider);
          _ref.invalidate(adminAnnouncementsProvider);
          _ref.invalidate(notificationsProvider);
          _ref.invalidate(unreadNotificationCountProvider);
          _ref.invalidate(homeDashboardProvider);
          _ref.invalidate(superAdminActivityProvider);
          _ref.invalidate(collegeAdminActivityProvider);
          _ref.invalidate(hodActivityProvider);
          _ref.invalidate(facultyActivityProvider);
          _ref.invalidate(studentActivityProvider);
        });
        break;

      case 'request':
        _debounceAndExecute('request', () {
          _ref.invalidate(myRequestsProvider);
          _ref.invalidate(incomingRequestsProvider);
          _ref.invalidate(requestSummaryCountsProvider);
          _ref.invalidate(notificationsProvider);
          _ref.invalidate(unreadNotificationCountProvider);
          _ref.invalidate(homeDashboardProvider);
          if (event.aggregateId.isNotEmpty) {
            _ref.invalidate(requestDetailProvider(event.aggregateId));
          }
        });
        break;

      case 'timetable':
        _debounceAndExecute('timetable', () {
          _ref.invalidate(weeklyTimetableProvider);
          _ref.invalidate(todayScheduleProvider);
          _ref.invalidate(nextClassProvider);
          _ref.invalidate(homeDashboardProvider);
        });
        break;

      case 'attendance':
        _debounceAndExecute('attendance', () {
          // Invalidate timetable & notification as attendance alerts may have been issued
          _ref.invalidate(weeklyTimetableProvider);
          _ref.invalidate(notificationsProvider);
          _ref.invalidate(unreadNotificationCountProvider);
          _ref.invalidate(homeDashboardProvider);
        });
        break;

      case 'facultyAssignment':
        _debounceAndExecute('facultyAssignment', () {
          _ref.invalidate(facultyAssignmentsProvider);
          _ref.invalidate(myFacultyAssignmentsProvider);
          _ref.invalidate(weeklyTimetableProvider);
          _ref.invalidate(facultyCourseAssignmentsProvider);
          _ref.invalidate(homeDashboardProvider);
        });
        break;

      case 'studentEnrollment':
        _debounceAndExecute('studentEnrollment', () {
          final sectionId = event.payload['sectionId'] as String?;
          if (sectionId != null && sectionId.isNotEmpty) {
            _ref.invalidate(sectionEnrollmentsNotifierProvider(sectionId));
          }
          _ref.invalidate(weeklyTimetableProvider);
          _ref.invalidate(studentAssignmentsProvider);
          _ref.invalidate(homeDashboardProvider);
        });
        break;

      case 'assignment':
        _debounceAndExecute('assignment', () {
          _ref.invalidate(facultyCourseAssignmentsProvider);
          _ref.invalidate(studentAssignmentsProvider);
          if (event.aggregateId.isNotEmpty) {
            _ref.invalidate(assignmentDetailProvider(event.aggregateId));
            _ref.invalidate(assignmentActivityProvider(event.aggregateId));
            _ref.invalidate(mySubmissionProvider(event.aggregateId));
          }
          _ref.invalidate(notificationsProvider);
          _ref.invalidate(unreadNotificationCountProvider);
          _ref.invalidate(homeDashboardProvider);
        });
        break;

      case 'submission':
        _debounceAndExecute('submission', () {
          _ref.invalidate(studentAssignmentsProvider);
          _ref.invalidate(facultyCourseAssignmentsProvider);
          final assignmentId = (event.payload['assignmentId'] as String?) ?? event.aggregateId;
          if (assignmentId.isNotEmpty) {
            _ref.invalidate(assignmentDetailProvider(assignmentId));
            _ref.invalidate(assignmentActivityProvider(assignmentId));
            _ref.invalidate(mySubmissionProvider(assignmentId));
          }
          _ref.invalidate(notificationsProvider);
          _ref.invalidate(unreadNotificationCountProvider);
          _ref.invalidate(homeDashboardProvider);
        });
        break;

      case 'note':
        _debounceAndExecute('note', () {
          _ref.invalidate(notificationsProvider);
          _ref.invalidate(unreadNotificationCountProvider);
          _ref.invalidate(homeDashboardProvider);
        });
        break;

      case 'practical':
        _debounceAndExecute('practical', () {
          _ref.invalidate(practicalSessionsListProvider);
          if (event.aggregateId.isNotEmpty) {
            _ref.invalidate(practicalSessionDetailProvider(event.aggregateId));
          }
          final sessionId = event.payload['sessionId'] as String?;
          if (sessionId != null && sessionId.isNotEmpty) {
            _ref.invalidate(practicalSessionDetailProvider(sessionId));
          }
          _ref.invalidate(studentPracticalHistoryProvider(null));
          _ref.invalidate(notificationsProvider);
          _ref.invalidate(unreadNotificationCountProvider);
          _ref.invalidate(homeDashboardProvider);
        });
        break;

      case 'assessment':
        _debounceAndExecute(domain, () {
          _ref.invalidate(studentMarksProvider(null));
          _ref.invalidate(notificationsProvider);
          _ref.invalidate(unreadNotificationCountProvider);
          _ref.invalidate(homeDashboardProvider);
        });
        break;

      case 'academicRecord':
      case 'subjectAcademicRecord':
        _debounceAndExecute(domain, () {
          _ref.invalidate(studentAcademicRecordsHistoryProvider(null));
          if (event.aggregateId.isNotEmpty) {
            _ref.invalidate(academicRecordDetailProvider(event.aggregateId));
          }
          final recordId = event.payload['recordId'] as String?;
          if (recordId != null && recordId.isNotEmpty) {
            _ref.invalidate(academicRecordDetailProvider(recordId));
          }
          _ref.invalidate(notificationsProvider);
          _ref.invalidate(unreadNotificationCountProvider);
          _ref.invalidate(homeDashboardProvider);
        });
        break;

      case 'academicResult':
        _debounceAndExecute(domain, () {
          _ref.invalidate(studentOfficialResultProvider(null));
          _ref.invalidate(adminResultsQueryProvider);
          if (event.aggregateId.isNotEmpty) {
            _ref.invalidate(resultDetailProvider(event.aggregateId));
          }
          _ref.invalidate(notificationsProvider);
          _ref.invalidate(unreadNotificationCountProvider);
          _ref.invalidate(homeDashboardProvider);
        });
        break;

      case 'calendar':
        _debounceAndExecute('calendar', () {
          _ref.invalidate(calendarEventsProvider);
          _ref.invalidate(notificationsProvider);
          _ref.invalidate(unreadNotificationCountProvider);
          _ref.invalidate(homeDashboardProvider);
        });
        break;

      case 'profile':
        _debounceAndExecute('profile', () {
          _ref.invalidate(profileProvider);
          _ref.invalidate(homeDashboardProvider);
          final updatedName = event.payload['name'] as String?;
          final updatedAvatar = event.payload['avatarUrl'] as String?;
          final authState = _ref.read(authProvider);
          if (authState is AuthAuthenticated) {
            final targetUserId = event.payload['userId'] as String? ?? event.aggregateId;
            if (targetUserId == authState.user.id) {
              final updatedUser = authState.user.copyWith(
                name: updatedName ?? authState.user.name,
                profilePictureUrl: updatedAvatar ?? authState.user.profilePictureUrl,
              );
              _ref.read(authProvider.notifier).updateCurrentUser(updatedUser);
            }
          }
        });
        break;

      case 'dashboard':
        _debounceAndExecute('dashboard', () {
          _ref.invalidate(homeDashboardProvider);
        });
        break;

      default:
        // Safely ignore unknown event without crashing
        debugPrint('[Realtime Dispatcher] Unhandled or unknown event type: ${event.eventType}. Ignored safely.');
        break;
    }
  }

  void _debounceAndExecute(String domain, VoidCallback action) {
    if (_debounceTimers.containsKey(domain)) {
      _debounceTimers[domain]?.cancel();
    }

    _debounceTimers[domain] = Timer(_debounceWindow, () {
      _debounceTimers.remove(domain);
      try {
        action();
        debugPrint('[Realtime Dispatcher] Invalidation executed for domain: $domain');
      } catch (err) {
        debugPrint('[Realtime Dispatcher] Error during provider invalidation for $domain: $err');
      }
    });
  }

  /// Triggers authoritative resynchronization across primary providers (e.g. after socket reconnect).
  void triggerAuthoritativeResync() {
    debugPrint('[Realtime Dispatcher] Performing authoritative resync on reconnect...');
    _ref.invalidate(profileProvider);
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadNotificationCountProvider);
    _ref.invalidate(announcementsProvider);
    _ref.invalidate(myRequestsProvider);
    _ref.invalidate(requestSummaryCountsProvider);
    _ref.invalidate(weeklyTimetableProvider);
    _ref.invalidate(myFacultyAssignmentsProvider);
    _ref.invalidate(facultyCourseAssignmentsProvider);
    _ref.invalidate(studentAssignmentsProvider);
    _ref.invalidate(homeDashboardProvider);
  }
}
