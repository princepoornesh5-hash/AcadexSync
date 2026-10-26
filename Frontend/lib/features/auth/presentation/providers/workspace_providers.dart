import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/realtime/presentation/providers/realtime_providers.dart';
import '../../data/repositories/workspace_repository.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/role_enum.dart';
import '../../domain/models/user_model.dart';
import '../../domain/models/workspace_model.dart';
import '../../services/session_manager.dart';
import 'auth_provider.dart';

import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../../timetable/presentation/providers/timetable_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../../../analytics/presentation/providers/analytics_providers.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../requests/presentation/providers/requests_providers.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';
import '../../../academic_results/presentation/providers/academic_result_providers.dart';

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return WorkspaceRepository();
});

/// Authoritative list of active workspace memberships for the authenticated user
final userWorkspacesProvider = FutureProvider<List<WorkspaceMembershipModel>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    return [];
  }

  final repo = ref.watch(workspaceRepositoryProvider);
  try {
    final memberships = await repo.getMyMemberships();
    // Exclude any non-active memberships from ordinary selection
    return memberships.where((m) => m.isActive).toList();
  } catch (e) {
    debugPrint('[WORKSPACE] Failed to load memberships: $e');
    return [];
  }
});

/// Currently selected active workspace ID in the client session
final activeWorkspaceIdProvider = StateProvider<String?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return authState.user.collegeId;
  }
  return null;
});

/// Fully resolved active workspace model from authoritative memberships
final activeWorkspaceProvider = Provider<WorkspaceMembershipModel?>((ref) {
  final workspacesAsync = ref.watch(userWorkspacesProvider);
  final activeId = ref.watch(activeWorkspaceIdProvider);
  final authState = ref.watch(authProvider);

  final memberships = workspacesAsync.value ?? [];
  if (memberships.isEmpty) return null;

  if (activeId != null && activeId.isNotEmpty) {
    final match = memberships.where((m) => m.collegeId == activeId);
    if (match.isNotEmpty) return match.first;
  }

  // Fallback to user's collegeId if activeId not set
  if (authState is AuthAuthenticated && authState.user.collegeId != null) {
    final match = memberships.where((m) => m.collegeId == authState.user.collegeId);
    if (match.isNotEmpty) return match.first;
  }

  // Fallback to default workspace
  final defaultWorkspace = memberships.where((m) => m.isDefault);
  if (defaultWorkspace.isNotEmpty) return defaultWorkspace.first;

  return memberships.first;
});

/// Counter incremented on each workspace switch or logout to guard against stale in-flight responses
final workspaceGenerationProvider = StateProvider<int>((ref) => 0);

/// Guard flag preventing concurrent duplicate workspace switches
final isSwitchingWorkspaceProvider = StateProvider<bool>((ref) => false);

/// Central controller executing the secure workspace switching lifecycle
class WorkspaceSwitchController {
  final Ref _ref;
  final WorkspaceRepository _repository;
  final SessionManager _sessionManager;
  final ApiClient _apiClient;

  WorkspaceSwitchController(
    this._ref,
    this._repository,
    this._sessionManager,
    this._apiClient,
  );

  void _invalidateWorkspaceScopedCaches() {
    try {
      _ref.read(workspaceGenerationProvider.notifier).state++;
      _apiClient.incrementWorkspaceEpoch();

      _ref.invalidate(userWorkspacesProvider);
      _ref.invalidate(notificationsProvider);
      _ref.invalidate(unreadNotificationCountProvider);
      _ref.invalidate(announcementsProvider);
      _ref.invalidate(adminAnnouncementsProvider);
      _ref.invalidate(userNotesProvider);
      _ref.invalidate(myFacultyAssignmentsProvider);
      _ref.invalidate(myFacultyAssignmentsAsyncProvider);
      _ref.invalidate(todayScheduleProvider);
      _ref.invalidate(weeklyTimetableProvider);
      _ref.invalidate(currentStudentAcademicProfileProvider);
      _ref.invalidate(departmentsProvider);
      _ref.invalidate(coursesProvider);
      _ref.invalidate(semestersProvider);
      _ref.invalidate(sectionsProvider);
      _ref.invalidate(studentStatsProvider);
      _ref.invalidate(facultyStatsProvider);
      _ref.invalidate(hodStatsProvider);
      _ref.invalidate(collegeAdminStatsProvider);
      _ref.invalidate(superAdminStatsProvider);
      _ref.invalidate(roleDashboardReportProvider);
      _ref.invalidate(assignedClassesProvider);
      _ref.invalidate(activeClassProvider);
      _ref.invalidate(activeStudentListProvider);
      _ref.invalidate(facultySessionsProvider);
      _ref.invalidate(myAttendanceReportProvider);
      _ref.invalidate(myRequestsProvider);
      _ref.invalidate(selectedCalendarDateProvider);
      _ref.invalidate(currentMonthProvider);
      _ref.invalidate(studentOfficialResultProvider);
      _ref.invalidate(analyticsSummaryProvider);
      _ref.invalidate(trendChartProvider);
      _ref.invalidate(comparisonChartProvider);
      _ref.invalidate(insightsProvider);
      _ref.invalidate(recentReportsProvider);
    } catch (_) {}
  }

  /// Executes authoritative workspace switch following Prompt 4 lifecycle
  Future<bool> switchWorkspace(String targetCollegeId) async {
    final isSwitching = _ref.read(isSwitchingWorkspaceProvider);
    if (isSwitching) {
      debugPrint('[WORKSPACE] Switch already in progress. Ignoring duplicate request.');
      return false;
    }

    final authState = _ref.read(authProvider);
    if (authState is! AuthAuthenticated) {
      debugPrint('[WORKSPACE] Switch attempted without authenticated session.');
      return false;
    }

    final currentCollegeId = _ref.read(activeWorkspaceIdProvider) ?? authState.user.collegeId;
    if (currentCollegeId == targetCollegeId) {
      debugPrint('[WORKSPACE] Target workspace is already active ($targetCollegeId).');
      return true;
    }

    _ref.read(isSwitchingWorkspaceProvider.notifier).state = true;

    try {
      // 1. Authoritative membership validation check
      final availableWorkspaces = await _ref.read(userWorkspacesProvider.future);
      final eligible = availableWorkspaces.any(
        (m) => m.collegeId == targetCollegeId && m.isActive,
      );

      // Super admins may enter college context without explicit membership
      final isSuperAdmin = authState.user.role == AppRole.superAdmin;
      if (!eligible && !isSuperAdmin) {
        throw Exception('You do not hold an active membership in this college workspace.');
      }

      // 2. Execute secure backend switch
      final result = await _repository.switchWorkspace(targetCollegeId);

      // 3. Persist new token and active workspace in client storage
      await _apiClient.saveToken(result.accessToken);
      await _apiClient.setActiveWorkspace(targetCollegeId);

      // 4. Update session manager with new user and token
      final updatedUser = UserModel.fromJson(result.userJson);
      await _sessionManager.saveSession(
        token: result.accessToken,
        user: updatedUser,
      );

      // 5. Rebind realtime rooms via socket without dropping connection
      try {
        final realtime = _ref.read(realtimeServiceProvider);
        realtime.switchWorkspace(targetCollegeId);
      } catch (e) {
        debugPrint('[WORKSPACE] Realtime room rebind notice skipped: $e');
      }

      // 6. Invalidate all workspace-scoped caches & providers
      _invalidateWorkspaceScopedCaches();

      // 7. Update active workspace state & auth state
      _ref.read(activeWorkspaceIdProvider.notifier).state = targetCollegeId;
      _ref.read(authProvider.notifier).updateCurrentUser(updatedUser);

      debugPrint('[WORKSPACE] Successfully switched to workspace $targetCollegeId (${updatedUser.role.displayName})');
      return true;
    } catch (e) {
      debugPrint('[WORKSPACE] Failed to switch workspace: $e');
      rethrow;
    } finally {
      _ref.read(isSwitchingWorkspaceProvider.notifier).state = false;
    }
  }
}

final workspaceSwitchControllerProvider = Provider<WorkspaceSwitchController>((ref) {
  return WorkspaceSwitchController(
    ref,
    ref.watch(workspaceRepositoryProvider),
    ref.watch(sessionManagerProvider),
    apiClient,
  );
});
