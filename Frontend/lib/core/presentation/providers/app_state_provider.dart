import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/app_state.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/auth/domain/models/auth_state.dart';

class AppStateNotifier extends Notifier<GlobalAppState> {
  @override
  GlobalAppState build() {
    // Clear state on logout
    ref.listen(authProvider, (previous, next) {
      if (next is AuthUnauthenticated) {
        state = const GlobalAppState();
      }
    });
    return const GlobalAppState();
  }

  void setTheme(ThemeMode theme) {
    state = state.copyWith(currentTheme: theme);
  }

  void setCollege(String collegeId) {
    state = state.copyWith(selectedCollegeId: collegeId);
  }

  void setDepartment(String departmentId) {
    state = state.copyWith(selectedDepartmentId: departmentId);
  }

  void setSemester(String semesterId) {
    state = state.copyWith(selectedSemesterId: semesterId);
  }

  void setSection(String sectionId) {
    state = state.copyWith(selectedSectionId: sectionId);
  }
}

final appStateProvider = NotifierProvider<AppStateNotifier, GlobalAppState>(() {
  return AppStateNotifier();
});
