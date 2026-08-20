import mongoose, { Document, Schema } from 'mongoose';
import { StudentLifecycleState } from '../constants/status';

export interface IStudent extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  instituteId: string;
  name: string;
  rollNumber?: string;
  admissionNumber?: string;
  email?: string;
  phone?: string;
  courseId?: mongoose.Types.ObjectId;
  academicYearId?: mongoose.Types.ObjectId;
  semesterId?: mongoose.Types.ObjectId;
  sectionId?: mongoose.Types.ObjectId;
  lifecycleState: StudentLifecycleState;
  admissionDate?: Date;
  graduationDate?: Date;
  parentName?: string;
  parentPhone?: string;
  bloodGroup?: string;
  address?: string;
  dateOfBirth?: Date;
  status: string;
  isActive: boolean;
  metadata?: Record<string, unknown>;
  createdAt: Date;
  updatedAt: Date;
}

const StudentSchema = new Schema<IStudent>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    userId: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    instituteId: { type: String, default: null, trim: true, uppercase: true },
    name: { type: String, required: true, trim: true },
    rollNumber: { type: String, default: null, trim: true },
    admissionNumber: { type: String, default: null, trim: true },
    email: { type: String, default: null, lowercase: true, trim: true },
    phone: { type: String, default: null, trim: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', default: null },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', default: null },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', default: null },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', default: null },
    lifecycleState: {
      type: String,
      enum: Object.values(StudentLifecycleState),
      default: StudentLifecycleState.ACTIVE,
    },
    admissionDate: { type: Date, default: null },
    graduationDate: { type: Date, default: null },
    parentName: { type: String, default: null },
    parentPhone: { type: String, default: null },
    bloodGroup: { type: String, default: null },
    address: { type: String, default: null },
    dateOfBirth: { type: Date, default: null },
    status: { type: String, default: 'active' },
    isActive: { type: Boolean, default: true },
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
        if (ret.courseId) ret.courseId = ret.courseId.toString();
        if (ret.semesterId) ret.semesterId = ret.semesterId.toString();
        if (ret.sectionId) ret.sectionId = ret.sectionId.toString();
        if (ret.academicYearId) ret.academicYearId = ret.academicYearId.toString();
        if (ret.userId) ret.userId = ret.userId.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

StudentSchema.index(
  { userId: 1 },
  { unique: true, partialFilterExpression: { userId: { $type: 'objectId' } } }
);
StudentSchema.index(
  { collegeId: 1, rollNumber: 1 },
  { unique: true, partialFilterExpression: { rollNumber: { $type: 'string' } } }
);
StudentSchema.index(
  { collegeId: 1, admissionNumber: 1 },
  { unique: true, partialFilterExpression: { admissionNumber: { $type: 'string' } } }
);
StudentSchema.index({ collegeId: 1, departmentId: 1 });
StudentSchema.index({ collegeId: 1, lifecycleState: 1 });

export const Student = mongoose.model<IStudent>('Student', StudentSchema);
