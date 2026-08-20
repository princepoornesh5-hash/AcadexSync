import {
  AppRole,
  ALL_ROLES,
  isValidRole,
  normalizeRole,
  ROLE_HIERARCHY,
} from '../../src/constants/roles';

describe('Role Model & RBAC Hierarchy', () => {
  it('should support all 5 required ACADEX roles', () => {
    expect(ALL_ROLES).toContain(AppRole.SUPER_ADMIN);
    expect(ALL_ROLES).toContain(AppRole.COLLEGE_ADMIN);
    expect(ALL_ROLES).toContain(AppRole.HOD);
    expect(ALL_ROLES).toContain(AppRole.FACULTY);
    expect(ALL_ROLES).toContain(AppRole.STUDENT);
    expect(ALL_ROLES).toHaveLength(5);
  });

  it('should normalize role strings correctly across naming variations', () => {
    expect(normalizeRole('SUPER_ADMIN')).toBe(AppRole.SUPER_ADMIN);
    expect(normalizeRole('Super Admin')).toBe(AppRole.SUPER_ADMIN);
    expect(normalizeRole('superadmin')).toBe(AppRole.SUPER_ADMIN);
    expect(normalizeRole('COLLEGE_ADMIN')).toBe(AppRole.COLLEGE_ADMIN);
    expect(normalizeRole('College Admin')).toBe(AppRole.COLLEGE_ADMIN);
    expect(normalizeRole('hod')).toBe(AppRole.HOD);
    expect(normalizeRole('faculty')).toBe(AppRole.FACULTY);
    expect(normalizeRole('student')).toBe(AppRole.STUDENT);
  });

  it('should validate roles strictly', () => {
    expect(isValidRole('SUPER_ADMIN')).toBe(true);
    expect(isValidRole('COLLEGE_ADMIN')).toBe(true);
    expect(isValidRole('HOD')).toBe(true);
    expect(isValidRole('FACULTY')).toBe(true);
    expect(isValidRole('STUDENT')).toBe(true);
    expect(isValidRole('UNKNOWN_ROLE')).toBe(false);
    expect(isValidRole('')).toBe(false);
  });

  it('should preserve strict role hierarchy ordering', () => {
    expect(ROLE_HIERARCHY[AppRole.SUPER_ADMIN]).toBeGreaterThan(
      ROLE_HIERARCHY[AppRole.COLLEGE_ADMIN]
    );
    expect(ROLE_HIERARCHY[AppRole.COLLEGE_ADMIN]).toBeGreaterThan(
      ROLE_HIERARCHY[AppRole.HOD]
    );
    expect(ROLE_HIERARCHY[AppRole.HOD]).toBeGreaterThan(
      ROLE_HIERARCHY[AppRole.FACULTY]
    );
    expect(ROLE_HIERARCHY[AppRole.FACULTY]).toBeGreaterThan(
      ROLE_HIERARCHY[AppRole.STUDENT]
    );
  });
});
