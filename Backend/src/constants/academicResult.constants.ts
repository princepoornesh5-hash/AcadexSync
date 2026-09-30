export enum ResultLifecycleStatus {
  DRAFT = 'DRAFT',
  CALCULATED = 'CALCULATED',
  UNDER_REVIEW = 'UNDER_REVIEW',
  FINALIZED = 'FINALIZED',
  PUBLISHED = 'PUBLISHED',
  REOPENED = 'REOPENED',
  ARCHIVED = 'ARCHIVED',
}

export enum SubjectResultStatus {
  PASS = 'PASS',
  FAIL = 'FAIL',
  INCOMPLETE = 'INCOMPLETE',
  WITHHELD = 'WITHHELD',
  EXEMPTED = 'EXEMPTED',
}

export enum OverallResultStatus {
  PASS = 'PASS',
  FAIL = 'FAIL',
  INCOMPLETE = 'INCOMPLETE',
  WITHHELD = 'WITHHELD',
  EXEMPTED = 'EXEMPTED',
}

export const VALID_RESULT_TRANSITIONS: Record<ResultLifecycleStatus, ResultLifecycleStatus[]> = {
  [ResultLifecycleStatus.DRAFT]: [ResultLifecycleStatus.CALCULATED, ResultLifecycleStatus.ARCHIVED],
  [ResultLifecycleStatus.CALCULATED]: [
    ResultLifecycleStatus.UNDER_REVIEW,
    ResultLifecycleStatus.FINALIZED,
    ResultLifecycleStatus.CALCULATED, // Re-calculation
    ResultLifecycleStatus.ARCHIVED,
  ],
  [ResultLifecycleStatus.UNDER_REVIEW]: [
    ResultLifecycleStatus.FINALIZED,
    ResultLifecycleStatus.CALCULATED, // Rejected back to recalculation
    ResultLifecycleStatus.ARCHIVED,
  ],
  [ResultLifecycleStatus.FINALIZED]: [
    ResultLifecycleStatus.PUBLISHED,
    ResultLifecycleStatus.REOPENED, // Controlled reopening before/after publication
    ResultLifecycleStatus.ARCHIVED,
  ],
  [ResultLifecycleStatus.PUBLISHED]: [
    ResultLifecycleStatus.REOPENED, // Controlled administrative reopening
    ResultLifecycleStatus.ARCHIVED,
  ],
  [ResultLifecycleStatus.REOPENED]: [
    ResultLifecycleStatus.CALCULATED,
    ResultLifecycleStatus.UNDER_REVIEW,
    ResultLifecycleStatus.ARCHIVED,
  ],
  [ResultLifecycleStatus.ARCHIVED]: [],
};

export function isValidResultTransition(
  current: ResultLifecycleStatus,
  target: ResultLifecycleStatus
): boolean {
  if (current === target) return true;
  const allowed = VALID_RESULT_TRANSITIONS[current] || [];
  return allowed.includes(target);
}

export interface IGradeDefinition {
  grade: string;
  minPercentage: number;
  maxPercentage: number;
  gradePoint: number;
  isPassing: boolean;
  description?: string;
}

export interface IPassCriteriaConfig {
  minSubjectPercentage: number;
  minAttendancePercentage?: number | null;
  minPracticalCompletionRate?: number | null;
  requireAllComponentsPassed?: boolean;
}

export interface IGPAPolicyConfig {
  enabled: boolean;
  scale: number;
  formula: 'CREDIT_WEIGHTED' | 'SIMPLE_AVERAGE';
  passingGradePointMin?: number;
}

export interface ICGPAPolicyConfig {
  enabled: boolean;
  calculationPeriod: 'CUMULATIVE_ACROSS_SEMESTERS';
}

/**
 * Standard UGC / AICTE 10-point scale preset
 */
export const PRESET_UGC_10_POINT_SCALE: IGradeDefinition[] = [
  { grade: 'O', minPercentage: 90, maxPercentage: 100, gradePoint: 10.0, isPassing: true, description: 'Outstanding' },
  { grade: 'A+', minPercentage: 80, maxPercentage: 89.99, gradePoint: 9.0, isPassing: true, description: 'Excellent' },
  { grade: 'A', minPercentage: 70, maxPercentage: 79.99, gradePoint: 8.0, isPassing: true, description: 'Very Good' },
  { grade: 'B+', minPercentage: 60, maxPercentage: 69.99, gradePoint: 7.0, isPassing: true, description: 'Good' },
  { grade: 'B', minPercentage: 50, maxPercentage: 59.99, gradePoint: 6.0, isPassing: true, description: 'Above Average' },
  { grade: 'C', minPercentage: 45, maxPercentage: 49.99, gradePoint: 5.0, isPassing: true, description: 'Average' },
  { grade: 'P', minPercentage: 40, maxPercentage: 44.99, gradePoint: 4.0, isPassing: true, description: 'Pass' },
  { grade: 'F', minPercentage: 0, maxPercentage: 39.99, gradePoint: 0.0, isPassing: false, description: 'Fail' },
];

/**
 * 4-Point GPA Scale preset
 */
export const PRESET_4_POINT_SCALE: IGradeDefinition[] = [
  { grade: 'A', minPercentage: 85, maxPercentage: 100, gradePoint: 4.0, isPassing: true, description: 'Excellent' },
  { grade: 'B', minPercentage: 70, maxPercentage: 84.99, gradePoint: 3.0, isPassing: true, description: 'Good' },
  { grade: 'C', minPercentage: 55, maxPercentage: 69.99, gradePoint: 2.0, isPassing: true, description: 'Satisfactory' },
  { grade: 'D', minPercentage: 40, maxPercentage: 54.99, gradePoint: 1.0, isPassing: true, description: 'Minimum Pass' },
  { grade: 'F', minPercentage: 0, maxPercentage: 39.99, gradePoint: 0.0, isPassing: false, description: 'Fail' },
];
