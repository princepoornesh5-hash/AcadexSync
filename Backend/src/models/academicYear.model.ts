import mongoose, { Document, Schema } from 'mongoose';
import { AcademicYearStatus } from '../constants/status';
import { ApiError } from '../utils/apiError';

export function validateAcademicYearOperationalCycle(name: string, startDate?: Date, endDate?: Date): void {
  const trimmed = name.trim();

  // Detect multi-year cohort/batch format: e.g. "2024-2028", "2024–2028", "2023-2027"
  const fullYearMatch = trimmed.match(/^(\d{4})\s*[-–/]\s*(\d{4})$/);
  if (fullYearMatch) {
    const startY = parseInt(fullYearMatch[1], 10);
    const endY = parseInt(fullYearMatch[2], 10);
    if (endY - startY > 1) {
      throw ApiError.badRequest(
        `Academic Year "${trimmed}" spans ${endY - startY} years and represents a multi-year student cohort/batch intake (e.g. 2024–2028), not an operational calendar cycle (e.g. 2026–2027). Please configure student cohorts separately.`
      );
    }
  }

  // Detect short-year format: e.g. "2024-28", "2024–28", "2024-27"
  const shortYearMatch = trimmed.match(/^(\d{4})\s*[-–/]\s*(\d{2})$/);
  if (shortYearMatch) {
    const startYY = parseInt(shortYearMatch[1].slice(-2), 10);
    const endYY = parseInt(shortYearMatch[2], 10);
    const diff = endYY >= startYY ? endYY - startYY : endYY + 100 - startYY;
    if (diff > 1) {
      throw ApiError.badRequest(
        `Academic Year "${trimmed}" spans ${diff} years and represents a multi-year student cohort/batch intake (e.g. 2024–27), not an operational calendar cycle (e.g. 2026–27). Please configure student cohorts separately.`
      );
    }
  }

  // Operational cycle duration check (max ~15 months = 460 days)
  if (startDate && endDate) {
    const durationDays = (endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24);
    if (durationDays > 460) {
      throw ApiError.badRequest(
        `Academic Year operational cycle duration (${Math.round(durationDays)} days) exceeds the maximum allowed 15 months. Multi-year spans represent student cohorts/batches, not operational academic years.`
      );
    }
  }
}

export interface IAcademicYear extends Document {
  collegeId: mongoose.Types.ObjectId;
  name: string;
  startDate: Date;
  endDate: Date;
  status: AcademicYearStatus;
  isCurrent: boolean;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const AcademicYearSchema = new Schema<IAcademicYear>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    name: { type: String, required: true, trim: true },
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    status: {
      type: String,
      enum: Object.values(AcademicYearStatus),
      default: AcademicYearStatus.UPCOMING,
    },
    isCurrent: { type: Boolean, default: false },
    isActive: { type: Boolean, default: true },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

AcademicYearSchema.index({ collegeId: 1, name: 1 }, { unique: true });
AcademicYearSchema.index({ collegeId: 1, isCurrent: 1 });
AcademicYearSchema.index({ collegeId: 1, status: 1 });

export const AcademicYear = mongoose.model<IAcademicYear>('AcademicYear', AcademicYearSchema);
