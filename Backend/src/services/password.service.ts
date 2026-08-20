import bcrypt from 'bcryptjs';
import { env } from '../config/env';
import { ApiError } from '../utils/apiError';

export interface PasswordValidationResult {
  valid: boolean;
  message?: string;
}

export class PasswordService {
  /**
   * Centralized Password Policy:
   * - Minimum length: 8 characters
   * - Maximum length: 128 characters
   * - Must contain at least one letter (a-z, A-Z)
   * - Must contain at least one digit (0-9)
   */
  static validatePassword(password: string): PasswordValidationResult {
    if (!password || typeof password !== 'string') {
      return { valid: false, message: 'Password is required' };
    }

    if (password.length < 8) {
      return {
        valid: false,
        message: 'Password must be at least 8 characters long',
      };
    }

    if (password.length > 128) {
      return {
        valid: false,
        message: 'Password must not exceed 128 characters',
      };
    }

    const hasLetter = /[a-zA-Z]/.test(password);
    const hasDigit = /[0-9]/.test(password);

    if (!hasLetter || !hasDigit) {
      return {
        valid: false,
        message: 'Password must contain at least one letter and one number',
      };
    }

    return { valid: true };
  }

  /**
   * Hashes a plaintext password using bcrypt with standard salt rounds.
   */
  static async hashPassword(password: string): Promise<string> {
    const validation = this.validatePassword(password);
    if (!validation.valid) {
      throw ApiError.badRequest(validation.message || 'Invalid password format');
    }

    const salt = await bcrypt.genSalt(env.BCRYPT_SALT_ROUNDS);
    return bcrypt.hash(password, salt);
  }

  /**
   * Securely verifies a plaintext password against its bcrypt hash.
   */
  static async verifyPassword(password: string, hash: string | null | undefined): Promise<boolean> {
    if (!password || !hash) {
      return false;
    }
    try {
      return await bcrypt.compare(password, hash);
    } catch {
      return false;
    }
  }
}
