import { AppRole } from '../constants/roles';

export interface TenantContext {
  collegeId?: string;
  isSuperAdmin: boolean;
  userRole: AppRole;
  userId: string;
}

export interface TenantFilter {
  collegeId?: string;
  [key: string]: unknown;
}
