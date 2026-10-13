import { Types } from 'mongoose';
import { ApiError } from '../utils/apiError';
import { AppRole } from '../constants/roles';
import { AuthenticatedUser } from '../types/auth.types';
import {
  InternalAssessment,
  AssessmentMark,
  HistoricalAttendanceSummary,
} from '../models';
import { StudentMarkStatus } from '../models/internalAssessment.model';
import { DepartmentAnalyticsQueryInput } from '../validations/departmentAnalytics.validation';

export interface AssessmentAnalyticsResult {
  scope: {
    collegeId: string;
    departmentId?: string;
  };
  overview: {
    totalAssessments: number;
    liveAssessmentsCount: number;
    importedAssessmentsCount: number;
    historicalManualAssessmentsCount?: number;
    totalMarksEntries: number;
    enteredMarksCount: number;
    absentCount: number;
    notAppearedCount: number;
    exemptedCount: number;
    notEnteredCount: number;
    sumObtainedMarks: number;
    sumMaximumMarks: number;
    overallPercentage: number | null;
    averageMarks: number | null;
    hasPassThreshold: boolean;
    passedCount: number;
    failedCount: number;
    passRate: number | null;
    participationRate: number;
  };
  subjectsBreakdown: Array<{
    subjectId: string;
    subjectName: string;
    subjectCode: string;
    assessmentsCount: number;
    enteredMarksCount: number;
    absentCount: number;
    exemptedCount: number;
    sumObtainedMarks: number;
    sumMaximumMarks: number;
    percentage: number | null;
    hasPassThreshold: boolean;
    passRate: number | null;
  }>;
  sectionsBreakdown: Array<{
    sectionId: string;
    sectionName: string;
    assessmentsCount: number;
    enteredMarksCount: number;
    absentCount: number;
    sumObtainedMarks: number;
    sumMaximumMarks: number;
    percentage: number | null;
  }>;
  attendanceOverview: {
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
    historicalPercentageMetrics: Array<{
      periodLabel: string;
      percentage: number;
      type: string;
    }>;
    hasDetailedData: boolean;
    hasPercentageOnlyData: boolean;
  };
}

export class AcademicAnalyticsService {
  /**
   * Resolves authorized tenant scope and performs strict RBAC validation.
   */
  static resolveScope(
    requester: AuthenticatedUser,
    query: { collegeId?: string; departmentId?: string }
  ): { collegeId: Types.ObjectId; departmentId?: Types.ObjectId } {
    if (!requester) {
      throw ApiError.unauthorized('Authentication required');
    }

    if (requester.role === AppRole.STUDENT) {
      throw ApiError.forbidden('Students are not authorized to access academic analytics');
    }

    let collegeIdStr = requester.collegeId ? requester.collegeId.toString() : '';
    if (requester.role === AppRole.SUPER_ADMIN && query.collegeId) {
      collegeIdStr = query.collegeId.toString();
    }

    if (!collegeIdStr) {
      throw ApiError.badRequest('College ID context missing');
    }

    if (query.collegeId && requester.role !== AppRole.SUPER_ADMIN && query.collegeId.toString() !== collegeIdStr) {
      throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
    }

    let departmentIdStr = query.departmentId ? query.departmentId.toString() : undefined;
    if (requester.role === AppRole.HOD || requester.role === AppRole.FACULTY) {
      if (!requester.departmentId) {
        throw ApiError.forbidden('User missing departmental assignment');
      }
      const userDeptStr = requester.departmentId.toString();
      if (departmentIdStr && departmentIdStr !== userDeptStr) {
        throw ApiError.forbidden('Access outside assigned department is strictly prohibited');
      }
      departmentIdStr = userDeptStr;
    }

    return {
      collegeId: new Types.ObjectId(collegeIdStr),
      departmentId: departmentIdStr && Types.ObjectId.isValid(departmentIdStr)
        ? new Types.ObjectId(departmentIdStr)
        : undefined,
    };
  }

  /**
   * Computes authoritative assessment and precision-aware academic analytics.
   */
  static async getAssessmentAnalytics(
    requester: AuthenticatedUser,
    query: DepartmentAnalyticsQueryInput
  ): Promise<AssessmentAnalyticsResult> {
    const { collegeId, departmentId } = this.resolveScope(requester, query);

    // 1. Build Assessment Filters
    const assessFilter: any = { collegeId };
    if (departmentId) assessFilter.departmentId = departmentId;
    if (query.courseId && Types.ObjectId.isValid(query.courseId)) {
      assessFilter.courseId = new Types.ObjectId(query.courseId);
    }
    if (query.semesterId && Types.ObjectId.isValid(query.semesterId)) {
      assessFilter.semesterId = new Types.ObjectId(query.semesterId);
    }
    if (query.sectionId && Types.ObjectId.isValid(query.sectionId)) {
      assessFilter.sectionId = new Types.ObjectId(query.sectionId);
    }
    if (query.subjectId && Types.ObjectId.isValid(query.subjectId)) {
      assessFilter.subjectId = new Types.ObjectId(query.subjectId);
    }
    if (query.academicYearId && Types.ObjectId.isValid(query.academicYearId)) {
      assessFilter.academicYearId = new Types.ObjectId(query.academicYearId);
    }
    if (query.startDate || query.endDate) {
      assessFilter.createdAt = {};
      if (query.startDate) assessFilter.createdAt.$gte = new Date(query.startDate);
      if (query.endDate) assessFilter.createdAt.$lte = new Date(query.endDate);
    }

    // Query canonical assessments
    const assessments = await InternalAssessment.find(assessFilter)
      .populate('subjectId', 'name code')
      .populate('sectionId', 'name')
      .lean();

    const assessIds = assessments.map((a) => a._id);

    // Query canonical marks
    const markFilter: any = {
      collegeId,
      assessmentId: { $in: assessIds },
    };
    if (query.studentId && Types.ObjectId.isValid(query.studentId)) {
      markFilter.studentId = new Types.ObjectId(query.studentId);
    }

    const marks = await AssessmentMark.find(markFilter).lean();

    // 2. Metrics Accumulation
    let liveAssessmentsCount = 0;
    let importedAssessmentsCount = 0;
    let historicalManualAssessmentsCount = 0;
    for (const a of assessments) {
      if (a.sourceType === 'IMPORTED') {
        importedAssessmentsCount++;
      } else if (a.sourceType === 'HISTORICAL_MANUAL') {
        historicalManualAssessmentsCount++;
      } else {
        liveAssessmentsCount++;
      }
    }

    let totalMarksEntries = marks.length;
    let enteredMarksCount = 0;
    let absentCount = 0;
    let notAppearedCount = 0;
    let exemptedCount = 0;
    let notEnteredCount = 0;

    let sumObtainedMarks = 0;
    let sumMaximumMarks = 0;

    let hasPassThreshold = false;
    let passedCount = 0;
    let failedCount = 0;

    // Build assessment map for rapid lookup
    const assessMap = new Map<string, any>();
    for (const a of assessments) {
      assessMap.set(a._id.toString(), a);
    }

    // Process marks with strict denominator-preserving mathematics
    for (const m of marks) {
      const assessment = assessMap.get(m.assessmentId.toString());
      const max = m.maximumMarks || assessment?.maximumMarks || 0;
      const passMarks = (m.passMarks !== undefined && m.passMarks !== null && m.passMarks > 0)
        ? m.passMarks
        : (assessment?.passMarks && assessment.passMarks > 0 ? assessment.passMarks : null);

      switch (m.status) {
        case StudentMarkStatus.ABSENT:
          absentCount++;
          // ABSENT is NOT zero; do not add to sumObtainedMarks or sumMaximumMarks
          break;
        case StudentMarkStatus.NOT_APPEARED:
          notAppearedCount++;
          break;
        case StudentMarkStatus.EXEMPTED:
          exemptedCount++;
          // EXEMPTED marks excluded from numerical averages by default
          break;
        case StudentMarkStatus.NOT_ENTERED:
          notEnteredCount++;
          break;
        case StudentMarkStatus.PRESENT:
        case StudentMarkStatus.ENTERED:
        default:
          if (m.marks !== null && m.marks !== undefined && typeof m.marks === 'number') {
            enteredMarksCount++;
            sumObtainedMarks += m.marks;
            sumMaximumMarks += max;

            if (passMarks !== null && passMarks > 0) {
              hasPassThreshold = true;
              if (m.marks >= passMarks) {
                passedCount++;
              } else {
                failedCount++;
              }
            }
          } else {
            notEnteredCount++;
          }
          break;
      }
    }

    // Denominator math: sum(obtained) / sum(maxMarks)
    const overallPercentage =
      sumMaximumMarks > 0 ? Math.round((sumObtainedMarks / sumMaximumMarks) * 10000) / 100 : null;

    const averageMarks =
      enteredMarksCount > 0 ? Math.round((sumObtainedMarks / enteredMarksCount) * 100) / 100 : null;

    const passRate =
      hasPassThreshold && (passedCount + failedCount) > 0
        ? Math.round((passedCount / (passedCount + failedCount)) * 10000) / 100
        : null;

    const participationRate =
      totalMarksEntries > 0
        ? Math.round(((enteredMarksCount + absentCount + notAppearedCount) / totalMarksEntries) * 10000) / 100
        : 0;

    // 3. Subject-wise Breakdown
    const subjectMap = new Map<string, {
      subjectId: string;
      subjectName: string;
      subjectCode: string;
      assessmentsCount: number;
      enteredMarksCount: number;
      absentCount: number;
      exemptedCount: number;
      sumObtainedMarks: number;
      sumMaximumMarks: number;
      passedCount: number;
      failedCount: number;
      hasPassThreshold: boolean;
    }>();

    for (const a of assessments) {
      if (!a.subjectId) continue;
      const subIdStr = (a.subjectId as any)._id?.toString() || a.subjectId.toString();
      const subName = (a.subjectId as any).name || 'Subject';
      const subCode = (a.subjectId as any).code || '';

      if (!subjectMap.has(subIdStr)) {
        subjectMap.set(subIdStr, {
          subjectId: subIdStr,
          subjectName: subName,
          subjectCode: subCode,
          assessmentsCount: 0,
          enteredMarksCount: 0,
          absentCount: 0,
          exemptedCount: 0,
          sumObtainedMarks: 0,
          sumMaximumMarks: 0,
          passedCount: 0,
          failedCount: 0,
          hasPassThreshold: false,
        });
      }
      subjectMap.get(subIdStr)!.assessmentsCount++;
    }

    for (const m of marks) {
      const assessment = assessMap.get(m.assessmentId.toString());
      if (!assessment?.subjectId) continue;
      const subIdStr = (assessment.subjectId as any)._id?.toString() || assessment.subjectId.toString();
      const subStats = subjectMap.get(subIdStr);
      if (!subStats) continue;

      const max = m.maximumMarks || assessment.maximumMarks || 0;
      const passMarks = (m.passMarks !== undefined && m.passMarks !== null && m.passMarks > 0)
        ? m.passMarks
        : (assessment.passMarks && assessment.passMarks > 0 ? assessment.passMarks : null);

      if (m.status === StudentMarkStatus.ABSENT) {
        subStats.absentCount++;
      } else if (m.status === StudentMarkStatus.EXEMPTED) {
        subStats.exemptedCount++;
      } else if (m.marks !== null && m.marks !== undefined && typeof m.marks === 'number') {
        subStats.enteredMarksCount++;
        subStats.sumObtainedMarks += m.marks;
        subStats.sumMaximumMarks += max;

        if (passMarks !== null && passMarks > 0) {
          subStats.hasPassThreshold = true;
          if (m.marks >= passMarks) {
            subStats.passedCount++;
          } else {
            subStats.failedCount++;
          }
        }
      }
    }

    const subjectsBreakdown = Array.from(subjectMap.values()).map((s) => ({
      subjectId: s.subjectId,
      subjectName: s.subjectName,
      subjectCode: s.subjectCode,
      assessmentsCount: s.assessmentsCount,
      enteredMarksCount: s.enteredMarksCount,
      absentCount: s.absentCount,
      exemptedCount: s.exemptedCount,
      sumObtainedMarks: Math.round(s.sumObtainedMarks * 100) / 100,
      sumMaximumMarks: s.sumMaximumMarks,
      percentage:
        s.sumMaximumMarks > 0 ? Math.round((s.sumObtainedMarks / s.sumMaximumMarks) * 10000) / 100 : null,
      hasPassThreshold: s.hasPassThreshold,
      passRate:
        s.hasPassThreshold && (s.passedCount + s.failedCount) > 0
          ? Math.round((s.passedCount / (s.passedCount + s.failedCount)) * 10000) / 100
          : null,
    }));

    // 4. Section-wise Breakdown
    const sectionMap = new Map<string, {
      sectionId: string;
      sectionName: string;
      assessmentsCount: number;
      enteredMarksCount: number;
      absentCount: number;
      sumObtainedMarks: number;
      sumMaximumMarks: number;
    }>();

    for (const a of assessments) {
      if (!a.sectionId) continue;
      const secIdStr = (a.sectionId as any)._id?.toString() || a.sectionId.toString();
      const secName = (a.sectionId as any).name || 'Section';

      if (!sectionMap.has(secIdStr)) {
        sectionMap.set(secIdStr, {
          sectionId: secIdStr,
          sectionName: secName,
          assessmentsCount: 0,
          enteredMarksCount: 0,
          absentCount: 0,
          sumObtainedMarks: 0,
          sumMaximumMarks: 0,
        });
      }
      sectionMap.get(secIdStr)!.assessmentsCount++;
    }

    for (const m of marks) {
      const assessment = assessMap.get(m.assessmentId.toString());
      if (!assessment?.sectionId) continue;
      const secIdStr = (assessment.sectionId as any)._id?.toString() || assessment.sectionId.toString();
      const secStats = sectionMap.get(secIdStr);
      if (!secStats) continue;

      const max = m.maximumMarks || assessment.maximumMarks || 0;

      if (m.status === StudentMarkStatus.ABSENT) {
        secStats.absentCount++;
      } else if (m.marks !== null && m.marks !== undefined && typeof m.marks === 'number') {
        secStats.enteredMarksCount++;
        secStats.sumObtainedMarks += m.marks;
        secStats.sumMaximumMarks += max;
      }
    }

    const sectionsBreakdown = Array.from(sectionMap.values()).map((sec) => ({
      sectionId: sec.sectionId,
      sectionName: sec.sectionName,
      assessmentsCount: sec.assessmentsCount,
      enteredMarksCount: sec.enteredMarksCount,
      absentCount: sec.absentCount,
      sumObtainedMarks: Math.round(sec.sumObtainedMarks * 100) / 100,
      sumMaximumMarks: sec.sumMaximumMarks,
      percentage:
        sec.sumMaximumMarks > 0 ? Math.round((sec.sumObtainedMarks / sec.sumMaximumMarks) * 10000) / 100 : null,
    }));

    // 5. Precision-Aware Attendance Overview for the scope
    let totalLiveHeld = 0;
    let totalLivePresent = 0;
    let totalHistHeld = 0;
    let totalHistPresent = 0;

    const summaryQuery: any = { collegeId };
    if (departmentId) summaryQuery.departmentId = departmentId;
    if (query.sectionId && Types.ObjectId.isValid(query.sectionId)) {
      summaryQuery.sectionId = new Types.ObjectId(query.sectionId);
    }
    if (query.subjectId && Types.ObjectId.isValid(query.subjectId)) {
      summaryQuery.subjectId = new Types.ObjectId(query.subjectId);
    }

    const summaries = await HistoricalAttendanceSummary.find(summaryQuery).lean();
    const historicalPercentageMetrics: Array<{ periodLabel: string; percentage: number; type: string }> = [];

    for (const s of summaries) {
      if (s.precisionLevel === 'PERIOD_SUMMARY' && s.classesHeld !== null && s.classesHeld !== undefined) {
        totalHistHeld += s.classesHeld;
        totalHistPresent += (s.presentCount ?? 0);
      } else if (s.precisionLevel === 'PERCENTAGE_ONLY') {
        historicalPercentageMetrics.push({
          periodLabel: s.periodLabel,
          percentage: s.attendancePercentage,
          type: 'PERCENTAGE_ONLY',
        });
      }
    }

    const attendanceTotalHeld = totalLiveHeld + totalHistHeld;
    const attendanceTotalPresent = totalLivePresent + totalHistPresent;
    const attendanceTotalAbsent = attendanceTotalHeld - attendanceTotalPresent;
    const attendancePercentage =
      attendanceTotalHeld > 0 ? Math.round((attendanceTotalPresent / attendanceTotalHeld) * 10000) / 100 : 0;

    return {
      scope: {
        collegeId: collegeId.toString(),
        departmentId: departmentId?.toString(),
      },
      overview: {
        totalAssessments: assessments.length,
        liveAssessmentsCount,
        importedAssessmentsCount,
        historicalManualAssessmentsCount,
        totalMarksEntries,
        enteredMarksCount,
        absentCount,
        notAppearedCount,
        exemptedCount,
        notEnteredCount,
        sumObtainedMarks: Math.round(sumObtainedMarks * 100) / 100,
        sumMaximumMarks,
        overallPercentage,
        averageMarks,
        hasPassThreshold,
        passedCount,
        failedCount,
        passRate,
        participationRate,
      },
      subjectsBreakdown,
      sectionsBreakdown,
      attendanceOverview: {
        detailedMetrics: {
          totalHeld: attendanceTotalHeld,
          totalPresent: attendanceTotalPresent,
          totalAbsent: attendanceTotalAbsent,
          percentage: attendancePercentage,
          liveHeld: totalLiveHeld,
          livePresent: totalLivePresent,
          historicalDetailedHeld: totalHistHeld,
          historicalDetailedPresent: totalHistPresent,
        },
        historicalPercentageMetrics,
        hasDetailedData: attendanceTotalHeld > 0,
        hasPercentageOnlyData: historicalPercentageMetrics.length > 0,
      },
    };
  }
}
