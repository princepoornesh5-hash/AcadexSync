import { Types } from 'mongoose';
import { AttendanceRecord } from '../../models/attendanceRecord.model';
import { HistoricalAttendanceSummary } from '../../models/historicalAttendanceSummary.model';
import { AttendanceStatus } from '../../constants/status';

export interface IHistoricalPercentageMetric {
  periodLabel: string;
  percentage: number;
  type: 'PERCENTAGE_ONLY';
}

export interface IStudentAttendanceAggregationResult {
  detailedMetrics: {
    totalHeld: number;
    totalPresent: number;
    totalAbsent: number;
    percentage: number;
    liveHeld: number;
    livePresent: number;
    historicalDetailedHeld: number;
    historicalDetailedPresent: number;
  };
  historicalPercentageMetrics: IHistoricalPercentageMetric[];
  hasDetailedData: boolean;
  hasPercentageOnlyData: boolean;
}

export class AttendanceAggregationService {
  /**
   * Aggregates attendance for a student across canonical live records, detailed historical records,
   * period summary records, and preserves percentage-only metrics without mathematical corruption.
   */
  static async aggregateForStudent(
    collegeId: string | Types.ObjectId,
    studentId: string | Types.ObjectId,
    options: {
      subjectId?: string | Types.ObjectId;
      studentEnrollmentId?: string | Types.ObjectId;
    } = {}
  ): Promise<IStudentAttendanceAggregationResult> {
    const collegeObjectId = new Types.ObjectId(collegeId.toString());
    const studentObjectId = new Types.ObjectId(studentId.toString());

    let liveHeld = 0;
    let livePresent = 0;
    let historicalDetailedHeld = 0;
    let historicalDetailedPresent = 0;

    // 1. Query canonical AttendanceRecord documents
    const recordQuery: any = {
      collegeId: collegeObjectId,
      studentId: studentObjectId,
      isCancelled: { $ne: true },
    };
    if (options.subjectId) {
      recordQuery.subjectId = new Types.ObjectId(options.subjectId.toString());
    }

    const records = await AttendanceRecord.find(recordQuery).lean();

    for (const rec of records) {
      const isHistorical = rec.sourceType === 'IMPORTED' || rec.sourceType === 'HISTORICAL_MANUAL';
      const isPresent = rec.status === AttendanceStatus.PRESENT;

      if (isHistorical) {
        historicalDetailedHeld++;
        if (isPresent) historicalDetailedPresent++;
      } else {
        liveHeld++;
        if (isPresent) livePresent++;
      }
    }

    // 2. Query HistoricalAttendanceSummary documents
    const summaryQuery: any = {
      collegeId: collegeObjectId,
      $or: [{ studentId: studentObjectId }],
    };
    if (options.studentEnrollmentId) {
      summaryQuery.$or.push({
        studentEnrollmentId: new Types.ObjectId(options.studentEnrollmentId.toString()),
      });
    }
    if (options.subjectId) {
      summaryQuery.subjectId = new Types.ObjectId(options.subjectId.toString());
    }

    const summaries = await HistoricalAttendanceSummary.find(summaryQuery).lean();
    const historicalPercentageMetrics: IHistoricalPercentageMetric[] = [];

    for (const s of summaries) {
      if (s.precisionLevel === 'PERIOD_SUMMARY' && s.classesHeld !== null && s.classesHeld !== undefined) {
        // Level 2 counts safely contribute to overall denominator aggregation
        historicalDetailedHeld += s.classesHeld;
        historicalDetailedPresent += (s.presentCount ?? 0);
      } else if (s.precisionLevel === 'PERCENTAGE_ONLY') {
        // Level 3 percentage-only: NEVER combine into denominator-based formula without denominator!
        historicalPercentageMetrics.push({
          periodLabel: s.periodLabel,
          percentage: s.attendancePercentage,
          type: 'PERCENTAGE_ONLY',
        });
      }
    }

    // 3. Mathematical precision-aware overall calculation
    const totalHeld = liveHeld + historicalDetailedHeld;
    const totalPresent = livePresent + historicalDetailedPresent;
    const totalAbsent = totalHeld - totalPresent;
    const percentage =
      totalHeld > 0 ? Math.round((totalPresent / totalHeld) * 10000) / 100 : 0;

    return {
      detailedMetrics: {
        totalHeld,
        totalPresent,
        totalAbsent,
        percentage,
        liveHeld,
        livePresent,
        historicalDetailedHeld,
        historicalDetailedPresent,
      },
      historicalPercentageMetrics,
      hasDetailedData: totalHeld > 0,
      hasPercentageOnlyData: historicalPercentageMetrics.length > 0,
    };
  }
}
