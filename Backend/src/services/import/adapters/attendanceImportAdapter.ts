import { Types } from 'mongoose';
import { ImportDataType } from '../../../constants/import.constants';
import { IImportBatch } from '../../../models/importBatch.model';
import { INormalizedImportRow } from '../importValidation.service';
import { IResolvedAcademicContext } from '../contextResolution.service';
import { IImportAdapter, IImportPersistenceResult } from './importAdapter.interface';
import {
  AttendanceSession,
  IAttendanceRecordItem,
} from '../../../models/attendanceSession.model';
import { AttendanceRecord } from '../../../models/attendanceRecord.model';
import { HistoricalAttendanceSummary } from '../../../models/historicalAttendanceSummary.model';
import { Subject } from '../../../models/subject.model';
import { FacultyAssignment } from '../../../models/facultyAssignment.model';
import { Faculty } from '../../../models/faculty.model';
import { Section } from '../../../models/section.model';
import { AttendanceStatus, AttendanceSessionStatus } from '../../../constants/status';
import { ApiError } from '../../../utils/apiError';
import { AuditService } from '../../audit.service';

function parseCanonicalDate(dateStr: string): Date {
  const trimmed = String(dateStr).trim();
  if (/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) {
    return new Date(`${trimmed}T00:00:00.000Z`);
  }
  return new Date(trimmed);
}

export class AttendanceImportAdapter implements IImportAdapter {
  dataType: ImportDataType = ImportDataType.ATTENDANCE;

  async persistBatch(
    batch: IImportBatch,
    validRows: INormalizedImportRow[],
    context: IResolvedAcademicContext
  ): Promise<IImportPersistenceResult> {
    const collegeId = batch.collegeId;

    if (!context.subjectId) {
      throw ApiError.badRequest('Attendance import requires a resolved Subject.');
    }

    const subject = await Subject.findOne({ _id: context.subjectId, collegeId });
    if (!subject) {
      throw ApiError.notFound('Target subject not found in college tenant.');
    }

    let sectionName: string | null = null;
    if (context.sectionId) {
      const sec = await Section.findOne({ _id: context.sectionId, collegeId });
      if (sec) sectionName = sec.name;
    }

    // Resolve Faculty for Detailed Session records
    let targetFacultyId: Types.ObjectId | null = null;
    if (context.facultyAssignmentId) {
      const fa = await FacultyAssignment.findOne({ _id: context.facultyAssignmentId, collegeId });
      if (fa && fa.facultyId) targetFacultyId = fa.facultyId as Types.ObjectId;
    }
    if (!targetFacultyId && context.sectionId) {
      const fa = await FacultyAssignment.findOne({
        collegeId,
        subjectId: context.subjectId,
        sectionId: context.sectionId,
      });
      if (fa && fa.facultyId) targetFacultyId = fa.facultyId as Types.ObjectId;
    }
    if (!targetFacultyId) {
      const anyFaculty = await Faculty.findOne({ collegeId });
      if (anyFaculty) targetFacultyId = anyFaculty._id as Types.ObjectId;
    }

    let importedCount = 0;
    const createdIds: string[] = [];

    // Group Detailed Session rows by date and timeSlot to create canonical AttendanceSession
    // Key: `${dateStr}_${timeSlot}`
    const detailedSessionGroups = new Map<string, INormalizedImportRow[]>();
    const summaryRows: INormalizedImportRow[] = [];
    const percentageOnlyRows: INormalizedImportRow[] = [];

    for (const row of validRows) {
      const rawDate = row.semanticValues.date || row.mappedValues.date;
      const rawHeld = row.semanticValues.classesHeld ?? (row.mappedValues.classesHeld ? Number(row.mappedValues.classesHeld) : null);
      const rawPct = row.semanticValues.attendancePercentage ?? (row.mappedValues.attendancePercentage ? Number(String(row.mappedValues.attendancePercentage).replace('%', '')) : null);

      if (rawDate && String(rawDate).trim() !== '') {
        // Level 1: DETAILED SESSION DATA
        const slot = row.semanticValues.timeSlot || row.mappedValues.timeSlot || 'Historical Session 1';
        const groupKey = `${String(rawDate).trim()}_${slot}`;
        if (!detailedSessionGroups.has(groupKey)) {
          detailedSessionGroups.set(groupKey, []);
        }
        detailedSessionGroups.get(groupKey)!.push(row);
      } else if (rawHeld !== null && !isNaN(rawHeld)) {
        // Level 2: PERIOD SUMMARY
        summaryRows.push(row);
      } else if (rawPct !== null && !isNaN(rawPct)) {
        // Level 3: PERCENTAGE ONLY
        percentageOnlyRows.push(row);
      } else {
        // Unidentifiable precision - reject row safely
        throw ApiError.badRequest(
          `Row #${row.rowNumber} does not contain valid attendance session date, period summary counts, or percentage metric.`
        );
      }
    }

    // =========================================================================
    // LEVEL 1: DETAILED SESSION PERSISTENCE (Canonical AttendanceSession + Records)
    // =========================================================================
    for (const [_groupKey, groupRows] of detailedSessionGroups.entries()) {
      const sampleRow = groupRows[0];
      const dateStr = sampleRow.semanticValues.date || sampleRow.mappedValues.date;
      const sessionDate = parseCanonicalDate(dateStr);
      if (isNaN(sessionDate.getTime())) {
        throw ApiError.badRequest(`Invalid date format '${dateStr}' in historical attendance row.`);
      }

      const timeSlot = sampleRow.semanticValues.timeSlot || sampleRow.mappedValues.timeSlot || 'Historical Session 1';

      if (!targetFacultyId) {
        throw ApiError.badRequest('Detailed attendance import requires a valid faculty assignment context.');
      }

      // Find or create canonical AttendanceSession
      let sessionQuery: any = {
        collegeId,
        subjectId: context.subjectId,
        date: sessionDate,
        timeSlot,
      };
      if (context.sectionId) sessionQuery.sectionId = context.sectionId;

      let session = await AttendanceSession.findOne(sessionQuery);

      if (!session) {
        session = await AttendanceSession.create({
          collegeId,
          departmentId: context.departmentId || subject.departmentId,
          courseId: context.courseId,
          academicYearId: context.academicYearId,
          semesterId: context.semesterId,
          sectionId: context.sectionId || null,
          sectionName: sectionName || null,
          subjectId: context.subjectId,
          subjectName: subject.name,
          timeSlot,
          date: sessionDate,
          facultyId: targetFacultyId,
          facultyAssignmentId: context.facultyAssignmentId || null,
          status: AttendanceSessionStatus.LOCKED,
          isSubmitted: true,
          isLocked: true,
          sourceType: 'IMPORTED',
          importBatchId: batch.importBatchId,
          createdBy: batch.uploadedBy.toString(),
          records: [],
          version: 1,
        });
        createdIds.push(session._id.toString());
      }

      for (const row of groupRows) {
        const studentRes = row.studentResolution;
        if (!studentRes.studentId || !studentRes.studentEnrollmentId) continue;

        const studentObjectId = new Types.ObjectId(studentRes.studentId);
        const enrollmentObjectId = new Types.ObjectId(studentRes.studentEnrollmentId);

        // Normalize status
        let targetStatus = AttendanceStatus.PRESENT;
        const rawStatus = (row.semanticValues.status || row.mappedValues.status || '').toUpperCase();
        if (['A', 'ABSENT', 'ABS'].includes(rawStatus)) {
          targetStatus = AttendanceStatus.ABSENT;
        } else if (['L', 'LATE'].includes(rawStatus)) {
          targetStatus = AttendanceStatus.LATE;
        } else if (['EXCUSED', 'E'].includes(rawStatus)) {
          targetStatus = AttendanceStatus.EXCUSED;
        }

        // Live vs Imported Conflict Check
        const existingRecord = await AttendanceRecord.findOne({
          sessionId: session._id,
          studentId: studentObjectId,
        });

        if (existingRecord) {
          if (existingRecord.sourceType === 'LIVE') {
            if (existingRecord.status !== targetStatus) {
              throw ApiError.badRequest(
                'IMPORT_CONFLICT_WITH_EXISTING_RECORD: Attendance status conflicts with an existing ACADEX live record for this student.'
              );
            }
            importedCount++;
            continue; // Idempotent match
          }

          if (existingRecord.sourceType === 'IMPORTED') {
            if (existingRecord.status === targetStatus) {
              importedCount++;
              continue; // Idempotent duplicate re-import
            } else {
              throw ApiError.badRequest(
                `IMPORT_CONFLICT_WITH_EXISTING_RECORD: Attendance status conflicts with an already imported record from batch ${existingRecord.importBatchId}.`
              );
            }
          }

          if (existingRecord.sourceType === 'HISTORICAL_MANUAL') {
            if (existingRecord.status === targetStatus) {
              importedCount++;
              continue; // Idempotent match
            } else {
              throw ApiError.badRequest(
                `IMPORT_CONFLICT_WITH_EXISTING_RECORD: Attendance status conflicts with an existing manual historical record for student '${studentRes.studentPin || studentRes.studentName}'.`
              );
            }
          }
        }

        // Persist new canonical AttendanceRecord
        await AttendanceRecord.create({
          collegeId,
          departmentId: context.departmentId || subject.departmentId,
          courseId: context.courseId,
          academicYearId: context.academicYearId,
          semesterId: context.semesterId,
          sectionId: context.sectionId || null,
          sessionId: session._id,
          studentId: studentObjectId,
          studentEnrollmentId: enrollmentObjectId,
          studentName: studentRes.studentName || 'Student',
          rollNumber: studentRes.rollNumber || '—',
          subjectId: context.subjectId,
          facultyId: targetFacultyId,
          date: sessionDate,
          timeSlot,
          status: targetStatus,
          sourceType: 'IMPORTED',
          importBatchId: batch.importBatchId,
        });

        // Add to session.records array
        const recordItem: IAttendanceRecordItem = {
          studentId: studentObjectId,
          studentName: studentRes.studentName || 'Student',
          rollNumber: studentRes.rollNumber || '—',
          sectionId: context.sectionId || null,
          status: targetStatus,
        };
        session.records.push(recordItem);
        importedCount++;
      }

      await session.save();
    }

    // =========================================================================
    // LEVEL 2: HISTORICAL PERIOD SUMMARY PERSISTENCE (HistoricalAttendanceSummary)
    // =========================================================================
    // Rule: NEVER manufacture fake AttendanceSession documents!
    for (const row of summaryRows) {
      const studentRes = row.studentResolution;
      if (!studentRes.studentId || !studentRes.studentEnrollmentId) continue;

      const studentObjectId = new Types.ObjectId(studentRes.studentId);
      const enrollmentObjectId = new Types.ObjectId(studentRes.studentEnrollmentId);

      const classesHeld = Number(row.semanticValues.classesHeld ?? row.mappedValues.classesHeld);
      const presentCount = Number(
        row.semanticValues.presentCount ??
        row.mappedValues.presentCount ??
        row.mappedValues.attended ??
        0
      );
      const absentCount = Number(
        row.semanticValues.absentCount ??
        row.mappedValues.absentCount ??
        (classesHeld - presentCount)
      );

      const attendancePercentage =
        classesHeld > 0 ? Math.round((presentCount / classesHeld) * 10000) / 100 : 0;

      const periodLabel =
        row.semanticValues.periodLabel ||
        row.mappedValues.periodLabel ||
        row.mappedValues.period ||
        row.mappedValues.month ||
        'Historical Period';

      // Conflict / Idempotency check
      const existingSummary = await HistoricalAttendanceSummary.findOne({
        collegeId,
        studentEnrollmentId: enrollmentObjectId,
        subjectId: context.subjectId,
        periodLabel,
      });

      if (existingSummary) {
        if (
          existingSummary.classesHeld === classesHeld &&
          existingSummary.presentCount === presentCount
        ) {
          importedCount++;
          continue; // Idempotent match
        } else {
          throw ApiError.badRequest(
            `IMPORT_CONFLICT_WITH_EXISTING_RECORD: Historical attendance summary conflicts with existing record for student '${studentRes.studentPin || studentRes.studentName}' in period '${periodLabel}'.`
          );
        }
      }

      const summaryDoc = await HistoricalAttendanceSummary.create({
        collegeId,
        departmentId: context.departmentId || subject.departmentId,
        courseId: context.courseId,
        academicYearId: context.academicYearId,
        semesterId: context.semesterId,
        sectionId: context.sectionId || null,
        subjectId: context.subjectId,
        studentEnrollmentId: enrollmentObjectId,
        studentId: studentObjectId,
        periodLabel,
        classesHeld,
        presentCount,
        absentCount,
        attendancePercentage,
        precisionLevel: 'PERIOD_SUMMARY',
        sourceType: 'IMPORTED',
        importBatchId: batch.importBatchId,
        importedBy: batch.uploadedBy,
        importedAt: new Date(),
        remarks: row.semanticValues.remarks || null,
      });

      createdIds.push(summaryDoc._id.toString());
      importedCount++;
    }

    // =========================================================================
    // LEVEL 3: PERCENTAGE-ONLY PERSISTENCE (HistoricalAttendanceSummary)
    // =========================================================================
    // Rule: NEVER convert percentages into fake counts or fake sessions!
    for (const row of percentageOnlyRows) {
      const studentRes = row.studentResolution;
      if (!studentRes.studentId || !studentRes.studentEnrollmentId) continue;

      const studentObjectId = new Types.ObjectId(studentRes.studentId);
      const enrollmentObjectId = new Types.ObjectId(studentRes.studentEnrollmentId);

      const attendancePercentage = Number(
        row.semanticValues.attendancePercentage ??
        String(row.mappedValues.attendancePercentage).replace('%', '')
      );

      const periodLabel =
        row.semanticValues.periodLabel ||
        row.mappedValues.periodLabel ||
        row.mappedValues.period ||
        row.mappedValues.month ||
        'Historical Aggregate';

      // Conflict / Idempotency check
      const existingSummary = await HistoricalAttendanceSummary.findOne({
        collegeId,
        studentEnrollmentId: enrollmentObjectId,
        subjectId: context.subjectId,
        periodLabel,
      });

      if (existingSummary) {
        if (
          existingSummary.precisionLevel === 'PERCENTAGE_ONLY' &&
          existingSummary.attendancePercentage === attendancePercentage
        ) {
          importedCount++;
          continue; // Idempotent match
        } else {
          throw ApiError.badRequest(
            `IMPORT_CONFLICT_WITH_EXISTING_RECORD: Percentage-only attendance conflicts with existing record for student '${studentRes.studentPin || studentRes.studentName}' in period '${periodLabel}'.`
          );
        }
      }

      const summaryDoc = await HistoricalAttendanceSummary.create({
        collegeId,
        departmentId: context.departmentId || subject.departmentId,
        courseId: context.courseId,
        academicYearId: context.academicYearId,
        semesterId: context.semesterId,
        sectionId: context.sectionId || null,
        subjectId: context.subjectId,
        studentEnrollmentId: enrollmentObjectId,
        studentId: studentObjectId,
        periodLabel,
        classesHeld: null, // Strictly null: no manufactured precision!
        presentCount: null, // Strictly null: no manufactured precision!
        absentCount: null, // Strictly null: no manufactured precision!
        attendancePercentage,
        precisionLevel: 'PERCENTAGE_ONLY',
        sourceType: 'IMPORTED',
        importBatchId: batch.importBatchId,
        importedBy: batch.uploadedBy,
        importedAt: new Date(),
        remarks: row.semanticValues.remarks || null,
      });

      createdIds.push(summaryDoc._id.toString());
      importedCount++;
    }

    // Record Provenance Audit
    await AuditService.logAction({
      collegeId: collegeId.toString(),
      actorUserId: batch.uploadedBy.toString(),
      entityType: 'Attendance',
      entityId: batch._id.toString(),
      action: 'HISTORICAL_ATTENDANCE_IMPORTED',
      metadata: {
        importBatchId: batch.importBatchId,
        subjectId: context.subjectId.toString(),
        detailedSessionCount: detailedSessionGroups.size,
        periodSummaryCount: summaryRows.length,
        percentageOnlyCount: percentageOnlyRows.length,
        importedCount,
        failedCount: batch.rowCount - importedCount,
        sourceType: 'IMPORTED',
      },
    });

    return {
      importedCount,
      failedCount: batch.rowCount - importedCount,
      createdIds,
      details: {
        importBatchId: batch.importBatchId,
        detailedSessions: detailedSessionGroups.size,
        periodSummaries: summaryRows.length,
        percentageOnlySummaries: percentageOnlyRows.length,
      },
    };
  }
}
