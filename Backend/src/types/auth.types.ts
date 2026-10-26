import { AppRole } from '../constants/roles';
import { AccountStatus, TokenType, MembershipStatus } from '../constants/status';

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
  workspaceMembershipId?: string | null;
  workspaceMembershipStatus?: MembershipStatus;
  activeRoles?: AppRole[];
  authorizedDepartmentIds?: string[];
  isAuthoritativeWorkspace?: boolean;
  isSuperAdmin?: boolean;
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
  requireSession?: boolean;
  invitationId?: string;
  flowId?: string;
  tokenId?: string;
  contactMethod?: string;
  purpose?: string;
  iat?: number;
  exp?: number;
}

