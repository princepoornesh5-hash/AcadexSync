import { AssessmentStatus, AssessmentType, StudentMarkStatus } from '../models/internalAssessment.model';

export { AssessmentStatus, AssessmentType, StudentMarkStatus };

/**
 * Valid lifecycle transitions for InternalAssessment
 * DRAFT -> OPEN -> CLOSED -> PUBLISHED -> ARCHIVED
 * With administrative unlock: PUBLISHED -> DRAFT
 * And backward-compatible: DRAFT -> REVIEWED -> PUBLISHED
 */
export const VALID_ASSESSMENT_TRANSITIONS: Record<AssessmentStatus, AssessmentStatus[]> = {
  [AssessmentStatus.DRAFT]: [AssessmentStatus.OPEN, AssessmentStatus.REVIEWED, AssessmentStatus.CLOSED],
  [AssessmentStatus.OPEN]: [AssessmentStatus.CLOSED, AssessmentStatus.REVIEWED, AssessmentStatus.DRAFT],
  [AssessmentStatus.REVIEWED]: [AssessmentStatus.CLOSED, AssessmentStatus.PUBLISHED, AssessmentStatus.DRAFT],
  [AssessmentStatus.CLOSED]: [AssessmentStatus.PUBLISHED, AssessmentStatus.OPEN, AssessmentStatus.DRAFT],
  [AssessmentStatus.PUBLISHED]: [AssessmentStatus.ARCHIVED, AssessmentStatus.DRAFT], // DRAFT permitted only via explicit administrative unlock
  [AssessmentStatus.ARCHIVED]: [], // Terminal historical state
};

export function isValidAssessmentTransition(
  current: AssessmentStatus,
  target: AssessmentStatus
): boolean {
  if (current === target) return true;
  const allowed = VALID_ASSESSMENT_TRANSITIONS[current] || [];
  return allowed.includes(target);
}
