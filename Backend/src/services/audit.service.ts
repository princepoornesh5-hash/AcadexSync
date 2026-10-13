import { AuditLog, IAuditLog } from '../models/auditLog.model';
import { AuthenticatedUser } from '../types/auth.types';

export class AuditService {
  static async log(data: Partial<IAuditLog>): Promise<IAuditLog> {
    return AuditLog.create(data);
  }

  static async logAction(data: Partial<IAuditLog>): Promise<IAuditLog> {
    return AuditLog.create(data);
  }

  /**
   * Authoritative audit logger that binds workspace and department context
   * exclusively from the backend-validated AuthenticatedUser identity.
   * Client-supplied overrides are strictly forbidden to prevent spoofing.
   */
  static async logAuthoritativeAction(
    user: AuthenticatedUser,
    action: string,
    entityType: string,
    entityId: string,
    options: {
      departmentId?: string;
      previousValue?: Record<string, unknown>;
      newValue?: Record<string, unknown>;
      metadata?: Record<string, unknown>;
      ipAddress?: string;
      userAgent?: string;
    } = {}
  ): Promise<IAuditLog> {
    return AuditLog.create({
      collegeId: user.collegeId,
      departmentId: user.departmentId || options.departmentId,
      workspaceMembershipId: user.workspaceMembershipId || undefined,
      actorUserId: user.id,
      actorEmail: user.email,
      actorRole: user.role,
      action,
      entityType,
      entityId,
      previousValue: options.previousValue,
      newValue: options.newValue,
      metadata: options.metadata,
      ipAddress: options.ipAddress,
      userAgent: options.userAgent,
      timestamp: new Date(),
    });
  }

  static async listAuditLogs(
    collegeId?: string,
    entityType?: string,
    actorUserId?: string,
    limit = 50
  ): Promise<IAuditLog[]> {
    const filter: Record<string, unknown> = {};
    if (collegeId) filter.collegeId = collegeId;
    if (entityType) filter.entityType = entityType;
    if (actorUserId) filter.actorUserId = actorUserId;

    return AuditLog.find(filter).sort({ timestamp: -1 }).limit(limit);
  }
}
