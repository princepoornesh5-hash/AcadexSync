export enum SubjectDeliveryType {
  THEORY = 'THEORY',
  PRACTICAL = 'PRACTICAL',
  THEORY_PRACTICAL = 'THEORY_PRACTICAL',
}

export enum PracticalSessionStatus {
  PLANNED = 'PLANNED',
  OPEN = 'OPEN',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

export enum PracticalParticipationStatus {
  NOT_STARTED = 'NOT_STARTED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  ABSENT = 'ABSENT',
  EXCUSED = 'EXCUSED',
}

export const PRACTICAL_CAPABLE_TYPES = new Set([
  'PRACTICAL',
  'LAB',
  'THEORY_PRACTICAL',
  'THEORY+PRACTICAL',
  'THEORY_AND_PRACTICAL',
  'BOTH',
]);

/**
 * Normalizes and checks if a subject type string represents a practical-capable subject.
 */
export function isSubjectPracticalCapable(subjectType?: string | null): boolean {
  if (!subjectType) return false;
  const normalized = subjectType.trim().toUpperCase().replace(/[\s\-_+]+/g, '_');
  if (PRACTICAL_CAPABLE_TYPES.has(normalized)) return true;
  // Also check if normalized string contains 'PRACTICAL' or 'LAB'
  return normalized.includes('PRACTICAL') || normalized.includes('LAB');
}
