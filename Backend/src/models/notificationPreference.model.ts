import mongoose, { Document, Schema } from 'mongoose';

export interface INotificationPreference extends Document {
  userId: mongoose.Types.ObjectId;
  collegeId?: mongoose.Types.ObjectId;
  notes: boolean;
  attendance: boolean;
  timetable: boolean;
  system: boolean;
  pushEnabled: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const NotificationPreferenceSchema = new Schema<INotificationPreference>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true, index: true },
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', default: null, index: true },
    notes: { type: Boolean, default: true },
    attendance: { type: Boolean, default: true },
    timetable: { type: Boolean, default: true },
    system: { type: Boolean, default: true }, // Mandatory security/system notices cannot be turned off
    pushEnabled: { type: Boolean, default: true },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        if (ret.userId) ret.userId = ret.userId.toString();
        if (ret.collegeId) ret.collegeId = ret.collegeId.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

export const NotificationPreference = mongoose.model<INotificationPreference>(
  'NotificationPreference',
  NotificationPreferenceSchema
);
