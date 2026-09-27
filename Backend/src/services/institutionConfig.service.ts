import mongoose from 'mongoose';
import { InstitutionConfiguration } from '../models/institutionConfiguration.model';
import { College } from '../models/college.model';
import { ApiError } from '../utils/apiError';
import {
  InstitutionType,
  DEFAULT_ACADEMIC_STRUCTURE,
  DEFAULT_TERMINOLOGY,
  DEFAULT_ATTENDANCE_ALERTS,
  INSTITUTION_PRESETS,
  IAcademicStructureConfig,
  ITerminologyConfig,
  IAttendanceAlertsConfig,
} from '../constants/institutionConfig.constants';
import { UpdateInstitutionConfigInput } from '../validations/institutionConfig.validation';

export class InstitutionConfigService {
  /**
   * Retrieves the effective institution configuration for a given college tenant.
   * If no explicit configuration has been saved yet, it falls back to the canonical defaults.
   */
  async getEffectiveConfiguration(collegeId: string) {
    if (!mongoose.Types.ObjectId.isValid(collegeId)) {
      throw ApiError.badRequest('Invalid college ID');
    }

    const config = await InstitutionConfiguration.findOne({ collegeId });
    if (config) {
      return config.toJSON();
    }

    // Default legacy / unconfigured fallback
    return {
      collegeId,
      institutionType: InstitutionType.ENGINEERING,
      academicStructure: { ...DEFAULT_ACADEMIC_STRUCTURE },
      terminology: { ...DEFAULT_TERMINOLOGY },
      attendanceAlerts: { ...DEFAULT_ATTENDANCE_ALERTS },
      isConfigured: false,
    };
  }

  /**
   * Updates or initializes the tenant's institution configuration.
   * Only COLLEGE_ADMIN or SUPER_ADMIN may perform this.
   */
  async updateConfiguration(
    collegeId: string,
    userId: string,
    input: UpdateInstitutionConfigInput
  ) {
    if (!mongoose.Types.ObjectId.isValid(collegeId)) {
      throw ApiError.badRequest('Invalid college ID');
    }

    const college = await College.findById(collegeId);
    if (!college) {
      throw ApiError.notFound('College not found');
    }

    // Existing config or defaults
    const existing = await InstitutionConfiguration.findOne({ collegeId });

    const mergedStructure: IAcademicStructureConfig = {
      ...(existing?.academicStructure || DEFAULT_ACADEMIC_STRUCTURE),
      ...(input.academicStructure || {}),
    };

    const mergedTerminology: ITerminologyConfig = {
      department: {
        ...(existing?.terminology?.department || DEFAULT_TERMINOLOGY.department),
        ...(input.terminology?.department || {}),
      },
      program: {
        ...(existing?.terminology?.program || DEFAULT_TERMINOLOGY.program),
        ...(input.terminology?.program || {}),
      },
      academicYear: {
        ...(existing?.terminology?.academicYear || DEFAULT_TERMINOLOGY.academicYear),
        ...(input.terminology?.academicYear || {}),
      },
      semester: {
        ...(existing?.terminology?.semester || DEFAULT_TERMINOLOGY.semester),
        ...(input.terminology?.semester || {}),
      },
      section: {
        ...(existing?.terminology?.section || DEFAULT_TERMINOLOGY.section),
        ...(input.terminology?.section || {}),
      },
      subject: {
        ...(existing?.terminology?.subject || DEFAULT_TERMINOLOGY.subject),
        ...(input.terminology?.subject || {}),
      },
      building: {
        ...(existing?.terminology?.building || DEFAULT_TERMINOLOGY.building),
        ...(input.terminology?.building || {}),
      },
      room: {
        ...(existing?.terminology?.room || DEFAULT_TERMINOLOGY.room),
        ...(input.terminology?.room || {}),
      },
    };

    const mergedAttendanceAlerts: IAttendanceAlertsConfig = {
      ...(existing?.attendanceAlerts || DEFAULT_ATTENDANCE_ALERTS),
      ...(input.attendanceAlerts || {}),
    };

    const institutionType =
      input.institutionType || existing?.institutionType || InstitutionType.ENGINEERING;

    const updated = await InstitutionConfiguration.findOneAndUpdate(
      { collegeId },
      {
        $set: {
          collegeId,
          institutionType,
          academicStructure: mergedStructure,
          terminology: mergedTerminology,
          attendanceAlerts: mergedAttendanceAlerts,
          isConfigured: true,
          updatedBy: new mongoose.Types.ObjectId(userId),
        },
      },
      { new: true, upsert: true, runValidators: true }
    );

    return updated.toJSON();
  }

  /**
   * Returns standard institution onboarding presets
   */
  getPresets() {
    return Object.values(INSTITUTION_PRESETS);
  }
}

export const institutionConfigService = new InstitutionConfigService();
