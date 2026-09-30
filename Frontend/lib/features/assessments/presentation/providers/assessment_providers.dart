import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/api_assessment_repository.dart';
import '../../domain/models/internal_assessment_models.dart';

final assessmentRepositoryProvider = Provider<ApiAssessmentRepository>((ref) {
  return ApiAssessmentRepository();
});

typedef AssessmentContextParams = ({
  String sectionId,
  String subjectId,
  String? academicYearId,
});

final assessmentContextProvider = FutureProvider.family<AssessmentContextModel, AssessmentContextParams>(
  (ref, params) async {
    final repo = ref.watch(assessmentRepositoryProvider);
    return repo.getAssessmentContext(
      sectionId: params.sectionId,
      subjectId: params.subjectId,
      academicYearId: params.academicYearId,
    );
  },
);

final studentMarksProvider = FutureProvider.family<List<StudentPublishedMarksItem>, String?>(
  (ref, semesterId) async {
    final repo = ref.watch(assessmentRepositoryProvider);
    return repo.getStudentMarks(semesterId: semesterId);
  },
);

typedef SubjectSummaryParams = ({
  String subjectId,
  String semesterId,
  String? studentId,
});

final subjectAssessmentSummaryProvider = FutureProvider.family<SubjectAssessmentSummaryModel, SubjectSummaryParams>(
  (ref, params) async {
    final repo = ref.watch(assessmentRepositoryProvider);
    return repo.getSubjectSummary(
      subjectId: params.subjectId,
      semesterId: params.semesterId,
      studentId: params.studentId,
    );
  },
);
