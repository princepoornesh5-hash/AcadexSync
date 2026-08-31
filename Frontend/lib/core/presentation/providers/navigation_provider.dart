import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalNavigationState {
  final String currentRoute;
  final List<String> navigationHistory;
  final String currentModule;
  final int selectedBottomTab;
  final bool drawerOpen;

  const GlobalNavigationState({
    this.currentRoute = '/',
    this.navigationHistory = const [],
    this.currentModule = 'Dashboard',
    this.selectedBottomTab = 0,
    this.drawerOpen = false,
  });

  GlobalNavigationState copyWith({
    String? currentRoute,
    List<String>? navigationHistory,
    String? currentModule,
    int? selectedBottomTab,
    bool? drawerOpen,
  }) {
    return GlobalNavigationState(
      currentRoute: currentRoute ?? this.currentRoute,
      navigationHistory: navigationHistory ?? this.navigationHistory,
      currentModule: currentModule ?? this.currentModule,
      selectedBottomTab: selectedBottomTab ?? this.selectedBottomTab,
      drawerOpen: drawerOpen ?? this.drawerOpen,
    );
  }
}

class NavigationNotifier extends Notifier<GlobalNavigationState> {
  @override
  GlobalNavigationState build() {
    return const GlobalNavigationState();
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
    
    // Determine current module
    String module = 'Dashboard';
    if (route.startsWith('/attendance')) {
      module = 'Attendance';
    } else if (route.startsWith('/users')) {
      module = 'Users';
    } else if (route.startsWith('/academics')) {
      module = 'Academics';
    }

    // Determine bottom tab index
    int tab = 0;
    if (route.startsWith('/attendance')) {
      tab = 1;
    } else if (route.startsWith('/profile')) {
      tab = 2;
    }

    state = state.copyWith(
      currentRoute: route,
      navigationHistory: history,
      currentModule: module,
      selectedBottomTab: tab,
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

final navigationProvider = NotifierProvider<NavigationNotifier, GlobalNavigationState>(() {
  return NavigationNotifier();
});

