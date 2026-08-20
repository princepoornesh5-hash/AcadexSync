import { AuthenticatedUser } from './auth.types';
import { TenantContext } from './tenant.types';

declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
      tenant?: TenantContext;
      collegeId?: string;
    }
  }
}

export {};
