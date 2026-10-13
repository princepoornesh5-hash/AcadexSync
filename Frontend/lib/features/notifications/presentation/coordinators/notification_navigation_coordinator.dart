import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/workspace_providers.dart';
import '../../domain/models/notification_models.dart';

class NotificationNavigationCoordinator {
  final Ref _ref;

  // Stored pending notification intent for cold start / uninitialized auth
  NotificationModel? _pendingNotification;

  NotificationNavigationCoordinator(this._ref);

  NotificationModel? get pendingNotification => _pendingNotification;

  void setPendingNotification(NotificationModel notification) {
    _pendingNotification = notification;
  }

  void clearPendingNotification() {
    _pendingNotification = null;
  }

  /// Processes any pending notification tap once auth has initialized
  Future<void> processPendingIfAny(BuildContext context) async {
    final pending = _pendingNotification;
    if (pending == null) return;

    final authState = _ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      _pendingNotification = null;
      await handleNotificationTap(context, pending);
    }
  }

  /// Central entry point for handling notification tap across UI, push, and realtime
  Future<void> handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
  ) async {
    final authState = _ref.read(authProvider);
    if (authState is! AuthAuthenticated) {
      // Store intent for cold start replay
      _pendingNotification = notification;
      return;
    }

    // 1. Resolve target navigation URI
    final targetRoute = _resolveNavigationRoute(notification);
    if (targetRoute == null || targetRoute.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No destination available for this notification.')),
      );
      return;
    }

    final targetCollegeId = notification.collegeId;
    final currentCollegeId = _ref.read(activeWorkspaceIdProvider) ?? authState.user.collegeId;

    // 2. Cross-workspace handling
    if (targetCollegeId != null &&
        targetCollegeId.isNotEmpty &&
        targetCollegeId != currentCollegeId) {
      try {
        final availableWorkspaces = await _ref.read(userWorkspacesProvider.future);
        final hasEligibleMembership = availableWorkspaces.any(
          (m) => m.collegeId == targetCollegeId && m.isActive,
        );

        final isSuperAdmin = authState.user.role == AppRole.superAdmin;

        if (!hasEligibleMembership && !isSuperAdmin) {
          // Access denied: do not switch workspace, do not reveal sensitive resources
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Access Denied: You do not have an active membership in this college workspace.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }

        // Switch workspace authoritatively
        final switchSuccess = await _ref
            .read(workspaceSwitchControllerProvider)
            .switchWorkspace(targetCollegeId);

        if (!switchSuccess) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to switch workspace.')),
            );
          }
          return;
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Workspace access error: $e')),
          );
        }
        return;
      }
    }

    // 3. Navigate to destination route within the now-authoritative workspace context
    if (!context.mounted) return;
    try {
      context.push(targetRoute);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This resource is no longer available.')),
        );
      }
    }
  }

  String? _resolveNavigationRoute(NotificationModel notification) {
    if (notification.navigationTarget != null && notification.navigationTarget!.isNotEmpty) {
      return notification.navigationTarget;
    }

    final entityType = notification.relatedEntityType?.toUpperCase();
    final entityId = notification.relatedEntityId;

    if (entityType == 'REQUEST' && entityId != null) {
      return '/requests/$entityId';
    }
    if (entityType == 'ASSIGNMENT' && entityId != null) {
      return '/assignments/$entityId';
    }
    if (entityType == 'ASSESSMENT' && entityId != null) {
      return '/assessments/$entityId';
    }
    if ((entityType == 'PRACTICAL' || entityType == 'PRACTICALSESSION') && entityId != null) {
      return '/practicals/$entityId';
    }
    if ((entityType == 'CALENDAR' || entityType == 'CALENDAREVENT') && entityId != null) {
      return '/calendar/event/$entityId';
    }
    if (entityType == 'ACADEMICRESULT') {
      return '/academic-results';
    }
    if (entityType == 'ANNOUNCEMENT' && entityId != null) {
      return '/announcements/$entityId';
    }

    return null;
  }
}

final notificationNavigationCoordinatorProvider = Provider<NotificationNavigationCoordinator>((ref) {
  return NotificationNavigationCoordinator(ref);
});
