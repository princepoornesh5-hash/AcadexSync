import { signAccessToken } from '../../src/utils/token';
import { AppRole } from '../../src/constants/roles';

export interface CreateTestTokenOptions {
  userId?: string;
  instituteId?: string;
  email?: string;
  name?: string;
  role?: AppRole;
  collegeId?: string;
  departmentId?: string;
  courseId?: string;
  sectionId?: string;
  semesterId?: string;
  firebaseUid?: string;
  expiresInSeconds?: number;
}

/**
 * Creates a cryptographically signed Authorization header with TokenType.ACCESS for integration tests
 */
export function createTestAuthHeader(options: CreateTestTokenOptions = {}): {
  Authorization: string;
} {
  const userId = options.userId || 'usr_test_default';
  const token = signAccessToken(
    {
      userId,
      instituteId: options.instituteId || `INST-${userId}`,
      email: options.email || `${userId}@acadex.edu`,
      name: options.name || 'Test User',
      role: options.role || AppRole.SUPER_ADMIN,
      collegeId: options.collegeId,
      departmentId: options.departmentId,
      courseId: options.courseId,
      sectionId: options.sectionId,
      semesterId: options.semesterId,
      firebaseUid: options.firebaseUid,
    },
    options.expiresInSeconds || 3600
  );

  return {
    Authorization: `Bearer ${token}`,
  };
}

export function createTestToken(options: CreateTestTokenOptions = {}): string {
  const userId = options.userId || 'usr_test_default';
  return signAccessToken(
    {
      userId,
      instituteId: options.instituteId || `INST-${userId}`,
      email: options.email || `${userId}@acadex.edu`,
      name: options.name || 'Test User',
      role: options.role || AppRole.SUPER_ADMIN,
      collegeId: options.collegeId,
      departmentId: options.departmentId,
      courseId: options.courseId,
      sectionId: options.sectionId,
      semesterId: options.semesterId,
      firebaseUid: options.firebaseUid,
    },
    options.expiresInSeconds || 3600
  );
}
