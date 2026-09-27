import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/institution_config_models.dart';
import '../../domain/repositories/institution_config_repository.dart';
import '../../data/repositories/api_institution_config_repository.dart';

final institutionConfigRepositoryProvider = Provider<InstitutionConfigRepository>((ref) {
  return ApiInstitutionConfigRepository();
});

final institutionConfigProvider = FutureProvider<InstitutionConfigModel>((ref) async {
  final repo = ref.watch(institutionConfigRepositoryProvider);
  return repo.getEffectiveConfiguration();
});

final institutionPresetsProvider = FutureProvider<List<InstitutionPresetModel>>((ref) async {
  final repo = ref.watch(institutionConfigRepositoryProvider);
  return repo.getPresets();
});

class TerminologyHelper {
  final InstitutionConfigModel config;

  const TerminologyHelper(this.config);

  /// Default fallback helper when config is loading or unavailable
  factory TerminologyHelper.fallback() {
    return const TerminologyHelper(InstitutionConfigModel(collegeId: ''));
  }

  /// Returns the configured singular or plural label for any canonical concept
  String label(AcademicConcept concept, {bool plural = false}) {
    final term = config.terminology.getTerm(concept);
    return plural ? term.plural : term.singular;
  }

  /// Checks if a canonical academic concept is active for the current institution
  bool isConceptEnabled(AcademicConcept concept) {
    switch (concept) {
      case AcademicConcept.department:
        return true;
      case AcademicConcept.program:
        return config.academicStructure.program;
      case AcademicConcept.academicYear:
        return config.academicStructure.academicYear;
      case AcademicConcept.semester:
        return config.academicStructure.semester;
      case AcademicConcept.section:
        return config.academicStructure.section;
      case AcademicConcept.subject:
        return config.academicStructure.subject;
      case AcademicConcept.building:
        return config.academicStructure.building;
      case AcademicConcept.room:
        return config.academicStructure.room;
    }
  }

  bool get isSectionEnabled => config.academicStructure.section;
  bool get isBuildingEnabled => config.academicStructure.building;
  bool get isRoomEnabled => config.academicStructure.room;

  /// Formats teaching context consistently based on whether section is enabled
  String formatTeachingContext({
    required String subject,
    String? semester,
    String? section,
  }) {
    final parts = <String>[subject];
    if (semester != null && semester.isNotEmpty) {
      parts.add(semester);
    }
    if (isSectionEnabled && section != null && section.isNotEmpty) {
      parts.add(section);
    }
    return parts.join(' · ');
  }

  /// Compact teaching context formatter (e.g. for dropdowns or list cards)
  String formatCompactContext({
    String? subjectName,
    String? sectionName,
    String? semesterName,
    String? subject,
    String? section,
    String? semester,
  }) {
    final effSubject = subjectName ?? subject ?? 'Subject';
    final effSection = sectionName ?? section;
    final effSemester = semesterName ?? semester;

    if (isSectionEnabled && effSection != null && effSection.isNotEmpty) {
      return '$effSubject • $effSection';
    }
    if (effSemester != null && effSemester.isNotEmpty) {
      return '$effSubject • $effSemester';
    }
    return effSubject;
  }
}

final terminologyProvider = Provider<TerminologyHelper>((ref) {
  final configAsync = ref.watch(institutionConfigProvider);
  return configAsync.maybeWhen(
    data: (cfg) => TerminologyHelper(cfg),
    orElse: () => TerminologyHelper.fallback(),
  );
});

class InstitutionConfigActionState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  const InstitutionConfigActionState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });
}

class InstitutionConfigNotifier extends StateNotifier<InstitutionConfigActionState> {
  final InstitutionConfigRepository _repo;
  final Ref _ref;

  InstitutionConfigNotifier(this._repo, this._ref)
      : super(const InstitutionConfigActionState());

  Future<InstitutionConfigModel?> updateConfiguration({
    required InstitutionType institutionType,
    required AcademicStructureConfig academicStructure,
    required TerminologyConfig terminology,
    AttendanceAlertsConfig? attendanceAlerts,
  }) async {
    state = const InstitutionConfigActionState(isLoading: true);
    try {
      final updated = await _repo.updateConfiguration(
        institutionType: institutionType,
        academicStructure: academicStructure,
        terminology: terminology,
        attendanceAlerts: attendanceAlerts,
      );
      _ref.invalidate(institutionConfigProvider);
      state = const InstitutionConfigActionState(isSuccess: true);
      return updated;
    } catch (e) {
      state = InstitutionConfigActionState(error: e.toString());
      return null;
    }
  }

  void resetState() {
    state = const InstitutionConfigActionState();
  }
}

final institutionConfigActionProvider =
    StateNotifierProvider.autoDispose<InstitutionConfigNotifier, InstitutionConfigActionState>((ref) {
  final repo = ref.watch(institutionConfigRepositoryProvider);
  return InstitutionConfigNotifier(repo, ref);
});
