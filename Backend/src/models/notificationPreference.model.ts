import mongoose, { Document, Schema } from 'mongoose';

export interface INotificationPreference extends Document {
  userId: mongoose.Types.ObjectId;
  collegeId?: mongoose.Types.ObjectId;
  inAppEnabled: boolean;
  pushEnabled: boolean;
  academic: boolean;
  assignments: boolean;
  practicals: boolean;
  assessments: boolean;
  calendar: boolean;
  announcements: boolean;
  notes: boolean;
  attendance: boolean;
  timetable: boolean;
  academicResults: boolean; // MANDATORY - cannot be disabled
  system: boolean; // MANDATORY - cannot be disabled
  createdAt: Date;
  updatedAt: Date;
}

const NotificationPreferenceSchema = new Schema<INotificationPreference>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true, index: true },
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', default: null, index: true },
    inAppEnabled: { type: Boolean, default: true },
    pushEnabled: { type: Boolean, default: true },
    academic: { type: Boolean, default: true },
    assignments: { type: Boolean, default: true },
    practicals: { type: Boolean, default: true },
    assessments: { type: Boolean, default: true },
    calendar: { type: Boolean, default: true },
    announcements: { type: Boolean, default: true },
    notes: { type: Boolean, default: true },
    attendance: { type: Boolean, default: true },
    timetable: { type: Boolean, default: true },
    academicResults: { type: Boolean, default: true }, // Mandatory official notices
    system: { type: Boolean, default: true }, // Mandatory security/system notices cannot be turned off
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
