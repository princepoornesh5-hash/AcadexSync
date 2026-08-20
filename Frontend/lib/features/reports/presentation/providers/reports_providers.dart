import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/reports_repository.dart';
import '../../domain/models/report_models.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ApiReportsRepository(apiClient: ApiClient());
});

final selectedDatePresetProvider = StateProvider<DateRangePreset>((ref) {
  return DateRangePreset.thisMonth;
});

final customStartDateProvider = StateProvider<DateTime?>((ref) => null);
final customEndDateProvider = StateProvider<DateTime?>((ref) => null);

final roleDashboardReportProvider = FutureProvider.autoDispose<RoleDashboardReportModel?>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final preset = ref.watch(selectedDatePresetProvider);
  final startDate = ref.watch(customStartDateProvider);
  final endDate = ref.watch(customEndDateProvider);

  return repo.getDashboard(
    preset: preset,
    startDate: startDate,
    endDate: endDate,
  );
});

final myAttendanceReportProvider = FutureProvider.autoDispose<StudentAttendanceReportModel?>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final preset = ref.watch(selectedDatePresetProvider);
  final startDate = ref.watch(customStartDateProvider);
  final endDate = ref.watch(customEndDateProvider);

  return repo.getStudentAttendanceReport(
    studentId: 'me',
    preset: preset,
    startDate: startDate,
    endDate: endDate,
  );
});

final studentAttendanceReportFamily = FutureProvider.autoDispose.family<StudentAttendanceReportModel?, String>((ref, studentId) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final preset = ref.watch(selectedDatePresetProvider);
  final startDate = ref.watch(customStartDateProvider);
  final endDate = ref.watch(customEndDateProvider);

  return repo.getStudentAttendanceReport(
    studentId: studentId,
    preset: preset,
    startDate: startDate,
    endDate: endDate,
  );
});

final sectionAttendanceReportFamily = FutureProvider.autoDispose.family<SectionAttendanceReportModel?, String>((ref, sectionId) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final preset = ref.watch(selectedDatePresetProvider);
  final startDate = ref.watch(customStartDateProvider);
  final endDate = ref.watch(customEndDateProvider);

  return repo.getSectionAttendanceReport(
    sectionId: sectionId,
    preset: preset,
    startDate: startDate,
    endDate: endDate,
  );
});

final departmentAttendanceReportFamily = FutureProvider.autoDispose.family<DepartmentAttendanceReportModel?, String>((ref, departmentId) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final preset = ref.watch(selectedDatePresetProvider);
  final startDate = ref.watch(customStartDateProvider);
  final endDate = ref.watch(customEndDateProvider);

  return repo.getDepartmentAttendanceReport(
    departmentId: departmentId,
    preset: preset,
    startDate: startDate,
    endDate: endDate,
  );
});

final collegeAttendanceReportFamily = FutureProvider.autoDispose.family<CollegeAttendanceReportModel?, String>((ref, collegeId) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final preset = ref.watch(selectedDatePresetProvider);
  final startDate = ref.watch(customStartDateProvider);
  final endDate = ref.watch(customEndDateProvider);

  return repo.getCollegeAttendanceReport(
    collegeId: collegeId,
    preset: preset,
    startDate: startDate,
    endDate: endDate,
  );
});

final academicReportProvider = FutureProvider.autoDispose<AcademicHierarchyReportModel?>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getAcademicReport();
});

final notesAnalyticsReportProvider = FutureProvider.autoDispose<NotesAnalyticsReportModel?>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getNotesReport();
});
