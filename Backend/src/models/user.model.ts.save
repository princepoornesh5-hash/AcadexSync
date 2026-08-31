import mongoose, { Document, Schema } from 'mongoose';
import { AppRole } from '../constants/roles';
import { AccountStatus } from '../constants/status';

export interface IUser extends Document {
  instituteId: string;
  name: string;
  email?: string;
  phone?: string;
  role: AppRole;
  passwordHash?: string;
  collegeId?: mongoose.Types.ObjectId;
  departmentId?: mongoose.Types.ObjectId;
  courseId?: mongoose.Types.ObjectId;
  sectionId?: mongoose.Types.ObjectId;
  semesterId?: mongoose.Types.ObjectId;
  firebaseUid?: string;
  profilePictureUrl?: string;
  accountStatus: AccountStatus;
  activationStatus: string;
  lastLoginAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema = new Schema<IUser>(
  {
    instituteId: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
    },
    name: { type: String, required: true, trim: true },
    email: {
      type: String,
      unique: true,
      sparse: true,
      lowercase: true,
      trim: true,
    },
    phone: {
      type: String,
      unique: true,
      sparse: true,
      trim: true,
    },
    role: {
      type: String,
      enum: Object.values(AppRole),
      required: true,
      default: AppRole.STUDENT,
    },
    passwordHash: { type: String, default: null },
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', default: null, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', default: null },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', default: null },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', default: null },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', default: null },
    firebaseUid: { type: String, default: null, sparse: true, index: true },
    profilePictureUrl: { type: String, default: null },
    accountStatus: {
      type: String,
      enum: Object.values(AccountStatus),
      default: AccountStatus.ACTIVE,
    },
    activationStatus: {
      type: String,
      enum: ['pending', 'activated', 'deactivated'],
      default: 'activated',
    },
    lastLoginAt: { type: Date, default: null },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        if (ret.collegeId) ret.collegeId = ret.collegeId.toString();
        if (ret.departmentId) ret.departmentId = ret.departmentId.toString();
        if (ret.courseId) ret.courseId = ret.courseId.toString();
        if (ret.sectionId) ret.sectionId = ret.sectionId.toString();
        if (ret.semesterId) ret.semesterId = ret.semesterId.toString();
        delete ret.passwordHash;
        delete ret.__v;
        return ret;
      },
    },
    toObject: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        if (ret.collegeId) ret.collegeId = ret.collegeId.toString();
        if (ret.departmentId) ret.departmentId = ret.departmentId.toString();
        if (ret.courseId) ret.courseId = ret.courseId.toString();
        if (ret.sectionId) ret.sectionId = ret.sectionId.toString();
        if (ret.semesterId) ret.semesterId = ret.semesterId.toString();
        delete ret.passwordHash;
        delete ret.__v;
        return ret;
      },
    },
  }
);

UserSchema.index({ collegeId: 1, role: 1 });
UserSchema.index({ collegeId: 1, departmentId: 1 });
UserSchema.index({ departmentId: 1, role: 1 });

export const User = mongoose.model<IUser>('User', UserSchema);
