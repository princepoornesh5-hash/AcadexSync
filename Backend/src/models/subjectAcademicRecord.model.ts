import mongoose, { Document, Schema } from 'mongoose';
import { SubjectAcademicStatus } from '../constants/academicRecord.constants';

export interface ISubjectAcademicRecord extends Document {
  collegeId: mongoose.Types.ObjectId;
  academicRecordId: mongoose.Types.ObjectId;
  studentId: mongoose.Types.ObjectId;
  subjectId: mongoose.Types.ObjectId;
  facultyAssignmentId?: mongoose.Types.ObjectId | null;
  status: SubjectAcademicStatus;
  credits: number;
  remarks?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

const SubjectAcademicRecordSchema = new Schema<ISubjectAcademicRecord>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    academicRecordId: { type: Schema.Types.ObjectId, ref: 'AcademicRecord', required: true, index: true },
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    facultyAssignmentId: { type: Schema.Types.ObjectId, ref: 'FacultyAssignment', default: null, index: true },
    status: {
      type: String,
      enum: Object.values(SubjectAcademicStatus),
      default: SubjectAcademicStatus.ENROLLED,
      index: true,
    },
    credits: { type: Number, default: 0 },
    remarks: { type: String, default: null, trim: true },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.academicRecordId = ret.academicRecordId?.toString();
        ret.studentId = ret.studentId?.toString();
        ret.subjectId = ret.subjectId?.toString();
        if (ret.facultyAssignmentId) ret.facultyAssignmentId = ret.facultyAssignmentId.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

// One subject entry per academic record
SubjectAcademicRecordSchema.index(
  { collegeId: 1, academicRecordId: 1, subjectId: 1 },
  { unique: true }
);

SubjectAcademicRecordSchema.index({ collegeId: 1, studentId: 1 });
SubjectAcademicRecordSchema.index({ collegeId: 1, facultyAssignmentId: 1 });

export const SubjectAcademicRecord = mongoose.model<ISubjectAcademicRecord>(
  'SubjectAcademicRecord',
  SubjectAcademicRecordSchema
);
