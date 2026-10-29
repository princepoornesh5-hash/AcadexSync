import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/domain/models/role_enum.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';

extension SafeNavigationExtension on BuildContext {
  /// Resolves an intelligent fallback route if no navigation history exists in the stack.
  String resolveDefaultFallback() {
    // 1. Try to inspect current matched location
    String currentPath = '';
    try {
      final state = GoRouterState.of(this);
      currentPath = state.matchedLocation;
    } catch (_) {
      try {
        currentPath = GoRouter.of(this).routeInformationProvider.value.uri.path;
      } catch (_) {}
    }

    // 2. Derive parent route for subroutes
    if (currentPath.isNotEmpty && currentPath != '/') {
      final segments = currentPath
          .split('/')
          .where((s) => s.isNotEmpty)
          .toList();
      if (segments.length > 1) {
        final parentPath =
            '/${segments.sublist(0, segments.length - 1).join('/')}';
        // Avoid falling back to root or /dashboard prefix without role
        if (parentPath.isNotEmpty && parentPath != '/dashboard') {
          return parentPath;
        }
      }
    }

    // 3. Fallback to role-appropriate dashboard or login
    try {
      final container = ProviderScope.containerOf(this, listen: false);
      final user = container.read(currentUserProvider);
      if (user != null) {
        switch (user.role) {
          case AppRole.superAdmin:
            return '/dashboard/super_admin';
          case AppRole.collegeAdmin:
            return '/dashboard/college_admin';
          case AppRole.hod:
            return '/dashboard/hod';
          case AppRole.faculty:
            return '/dashboard/faculty';
          case AppRole.student:
            return '/dashboard/student';
        }
      }
    } catch (_) {}

    return '/dashboard';
  }

  /// Safely pops the current screen if possible, falling back to a specified route or the role dashboard.
  /// Prevents `Bad state: There is nothing to pop` exceptions when deep-linking, refreshing,
  /// or navigating via `context.go()`.
  void safePop({String? fallbackRoute}) {
    if (canPop()) {
      pop();
    } else if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop();
    } else if (fallbackRoute != null && fallbackRoute.isNotEmpty) {
      go(fallbackRoute);
    } else {
      go(resolveDefaultFallback());
    }
  }
}
