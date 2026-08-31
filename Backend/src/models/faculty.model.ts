import mongoose, { Document, Schema } from 'mongoose';

export interface IFaculty extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  instituteId: string;
  name: string;
  employeeId?: string;
  email: string;
  phone?: string;
  designation?: string;
  qualification?: string;
  specialization?: string;
  joiningDate?: Date;
  status: string;
  isActive: boolean;
  subjectIds: mongoose.Types.ObjectId[];
  sectionIds: mongoose.Types.ObjectId[];
  metadata?: Record<string, unknown>;
  createdAt: Date;
  updatedAt: Date;
}

const FacultySchema = new Schema<IFaculty>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    userId: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    instituteId: { type: String, default: null, trim: true, uppercase: true },
    name: { type: String, required: true, trim: true },
    employeeId: { type: String, default: null, trim: true },
    email: { type: String, required: true, lowercase: true, trim: true },
    phone: { type: String, default: null, trim: true },
    designation: { type: String, default: 'Assistant Professor', trim: true },
    qualification: { type: String, default: '', trim: true },
    specialization: { type: String, default: '', trim: true },
    joiningDate: { type: Date, default: null },
    status: { type: String, default: 'active', index: true },
    isActive: { type: Boolean, default: true, index: true },
    subjectIds: [{ type: Schema.Types.ObjectId, ref: 'Subject' }],
    sectionIds: [{ type: Schema.Types.ObjectId, ref: 'Section' }],
    metadata: { type: Schema.Types.Mixed, default: null },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.departmentId = ret.departmentId?.toString();
        if (ret.userId) ret.userId = ret.userId.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

FacultySchema.index(
  { userId: 1 },
  { unique: true, partialFilterExpression: { userId: { $type: 'objectId' } } }
);
FacultySchema.index(
  { collegeId: 1, employeeId: 1 },
  { unique: true, partialFilterExpression: { employeeId: { $type: 'string' } } }
);
FacultySchema.index({ collegeId: 1, departmentId: 1 });
FacultySchema.index({ collegeId: 1, email: 1 });
FacultySchema.index({ departmentId: 1, isActive: 1 });

export const Faculty = mongoose.model<IFaculty>('Faculty', FacultySchema);