import { z } from 'zod';
import { InstitutionType } from '../constants/institutionConfig.constants';

const ConceptTermSchema = z.object({
  singular: z.string().trim().min(1, 'Singular label cannot be empty').max(50),
  plural: z.string().trim().min(1, 'Plural label cannot be empty').max(50),
});

export const updateInstitutionConfigSchema = z.object({
  institutionType: z.nativeEnum(InstitutionType).optional(),
  academicStructure: z
    .object({
      program: z.boolean().optional(),
      academicYear: z.boolean().optional(),
      semester: z.boolean().optional(),
      section: z.boolean().optional(),
      subject: z.boolean().optional(),
      building: z.boolean().optional(),
      room: z.boolean().optional(),
    })
    .optional(),
  terminology: z
    .object({
      department: ConceptTermSchema.optional(),
      program: ConceptTermSchema.optional(),
      academicYear: ConceptTermSchema.optional(),
      semester: ConceptTermSchema.optional(),
      section: ConceptTermSchema.optional(),
      subject: ConceptTermSchema.optional(),
      building: ConceptTermSchema.optional(),
      room: ConceptTermSchema.optional(),
    })
    .optional(),
  attendanceAlerts: z
    .object({
      enabled: z.boolean().optional(),
      warningPercentage: z.number().min(0).max(100).optional(),
      criticalPercentage: z.number().min(0).max(100).optional(),
      absenceAlertsEnabled: z.boolean().optional(),
    })
    .optional(),
  assessmentConfig: z
    .object({
      enabled: z.boolean().optional(),
      maxTotalMarks: z.number().min(1).max(500).optional(),
      allowDecimals: z.boolean().optional(),
      requireHodApproval: z.boolean().optional(),
      components: z
        .array(
          z.object({
            key: z.string().trim().min(1),
            name: z.string().trim().min(1),
            maxMarks: z.number().min(1),
            weightage: z.number().optional(),
            enabled: z.boolean(),
            appliesTo: z.enum(['all', 'theory', 'practical']).default('all'),
            visibleToStudents: z.boolean().default(true),
          })
        )
        .optional(),
    })
    .optional(),
});

export type UpdateInstitutionConfigInput = z.infer<typeof updateInstitutionConfigSchema>;
