import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../academic_structure/domain/models/academic_models.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';

/// Memoized provider for Department lookup by ID in Certificates.
final certificateDepartmentMapProvider = Provider<Map<String, Department>>((ref) {
  final async = ref.watch(departmentsProvider);
  return async.maybeWhen(
    data: (list) => {for (var item in list) item.id: item},
    orElse: () => const {},
  );
});

/// Memoized provider for Course lookup by ID in Certificates.
final certificateCourseMapProvider = Provider<Map<String, Course>>((ref) {
  final async = ref.watch(coursesProvider);
  return async.maybeWhen(
    data: (list) => {for (var item in list) item.id: item},
    orElse: () => const {},
  );
});

/// Memoized provider for Section lookup by ID in Certificates.
final certificateSectionMapProvider = Provider<Map<String, Section>>((ref) {
  final async = ref.watch(sectionsProvider);
  return async.maybeWhen(
    data: (list) => {for (var item in list) item.id: item},
    orElse: () => const {},
  );
});

/// Memoized provider for Academic Year lookup by ID in Certificates.
final certificateAcademicYearMapProvider = Provider<Map<String, AcademicYear>>((ref) {
  final async = ref.watch(academicYearsProvider);
  return async.maybeWhen(
    data: (list) => {for (var item in list) item.id: item},
    orElse: () => const {},
  );
});
