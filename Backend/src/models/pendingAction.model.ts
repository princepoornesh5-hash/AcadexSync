import mongoose, { Document, Schema } from 'mongoose';

export type PendingActionType =
  | 'CREATE_ASSIGNMENT'
  | 'CREATE_CALENDAR_EVENT'
  | 'CREATE_REQUEST'
  | 'RESPOND_REQUEST';
export type PendingActionStatus = 'PENDING' | 'EXECUTED' | 'CANCELLED' | 'EXPIRED';

export interface IPendingAction extends Document {
  actionId: string;
  userId: string;
  userRole: string;
  collegeId: string;
  actionType: PendingActionType;
  status: PendingActionStatus;
  draftPayload: Record<string, any>;
  summary: string;
  preview: Record<string, any>;
  expiresAt: Date;
  executedAt?: Date | null;
  executionResult?: Record<string, any> | null;
  idempotencyKey?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

const PendingActionSchema = new Schema<IPendingAction>(
  {
    actionId: { type: String, required: true, unique: true, index: true },
    userId: { type: String, required: true, index: true },
    userRole: { type: String, required: true },
    collegeId: { type: String, required: true, index: true },
    actionType: {
      type: String,
      required: true,
      enum: ['CREATE_ASSIGNMENT', 'CREATE_CALENDAR_EVENT', 'CREATE_REQUEST', 'RESPOND_REQUEST'],
      index: true,
    },
    status: {
      type: String,
      required: true,
      enum: ['PENDING', 'EXECUTED', 'CANCELLED', 'EXPIRED'],
      default: 'PENDING',
      index: true,
    },
    draftPayload: { type: Schema.Types.Mixed, required: true },
    summary: { type: String, required: true },
    preview: { type: Schema.Types.Mixed, required: true },
    expiresAt: { type: Date, required: true, index: { expires: 0 } }, // Auto-cleans expired documents
    executedAt: { type: Date, default: null },
    executionResult: { type: Schema.Types.Mixed, default: null },
    idempotencyKey: { type: String, default: null, index: true },
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

PendingActionSchema.index({ collegeId: 1, status: 1, createdAt: -1 });
PendingActionSchema.index({ userId: 1, status: 1, createdAt: -1 });
PendingActionSchema.index({ actionId: 1, userId: 1 });

export const PendingAction = mongoose.model<IPendingAction>('PendingAction', PendingActionSchema);
