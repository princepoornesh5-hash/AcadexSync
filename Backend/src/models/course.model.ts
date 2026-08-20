import mongoose, { Document, Schema } from 'mongoose';

export interface ICourse extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  name: string;
  code: string;
  duration: number;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const CourseSchema = new Schema<ICourse>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    name: { type: String, required: true, trim: true },
    code: { type: String, required: true, uppercase: true, trim: true },
    duration: { type: Number, default: 3, min: 1, max: 6 },
    isActive: { type: Boolean, default: true },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.departmentId = ret.departmentId?.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

CourseSchema.index({ collegeId: 1, departmentId: 1, code: 1 }, { unique: true });
CourseSchema.index({ collegeId: 1, code: 1 }, { unique: true });
CourseSchema.index({ collegeId: 1, name: 1 });

export const Course = mongoose.model<ICourse>('Course', CourseSchema);
