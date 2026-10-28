import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/api_assessment_repository.dart';
import '../../domain/models/internal_assessment_models.dart';

final assessmentRepositoryProvider = Provider<ApiAssessmentRepository>((ref) {
  return ApiAssessmentRepository();
});

typedef AssessmentContextParams = ({
  String? sectionId,
  String? subjectId,
  String? academicYearId,
});

final assessmentContextProvider =
    FutureProvider.family<AssessmentContextModel, AssessmentContextParams>((
      ref,
      params,
    ) async {
      final repo = ref.watch(assessmentRepositoryProvider);
      return repo.getAssessmentContext(
        sectionId: params.sectionId,
        subjectId: params.subjectId,
        academicYearId: params.academicYearId,
      );
    });

final assessmentsListProvider =
    FutureProvider.family<List<InternalAssessmentModel>, Map<String, String?>>((
      ref,
      filters,
    ) async {
      final repo = ref.watch(assessmentRepositoryProvider);
      return repo.listAssessments(
        facultyAssignmentId: filters['facultyAssignmentId'],
        sectionId: filters['sectionId'],
        subjectId: filters['subjectId'],
        semesterId: filters['semesterId'],
        academicYearId: filters['academicYearId'],
        status: filters['status'],
        assessmentType: filters['assessmentType'],
      );
    });

final assessmentDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((
      ref,
      assessmentId,
    ) async {
      final repo = ref.watch(assessmentRepositoryProvider);
      return repo.getAssessmentById(assessmentId);
    });

final examTimetableProvider =
    FutureProvider.family<List<AssessmentScheduleModel>, Map<String, String?>>((
      ref,
      params,
    ) async {
      final repo = ref.watch(assessmentRepositoryProvider);
      return repo.getExamTimetable(
        sectionId: params['sectionId'],
        semesterId: params['semesterId'],
        dateFrom: params['dateFrom'],
        dateTo: params['dateTo'],
      );
    });

final studentMarksProvider =
    FutureProvider.family<List<StudentPublishedMarksItem>, String?>((
      ref,
      semesterId,
    ) async {
      final repo = ref.watch(assessmentRepositoryProvider);
      return repo.getStudentMarks(semesterId: semesterId);
    });

typedef SubjectSummaryParams = ({
  String subjectId,
  String semesterId,
  String? studentId,
});

final subjectAssessmentSummaryProvider =
    FutureProvider.family<SubjectAssessmentSummaryModel, SubjectSummaryParams>((
      ref,
      params,
    ) async {
      final repo = ref.watch(assessmentRepositoryProvider);
      return repo.getSubjectSummary(
        subjectId: params.subjectId,
        semesterId: params.semesterId,
        studentId: params.studentId,
      );
    });

final assessmentRosterProvider =
    FutureProvider.family<MarksRosterResponseModel, String>((
      ref,
      assessmentId,
    ) async {
      final repo = ref.watch(assessmentRepositoryProvider);
      return repo.getMarksRoster(assessmentId);
    });
