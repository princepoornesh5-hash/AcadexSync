import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../academic_structure/domain/models/academic_models.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';

/// Memoized provider for Subject lookup by ID.
final notesSubjectMapProvider = Provider<Map<String, Subject>>((ref) {
  final async = ref.watch(subjectsProvider);
  return async.maybeWhen(
    data: (list) => {for (var item in list) item.id: item},
    orElse: () => const {},
  );
});

/// Memoized provider for Faculty lookup by ID.
final notesFacultyMapProvider = Provider<Map<String, Faculty>>((ref) {
  final state = ref.watch(facultyProvider(null));
  return {for (var item in state.items.whereType<Faculty>()) item.id: item};
});

/// Memoized provider for Section lookup by ID.
final notesSectionMapProvider = Provider<Map<String, Section>>((ref) {
  final async = ref.watch(sectionsProvider);
  return async.maybeWhen(
    data: (list) => {for (var item in list) item.id: item},
    orElse: () => const {},
  );
});

/// Memoized provider for Department lookup by ID.
final notesDepartmentMapProvider = Provider<Map<String, Department>>((ref) {
  final async = ref.watch(departmentsProvider);
  return async.maybeWhen(
    data: (list) => {for (var item in list) item.id: item},
    orElse: () => const {},
  );
});

/// Memoized provider for Course lookup by ID.
final notesCourseMapProvider = Provider<Map<String, Course>>((ref) {
  final async = ref.watch(coursesProvider);
  return async.maybeWhen(
    data: (list) => {for (var item in list) item.id: item},
    orElse: () => const {},
  );
});
