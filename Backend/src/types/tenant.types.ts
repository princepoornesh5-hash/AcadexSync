import { AppRole } from '../constants/roles';
import { MembershipStatus } from '../constants/status';

export interface TenantContext {
  collegeId?: string;
  isSuperAdmin: boolean;
  userRole: AppRole;
  userId: string;
  workspaceMembershipId?: string | null;
  membershipStatus?: MembershipStatus;
  departmentId?: string | null;
}

export interface TenantFilter {
  collegeId?: string;
  [key: string]: unknown;
}

