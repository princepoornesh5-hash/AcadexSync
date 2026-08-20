import { AppRole } from '../constants/roles';
import { AccountStatus, TokenType } from '../constants/status';

export interface AuthenticatedUser {
  id: string;
  instituteId: string;
  email?: string;
  phone?: string;
  name: string;
  role: AppRole;
  collegeId?: string;
  departmentId?: string;
  courseId?: string;
  sectionId?: string;
  semesterId?: string;
  firebaseUid?: string;
  accountStatus: AccountStatus;
  activationStatus?: string;
  sessionId?: string;
}

export interface JwtPayload {
  userId: string;
  instituteId?: string;
  email?: string;
  phone?: string;
  name?: string;
  role: AppRole;
  collegeId?: string;
  departmentId?: string;
  courseId?: string;
  sectionId?: string;
  semesterId?: string;
  firebaseUid?: string;
  tokenType: TokenType;
  sessionId?: string;
  iat?: number;
  exp?: number;
}
