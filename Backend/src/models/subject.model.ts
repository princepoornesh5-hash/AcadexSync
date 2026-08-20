import mongoose, { Document, Schema } from 'mongoose';

export interface ISubject extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  courseId?: mongoose.Types.ObjectId;
  semesterId: mongoose.Types.ObjectId;
  name: string;
  code: string;
  credits: number;
  type: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const SubjectSchema = new Schema<ISubject>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', default: null },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', required: true, index: true },
    name: { type: String, required: true, trim: true },
    code: { type: String, required: true, uppercase: true, trim: true },
    credits: { type: Number, default: 3, min: 0 },
    type: { type: String, default: 'Theory' },
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
        ret.semesterId = ret.semesterId?.toString();
        if (ret.courseId) ret.courseId = ret.courseId.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

SubjectSchema.index(
  { collegeId: 1, departmentId: 1, semesterId: 1, code: 1 },
  { unique: true }
);
SubjectSchema.index({ collegeId: 1, semesterId: 1 });

export const Subject = mongoose.model<ISubject>('Subject', SubjectSchema);
