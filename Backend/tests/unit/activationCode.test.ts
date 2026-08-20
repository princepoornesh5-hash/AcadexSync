import {
  generateActivationCode,
  normalizeActivationCode,
  hashActivationCode,
  verifyActivationCode,
} from '../../src/utils/activationCode';

describe('Activation Code Utility Unit Tests', () => {
  it('should generate cryptographically random formatted activation codes (4-4-4)', () => {
    const code = generateActivationCode();
    expect(code).toMatch(/^[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{4}-[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{4}-[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{4}$/);
    expect(code.length).toBe(14); // 12 chars + 2 hyphens
  });

  it('should normalize activation codes correctly (strip whitespace, hyphens, uppercase)', () => {
    expect(normalizeActivationCode('acx7-kp92-m4qt')).toBe('ACX7KP92M4QT');
    expect(normalizeActivationCode('  ACX7 KP92 M4QT  ')).toBe('ACX7KP92M4QT');
  });

  it('should generate a 64-character hex HMAC-SHA256 hash', () => {
    const code = 'ACX7-KP92-M4QT';
    const hash = hashActivationCode(code);
    expect(hash).not.toBe(code);
    expect(hash).toHaveLength(64);
  });

  it('should verify matching activation code with constant-time equality', () => {
    const code = 'ACX7-KP92-M4QT';
    const hash = hashActivationCode(code);

    // Matching raw code (with or without hyphens / case)
    expect(verifyActivationCode(code, hash)).toBe(true);
    expect(verifyActivationCode('acx7-kp92-m4qt', hash)).toBe(true);
    expect(verifyActivationCode('ACX7KP92M4QT', hash)).toBe(true);

    // Mismatched code
    expect(verifyActivationCode('DIFF-CODE-1234', hash)).toBe(false);
    expect(verifyActivationCode('', hash)).toBe(false);
  });
});
