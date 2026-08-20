import { ApiError } from './apiError';

const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
const PHONE_REGEX = /^\+?[0-9]{7,15}$/;

/**
 * Normalizes email address by trimming whitespace and converting to lowercase.
 */
export function normalizeEmail(email: string): string {
  if (!email || typeof email !== 'string') {
    throw ApiError.badRequest('Invalid email address format');
  }
  const trimmed = email.trim().toLowerCase();
  if (!EMAIL_REGEX.test(trimmed)) {
    throw ApiError.badRequest('Invalid email address format');
  }
  return trimmed;
}

/**
 * Normalizes phone number by removing spaces, dashes, dots, and parentheses.
 * Preserves leading '+' for international standard notation.
 */
export function normalizePhone(phone: string): string {
  if (!phone || typeof phone !== 'string') {
    throw ApiError.badRequest('Invalid phone number format');
  }
  // Remove formatting characters: spaces, dashes, dots, parentheses
  const cleaned = phone.replace(/[\s\-().]/g, '');
  if (!PHONE_REGEX.test(cleaned)) {
    throw ApiError.badRequest('Invalid phone number format. Must contain 7 to 15 digits.');
  }
  return cleaned;
}

export function isEmail(input: string): boolean {
  if (!input || typeof input !== 'string') return false;
  return EMAIL_REGEX.test(input.trim().toLowerCase());
}

export function isPhone(input: string): boolean {
  if (!input || typeof input !== 'string') return false;
  const cleaned = input.replace(/[\s\-().]/g, '');
  return PHONE_REGEX.test(cleaned);
}

export interface NormalizedIdentifier {
  type: 'email' | 'phone';
  normalized: string;
}

/**
 * Automatically detects whether identifier is an email or phone, and applies
 * centralized normalization.
 */
export function normalizeIdentifier(rawIdentifier: string): NormalizedIdentifier {
  if (!rawIdentifier || typeof rawIdentifier !== 'string' || rawIdentifier.trim() === '') {
    throw ApiError.badRequest('Identifier (email or phone) is required');
  }

  const trimmed = rawIdentifier.trim();

  if (isEmail(trimmed)) {
    return {
      type: 'email',
      normalized: normalizeEmail(trimmed),
    };
  }

  if (isPhone(trimmed)) {
    return {
      type: 'phone',
      normalized: normalizePhone(trimmed),
    };
  }

  throw ApiError.badRequest('Identifier must be a valid email address or phone number');
}
