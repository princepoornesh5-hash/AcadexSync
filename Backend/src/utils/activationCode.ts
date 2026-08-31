import crypto from 'crypto';
import { env } from '../config/env';

// Human-friendly alphabet excluding confusing characters: 0, O, 1, I, L
const CHARSET = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

/**
 * Generates a cryptographically random, human-shareable activation code.
 * Format: 3 groups of 4 characters separated by hyphens (e.g. ACX7-KP92-M4QT)
 */
export function generateActivationCode(): string {
  const bytes = crypto.randomBytes(12);
  let code = '';
  for (let i = 0; i < 12; i++) {
    code += CHARSET[bytes[i] % CHARSET.length];
  }
  // Group into 4-4-4
  return `${code.slice(0, 4)}-${code.slice(4, 8)}-${code.slice(8, 12)}`;
}

/**
 * Standardizes activation code by trimming, removing hyphens/spaces, and converting to uppercase.
 */
export function normalizeActivationCode(rawCode: string): string {
  if (!rawCode || typeof rawCode !== 'string') return '';
  return rawCode.replace(/[\s\-\u2010-\u2015\u2212\u00A0\u200B-\u200D\uFEFF]/g, '').toUpperCase();
}

/**
 * Hashes an activation code using HMAC-SHA256 with the activation code secret.
 */
export function hashActivationCode(rawCode: string): string {
  const normalized = normalizeActivationCode(rawCode);
  return crypto
    .createHmac('sha256', env.ACTIVATION_CODE_SECRET)
    .update(normalized)
    .digest('hex');
}

/**
 * Constant-time comparison between raw code and expected hash.
 */
export function verifyActivationCode(rawCode: string, expectedHash: string): boolean {
  if (!rawCode || !expectedHash) return false;
  const hash = hashActivationCode(rawCode);
  const bufA = Buffer.from(hash, 'hex');
  const bufB = Buffer.from(expectedHash, 'hex');
  if (bufA.length !== bufB.length) return false;
  return crypto.timingSafeEqual(bufA, bufB);
}
