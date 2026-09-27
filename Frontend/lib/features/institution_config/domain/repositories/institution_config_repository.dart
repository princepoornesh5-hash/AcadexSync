import '../models/institution_config_models.dart';

abstract class InstitutionConfigRepository {
  Future<InstitutionConfigModel> getEffectiveConfiguration();

  Future<InstitutionConfigModel> updateConfiguration({
    InstitutionType? institutionType,
    AcademicStructureConfig? academicStructure,
    TerminologyConfig? terminology,
    AttendanceAlertsConfig? attendanceAlerts,
  });

  Future<List<InstitutionPresetModel>> getPresets();
}
