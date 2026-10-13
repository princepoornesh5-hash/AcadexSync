import {
  ImportDataType,
  ImportIssueCode,
  IssueSeverity,
  RowValidationStatus,
} from '../../constants/import.constants';
import { IColumnMapping } from '../../models/importBatch.model';
import {
  ContextResolutionService,
  IStudentResolutionResult,
} from './contextResolution.service';

export interface IValidationIssue {
  code: ImportIssueCode;
  severity: IssueSeverity;
  message: string;
  column?: string;
  rowNumber: number;
}

export interface INormalizedImportRow {
  rowNumber: number;
  rawValues: Record<string, any>;
  mappedValues: Record<string, any>;
  studentResolution: IStudentResolutionResult;
  semanticValues: {
    marks?: number | null;
    maximumMarks?: number | null;
    status?: string | null;
    attendancePercentage?: number | null;
    classesHeld?: number | null;
    presentCount?: number | null;
    absentCount?: number | null;
    date?: string | null;
    timeSlot?: string | null;
    periodLabel?: string | null;
    remarks?: string | null;
  };
  issues: IValidationIssue[];
  status: RowValidationStatus;
}

export interface IValidationSummary {
  rowCount: number;
  validCount: number;
  warningCount: number;
  unresolvedCount: number;
  errorCount: number;
  conflictCount: number;
  detectedPrecision?: 'DETAILED_SESSION' | 'PERIOD_SUMMARY' | 'PERCENTAGE_ONLY' | 'NOT_APPLICABLE' | 'MIXED';
  detailedCount?: number;
  summaryCount?: number;
  percentageOnlyCount?: number;
}

export class ImportValidationService {
  /**
   * Validates and normalizes all parsed rows against column mappings and resolved student context.
   */
  static validateRows(
    rows: Array<{ rowNumber: number; values: Record<string, any> }>,
    mappings: IColumnMapping[],
    dataType: ImportDataType,
    studentContext: Awaited<ReturnType<typeof ContextResolutionService.prepareStudentResolutionContext>>,
    defaultMaxMarks?: number
  ): {
    normalizedRows: INormalizedImportRow[];
    summary: IValidationSummary;
  } {
    const mappingByTarget = new Map<string, string>();
    for (const m of mappings) {
      if (m.targetField && m.targetField !== 'UNMAPPED') {
        mappingByTarget.set(m.targetField, m.sourceColumn);
      }
    }

    const normalizedRows: INormalizedImportRow[] = [];

    // Track student occurrences for duplicate/conflict detection
    // Key: studentEnrollmentId or studentPin -> list of { rowNumber, marks, status }
    const studentOccurrences = new Map<string, Array<{ rowNumber: number; marks?: number | null; status?: string | null }>>();

    for (const rawRow of rows) {
      const issues: IValidationIssue[] = [];
      const mappedValues: Record<string, any> = {};

      for (const [targetField, sourceCol] of mappingByTarget.entries()) {
        mappedValues[targetField] = rawRow.values[sourceCol] ?? '';
      }

      // 1. Resolve student identity
      const studentResolution = ContextResolutionService.resolveStudentRow(
        {
          studentPin: mappedValues.studentPin,
          rollNumber: mappedValues.rollNumber,
          admissionNumber: mappedValues.admissionNumber,
          studentEnrollmentId: mappedValues.studentEnrollmentId,
          studentId: mappedValues.studentId,
          studentName: mappedValues.studentName,
        },
        studentContext
      );

      if (studentResolution.status === RowValidationStatus.INVALID) {
        issues.push({
          code: studentResolution.issueCode || ImportIssueCode.STUDENT_NOT_FOUND,
          severity: IssueSeverity.ERROR,
          message: studentResolution.reason || 'Failed to resolve student',
          column: mappingByTarget.get('studentPin') || 'Student Identifier',
          rowNumber: rawRow.rowNumber,
        });
      } else if (studentResolution.status === RowValidationStatus.UNRESOLVED) {
        issues.push({
          code: studentResolution.issueCode || ImportIssueCode.STUDENT_AMBIGUOUS,
          severity: IssueSeverity.WARNING,
          message: studentResolution.reason || 'Student identity is ambiguous',
          column: mappingByTarget.get('studentName') || 'Student Name',
          rowNumber: rawRow.rowNumber,
        });
      } else if (studentResolution.status === RowValidationStatus.WARNING && studentResolution.reason) {
        issues.push({
          code: ImportIssueCode.STUDENT_AMBIGUOUS,
          severity: IssueSeverity.WARNING,
          message: studentResolution.reason,
          rowNumber: rawRow.rowNumber,
        });
      }

      // 2. Parse and validate semantic values
      const semanticValues: INormalizedImportRow['semanticValues'] = {};

      // Marks validation (for ASSESSMENT, ASSIGNMENT, etc.)
      if (dataType === ImportDataType.ASSESSMENT || dataType === ImportDataType.ASSIGNMENT) {
        const rawMarks = mappedValues.marks;
        if (rawMarks !== undefined && rawMarks !== '') {
          const strMarks = String(rawMarks).trim();
          const upperMarks = strMarks.toUpperCase();

          if (['A', 'ABS', 'ABSENT', 'AB'].includes(upperMarks)) {
            semanticValues.status = 'ABSENT';
            semanticValues.marks = null;
          } else if (['NA', 'NOT_APPEARED', 'NOT APPEARED'].includes(upperMarks)) {
            semanticValues.status = 'NOT_APPEARED';
            semanticValues.marks = null;
          } else if (['EXEMPT', 'EXEMPTED'].includes(upperMarks)) {
            semanticValues.status = 'EXEMPTED';
            semanticValues.marks = null;
          } else {
            const numMarks = Number(strMarks);
            if (isNaN(numMarks)) {
              issues.push({
                code: ImportIssueCode.INVALID_VALUE,
                severity: IssueSeverity.ERROR,
                message: `Invalid non-numeric marks value '${rawMarks}'`,
                column: mappingByTarget.get('marks'),
                rowNumber: rawRow.rowNumber,
              });
            } else if (numMarks < 0) {
              issues.push({
                code: ImportIssueCode.INVALID_VALUE,
                severity: IssueSeverity.ERROR,
                message: `Negative marks (${numMarks}) are not permitted`,
                column: mappingByTarget.get('marks'),
                rowNumber: rawRow.rowNumber,
              });
            } else {
              semanticValues.marks = numMarks;
              if (semanticValues.status === undefined) {
                semanticValues.status = 'PRESENT';
              }
            }
          }
        }

        // Maximum marks
        let effectiveMaxMarks = defaultMaxMarks;
        if (mappedValues.maximumMarks) {
          const numMax = Number(mappedValues.maximumMarks);
          if (!isNaN(numMax) && numMax > 0) {
            effectiveMaxMarks = numMax;
          }
        }
        semanticValues.maximumMarks = effectiveMaxMarks;

        if (
          semanticValues.marks !== undefined &&
          semanticValues.marks !== null &&
          effectiveMaxMarks !== undefined &&
          effectiveMaxMarks > 0
        ) {
          if (semanticValues.marks > effectiveMaxMarks) {
            issues.push({
              code: ImportIssueCode.INVALID_VALUE,
              severity: IssueSeverity.ERROR,
              message: `Marks (${semanticValues.marks}) exceed maximum marks allowed (${effectiveMaxMarks})`,
              column: mappingByTarget.get('marks'),
              rowNumber: rawRow.rowNumber,
            });
          }
        }
      }

      // Attendance validation
      if (dataType === ImportDataType.ATTENDANCE) {
        if (mappedValues.attendancePercentage !== undefined && mappedValues.attendancePercentage !== '') {
          const pct = Number(String(mappedValues.attendancePercentage).replace('%', '').trim());
          if (isNaN(pct) || pct < 0 || pct > 100) {
            issues.push({
              code: ImportIssueCode.INVALID_VALUE,
              severity: IssueSeverity.ERROR,
              message: `Attendance percentage must be between 0 and 100, got '${mappedValues.attendancePercentage}'`,
              column: mappingByTarget.get('attendancePercentage'),
              rowNumber: rawRow.rowNumber,
            });
          } else {
            semanticValues.attendancePercentage = pct;
          }
        }

        if (mappedValues.classesHeld !== undefined && mappedValues.classesHeld !== '') {
          const held = Number(mappedValues.classesHeld);
          if (isNaN(held) || held < 0) {
            issues.push({
              code: ImportIssueCode.INVALID_VALUE,
              severity: IssueSeverity.ERROR,
              message: `Classes held must be a non-negative number, got '${mappedValues.classesHeld}'`,
              column: mappingByTarget.get('classesHeld'),
              rowNumber: rawRow.rowNumber,
            });
          } else {
            semanticValues.classesHeld = held;
          }
        }

        if (mappedValues.presentCount !== undefined && mappedValues.presentCount !== '') {
          const pres = Number(mappedValues.presentCount);
          if (isNaN(pres) || pres < 0) {
            issues.push({
              code: ImportIssueCode.INVALID_VALUE,
              severity: IssueSeverity.ERROR,
              message: `Present count must be a non-negative number, got '${mappedValues.presentCount}'`,
              column: mappingByTarget.get('presentCount'),
              rowNumber: rawRow.rowNumber,
            });
          } else {
            semanticValues.presentCount = pres;
          }
        }

        if (mappedValues.absentCount !== undefined && mappedValues.absentCount !== '') {
          const abs = Number(mappedValues.absentCount);
          if (isNaN(abs) || abs < 0) {
            issues.push({
              code: ImportIssueCode.INVALID_VALUE,
              severity: IssueSeverity.ERROR,
              message: `Absent count must be a non-negative number, got '${mappedValues.absentCount}'`,
              column: mappingByTarget.get('absentCount'),
              rowNumber: rawRow.rowNumber,
            });
          } else {
            semanticValues.absentCount = abs;
          }
        }

        if (
          semanticValues.classesHeld !== undefined &&
          semanticValues.classesHeld !== null &&
          semanticValues.presentCount !== undefined &&
          semanticValues.presentCount !== null
        ) {
          if (semanticValues.presentCount > semanticValues.classesHeld) {
            issues.push({
              code: ImportIssueCode.INVALID_VALUE,
              severity: IssueSeverity.ERROR,
              message: `Present count (${semanticValues.presentCount}) cannot exceed total classes held (${semanticValues.classesHeld})`,
              column: mappingByTarget.get('presentCount'),
              rowNumber: rawRow.rowNumber,
            });
          }
        }

        if (mappedValues.date) {
          semanticValues.date = String(mappedValues.date).trim();
        }
        if (mappedValues.timeSlot) {
          semanticValues.timeSlot = String(mappedValues.timeSlot).trim();
        }
        if (mappedValues.periodLabel) {
          semanticValues.periodLabel = String(mappedValues.periodLabel).trim();
        }
      }

      // Status
      const rawStatus = mappedValues.status || mappedValues.attendanceStatus;
      if (rawStatus !== undefined && rawStatus !== '') {
        const upperStatus = String(rawStatus).trim().toUpperCase();
        if (['P', 'PRESENT', '1'].includes(upperStatus)) {
          semanticValues.status = 'PRESENT';
        } else if (['A', 'ABSENT', 'ABS', 'AB'].includes(upperStatus)) {
          semanticValues.status = 'ABSENT';
          if (dataType === ImportDataType.ASSESSMENT) {
            semanticValues.marks = null;
          }
        } else if (['EXEMPT', 'EXEMPTED'].includes(upperStatus)) {
          semanticValues.status = 'EXEMPTED';
          if (dataType === ImportDataType.ASSESSMENT) {
            semanticValues.marks = null;
          }
        } else if (['NOT_APPEARED', 'NA', 'NOT APPEARED'].includes(upperStatus)) {
          semanticValues.status = 'NOT_APPEARED';
          if (dataType === ImportDataType.ASSESSMENT) {
            semanticValues.marks = null;
          }
        } else if (['L', 'LATE'].includes(upperStatus)) {
          semanticValues.status = 'LATE';
        } else {
          semanticValues.status = upperStatus;
        }
      }

      // Remarks
      if (mappedValues.remarks) {
        semanticValues.remarks = String(mappedValues.remarks).trim();
      }

      // 3. Determine initial row status
      let rowStatus: RowValidationStatus = RowValidationStatus.VALID;
      if (issues.some((i) => i.severity === IssueSeverity.ERROR)) {
        rowStatus = RowValidationStatus.INVALID;
      } else if (studentResolution.status === RowValidationStatus.UNRESOLVED) {
        rowStatus = RowValidationStatus.UNRESOLVED;
      } else if (issues.some((i) => i.severity === IssueSeverity.WARNING)) {
        rowStatus = RowValidationStatus.WARNING;
      }

      normalizedRows.push({
        rowNumber: rawRow.rowNumber,
        rawValues: rawRow.values,
        mappedValues,
        studentResolution,
        semanticValues,
        issues,
        status: rowStatus,
      });

      // Track occurrences for duplicate/conflict detection
      const studentKey = studentResolution.studentEnrollmentId || studentResolution.studentPin;
      if (studentKey) {
        if (!studentOccurrences.has(studentKey)) {
          studentOccurrences.set(studentKey, []);
        }
        studentOccurrences.get(studentKey)!.push({
          rowNumber: rawRow.rowNumber,
          marks: semanticValues.marks,
          status: semanticValues.status,
        });
      }
    }

    // 4. Duplicate & Cross-Row Conflict Detection Pass
    let conflictCount = 0;
    for (const [studentKey, occurrences] of studentOccurrences.entries()) {
      if (occurrences.length > 1) {
        // Check if marks or statuses conflict across occurrences
        const distinctMarks = new Set(occurrences.map((o) => o.marks).filter((m) => m !== undefined));
        const distinctStatuses = new Set(occurrences.map((o) => o.status).filter((s) => s !== undefined));

        const hasConflict = distinctMarks.size > 1 || distinctStatuses.size > 1;

        for (const occ of occurrences) {
          const row = normalizedRows.find((r) => r.rowNumber === occ.rowNumber);
          if (row) {
            if (hasConflict) {
              conflictCount++;
              row.status = RowValidationStatus.DUPLICATE_CONFLICT;
              row.issues.push({
                code: ImportIssueCode.CONFLICTING_ROW,
                severity: IssueSeverity.ERROR,
                message: `Conflicting data found for student '${studentKey}' across multiple rows (${occurrences.map((o) => o.rowNumber).join(', ')})`,
                rowNumber: occ.rowNumber,
              });
            } else {
              if (row.status !== RowValidationStatus.INVALID) {
                row.status = RowValidationStatus.WARNING;
              }
              row.issues.push({
                code: ImportIssueCode.DUPLICATE_ROW,
                severity: IssueSeverity.WARNING,
                message: `Duplicate row for student '${studentKey}' found on rows (${occurrences.map((o) => o.rowNumber).join(', ')})`,
                rowNumber: occ.rowNumber,
              });
            }
          }
        }
      }
    }

    // 5. Aggregate Summary Counts
    let validCount = 0;
    let warningCount = 0;
    let unresolvedCount = 0;
    let errorCount = 0;

    let detailedCount = 0;
    let summaryCount = 0;
    let percentageOnlyCount = 0;

    for (const r of normalizedRows) {
      if (r.status === RowValidationStatus.VALID) validCount++;
      else if (r.status === RowValidationStatus.WARNING) warningCount++;
      else if (r.status === RowValidationStatus.UNRESOLVED) unresolvedCount++;
      else if (r.status === RowValidationStatus.INVALID || r.status === RowValidationStatus.DUPLICATE_CONFLICT)
        errorCount++;

      if (dataType === ImportDataType.ATTENDANCE) {
        if (r.semanticValues.date || (r.mappedValues.date && String(r.mappedValues.date).trim() !== '')) {
          detailedCount++;
        } else if (
          (r.semanticValues.classesHeld !== undefined && r.semanticValues.classesHeld !== null) ||
          (r.mappedValues.classesHeld !== undefined && String(r.mappedValues.classesHeld).trim() !== '')
        ) {
          summaryCount++;
        } else if (
          (r.semanticValues.attendancePercentage !== undefined && r.semanticValues.attendancePercentage !== null) ||
          (r.mappedValues.attendancePercentage !== undefined && String(r.mappedValues.attendancePercentage).trim() !== '')
        ) {
          percentageOnlyCount++;
        }
      }
    }

    let detectedPrecision: IValidationSummary['detectedPrecision'] = 'NOT_APPLICABLE';
    if (dataType === ImportDataType.ATTENDANCE) {
      if (detailedCount > 0 && summaryCount === 0 && percentageOnlyCount === 0) {
        detectedPrecision = 'DETAILED_SESSION';
      } else if (summaryCount > 0 && detailedCount === 0 && percentageOnlyCount === 0) {
        detectedPrecision = 'PERIOD_SUMMARY';
      } else if (percentageOnlyCount > 0 && detailedCount === 0 && summaryCount === 0) {
        detectedPrecision = 'PERCENTAGE_ONLY';
      } else if (detailedCount + summaryCount + percentageOnlyCount > 0) {
        detectedPrecision = 'MIXED';
      }
    }

    return {
      normalizedRows,
      summary: {
        rowCount: normalizedRows.length,
        validCount,
        warningCount,
        unresolvedCount,
        errorCount,
        conflictCount,
        detectedPrecision,
        detailedCount: dataType === ImportDataType.ATTENDANCE ? detailedCount : undefined,
        summaryCount: dataType === ImportDataType.ATTENDANCE ? summaryCount : undefined,
        percentageOnlyCount: dataType === ImportDataType.ATTENDANCE ? percentageOnlyCount : undefined,
      },
    };
  }
}
