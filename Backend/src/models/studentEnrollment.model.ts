import mongoose, { Document, Schema } from 'mongoose';

export interface IStudentEnrollment extends Document {
  collegeId: mongoose.Types.ObjectId;
  studentId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  courseId: mongoose.Types.ObjectId;
  academicYearId: mongoose.Types.ObjectId;
  semesterId: mongoose.Types.ObjectId;
  sectionId: mongoose.Types.ObjectId;
  enrollmentDate: Date;
  status: string;
  createdAt: Date;
  updatedAt: Date;
}

const StudentEnrollmentSchema = new Schema<IStudentEnrollment>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', required: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', required: true },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', required: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', required: true, index: true },
    enrollmentDate: { type: Date, default: Date.now },
    status: { type: String, default: 'active' },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        if (ret.studentId && typeof ret.studentId === 'object' && ret.studentId._id) {
          ret.student = ret.studentId;
          ret.studentId = ret.studentId._id.toString();
        } else {
          ret.studentId = ret.studentId?.toString();
        }
        ret.departmentId = ret.departmentId?.toString();
        ret.courseId = ret.courseId?.toString();
        ret.academicYearId = ret.academicYearId?.toString();
        ret.semesterId = ret.semesterId?.toString();
        ret.sectionId = ret.sectionId?.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

StudentEnrollmentSchema.index(
  { collegeId: 1, studentId: 1, semesterId: 1, sectionId: 1 },
  { unique: true }
);
StudentEnrollmentSchema.index({ collegeId: 1, sectionId: 1 });

export const StudentEnrollment = mongoose.model<IStudentEnrollment>(
  'StudentEnrollment',
  StudentEnrollmentSchema
);
