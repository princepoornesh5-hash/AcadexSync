import { AuditLog, IAuditLog } from '../models/auditLog.model';

export class AuditService {
  static async log(data: Partial<IAuditLog>): Promise<IAuditLog> {
    return AuditLog.create(data);
  }

  static async logAction(data: Partial<IAuditLog>): Promise<IAuditLog> {
    return AuditLog.create(data);
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
