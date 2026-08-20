import mongoose, { Document, Schema } from 'mongoose';

export interface IAuthSession extends Document {
  userId: mongoose.Types.ObjectId;
  sessionId: string;
  refreshTokenHash: string;
  userAgent?: string;
  ipAddress?: string;
  expiresAt: Date;
  revokedAt?: Date;
  lastUsedAt: Date;
  createdAt: Date;
  updatedAt: Date;
  isRevoked(): boolean;
  isExpired(): boolean;
}

const AuthSessionSchema = new Schema<IAuthSession>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    sessionId: { type: String, required: true },
    refreshTokenHash: { type: String, required: true },
    userAgent: { type: String, default: null },
    ipAddress: { type: String, default: null },
    expiresAt: { type: Date, required: true },
    revokedAt: { type: Date, default: null },
    lastUsedAt: { type: Date, default: Date.now },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.userId = ret.userId?.toString();
        delete ret.refreshTokenHash;
        delete ret.__v;
        return ret;
      },
    },
  }
);

AuthSessionSchema.methods.isRevoked = function (): boolean {
  return this.revokedAt !== null && this.revokedAt !== undefined;
};

AuthSessionSchema.methods.isExpired = function (): boolean {
  return new Date() > this.expiresAt;
};

AuthSessionSchema.index({ sessionId: 1 }, { unique: true });
AuthSessionSchema.index({ userId: 1, revokedAt: 1 });
AuthSessionSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

export const AuthSession = mongoose.model<IAuthSession>('AuthSession', AuthSessionSchema);
