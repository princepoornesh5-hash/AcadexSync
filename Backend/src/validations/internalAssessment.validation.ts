import { z } from 'zod';
import { Types } from 'mongoose';
import { AssessmentStatus, AssessmentType, StudentMarkStatus } from '../models/internalAssessment.model';

const objectIdRegex = /^[0-9a-fA-F]{24}$/;
const isValidObjectId = (val: string) => objectIdRegex.test(val) && Types.ObjectId.isValid(val);

export const objectIdSchema = z
  .string()
  .refine(isValidObjectId, { message: 'Invalid ObjectId format' });

export const assessmentComponentSchema = z.object({
  key: z.string().min(1, 'Component key is required'),
  name: z.string().min(1, 'Component name is required'),
  maxMarks: z.number().positive('Max marks must be greater than 0'),
  weightage: z.number().min(0).max(100).optional().default(0),
  isStudentVisible: z.boolean().optional().default(true),
});

export const studentMarkEntrySchema = z.object({
  studentEnrollmentId: objectIdSchema.optional(),
  studentId: objectIdSchema.optional(),
  studentName: z.string().optional(),
  rollNumber: z.string().optional(),
  admissionNumber: z.string().optional(),
  componentMarks: z.record(z.union([z.number().min(0), z.null()])).optional().default({}),
  marks: z.number().min(0).nullable().optional(),
  obtainedMarks: z.number().min(0).optional(),
  totalMarks: z.number().min(0).optional(),
  status: z.nativeEnum(StudentMarkStatus).optional().default(StudentMarkStatus.NOT_ENTERED),
  remarks: z.string().max(500).optional(),
}).refine((data) => data.studentEnrollmentId || data.studentId, {
  message: 'Either studentEnrollmentId or studentId must be provided',
});

export const getContextSchema = z.object({
  query: z.object({
    assessmentId: objectIdSchema.optional(),
    facultyAssignmentId: objectIdSchema.optional(),
    sectionId: objectIdSchema.optional(),
    subjectId: objectIdSchema.optional(),
    academicYearId: objectIdSchema.optional(),
  }),
});

export const academicScopeTargetSchema = z.object({
  departmentId: objectIdSchema,
  courseId: objectIdSchema,
  academicYearId: objectIdSchema,
  semesterId: objectIdSchema,
  sectionId: objectIdSchema.optional().nullable(),
  facultyAssignmentId: objectIdSchema.optional().nullable(),
  departmentName: z.string().optional(),
  sectionName: z.string().optional(),
  semesterNumber: z.number().optional(),
});

export const previewScopeSchema = z.object({
  body: z.object({
    subjectId: objectIdSchema,
    academicScopes: z.array(academicScopeTargetSchema).min(1, 'At least one academic scope is required'),
  }),
});

export const checkScheduleConflictsSchema = z.object({
  body: z.object({
    date: z.string().min(8, 'Exam date is required'),
    startTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'Invalid startTime (HH:MM)'),
    endTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'Invalid endTime (HH:MM)'),
    roomId: objectIdSchema.optional().nullable(),
    invigilatorFacultyId: objectIdSchema.optional().nullable(),
    targetSectionIds: z.array(objectIdSchema).optional(),
    assessmentId: objectIdSchema.optional().nullable(),
  }).refine(
    (data) => {
      const [sh, sm] = data.startTime.split(':').map(Number);
      const [eh, em] = data.endTime.split(':').map(Number);
      return eh * 60 + em > sh * 60 + sm;
    },
    { message: 'endTime must be strictly later than startTime' }
  ),
});

export const createAssessmentSchema = z.object({
  body: z.object({
    departmentId: objectIdSchema.optional(),
    courseId: objectIdSchema.optional(),
    academicYearId: objectIdSchema.optional(),
    semesterId: objectIdSchema.optional(),
    sectionId: objectIdSchema.optional().nullable(),
    subjectId: objectIdSchema.optional(),
    facultyAssignmentId: objectIdSchema.optional().nullable(),
    academicScopes: z.array(academicScopeTargetSchema).optional(),
    title: z.string().min(2, 'Title must be at least 2 characters').max(150),
    description: z.string().max(1000).optional(),
    assessmentType: z.string().optional().default(AssessmentType.INTERNAL_EXAM),
    maximumMarks: z.number().positive('Maximum marks must be greater than 0'),
    passMarks: z.number().min(0).optional(),
    weightage: z.number().min(0).max(100).optional(),
    assessmentDate: z.string().or(z.date()).optional(),
    components: z.array(assessmentComponentSchema).optional(),
    sourceType: z.enum(['LIVE', 'IMPORTED', 'HISTORICAL_MANUAL']).optional(),
    isHistorical: z.boolean().optional(),
  }).refine(
    (data) =>
      Boolean(
        (data.academicScopes && data.academicScopes.length > 0) ||
        data.facultyAssignmentId ||
        (data.subjectId && data.sectionId && data.departmentId && data.courseId && data.academicYearId && data.semesterId)
      ),
    {
      message:
        'Either academicScopes, facultyAssignmentId, or full academic context (department, course, academicYear, semester, section, subject) must be provided',
    }
  ),
});

export const updateAssessmentSchema = z.object({
  body: z.object({
    title: z.string().min(2).max(150).optional(),
    description: z.string().max(1000).optional(),
    assessmentType: z.nativeEnum(AssessmentType).optional(),
    maximumMarks: z.number().positive().optional(),
    passMarks: z.number().min(0).optional(),
    weightage: z.number().min(0).max(100).optional(),
    assessmentDate: z.string().or(z.date()).optional(),
    components: z.array(assessmentComponentSchema).optional(),
    status: z.nativeEnum(AssessmentStatus).optional(),
  }),
});

export const scheduleAssessmentSchema = z.object({
  body: z.object({
    assessmentId: objectIdSchema.optional(),
    date: z.string().min(8, 'Exam date is required'),
    startTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'Invalid startTime (HH:MM)'),
    endTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'Invalid endTime (HH:MM)'),
    roomId: objectIdSchema.optional().nullable(),
    invigilatorFacultyId: objectIdSchema.optional().nullable(),
    instructions: z.string().max(1000).optional(),
  }).refine(
    (data) => {
      const [sh, sm] = data.startTime.split(':').map(Number);
      const [eh, em] = data.endTime.split(':').map(Number);
      return eh * 60 + em > sh * 60 + sm;
    },
    { message: 'endTime must be strictly later than startTime' }
  ),
});

export const listAssessmentsSchema = z.object({
  query: z.object({
    facultyAssignmentId: objectIdSchema.optional(),
    sectionId: objectIdSchema.optional(),
    subjectId: objectIdSchema.optional(),
    semesterId: objectIdSchema.optional(),
    academicYearId: objectIdSchema.optional(),
    status: z.nativeEnum(AssessmentStatus).optional(),
    assessmentType: z.nativeEnum(AssessmentType).optional(),
  }),
});

export const saveDraftMarksSchema = z.object({
  body: z.object({
    assessmentId: objectIdSchema.optional(),
    sectionId: objectIdSchema.optional(),
    subjectId: objectIdSchema.optional(),
    academicYearId: objectIdSchema.optional(),
    title: z.string().optional(),
    entries: z.array(studentMarkEntrySchema).min(1, 'At least one student mark entry is required'),
  }).refine((data) => data.assessmentId || (data.sectionId && data.subjectId), {
    message: 'Either assessmentId or both sectionId and subjectId must be provided',
  }),
});

export const bulkSaveMarksSchema = z.object({
  body: z.object({
    assessmentId: objectIdSchema.optional(),
    sectionId: objectIdSchema.optional(),
    subjectId: objectIdSchema.optional(),
    academicYearId: objectIdSchema.optional(),
    title: z.string().optional(),
    entries: z.array(studentMarkEntrySchema).min(1, 'At least one student mark entry is required'),
  }).refine((data) => data.assessmentId || (data.sectionId && data.subjectId), {
    message: 'Either assessmentId or both sectionId and subjectId must be provided',
  }),
});

export const correctMarkSchema = z.object({
  body: z.object({
    assessmentId: objectIdSchema.optional(),
    sectionId: objectIdSchema.optional(),
    subjectId: objectIdSchema.optional(),
    studentId: objectIdSchema,
    componentKey: z.string().optional(),
    newMark: z.number().min(0, 'Marks cannot be negative'),
    status: z.nativeEnum(StudentMarkStatus).optional(),
    reason: z.string().min(5, 'Correction reason must be at least 5 characters long'),
  }).refine((data) => data.assessmentId || (data.sectionId && data.subjectId), {
    message: 'Either assessmentId or both sectionId and subjectId must be provided',
  }),
});

export const reviewSchema = z.object({
  body: z.object({
    sectionId: objectIdSchema,
    subjectId: objectIdSchema,
    comments: z.string().max(1000).optional(),
  }),
});

export const publishSchema = z.object({
  body: z.object({
    sectionId: objectIdSchema,
    subjectId: objectIdSchema,
  }),
});

export const unlockSchema = z.object({
  body: z.object({
    sectionId: objectIdSchema,
    subjectId: objectIdSchema,
    reason: z.string().min(5, 'Unlock reason must be at least 5 characters long'),
  }),
});

export const assessmentTransitionSchema = z.object({
  body: z.object({
    status: z.nativeEnum(AssessmentStatus),
    reason: z.string().min(3).optional(),
  }),
});

export const subjectSummarySchema = z.object({
  query: z.object({
    subjectId: objectIdSchema,
    semesterId: objectIdSchema,
    studentId: objectIdSchema.optional(),
  }),
});
