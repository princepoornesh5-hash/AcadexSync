import { z } from 'zod';
import { TransferCreditStatus } from '../constants/status';

export const createTransferCreditSchema = z.object({
  studentId: z.string().min(1, 'studentId is required'),
  studentEnrollmentId: z.string().min(1, 'studentEnrollmentId is required'),
  originCollegeId: z.string().optional(),
  originInstitutionName: z.string().min(1, 'originInstitutionName is required').max(200),
  priorProgramOrDegree: z.string().max(200).optional(),
  admissionType: z.enum([
    'LATERAL_ENTRY',
    'INTER_COLLEGE_TRANSFER',
    'CREDIT_EXCHANGE',
    'REGULAR_ADMISSION_CREDIT',
  ]).default('INTER_COLLEGE_TRANSFER'),
  entrySemesterNumber: z.number().int().min(1).max(12).default(3),
  recognizedCredits: z.number().min(0, 'recognizedCredits must be non-negative'),
  recognizedGradePoints: z.number().min(0).optional().nullable(),
  transferredSubjects: z
    .array(
      z.object({
        subjectCode: z.string().min(1),
        subjectName: z.string().min(1),
        credits: z.number().min(0),
        grade: z.string().optional().nullable(),
        gradePoints: z.number().min(0).optional().nullable(),
        equivalentSubjectId: z.string().optional().nullable(),
        remarks: z.string().optional().nullable(),
      })
    )
    .default([]),
  verificationDocumentUrl: z.string().optional().nullable(),
  remarks: z.string().max(500).optional().nullable(),
});

export const updateTransferCreditStatusSchema = z.object({
  status: z.enum([
    TransferCreditStatus.PENDING,
    TransferCreditStatus.VERIFIED,
    TransferCreditStatus.APPROVED,
    TransferCreditStatus.REJECTED,
  ]),
  rejectionReason: z.string().max(500).optional().nullable(),
  remarks: z.string().max(500).optional().nullable(),
});

export type CreateTransferCreditInput = z.infer<typeof createTransferCreditSchema>;
export type UpdateTransferCreditStatusInput = z.infer<typeof updateTransferCreditStatusSchema>;
