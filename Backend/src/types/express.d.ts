import { AuthenticatedUser } from './auth.types';
import { TenantContext } from './tenant.types';
import { AppRole } from '../constants/roles';
import { MembershipStatus } from '../constants/status';

export interface WorkspaceContext {
  collegeId: string;
  membershipId?: string | null;
  membershipStatus?: MembershipStatus;
  roles: AppRole[];
  roleAssignments: Array<{
    role: AppRole;
    departmentId?: string | null;
    scope?: Record<string, unknown> | null;
  }>;
  departmentId?: string | null;
  authorizedDepartmentIds: string[];
  isAuthoritative: boolean;
  isSuperAdmin: boolean;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
      tenant?: TenantContext;
      collegeId?: string;
      workspace?: WorkspaceContext;
    }
  }
}

export {};

