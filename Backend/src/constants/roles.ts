export enum AppRole {
  SUPER_ADMIN = 'SUPER_ADMIN',
  COLLEGE_ADMIN = 'COLLEGE_ADMIN',
  HOD = 'HOD',
  FACULTY = 'FACULTY',
  STUDENT = 'STUDENT',
}

export const ALL_ROLES: AppRole[] = [
  AppRole.SUPER_ADMIN,
  AppRole.COLLEGE_ADMIN,
  AppRole.HOD,
  AppRole.FACULTY,
  AppRole.STUDENT,
];

export function isValidRole(role: string): role is AppRole {
  const normalized = role.trim().replace(/[\s_-]+/g, '_').toUpperCase();
  return Object.values(AppRole).includes(normalized as AppRole);
}

export function normalizeRole(role: string): AppRole {
  const normalized = role.trim().replace(/[\s_-]+/g, '_').toUpperCase();
  switch (normalized) {
    case 'SUPERADMIN':
    case 'SUPER_ADMIN':
      return AppRole.SUPER_ADMIN;
    case 'COLLEGEADMIN':
    case 'COLLEGE_ADMIN':
      return AppRole.COLLEGE_ADMIN;
    case 'HOD':
      return AppRole.HOD;
    case 'FACULTY':
      return AppRole.FACULTY;
    case 'STUDENT':
      return AppRole.STUDENT;
    default:
      throw new Error(`Unrecognized or invalid AppRole value: "${role}"`);
  }
}

export const ROLE_HIERARCHY: Record<AppRole, number> = {
  [AppRole.SUPER_ADMIN]: 100,
  [AppRole.COLLEGE_ADMIN]: 80,
  [AppRole.HOD]: 60,
  [AppRole.FACULTY]: 40,
  [AppRole.STUDENT]: 20,
};
