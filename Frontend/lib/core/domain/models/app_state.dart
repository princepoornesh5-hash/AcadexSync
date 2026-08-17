import 'package:flutter/material.dart';

class GlobalAppState {
  final ThemeMode currentTheme;
  final String? selectedCollegeId;
  final String? selectedDepartmentId;
  final String? selectedSemesterId;
  final String? selectedSectionId;

  const GlobalAppState({
    this.currentTheme = ThemeMode.light,
    this.selectedCollegeId,
    this.selectedDepartmentId,
    this.selectedSemesterId,
    this.selectedSectionId,
  });

  GlobalAppState copyWith({
    ThemeMode? currentTheme,
    String? selectedCollegeId,
    String? selectedDepartmentId,
    String? selectedSemesterId,
    String? selectedSectionId,
  }) {
    return GlobalAppState(
      currentTheme: currentTheme ?? this.currentTheme,
      selectedCollegeId: selectedCollegeId ?? this.selectedCollegeId,
      selectedDepartmentId: selectedDepartmentId ?? this.selectedDepartmentId,
      selectedSemesterId: selectedSemesterId ?? this.selectedSemesterId,
      selectedSectionId: selectedSectionId ?? this.selectedSectionId,
    );
  }
}
