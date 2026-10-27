import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../features/auth/domain/models/role_enum.dart';
import '../../../features/search/domain/models/search_models.dart';

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
    // Clean query parameters and fragments for matching
    final cleanRoute = currentRoute.split('?').first.split('#').first;

    // Exact route match
    if (cleanRoute == route) return true;

    // Specific allowed matching prefixes (exact or subroute)
    for (final prefix in matchingPrefixes) {
      if (cleanRoute == prefix || cleanRoute.startsWith('$prefix/')) {
        return true;
      }
    }

    // Properly defined route ancestry for standard subroutes (excluding root & dashboard)
    if (route != '/' && !route.startsWith('/dashboard') && route != '/academics') {
      if (cleanRoute.startsWith('$route/')) {
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
        '/academic-structure',
        '/academics/setup',
        '/academics/colleges',
        '/academics/departments',
        '/academics/courses',
        '/academics/semesters',
        '/academics/sections',
        '/academics/subjects',
        '/academics/academic_years',
        '/faculty-assignments',
      ],
    ),
    AcadexNavItem(
      id: 'rooms',
      label: 'Rooms',
      icon: LucideIcons.doorClosed,
      route: '/academics/rooms',
      group: AcadexNavGroup.academics,
      allowedRoles: const [AppRole.collegeAdmin, AppRole.hod, AppRole.superAdmin],
      isPrimary: false,
      matchingPrefixes: const ['/academics/rooms'],
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
      id: 'students',
      label: 'Students',
      icon: LucideIcons.graduationCap,
      route: '/academics/students',
      group: AcadexNavGroup.academics,
      allowedRoles: const [AppRole.collegeAdmin, AppRole.hod, AppRole.faculty],
      isPrimary: true,
      matchingPrefixes: const ['/academics/students'],
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
    AcadexNavItem(
      id: 'calendar',
      label: 'Calendar',
      icon: LucideIcons.calendar,
      route: '/calendar',
      group: AcadexNavGroup.academics,
      allowedRoles: const [AppRole.collegeAdmin, AppRole.hod, AppRole.faculty, AppRole.student],
      isPrimary: false,
      matchingPrefixes: const ['/calendar'],
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
      id: 'assignments',
      label: 'Assignments',
      icon: LucideIcons.fileSpreadsheet,
      route: '/assignments',
      group: AcadexNavGroup.operations,
      allowedRoles: const [AppRole.faculty, AppRole.student, AppRole.hod],
      isPrimary: false,
      matchingPrefixes: const ['/assignments'],
    ),
    AcadexNavItem(
      id: 'people',
      label: 'People',
      icon: LucideIcons.users,
      route: '/users',
      group: AcadexNavGroup.operations,
      allowedRoles: const [AppRole.superAdmin, AppRole.collegeAdmin],
      isPrimary: true,
      matchingPrefixes: const ['/users'],
    ),
    AcadexNavItem(
      id: 'requests',
      label: 'Request Center',
      icon: LucideIcons.inbox,
      route: '/requests',
      group: AcadexNavGroup.operations,
      allowedRoles: const [AppRole.collegeAdmin, AppRole.hod, AppRole.faculty, AppRole.student],
      isPrimary: false,
      matchingPrefixes: const ['/requests'],
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
      allowedRoles: AppRole.values,
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
    // Exclude redundant items from drawer grouping:
    // Notifications has a dedicated high-priority icon in the app bar;
    // Profile is directly accessible via the top drawer profile context header;
    // Rooms is managed directly within the Academics structure module.
    final allowedItems = _allNavItems
        .where((item) =>
            item.allowedRoles.contains(role) &&
            item.id != 'notifications' &&
            item.id != 'rooms')
        .toList();

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

  /// Resolves the single authoritative active navigation item for a route and role.
  /// Uses route specificity scoring to guarantee that more specific child destinations
  /// (such as /academics/students) always win over broader ancestor routes (like /academics).
  static AcadexNavItem? resolveActiveItem(
    String activeRoute,
    AppRole role, {
    List<AcadexNavItem>? candidates,
  }) {
    final cleanRoute = activeRoute.split('?').first.split('#').first;
    final items = candidates ?? _allNavItems.where((item) => item.allowedRoles.contains(role)).toList();

    AcadexNavItem? bestMatch;
    int bestScore = -1;

    for (final item in items) {
      if (!item.matchesRoute(cleanRoute)) continue;

      int score = 0;
      final itemCleanRoute = item.route.split('?').first.split('#').first;

      if (cleanRoute == itemCleanRoute) {
        // Highest priority: exact route match
        score = 2000 + itemCleanRoute.length;
      } else {
        // Match against explicit matching prefixes
        for (final prefix in item.matchingPrefixes) {
          if (cleanRoute == prefix) {
            score = math.max(score, 1000 + prefix.length);
          } else if (cleanRoute.startsWith('$prefix/')) {
            score = math.max(score, 500 + prefix.length);
          }
        }
        // Subroute prefix match
        if (score == 0 && itemCleanRoute != '/' && !itemCleanRoute.startsWith('/dashboard')) {
          if (cleanRoute.startsWith('$itemCleanRoute/')) {
            score = 100 + itemCleanRoute.length;
          }
        }
        // General match fallback
        if (score == 0) {
          score = 10;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = item;
      }
    }

    return bestMatch;
  }

  /// Matches authorized navigation destinations for global search, enabling
  /// quick module navigation (e.g. typing "students" resolves to Students Directory)
  static List<SearchResult> searchNavigationDestinations(String query, AppRole role) {
    final prefix = query.trim().toLowerCase();
    if (prefix.isEmpty) return [];

    final results = <SearchResult>[];
    final allowedItems = _allNavItems.where((it) => it.allowedRoles.contains(role) && it.id != 'home');

    for (final item in allowedItems) {
      final labelLower = item.label.toLowerCase();
      final idLower = item.id.toLowerCase();
      final routeLower = item.route.toLowerCase();

      bool matches = labelLower.contains(prefix) || idLower.contains(prefix) || routeLower.contains(prefix);

      // Check common synonyms for campus workflows
      if (!matches) {
        if (prefix == 'students' || prefix == 'student') {
          matches = item.id == 'students';
        } else if (prefix == 'faculty' || prefix == 'teachers' || prefix == 'staff') {
          matches = item.id == 'faculty' || item.id == 'my_classes';
        } else if (prefix == 'courses' || prefix == 'programs' || prefix == 'degrees') {
          matches = item.id == 'academics';
        } else if (prefix == 'timetable' || prefix == 'schedule' || prefix == 'classes') {
          matches = item.id == 'timetable_admin' || item.id == 'timetable_user';
        } else if (prefix == 'attendance' || prefix == 'absent') {
          matches = item.id == 'attendance';
        } else if (prefix == 'grades' || prefix == 'marks' || prefix == 'results') {
          matches = item.id == 'reports' || item.id == 'analytics_hod';
        }
      }

      if (matches) {
        String groupDesc = 'Academic Navigation';
        switch (item.group) {
          case AcadexNavGroup.workspace:
            groupDesc = 'Workspace Hub';
            break;
          case AcadexNavGroup.academics:
            groupDesc = 'Academic Module';
            break;
          case AcadexNavGroup.operations:
            groupDesc = 'Campus Operations';
            break;
          case AcadexNavGroup.insights:
            groupDesc = 'Insights & Analytics';
            break;
          case AcadexNavGroup.system:
            groupDesc = 'System & Preferences';
            break;
        }

        results.add(SearchResult(
          id: 'nav_${item.id}',
          title: item.label,
          subtitle: '$groupDesc • ${item.route}',
          type: SearchResultType.navigation,
          destinationRoute: item.route,
          relevanceScore: labelLower.startsWith(prefix) ? 100 : 80,
        ));
      }
    }

    return results;
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
