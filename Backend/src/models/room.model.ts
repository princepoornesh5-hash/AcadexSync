import mongoose, { Document, Schema } from 'mongoose';

export interface IRoom extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId?: mongoose.Types.ObjectId | null;
  buildingId?: mongoose.Types.ObjectId | null;
  building?: string | null;
  name: string;
  code: string;
  capacity: number;
  type: string;
  status: 'active' | 'inactive' | 'retired' | 'archived';
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const RoomSchema = new Schema<IRoom>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', default: null, index: true },
    buildingId: { type: Schema.Types.ObjectId, ref: 'Building', default: null, index: true },
    building: { type: String, default: null, trim: true },
    name: { type: String, required: true, trim: true },
    code: { type: String, required: true, uppercase: true, trim: true },
    capacity: { type: Number, required: true, min: 1, default: 60 },
    type: {
      type: String,
      enum: ['lecture', 'lab', 'seminar', 'other'],
      default: 'lecture',
    },
    status: {
      type: String,
      enum: ['active', 'inactive', 'retired', 'archived'],
      default: 'active',
      index: true,
    },
    isActive: { type: Boolean, default: true },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        if (ret.departmentId) ret.departmentId = ret.departmentId.toString();
        if (ret.buildingId) ret.buildingId = ret.buildingId.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

RoomSchema.index({ collegeId: 1, code: 1 }, { unique: true });
RoomSchema.index({ collegeId: 1, isActive: 1 });

export const Room = mongoose.model<IRoom>('Room', RoomSchema);
