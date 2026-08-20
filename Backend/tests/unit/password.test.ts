import { PasswordService } from '../../src/services/password.service';

describe('Password Policy & Hashing Service Unit Tests', () => {
  it('16. Password hash is NOT plaintext and starts with bcrypt identifier', async () => {
    const raw = 'SecurePass123';
    const hash = await PasswordService.hashPassword(raw);

    expect(hash).not.toBe(raw);
    expect(hash.length).toBeGreaterThan(30);
    expect(hash.startsWith('$2a$') || hash.startsWith('$2b$')).toBe(true);
  });

  it('17. Correct password verifies successfully', async () => {
    const raw = 'MyStrongPassword456';
    const hash = await PasswordService.hashPassword(raw);

    const isMatch = await PasswordService.verifyPassword(raw, hash);
    expect(isMatch).toBe(true);
  });

  it('18. Incorrect password fails verification', async () => {
    const raw = 'MyStrongPassword456';
    const hash = await PasswordService.hashPassword(raw);

    const isMatch = await PasswordService.verifyPassword('WrongPassword123', hash);
    expect(isMatch).toBe(false);
  });

  it('19. Password policy rejects invalid passwords (too short, missing numbers, missing letters)', async () => {
    // Too short (< 8 chars)
    expect(PasswordService.validatePassword('Short1').valid).toBe(false);
    expect(PasswordService.validatePassword('Short1').message).toContain('at least 8 characters');

    // Missing numbers
    expect(PasswordService.validatePassword('OnlyLettersHere').valid).toBe(false);
    expect(PasswordService.validatePassword('OnlyLettersHere').message).toContain('at least one letter and one number');

    // Missing letters
    expect(PasswordService.validatePassword('1234567890').valid).toBe(false);
    expect(PasswordService.validatePassword('1234567890').message).toContain('at least one letter and one number');

    // Empty / null
    expect(PasswordService.validatePassword('').valid).toBe(false);

    // Valid passwords
    expect(PasswordService.validatePassword('ValidPass123').valid).toBe(true);
    expect(PasswordService.validatePassword('AlphaNumeric999!').valid).toBe(true);
  });
});
