import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../features/auth/domain/models/role_enum.dart';

/// Conceptual navigation groups for desktop drawer and navigation rail
enum AcadexNavGroup {
  workspace('WORKSPACE'),
  academics('ACADEMICS'),
  operations('OPERATIONS'),
  insights('INSIGHTS'),
  system('SYSTEM');

  final String title;
  const AcadexNavGroup(this.title);
}

/// Centralized navigation destination definition for all roles and form factors
class AcadexNavItem {
  final String id;
  final String label;
  final IconData icon;
  final String route;
  final AcadexNavGroup group;
  final List<AppRole> allowedRoles;
  final bool isPrimary;
  final List<String> matchingPrefixes;
  final bool Function(String currentRoute)? customMatch;
  final int? badgeCount;

  const AcadexNavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    required this.group,
    required this.allowedRoles,
    this.isPrimary = true,
    this.matchingPrefixes = const [],
    this.customMatch,
    this.badgeCount,
  });

  /// Authoritative route matching logic for active state highlighting
  bool matchesRoute(String currentRoute) {
    if (customMatch != null) {
      return customMatch!(currentRoute);
    }
    if (currentRoute == route) return true;
    for (final prefix in matchingPrefixes) {
      if (currentRoute == prefix || currentRoute.startsWith('$prefix/')) {
        return true;
      }
    }
    if (route != '/' && !route.startsWith('/dashboard')) {
      if (currentRoute.startsWith(route)) {
        return true;
      }
    }
    return false;
  }
}

/// Centralized navigation registry and role-specific resolution service
class AcadexNavigationService {
  AcadexNavigationService._();

  /// Authoritative registry of all navigation destinations across ACADEX
  static final List<AcadexNavItem> _allNavItems = [
    // ── WORKSPACE ──────────────────────────────────────────
    AcadexNavItem(
      id: 'home',
      label: 'Home',
      icon: LucideIcons.layoutDashboard,
      route: '/dashboard',
      group: AcadexNavGroup.workspace,
      allowedRoles: AppRole.values,
      isPrimary: true,
      customMatch: (r) => r.startsWith('/dashboard') || r == '/',
    ),

    // ── ACADEMICS ──────────────────────────────────────────
    AcadexNavItem(
      id: 'academics',
      label: 'Academics',
      icon: LucideIcons.layers,
      route: '/academics',
      group: AcadexNavGroup.academics,
      allowedRoles: const [AppRole.collegeAdmin, AppRole.hod],
      isPrimary: true,
      matchingPrefixes: const [
        '/academics',
        '/academic-structure',
        '/academics/setup',
        '/academics/colleges',
        '/academics/departments',
        '/academics/courses',
        '/academics/semesters',
        '/academics/sections',
        '/academics/subjects',
        '/faculty-assignments',
      ],
    ),
    AcadexNavItem(
      id: 'colleges',
      label: 'Colleges',
      icon: LucideIcons.building,
      route: '/academics/colleges',
      group: AcadexNavGroup.academics,
      allowedRoles: const [AppRole.superAdmin],
      isPrimary: true,
      matchingPrefixes: const ['/academics/colleges'],
    ),
    AcadexNavItem(
      id: 'my_classes',
      label: 'My Classes',
      icon: LucideIcons.bookOpen,
      route: '/my-assignments',
      group: AcadexNavGroup.academics,
      allowedRoles: const [AppRole.faculty],
      isPrimary: true,
      matchingPrefixes: const ['/my-assignments'],
    ),
    AcadexNavItem(
      id: 'timetable_admin',
      label: 'Timetable',
      icon: LucideIcons.calendarDays,
      route: '/timetable/manage',
      group: AcadexNavGroup.academics,
      allowedRoles: const [AppRole.collegeAdmin, AppRole.hod],
      isPrimary: false, // In More menu for mobile; in Academics group for desktop
      matchingPrefixes: const ['/timetable'],
    ),
    AcadexNavItem(
      id: 'timetable_user',
      label: 'Timetable',
      icon: LucideIcons.calendarDays,
      route: '/timetable',
      group: AcadexNavGroup.academics,
      allowedRoles: const [AppRole.faculty, AppRole.student],
      isPrimary: true,
      matchingPrefixes: const ['/timetable'],
    ),

    // ── OPERATIONS ─────────────────────────────────────────
    AcadexNavItem(
      id: 'attendance',
      label: 'Attendance',
      icon: LucideIcons.clipboardCheck,
      route: '/attendance',
      group: AcadexNavGroup.operations,
      allowedRoles: const [AppRole.collegeAdmin, AppRole.hod, AppRole.faculty, AppRole.student],
      isPrimary: true,
      matchingPrefixes: const ['/attendance'],
    ),
    AcadexNavItem(
      id: 'notes',
      label: 'Notes',
      icon: LucideIcons.fileText,
      route: '/notes',
      group: AcadexNavGroup.operations,
      allowedRoles: const [AppRole.hod, AppRole.faculty, AppRole.student],
      isPrimary: true,
      matchingPrefixes: const ['/notes'],
    ),
    AcadexNavItem(
      id: 'people',
      label: 'People',
      icon: LucideIcons.users,
      route: '/users',
      group: AcadexNavGroup.operations,
      allowedRoles: const [AppRole.superAdmin, AppRole.collegeAdmin],
      isPrimary: true,
      matchingPrefixes: const ['/users', '/academics/faculty', '/academics/students'],
    ),

    // ── INSIGHTS ───────────────────────────────────────────
    AcadexNavItem(
      id: 'reports',
      label: 'Reports',
      icon: LucideIcons.barChart3,
      route: '/analytics',
      group: AcadexNavGroup.insights,
      allowedRoles: const [AppRole.superAdmin, AppRole.collegeAdmin],
      isPrimary: true,
      matchingPrefixes: const ['/analytics', '/reports'],
    ),
    AcadexNavItem(
      id: 'analytics_hod',
      label: 'Analytics',
      icon: LucideIcons.barChart3,
      route: '/analytics',
      group: AcadexNavGroup.insights,
      allowedRoles: const [AppRole.hod],
      isPrimary: false, // In More menu for HOD
      matchingPrefixes: const ['/analytics'],
    ),

    // ── SECONDARY TOOLS & SYSTEM ───────────────────────────
    AcadexNavItem(
      id: 'notifications',
      label: 'Notifications',
      icon: LucideIcons.bell,
      route: '/notifications',
      group: AcadexNavGroup.system,
      allowedRoles: AppRole.values,
      isPrimary: false,
      matchingPrefixes: const ['/notifications'],
    ),
    AcadexNavItem(
      id: 'ai_assistant',
      label: 'AI Assistant',
      icon: LucideIcons.bot,
      route: '/ai-assistant',
      group: AcadexNavGroup.system,
      allowedRoles: const [AppRole.superAdmin, AppRole.collegeAdmin, AppRole.hod, AppRole.faculty],
      isPrimary: false, // Secondary contextual feature
      matchingPrefixes: const ['/ai-assistant'],
    ),
    AcadexNavItem(
      id: 'profile',
      label: 'Profile',
      icon: LucideIcons.user,
      route: '/profile',
      group: AcadexNavGroup.system,
      allowedRoles: AppRole.values,
      isPrimary: false,
      matchingPrefixes: const ['/profile'],
    ),
    AcadexNavItem(
      id: 'settings',
      label: 'Settings',
      icon: LucideIcons.settings,
      route: '/settings',
      group: AcadexNavGroup.system,
      allowedRoles: AppRole.values,
      isPrimary: false,
      matchingPrefixes: const ['/settings'],
    ),
  ];

  /// Root dashboard route for a given user role
  static String getDashboardRoute(AppRole role) {
    switch (role) {
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

  /// Returns the 4 primary navigation destinations for mobile bottom navigation (excluding the 5th 'More' tab)
  static List<AcadexNavItem> getPrimaryNavItems(AppRole role) {
    final dashboardRoute = getDashboardRoute(role);

    switch (role) {
      case AppRole.hod:
        return [
          _getItemWithResolvedRoute('home', dashboardRoute),
          _getItem('academics'),
          _getItem('attendance'),
          _getItem('notes'),
        ];

      case AppRole.collegeAdmin:
        return [
          _getItemWithResolvedRoute('home', dashboardRoute),
          _getItem('academics'),
          _getItem('people'),
          _getItem('reports'),
        ];

      case AppRole.faculty:
        return [
          _getItemWithResolvedRoute('home', dashboardRoute),
          _getItem('my_classes'),
          _getItem('attendance'),
          _getItem('notes'),
        ];

      case AppRole.student:
        return [
          _getItemWithResolvedRoute('home', dashboardRoute),
          _getItem('timetable_user'),
          _getItem('attendance'),
          _getItem('notes'),
        ];

      case AppRole.superAdmin:
        return [
          _getItemWithResolvedRoute('home', dashboardRoute),
          _getItem('colleges'),
          _getItem('people'),
          _getItem('reports'),
        ];
    }
  }

  /// Returns grouped navigation items for desktop drawer and navigation rail
  /// Grouped conceptually: WORKSPACE, ACADEMICS, OPERATIONS, INSIGHTS, SYSTEM
  /// Excludes groups that have no accessible items for the given role.
  static Map<AcadexNavGroup, List<AcadexNavItem>> getGroupedNavItems(AppRole role) {
    final dashboardRoute = getDashboardRoute(role);
    final allowedItems = _allNavItems.where((item) => item.allowedRoles.contains(role)).toList();

    final Map<AcadexNavGroup, List<AcadexNavItem>> grouped = {};

    for (final group in AcadexNavGroup.values) {
      final itemsInGroup = allowedItems.where((item) => item.group == group).map((item) {
        if (item.id == 'home') {
          return _getItemWithResolvedRoute('home', dashboardRoute);
        }
        return item;
      }).toList();

      if (itemsInGroup.isNotEmpty) {
        grouped[group] = itemsInGroup;
      }
    }

    return grouped;
  }

  /// Determines if a specific navigation item matches the active route
  static bool isItemActive(AcadexNavItem item, String activeRoute) {
    return item.matchesRoute(activeRoute);
  }

  /// Resolves the currently active navigation item from a route for a given role
  static AcadexNavItem? resolveActiveItem(String activeRoute, AppRole role) {
    final items = _allNavItems.where((item) => item.allowedRoles.contains(role));
    for (final item in items) {
      if (item.matchesRoute(activeRoute)) {
        return item;
      }
    }
    return null;
  }

  static AcadexNavItem _getItem(String id) {
    return _allNavItems.firstWhere((item) => item.id == id);
  }

  static AcadexNavItem _getItemWithResolvedRoute(String id, String resolvedRoute) {
    final base = _getItem(id);
    return AcadexNavItem(
      id: base.id,
      label: base.label,
      icon: base.icon,
      route: resolvedRoute,
      group: base.group,
      allowedRoles: base.allowedRoles,
      isPrimary: base.isPrimary,
      matchingPrefixes: base.matchingPrefixes,
      customMatch: base.customMatch,
    );
  }
}
