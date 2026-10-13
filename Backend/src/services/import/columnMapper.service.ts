import {
  ColumnMappingStatus,
  MappingConfidence,
  ImportDataType,
} from '../../constants/import.constants';
import { IColumnMapping } from '../../models/importBatch.model';

export interface ITargetFieldDefinition {
  field: string;
  label: string;
  required: boolean;
  aliases: string[];
}

export class ColumnMapperService {
  private static readonly TARGET_FIELDS: Record<ImportDataType, ITargetFieldDefinition[]> = {
    [ImportDataType.ASSESSMENT]: [
      {
        field: 'studentPin',
        label: 'Student PIN / Roll / Admission No',
        required: true,
        aliases: [
          'pin',
          'pinno',
          'pinnumber',
          'studentpin',
          'roll',
          'rollno',
          'rollnumber',
          'admissionno',
          'admissionnumber',
          'admno',
          'regno',
          'registrationno',
          'regnumber',
          'id',
          'studentid',
        ],
      },
      {
        field: 'studentName',
        label: 'Student Name',
        required: false,
        aliases: ['name', 'studentname', 'fullname', 'candidatename'],
      },
      {
        field: 'marks',
        label: 'Obtained Marks / Score',
        required: true,
        aliases: [
          'marks',
          'mark',
          'obtainedmarks',
          'score',
          'ut1',
          'ut2',
          'ut',
          'internal',
          'internal1',
          'internal2',
          'midterm',
          'mid',
          'exammarks',
          'markssecured',
          'total',
        ],
      },
      {
        field: 'maximumMarks',
        label: 'Maximum Marks',
        required: false,
        aliases: ['maxmarks', 'maximummarks', 'totalmarks', 'outof', 'max'],
      },
      {
        field: 'status',
        label: 'Attendance Status (Present/Absent)',
        required: false,
        aliases: ['status', 'attendancestatus', 'presentabsent', 'presence'],
      },
      {
        field: 'assessmentTitle',
        label: 'Assessment Title / Name',
        required: false,
        aliases: ['assessment', 'test', 'exam', 'assessmentname', 'examname', 'testname', 'type', 'category', 'title', 'paper'],
      },
      {
        field: 'subject',
        label: 'Subject Name / Code',
        required: false,
        aliases: ['subject', 'subjectname', 'subjectcode', 'subcode', 'course'],
      },
      {
        field: 'remarks',
        label: 'Remarks / Comments',
        required: false,
        aliases: ['remarks', 'remark', 'comments', 'notes'],
      },
    ],
    [ImportDataType.ATTENDANCE]: [
      {
        field: 'studentPin',
        label: 'Student PIN / Roll / Admission No',
        required: true,
        aliases: [
          'pin',
          'pinno',
          'pinnumber',
          'studentpin',
          'roll',
          'rollno',
          'rollnumber',
          'admissionno',
          'admissionnumber',
          'admno',
          'regno',
          'registrationno',
          'id',
        ],
      },
      {
        field: 'studentName',
        label: 'Student Name',
        required: false,
        aliases: ['name', 'studentname', 'fullname'],
      },
      {
        field: 'date',
        label: 'Session Date',
        required: false,
        aliases: ['date', 'sessiondate', 'attendancedate', 'day', 'classdate'],
      },
      {
        field: 'timeSlot',
        label: 'Time Slot / Period Number',
        required: false,
        aliases: ['slot', 'timeslot', 'slotnumber', 'periodnumber', 'session', 'hour'],
      },
      {
        field: 'attendanceStatus',
        label: 'Attendance Status (Present/Absent)',
        required: false,
        aliases: ['attendance', 'attendancestatus', 'present', 'p_a', 'status', 'p/a'],
      },
      {
        field: 'classesHeld',
        label: 'Classes Held / Total Conducted',
        required: false,
        aliases: ['classesheld', 'totalclasses', 'totalconducted', 'conducted', 'held', 'workingdays', 'totaldays', 'total'],
      },
      {
        field: 'presentCount',
        label: 'Classes Present / Attended',
        required: false,
        aliases: ['presentcount', 'classespresent', 'attended', 'attendedclasses', 'dayspresent', 'totalpresent', 'presentdays'],
      },
      {
        field: 'absentCount',
        label: 'Classes Absent',
        required: false,
        aliases: ['absentcount', 'classesabsent', 'daysabsent', 'totalabsent'],
      },
      {
        field: 'attendancePercentage',
        label: 'Attendance Percentage',
        required: false,
        aliases: ['percentage', 'attendancepercentage', 'attpercentage', 'percent', 'att_pct', 'pct'],
      },
      {
        field: 'periodLabel',
        label: 'Period / Month / Term',
        required: false,
        aliases: ['month', 'period', 'periodstart', 'duration', 'term', 'monthname'],
      },
      {
        field: 'subject',
        label: 'Subject Name / Code',
        required: false,
        aliases: ['subject', 'subjectname', 'subjectcode', 'subcode'],
      },
      {
        field: 'remarks',
        label: 'Remarks',
        required: false,
        aliases: ['remarks', 'comments'],
      },
    ],
    [ImportDataType.STUDENT_ROSTER]: [
      {
        field: 'studentPin',
        label: 'Student PIN / Roll No',
        required: true,
        aliases: ['pin', 'rollno', 'admissionno', 'id'],
      },
      {
        field: 'studentName',
        label: 'Student Name',
        required: true,
        aliases: ['name', 'studentname', 'fullname'],
      },
    ],
    [ImportDataType.ASSIGNMENT]: [
      {
        field: 'studentPin',
        label: 'Student PIN / Roll No',
        required: true,
        aliases: ['pin', 'rollno', 'admissionno', 'id'],
      },
      {
        field: 'studentName',
        label: 'Student Name',
        required: false,
        aliases: ['name', 'studentname', 'fullname'],
      },
      {
        field: 'marks',
        label: 'Marks / Score',
        required: true,
        aliases: ['marks', 'score', 'assignmentmarks'],
      },
    ],
    [ImportDataType.ACADEMIC_RESULT]: [
      {
        field: 'studentPin',
        label: 'Student PIN / Roll No',
        required: true,
        aliases: ['pin', 'rollno', 'admissionno', 'id'],
      },
      {
        field: 'studentName',
        label: 'Student Name',
        required: false,
        aliases: ['name', 'studentname', 'fullname'],
      },
      {
        field: 'marks',
        label: 'Total Marks / Grade',
        required: true,
        aliases: ['marks', 'grade', 'total', 'sgpa', 'cgpa'],
      },
    ],
    [ImportDataType.OTHER]: [
      {
        field: 'studentPin',
        label: 'Student Identifier',
        required: true,
        aliases: ['pin', 'rollno', 'admissionno', 'id'],
      },
      {
        field: 'studentName',
        label: 'Student Name',
        required: false,
        aliases: ['name', 'studentname', 'fullname'],
      },
    ],
  };

  /**
   * Normalizes header text for deterministic matching.
   */
  static normalizeHeader(text: string): string {
    return (text || '')
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9]/g, '');
  }

  /**
   * Generates auto-detected column mappings based on headers and target data type.
   */
  static generateMappings(headers: string[], dataType: ImportDataType): IColumnMapping[] {
    const definitions = this.TARGET_FIELDS[dataType] || this.TARGET_FIELDS[ImportDataType.OTHER];
    const mappings: IColumnMapping[] = [];

    const usedTargetFields = new Set<string>();

    for (const rawHeader of headers) {
      const normalized = this.normalizeHeader(rawHeader);

      let bestMatch: ITargetFieldDefinition | null = null;
      let confidence: MappingConfidence = MappingConfidence.LOW;
      let isExact = false;

      // 1. Search aliases
      for (const def of definitions) {
        if (def.aliases.some((alias) => normalized === alias)) {
          bestMatch = def;
          confidence = MappingConfidence.HIGH;
          isExact = true;
          break;
        } else if (def.aliases.some((alias) => normalized.includes(alias) || alias.includes(normalized))) {
          if (!bestMatch) {
            bestMatch = def;
            confidence = MappingConfidence.MEDIUM;
          }
        }
      }

      if (bestMatch) {
        if (usedTargetFields.has(bestMatch.field)) {
          // Multiple source headers match the same target field -> Ambiguous
          mappings.push({
            sourceColumn: rawHeader,
            targetField: bestMatch.field,
            confidence: MappingConfidence.LOW,
            status: ColumnMappingStatus.AMBIGUOUS,
          });
        } else {
          usedTargetFields.add(bestMatch.field);
          mappings.push({
            sourceColumn: rawHeader,
            targetField: bestMatch.field,
            confidence,
            status: isExact ? ColumnMappingStatus.AUTO_MATCHED : ColumnMappingStatus.UNMAPPED,
          });
        }
      } else {
        mappings.push({
          sourceColumn: rawHeader,
          targetField: 'UNMAPPED',
          confidence: MappingConfidence.LOW,
          status: ColumnMappingStatus.UNMAPPED,
        });
      }
    }

    return mappings;
  }

  /**
   * Applies user-supplied column mapping overrides to existing mappings.
   */
  static applyUserMappings(
    currentMappings: IColumnMapping[],
    userOverrides: Array<{ sourceColumn: string; targetField: string }>
  ): IColumnMapping[] {
    const overrideMap = new Map(userOverrides.map((o) => [o.sourceColumn, o.targetField]));

    return currentMappings.map((m) => {
      if (overrideMap.has(m.sourceColumn)) {
        const newTarget = overrideMap.get(m.sourceColumn)!;
        if (newTarget === 'UNMAPPED' || !newTarget) {
          return {
            sourceColumn: m.sourceColumn,
            targetField: 'UNMAPPED',
            confidence: MappingConfidence.LOW,
            status: ColumnMappingStatus.UNMAPPED,
          };
        }
        return {
          sourceColumn: m.sourceColumn,
          targetField: newTarget,
          confidence: MappingConfidence.HIGH,
          status: ColumnMappingStatus.USER_CONFIRMED,
        };
      }
      return m;
    });
  }

  /**
   * Validates if the required column mappings are satisfied.
   */
  static validateMappingCompleteness(
    mappings: IColumnMapping[],
    dataType: ImportDataType
  ): { isValid: boolean; missingFields: string[] } {
    const definitions = this.TARGET_FIELDS[dataType] || this.TARGET_FIELDS[ImportDataType.OTHER];
    const mappedTargets = new Set(
      mappings
        .filter((m) => m.status === ColumnMappingStatus.AUTO_MATCHED || m.status === ColumnMappingStatus.USER_CONFIRMED)
        .map((m) => m.targetField)
    );

    const requiredFields = definitions.filter((d) => d.required).map((d) => d.field);
    const missing = requiredFields.filter((rf) => !mappedTargets.has(rf));

    return {
      isValid: missing.length === 0,
      missingFields: missing,
    };
  }
}
