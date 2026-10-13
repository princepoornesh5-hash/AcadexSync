import { Types } from 'mongoose';
import { ImportDataType } from '../../../constants/import.constants';
import { IImportBatch } from '../../../models/importBatch.model';
import { INormalizedImportRow } from '../importValidation.service';
import { IResolvedAcademicContext } from '../contextResolution.service';
import { IImportAdapter, IImportPersistenceResult } from './importAdapter.interface';
import {
  InternalAssessment,
  AssessmentType,
  AssessmentStatus,
  StudentMarkStatus,
} from '../../../models/internalAssessment.model';
import { AssessmentMark } from '../../../models/assessmentMark.model';
import { FacultyAssignment } from '../../../models/facultyAssignment.model';
import { Subject } from '../../../models/subject.model';
import { ApiError } from '../../../utils/apiError';
import { AuditService } from '../../audit.service';

/**
 * Normalizes common historical assessment naming variants to canonical categories
 * while preserving human-readable titles.
 */
export function normalizeAssessmentCategory(rawTitle: string): {
  category: AssessmentType;
  title: string;
} {
  const title = (rawTitle || '').trim();
  const lower = title.toLowerCase();

  let category = AssessmentType.INTERNAL;

  if (
    lower.includes('unit test') ||
    /\but[-_\s]?\d*\b/i.test(lower) ||
    lower.startsWith('ut')
  ) {
    category = AssessmentType.UNIT_TEST;
  } else if (
    lower.includes('mid term') ||
    lower.includes('mid-term') ||
    lower.includes('midterm') ||
    /\bmid[-_\s]?\d*\b/i.test(lower)
  ) {
    category = AssessmentType.MID_TERM;
  } else if (
    lower.includes('model exam') ||
    lower.includes('model test') ||
    lower.startsWith('model')
  ) {
    category = AssessmentType.MODEL_EXAM;
  } else if (lower.includes('lab exam') || lower.includes('lab test')) {
    category = AssessmentType.LAB_EXAM;
  } else if (lower.includes('practical') || lower.includes('practical exam')) {
    category = AssessmentType.PRACTICAL;
  } else if (
    lower.includes('internal') ||
    /\bia[-_\s]?\d*\b/i.test(lower) ||
    lower.startsWith('ia')
  ) {
    category = AssessmentType.INTERNAL;
  } else if (lower.includes('quiz')) {
    category = AssessmentType.QUIZ;
  } else if (lower.includes('assignment')) {
    category = AssessmentType.ASSIGNMENT;
  } else if (lower.includes('project')) {
    category = AssessmentType.PROJECT;
  } else {
    category = AssessmentType.OTHER;
  }

  return {
    category,
    title: title || `Imported ${category}`,
  };
}

export class AssessmentImportAdapter implements IImportAdapter {
  dataType: ImportDataType = ImportDataType.ASSESSMENT;

  async persistBatch(
    batch: IImportBatch,
    validRows: INormalizedImportRow[],
    context: IResolvedAcademicContext
  ): Promise<IImportPersistenceResult> {
    const collegeId = batch.collegeId;

    if (!context.subjectId) {
      if (context.semesterId || context.sectionId) {
        const candidateSubjects = await Subject.find({
          collegeId,
          ...(context.semesterId ? { semesterId: context.semesterId } : {}),
        });
        if (candidateSubjects.length === 1) {
          context.subjectId = candidateSubjects[0]._id as Types.ObjectId;
        }
      }
      if (!context.subjectId) {
        const anySub = await Subject.findOne({ collegeId });
        if (anySub) {
          context.subjectId = anySub._id as Types.ObjectId;
        }
      }
    }

    if (!context.subjectId) {
      throw ApiError.badRequest('Assessment import requires a resolved Subject.');
    }

    // 1. Resolve FacultyAssignment & enforce ambiguity checks
    let resolvedFacultyAssignmentId = context.facultyAssignmentId;
    if (!resolvedFacultyAssignmentId && context.sectionId) {
      const candidateAssignments = await FacultyAssignment.find({
        collegeId,
        subjectId: context.subjectId,
        sectionId: context.sectionId,
      });

      if (candidateAssignments.length > 1) {
        throw ApiError.badRequest(
          'Multiple FacultyAssignments match this subject and section. Manual resolution is required.'
        );
      } else if (candidateAssignments.length === 1) {
        resolvedFacultyAssignmentId = candidateAssignments[0]._id as Types.ObjectId;
      }
    }

    // 2. Determine Assessment Title & Category
    const sampleRow = validRows[0];
    const rawTitle =
      (batch.metadata as any)?.assessmentTitle ||
      (batch.metadata as any)?.title ||
      sampleRow?.mappedValues?.assessmentTitle ||
      sampleRow?.mappedValues?.title ||
      batch.fileName.replace(/\.[^/.]+$/, '');

    const { category, title } = normalizeAssessmentCategory(rawTitle);

    // 3. Resolve Maximum Marks
    let maximumMarks = (batch.metadata as any)?.defaultMaxMarks;
    if (!maximumMarks || maximumMarks <= 0) {
      for (const r of validRows) {
        if (r.semanticValues.maximumMarks && r.semanticValues.maximumMarks > 0) {
          maximumMarks = r.semanticValues.maximumMarks;
          break;
        }
      }
    }

    if (!maximumMarks || maximumMarks <= 0) {
      let maxFound = 0;
      for (const r of validRows) {
        if (typeof r.semanticValues.marks === 'number' && r.semanticValues.marks > maxFound) {
          maxFound = r.semanticValues.marks;
        }
      }
      if (maxFound > 0) {
        maximumMarks = maxFound <= 25 ? 25 : maxFound <= 50 ? 50 : 100;
      }
    }

    if (!maximumMarks || maximumMarks <= 0) {
      throw ApiError.badRequest(
        'Assessment marks cannot be imported because the maximum mark is missing.'
      );
    }

    // 4. Find or Create Canonical Assessment (InternalAssessment)
    let assessmentQuery: any = {
      collegeId,
      subjectId: context.subjectId,
      title,
    };
    if (context.sectionId) assessmentQuery.sectionId = context.sectionId;
    if (resolvedFacultyAssignmentId) assessmentQuery.facultyAssignmentId = resolvedFacultyAssignmentId;

    let assessment = await InternalAssessment.findOne(assessmentQuery);

    if (!assessment) {
      assessment = await InternalAssessment.create({
        collegeId,
        departmentId: context.departmentId,
        courseId: context.courseId,
        academicYearId: context.academicYearId,
        semesterId: context.semesterId,
        sectionId: context.sectionId || null,
        subjectId: context.subjectId,
        facultyAssignmentId: resolvedFacultyAssignmentId || null,
        title,
        assessmentType: category,
        maximumMarks,
        passMarks: Math.ceil(maximumMarks * 0.35),
        status: AssessmentStatus.LOCKED,
        sourceType: 'IMPORTED',
        importBatchId: batch.importBatchId,
        createdBy: batch.uploadedBy,
        auditLog: [
          {
            action: 'HISTORICAL_IMPORT_CREATED',
            performedBy: batch.uploadedBy,
            performedByName: 'Import System',
            performedByRole: 'ADMIN',
            timestamp: new Date(),
            details: `Created from historical import batch ${batch.importBatchId}`,
          },
        ],
      });
    }

    // 5. Ingest Marks with Strict Conflict & Idempotency Rules
    let importedCount = 0;
    const createdMarkIds: string[] = [];

    for (const row of validRows) {
      const studentResolution = row.studentResolution;
      if (!studentResolution.studentEnrollmentId || !studentResolution.studentId) {
        continue;
      }

      const enrollmentObjectId = new Types.ObjectId(studentResolution.studentEnrollmentId);
      const studentObjectId = new Types.ObjectId(studentResolution.studentId);

      // Determine target marks and status
      let targetMarks = row.semanticValues.marks !== undefined ? row.semanticValues.marks : null;
      let targetStatus = StudentMarkStatus.NOT_ENTERED;

      const rawStatusStr = (row.semanticValues.status || '').toUpperCase();
      if (rawStatusStr === 'ABSENT') {
        targetStatus = StudentMarkStatus.ABSENT;
        targetMarks = null;
      } else if (rawStatusStr === 'EXEMPTED') {
        targetStatus = StudentMarkStatus.EXEMPTED;
        targetMarks = null;
      } else if (rawStatusStr === 'NOT_APPEARED') {
        targetStatus = StudentMarkStatus.NOT_APPEARED;
        targetMarks = null;
      } else if (targetMarks !== null && targetMarks !== undefined) {
        // Note: 0 marks is a valid score (PRESENT)
        targetStatus = StudentMarkStatus.PRESENT;
      }

      // Check existing mark for this student in this assessment
      const existingMark = await AssessmentMark.findOne({
        collegeId,
        assessmentId: assessment._id,
        studentEnrollmentId: enrollmentObjectId,
      });

      if (existingMark) {
        // Live Conflict Rule: Do NOT replace live records with conflicting imported data
        if (existingMark.sourceType === 'LIVE') {
          const marksMatch = existingMark.marks === targetMarks;
          const statusMatch = existingMark.status === targetStatus;
          if (!marksMatch || !statusMatch) {
            throw ApiError.badRequest(
              'IMPORT_CONFLICT_WITH_EXISTING_RECORD: Assessment mark conflicts with an existing ACADEX record for this student.'
            );
          }
          // If completely identical to live record, treat as idempotent no-op
          importedCount++;
          continue;
        }

        // Imported Record Idempotency: If previously imported with exact same data, skip safely
        if (existingMark.sourceType === 'IMPORTED') {
          const marksMatch = existingMark.marks === targetMarks;
          const statusMatch = existingMark.status === targetStatus;
          if (marksMatch && statusMatch) {
            importedCount++;
            continue;
          } else {
            throw ApiError.badRequest(
              `IMPORT_CONFLICT_WITH_EXISTING_RECORD: Assessment mark conflicts with an existing imported record for student '${studentResolution.studentPin || studentResolution.studentName}'.`
            );
          }
        }

        // Manual Historical Record Conflict / Idempotency Rule: Reject conflicts with existing manual historical marks
        if (existingMark.sourceType === 'HISTORICAL_MANUAL') {
          const marksMatch = existingMark.marks === targetMarks;
          const statusMatch = existingMark.status === targetStatus;
          if (marksMatch && statusMatch) {
            importedCount++;
            continue;
          } else {
            throw ApiError.badRequest(
              `IMPORT_CONFLICT_WITH_EXISTING_RECORD: Assessment mark conflicts with an existing manual historical record for student '${studentResolution.studentPin || studentResolution.studentName}'.`
            );
          }
        }
      }

      // Persist new canonical AssessmentMark
      const newMark = await AssessmentMark.create({
        collegeId,
        assessmentId: assessment._id,
        facultyAssignmentId: resolvedFacultyAssignmentId || null,
        subjectId: context.subjectId,
        studentEnrollmentId: enrollmentObjectId,
        studentId: studentObjectId,
        studentName: studentResolution.studentName || 'Student',
        rollNumber: studentResolution.rollNumber || null,
        admissionNumber: (row.rawValues as any)?.admissionNumber || null,
        marks: targetMarks,
        maximumMarks: assessment.maximumMarks,
        passMarks: assessment.passMarks,
        status: targetStatus,
        isLocked: true,
        lockedAt: new Date(),
        lockedBy: batch.uploadedBy,
        sourceType: 'IMPORTED',
        importBatchId: batch.importBatchId,
        remarks: row.semanticValues.remarks || null,
        auditHistory: [
          {
            action: 'HISTORICAL_MARK_IMPORTED',
            newMarks: targetMarks,
            newStatus: targetStatus,
            performedBy: batch.uploadedBy,
            performedByName: 'Import Administrator',
            reason: `Ingested from import batch ${batch.importBatchId}`,
            timestamp: new Date(),
          },
        ],
      });

      createdMarkIds.push(newMark._id.toString());
      importedCount++;
    }

    // 6. Record Provenance Audit
    await AuditService.logAction({
      collegeId: collegeId.toString(),
      actorUserId: batch.uploadedBy.toString(),
      entityType: 'Assessment',
      entityId: assessment._id.toString(),
      action: 'HISTORICAL_ASSESSMENT_IMPORTED',
      metadata: {
        importBatchId: batch.importBatchId,
        assessmentId: assessment._id.toString(),
        title: assessment.title,
        assessmentType: assessment.assessmentType,
        importedCount,
        failedCount: batch.rowCount - importedCount,
        sourceType: 'IMPORTED',
      },
    });

    return {
      importedCount,
      failedCount: batch.rowCount - importedCount,
      createdIds: createdMarkIds,
      details: {
        assessmentId: assessment._id.toString(),
        title: assessment.title,
        assessmentType: assessment.assessmentType,
        importBatchId: batch.importBatchId,
      },
    };
  }
}
