/**
 * Session Security & Identifier Validation Utilities
 * Validates canonical UUID v4 session identifiers and session lifecycle rules.
 */

const UUID_V4_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

/**
 * Validates that a session identifier conforms to canonical UUID format.
 * Rejects MongoDB ObjectIds, empty strings, and malformed strings.
 */
export function isValidSessionId(sessionId: unknown): boolean {
  if (typeof sessionId !== 'string') return false;
  return UUID_V4_REGEX.test(sessionId.trim());
}
