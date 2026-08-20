import {
  normalizeEmail,
  normalizePhone,
  normalizeIdentifier,
  isEmail,
  isPhone,
} from '../../src/utils/identifier';

describe('Identifier Normalization Unit Tests', () => {
  it('should normalize valid emails (trim, lowercase)', () => {
    expect(normalizeEmail('  User@Acadex.EDU  ')).toBe('user@acadex.edu');
    expect(normalizeEmail('JOHN.DOE+TAG@example.com')).toBe('john.doe+tag@example.com');
  });

  it('should reject invalid emails', () => {
    expect(() => normalizeEmail('invalid-email-address')).toThrow();
    expect(() => normalizeEmail('@missinguser.com')).toThrow();
  });

  it('should normalize valid phones (strip formatting, preserve +)', () => {
    expect(normalizePhone('+1 (555) 123-4567')).toBe('+15551234567');
    expect(normalizePhone('9876543210')).toBe('9876543210');
    expect(normalizePhone('+91-98765-43210')).toBe('+919876543210');
  });

  it('should reject invalid phone numbers', () => {
    expect(() => normalizePhone('123')).toThrow(); // too short (< 7 digits)
    expect(() => normalizePhone('abcdefghij')).toThrow();
  });

  it('should automatically detect identifier type and normalize accurately', () => {
    const emailResult = normalizeIdentifier('  Student@Institute.org  ');
    expect(emailResult.type).toBe('email');
    expect(emailResult.normalized).toBe('student@institute.org');

    const phoneResult = normalizeIdentifier(' +1 (555) 987-6543 ');
    expect(phoneResult.type).toBe('phone');
    expect(phoneResult.normalized).toBe('+15559876543');
  });

  it('isEmail and isPhone helpers should identify valid formats accurately', () => {
    expect(isEmail('alice@college.edu')).toBe(true);
    expect(isEmail('9876543210')).toBe(false);
    expect(isPhone('+15551234567')).toBe(true);
    expect(isPhone('not-a-phone')).toBe(false);
  });
});
