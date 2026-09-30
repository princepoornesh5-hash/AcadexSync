export enum AcademicProgressionStatus {
  ACTIVE = 'ACTIVE',
  COMPLETED = 'COMPLETED',
  PROMOTED = 'PROMOTED',
  RETAINED = 'RETAINED',
  WITHDRAWN = 'WITHDRAWN',
  DISCONTINUED = 'DISCONTINUED',
}

export enum SubjectAcademicStatus {
  ENROLLED = 'ENROLLED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  WITHDRAWN = 'WITHDRAWN',
  EXEMPTED = 'EXEMPTED',
}

export const VALID_PROGRESSION_TRANSITIONS: Record<AcademicProgressionStatus, AcademicProgressionStatus[]> = {
  [AcademicProgressionStatus.ACTIVE]: [
    AcademicProgressionStatus.COMPLETED,
    AcademicProgressionStatus.PROMOTED,
    AcademicProgressionStatus.RETAINED,
    AcademicProgressionStatus.WITHDRAWN,
    AcademicProgressionStatus.DISCONTINUED,
  ],
  [AcademicProgressionStatus.COMPLETED]: [
    AcademicProgressionStatus.PROMOTED,
    AcademicProgressionStatus.RETAINED,
  ],
  [AcademicProgressionStatus.PROMOTED]: [], // Terminal for that historical period
  [AcademicProgressionStatus.RETAINED]: [
    AcademicProgressionStatus.ACTIVE, // Retained students can be active in remediation
  ],
  [AcademicProgressionStatus.WITHDRAWN]: [],
  [AcademicProgressionStatus.DISCONTINUED]: [],
};

export function isValidProgressionTransition(
  current: AcademicProgressionStatus,
  target: AcademicProgressionStatus
): boolean {
  if (current === target) return true;
  const allowed = VALID_PROGRESSION_TRANSITIONS[current] || [];
  return allowed.includes(target);
}
