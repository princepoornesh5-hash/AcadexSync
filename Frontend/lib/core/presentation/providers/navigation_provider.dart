import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalNavigationState {
  final String currentRoute;
  final List<String> navigationHistory;
  final String currentModule;
  final int selectedBottomTab;
  final bool drawerOpen;
  final String? lastSelectedActionRoute;
  final String? lastSelectedActionId;

  const GlobalNavigationState({
    this.currentRoute = '/',
    this.navigationHistory = const [],
    this.currentModule = 'Dashboard',
    this.selectedBottomTab = 0,
    this.drawerOpen = false,
    this.lastSelectedActionRoute,
    this.lastSelectedActionId,
  });

  GlobalNavigationState copyWith({
    String? currentRoute,
    List<String>? navigationHistory,
    String? currentModule,
    int? selectedBottomTab,
    bool? drawerOpen,
    String? lastSelectedActionRoute,
    String? lastSelectedActionId,
    bool clearAction = false,
    bool clearActionId = false,
  }) {
    return GlobalNavigationState(
      currentRoute: currentRoute ?? this.currentRoute,
      navigationHistory: navigationHistory ?? this.navigationHistory,
      currentModule: currentModule ?? this.currentModule,
      selectedBottomTab: selectedBottomTab ?? this.selectedBottomTab,
      drawerOpen: drawerOpen ?? this.drawerOpen,
      lastSelectedActionRoute: clearAction
          ? null
          : (lastSelectedActionRoute ?? this.lastSelectedActionRoute),
      lastSelectedActionId: clearAction || clearActionId
          ? null
          : (lastSelectedActionId ?? this.lastSelectedActionId),
    );
  }
}

class NavigationNotifier extends Notifier<GlobalNavigationState> {
  @override
  GlobalNavigationState build() {
    return const GlobalNavigationState();
  }

  void selectDashboardAction({required String route, String? id}) {
    state = state.copyWith(
      lastSelectedActionRoute: route,
      lastSelectedActionId: id,
    );
  }

  void updateRoute(String route) {
    // Idempotent guard: avoid emitting state when currentRoute is already active
    if (state.currentRoute == route &&
        state.navigationHistory.isNotEmpty &&
        state.navigationHistory.last == route) {
      return;
    }

    final history = List<String>.from(state.navigationHistory);
    if (history.isEmpty || history.last != route) {
      history.add(route);
    }

    // Determine current module using simplified information architecture
    String module = 'Dashboard';
    if (route.startsWith('/academics') ||
        route.startsWith('/faculty-assignments') ||
        route.startsWith('/academic-structure')) {
      module = 'Academics';
    } else if (route.startsWith('/attendance')) {
      module = 'Attendance';
    } else if (route.startsWith('/timetable')) {
      module = 'Timetable';
    } else if (route.startsWith('/notes')) {
      module = 'Notes';
    } else if (route.startsWith('/users')) {
      module = 'People';
    } else if (route.startsWith('/analytics') || route.startsWith('/reports')) {
      module = 'Reports';
    } else if (route.startsWith('/profile')) {
      module = 'Profile';
    } else if (route.startsWith('/settings')) {
      module = 'Settings';
    } else if (route.startsWith('/my-assignments')) {
      module = 'My Classes';
    }

    // If navigating to a non-dashboard destination, record it as the most recent action route
    // so dashboard quick operations accurately reflect the active destination upon return.
    String? updatedActionRoute = state.lastSelectedActionRoute;
    String? updatedActionId = state.lastSelectedActionId;
    bool clearActionId = false;
    if (!route.startsWith('/dashboard') && route != '/' && route != '/login') {
      updatedActionRoute = route;
      // If the destination route does not match the previously clicked action route, clear the specific ID
      if (state.lastSelectedActionRoute != null &&
          !route.startsWith(state.lastSelectedActionRoute!)) {
        updatedActionId = null;
        clearActionId = true;
      }
    }

    state = state.copyWith(
      currentRoute: route,
      navigationHistory: history,
      currentModule: module,
      lastSelectedActionRoute: updatedActionRoute,
      lastSelectedActionId: updatedActionId,
      clearActionId: clearActionId,
    );
  }

  void toggleDrawer(bool open) {
    if (state.drawerOpen == open) return;
    state = state.copyWith(drawerOpen: open);
  }

  void clearHistory() {
    state = const GlobalNavigationState();
  }
}

final navigationProvider =
    NotifierProvider<NavigationNotifier, GlobalNavigationState>(() {
      return NavigationNotifier();
    });

extension DashboardActionSelectionX on GlobalNavigationState {
  /// Determines whether a dashboard action card is currently selected.
  ///
  /// Evaluates deterministic criteria:
  /// 1. Exact action ID matching if user clicked an explicit card.
  /// 2. Active route matching if entered directly, via sidebar, or back navigation.
  /// 3. Sub-route prefix matching (only when no other action has a closer match).
  /// 4. Fallback to [isPrimaryFallback] only on fresh dashboard before any action is selected/visited.
  bool isActionActive({
    required String route,
    String? id,
    bool isPrimaryFallback = false,
    List<String> allRoutes = const [],
  }) {
    // 1. If explicit action ID was stored:
    if (id != null &&
        id.isNotEmpty &&
        lastSelectedActionId != null &&
        lastSelectedActionId!.isNotEmpty) {
      if (id == lastSelectedActionId) return true;
    }

    // 2. If route was tracked:
    if (lastSelectedActionRoute != null &&
        lastSelectedActionRoute!.isNotEmpty) {
      final cleanActive = lastSelectedActionRoute!.split('?').first;
      final cleanRoute = route.split('?').first;

      if (cleanActive == cleanRoute) {
        // If an explicit action ID was also set and doesn't match this card, don't match
        if (lastSelectedActionId != null &&
            id != null &&
            lastSelectedActionId != id) {
          return false;
        }
        // If multiple actions share the same route without a specific ID,
        // deterministically pick the primary or first matching action
        if (allRoutes.isNotEmpty &&
            allRoutes.where((r) => r == route).length > 1) {
          if (isPrimaryFallback) return true;
          final firstMatchingIndex = allRoutes.indexOf(route);
          final currentIndex = id != null
              ? allRoutes.indexOf(route)
              : firstMatchingIndex;
          return currentIndex == firstMatchingIndex;
        }
        return true;
      }

      // Check prefix/subpath (e.g. /academics/students/123 matches /academics/students)
      if (cleanActive.startsWith('$cleanRoute/')) {
        // Only if no other card in allRoutes has a closer match
        final hasCloserMatch = allRoutes.any((r) {
          final cleanR = r.split('?').first;
          return cleanR != cleanRoute &&
              cleanActive.startsWith('$cleanR/') &&
              cleanR.length > cleanRoute.length;
        });
        if (!hasCloserMatch) return true;
      }

      return false;
    }

    // 3. Fallback when fresh dashboard:
    return isPrimaryFallback;
  }
}
