import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../academic_structure/domain/models/academic_models.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../domain/models/timetable_models.dart';

enum TimetableViewMode {
  day,
  week,
  list,
}

final timetableViewModeProvider = StateProvider<TimetableViewMode>((ref) => TimetableViewMode.day);

final timetableSelectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final timetableSelectedDayProvider = StateProvider<TimetableDay>((ref) {
  final date = ref.watch(timetableSelectedDateProvider);
  // Monday = 1 (index 0) ... Sunday = 7 (index 6)
  return TimetableDay.values[date.weekday - 1];
});

final timetableSubjectMapProvider = Provider<Map<String, Subject>>((ref) {
  final subjectsAsync = ref.watch(subjectsProvider);
  final list = subjectsAsync.valueOrNull ?? [];
  return {for (var s in list) s.id: s};
});

final timetableFacultyMapProvider = Provider<Map<String, Faculty>>((ref) {
  final facultyState = ref.watch(facultyProvider(null));
  final list = facultyState.items;
  return {for (var f in list) f.id: f};
});

final timetableSectionMapProvider = Provider<Map<String, Section>>((ref) {
  final sectionsAsync = ref.watch(sectionsProvider);
  final list = sectionsAsync.valueOrNull ?? [];
  return {for (var s in list) s.id: s};
});

final timetableDepartmentMapProvider = Provider<Map<String, Department>>((ref) {
  final deptsAsync = ref.watch(departmentsProvider);
  final list = deptsAsync.valueOrNull ?? [];
  return {for (var d in list) d.id: d};
});

final timetableCourseMapProvider = Provider<Map<String, Course>>((ref) {
  final coursesAsync = ref.watch(coursesProvider);
  final list = coursesAsync.valueOrNull ?? [];
  return {for (var c in list) c.id: c};
});

final timetableAcademicYearMapProvider = Provider<Map<String, AcademicYear>>((ref) {
  final yearsAsync = ref.watch(academicYearsProvider);
  final list = yearsAsync.valueOrNull ?? [];
  return {for (var y in list) y.id: y};
});

final timetableSemesterMapProvider = Provider<Map<String, Semester>>((ref) {
  final semAsync = ref.watch(semestersProvider);
  final list = semAsync.valueOrNull ?? [];
  return {for (var s in list) s.id: s};
});
