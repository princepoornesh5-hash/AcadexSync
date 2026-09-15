import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/department_analytics_models.dart';
import 'analytics_providers.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../../academic_structure/domain/models/academic_models.dart';

/// Active filter state for Department Analytics
final departmentAnalyticsFilterProvider =
    StateProvider<DepartmentAnalyticsFilter>((ref) {
  return const DepartmentAnalyticsFilter();
});

/// Department Overview metrics and breakdowns
final departmentOverviewProvider =
    FutureProvider.autoDispose<DepartmentOverviewModel>((ref) async {
  final repo = ref.watch(apiAnalyticsRepositoryProvider);
  final filter = ref.watch(departmentAnalyticsFilterProvider);
  return await repo.getDepartmentOverview(filter: filter);
});

/// Course analytics list with drilldowns
final departmentCoursesProvider =
    FutureProvider.autoDispose<List<CourseAnalyticsModel>>((ref) async {
  final repo = ref.watch(apiAnalyticsRepositoryProvider);
  final filter = ref.watch(departmentAnalyticsFilterProvider);
  return await repo.getDepartmentCourses(filter: filter);
});

/// Section analytics list with drilldowns
final departmentSectionsProvider =
    FutureProvider.autoDispose<List<SectionAnalyticsModel>>((ref) async {
  final repo = ref.watch(apiAnalyticsRepositoryProvider);
  final filter = ref.watch(departmentAnalyticsFilterProvider);
  return await repo.getDepartmentSections(filter: filter);
});

/// Subject analytics list with assigned sections
final departmentSubjectsProvider =
    FutureProvider.autoDispose<List<SubjectAnalyticsModel>>((ref) async {
  final repo = ref.watch(apiAnalyticsRepositoryProvider);
  final filter = ref.watch(departmentAnalyticsFilterProvider);
  return await repo.getDepartmentSubjects(filter: filter);
});

/// Student-level attendance roster analytics
final departmentStudentsProvider =
    FutureProvider.autoDispose<DepartmentStudentsResult>((ref) async {
  final repo = ref.watch(apiAnalyticsRepositoryProvider);
  final filter = ref.watch(departmentAnalyticsFilterProvider);
  return await repo.getDepartmentStudents(filter: filter);
});

/// At-risk students roster analytics
final departmentAtRiskStudentsProvider =
    FutureProvider.autoDispose<DepartmentStudentsResult>((ref) async {
  final repo = ref.watch(apiAnalyticsRepositoryProvider);
  final filter = ref.watch(departmentAnalyticsFilterProvider);
  return await repo.getDepartmentStudents(
    filter: filter.copyWith(atRiskOnly: true),
  );
});

/// Attendance trend timeline over time
final departmentTrendsProvider =
    FutureProvider.autoDispose<List<TrendAnalyticsModel>>((ref) async {
  final repo = ref.watch(apiAnalyticsRepositoryProvider);
  final filter = ref.watch(departmentAnalyticsFilterProvider);
  return await repo.getDepartmentTrends(filter: filter);
});

// =========================================================================
// CONTEXT-AWARE CASCADING FILTER PROVIDERS (Section 6)
// =========================================================================

/// Available courses in the department
final availableCoursesFilterProvider =
    Provider.autoDispose<List<Course>>((ref) {
  return ref.watch(coursesProvider).valueOrNull ?? [];
});

/// Semesters cascading from selected course
final availableSemestersFilterProvider =
    Provider.autoDispose<List<Semester>>((ref) {
  final allSemesters = ref.watch(semestersProvider).valueOrNull ?? [];
  final selectedCourseId = ref.watch(departmentAnalyticsFilterProvider).courseId;

  if (selectedCourseId == null || selectedCourseId.isEmpty) {
    return allSemesters;
  }
  return allSemesters.where((s) => s.courseId == selectedCourseId).toList();
});

/// Sections cascading from selected course & semester
final availableSectionsFilterProvider =
    Provider.autoDispose<List<Section>>((ref) {
  final allSections = ref.watch(sectionsProvider).valueOrNull ?? [];
  final filter = ref.watch(departmentAnalyticsFilterProvider);

  return allSections.where((s) {
    if (filter.courseId != null && filter.courseId!.isNotEmpty && s.courseId != filter.courseId) {
      return false;
    }
    if (filter.semesterId != null && filter.semesterId!.isNotEmpty && s.semesterId != filter.semesterId) {
      return false;
    }
    return true;
  }).toList();
});

/// Subjects cascading from selected course & semester
final availableSubjectsFilterProvider =
    Provider.autoDispose<List<Subject>>((ref) {
  final allSubjects = ref.watch(subjectsProvider).valueOrNull ?? [];
  final filter = ref.watch(departmentAnalyticsFilterProvider);

  return allSubjects.where((s) {
    if (filter.courseId != null && filter.courseId!.isNotEmpty && s.courseId != filter.courseId) {
      return false;
    }
    if (filter.semesterId != null && filter.semesterId!.isNotEmpty && s.semesterId != filter.semesterId) {
      return false;
    }
    return true;
  }).toList();
});
