import mongoose, { Document, Schema } from 'mongoose';

export interface IAuditLog extends Document {
  collegeId?: string;
  actorUserId: string;
  actorEmail?: string;
  actorRole?: string;
  action: string;
  entityType: string;
  entityId: string;
  previousValue?: Record<string, unknown>;
  newValue?: Record<string, unknown>;
  metadata?: Record<string, unknown>;
  ipAddress?: string;
  userAgent?: string;
  timestamp: Date;
  createdAt: Date;
  updatedAt: Date;
}

const AuditLogSchema = new Schema<IAuditLog>(
  {
    collegeId: { type: String, default: null, index: true },
    actorUserId: { type: String, required: true, index: true },
    actorEmail: { type: String, default: null },
    actorRole: { type: String, default: null },
    action: { type: String, required: true, trim: true },
    entityType: { type: String, required: true, trim: true, index: true },
    entityId: { type: String, required: true, trim: true, index: true },
    previousValue: { type: Schema.Types.Mixed, default: null },
    newValue: { type: Schema.Types.Mixed, default: null },
    metadata: { type: Schema.Types.Mixed, default: null },
    ipAddress: { type: String, default: null },
    userAgent: { type: String, default: null },
    timestamp: { type: Date, default: Date.now, index: true },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

AuditLogSchema.index({ collegeId: 1, entityType: 1, timestamp: -1 });
AuditLogSchema.index({ actorUserId: 1, timestamp: -1 });
AuditLogSchema.index({ entityType: 1, entityId: 1 });

export const AuditLog = mongoose.model<IAuditLog>('AuditLog', AuditLogSchema);
