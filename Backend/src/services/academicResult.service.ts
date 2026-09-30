import { Types } from 'mongoose';
import {
  AcademicResult,
  IAcademicResult,
  ISubjectResult,
  IResultSummary,
  IPublicationSnapshot,
  AcademicRuleConfiguration,
  IAcademicRuleConfiguration,
  AcademicRecord,
  SubjectAcademicRecord,
  InternalAssessment,
  StudentEnrollment,
  Student,
  Subject,
} from '../models';
import {
  ResultLifecycleStatus,
  SubjectResultStatus,
  OverallResultStatus,
  isValidResultTransition,
  IGradeDefinition,
} from '../constants/academicResult.constants';
import { AppRole } from '../constants/roles';
import { NotificationService } from './notification.service';
import { NotificationType, NotificationCategory, NotificationPriority } from '../constants/notification.constants';
import { realtimeEventBus } from '../realtime/realtimeEventBus';
import { AcadexEventType } from '../realtime/contracts/eventRegistry';
import { Logger } from '../utils/logger';

export interface IValidationFailure {
  subjectId: string;
  subjectCode: string;
  subjectName: string;
  reason: string;
}

export class AcademicResultService {
  /**
   * Resolves effective rule configuration for a course or college default
   */
  static async getEffectiveRuleConfig(
    collegeId: string | Types.ObjectId,
    courseId?: string | Types.ObjectId | null
  ): Promise<IAcademicRuleConfiguration | null> {
    const cId = new Types.ObjectId(collegeId);

    // 1. Try course-specific rule
    if (courseId) {
      const courseRule = await AcademicRuleConfiguration.findOne({
        collegeId: cId,
        courseId: new Types.ObjectId(courseId),
        isConfigured: true,
      });
      if (courseRule) return courseRule;
    }

    // 2. Try college default rule
    const defaultRule = await AcademicRuleConfiguration.findOne({
      collegeId: cId,
      isDefault: true,
      isConfigured: true,
    });
    if (defaultRule) return defaultRule;

    // 3. Fallback to any configured rule for this college
    return AcademicRuleConfiguration.findOne({
      collegeId: cId,
      isConfigured: true,
    });
  }

  /**
   * Helper to evaluate a numerical percentage against configured grading scale
   */
  static matchGrade(
    percentage: number,
    gradingScale: IGradeDefinition[]
  ): { grade: string | null; gradePoint: number | null; isPassing: boolean } {
    if (!gradingScale || gradingScale.length === 0) {
      return { grade: null, gradePoint: null, isPassing: true };
    }

    // Sort descending by minPercentage
    const sorted = [...gradingScale].sort((a, b) => b.minPercentage - a.minPercentage);

    for (const def of sorted) {
      // Allow a tiny epsilon (0.001) for boundary floating point safety
      if (percentage >= def.minPercentage - 0.001 && percentage <= def.maxPercentage + 0.001) {
        return {
          grade: def.grade,
          gradePoint: def.gradePoint,
          isPassing: def.isPassing,
        };
      }
    }

    // If below lowest threshold, check if there is an explicit lowest failing grade
    const lowest = sorted[sorted.length - 1];
    if (percentage < lowest.minPercentage) {
      return {
        grade: lowest.grade,
        gradePoint: lowest.gradePoint,
        isPassing: lowest.isPassing,
      };
    }

    return { grade: null, gradePoint: null, isPassing: true };
  }

  /**
   * Calculates or recalculates a student's semester academic result
   */
  static async calculateSemesterResult(params: {
    collegeId: string | Types.ObjectId;
    studentId: string | Types.ObjectId;
    semesterId: string | Types.ObjectId;
    academicYearId: string | Types.ObjectId;
    user: { id: string; name?: string; role?: string };
    courseId?: string | Types.ObjectId;
  }): Promise<{ result: IAcademicResult; warnings: string[] }> {
    const collegeId = new Types.ObjectId(params.collegeId);
    const studentId = new Types.ObjectId(params.studentId);
    const semesterId = new Types.ObjectId(params.semesterId);
    const academicYearId = new Types.ObjectId(params.academicYearId);
    const warnings: string[] = [];

    // 1. Resolve AcademicRecord
    let academicRecord = await AcademicRecord.findOne({
      collegeId,
      studentId,
      academicYearId,
      semesterId,
    });

    // If not found, attempt to find through active StudentEnrollment
    let enrollment = null;
    if (!academicRecord) {
      enrollment = await StudentEnrollment.findOne({
        collegeId,
        studentId,
        semesterId,
        status: 'active',
      });

      if (!enrollment) {
        throw new Error('Student has no active enrollment or academic record for this semester.');
      }

      // Auto-initialize academic record if absent
      academicRecord = await AcademicRecord.create({
        collegeId,
        studentId,
        studentEnrollmentId: enrollment._id,
        departmentId: enrollment.departmentId,
        courseId: enrollment.courseId,
        academicYearId,
        semesterId,
        sectionId: enrollment.sectionId || null,
        academicStage: enrollment.academicStage || null,
        cohort: enrollment.cohort || null,
      });
    } else {
      enrollment = await StudentEnrollment.findById(academicRecord.studentEnrollmentId);
    }

    const courseId = academicRecord.courseId;
    const departmentId = academicRecord.departmentId;
    const sectionId = academicRecord.sectionId;

    // 2. Resolve Academic Rule Configuration (Mandatory Prerequisite)
    const ruleConfig = await this.getEffectiveRuleConfig(collegeId, courseId);
    if (!ruleConfig || !ruleConfig.isConfigured || !ruleConfig.gradingScale || ruleConfig.gradingScale.length === 0) {
      throw new Error('Result grading rules are not configured for this academic program.');
    }

    // 3. Resolve Enrolled Subjects from SubjectAcademicRecord
    let subjectRecords = await SubjectAcademicRecord.find({
      collegeId,
      academicRecordId: academicRecord._id,
    }).populate('subjectId');

    // If SubjectAcademicRecords are empty, populate from course/semester subjects
    if (subjectRecords.length === 0) {
      const defaultSubjects = await Subject.find({
        collegeId,
        courseId,
        semesterId,
        status: 'active',
      });

      if (defaultSubjects.length === 0) {
        throw new Error('No enrolled subjects found for this academic period.');
      }

      const createdRecords = [];
      for (const subj of defaultSubjects) {
        const sr = await SubjectAcademicRecord.create({
          collegeId,
          academicRecordId: academicRecord._id,
          studentId,
          subjectId: subj._id,
          credits: subj.credits || 0,
        });
        createdRecords.push(await sr.populate('subjectId'));
      }
      subjectRecords = createdRecords;
    }

    // 4. Existing AcademicResult Check & Concurrency Lock
    let result = await AcademicResult.findOne({
      collegeId,
      studentId,
      academicYearId,
      semesterId,
    });

    if (result) {
      if (
        result.status === ResultLifecycleStatus.FINALIZED ||
        result.status === ResultLifecycleStatus.PUBLISHED
      ) {
        throw new Error(
          'This academic result is finalized and locked. It must be officially reopened before recalculation.'
        );
      }
    }

    // 5. Calculate Subject Results
    const subjectResults: ISubjectResult[] = [];
    let totalCreditsAttempted = 0;
    let totalCreditsEarned = 0;
    let totalMaxMarks = 0;
    let totalObtainedMarks = 0;
    let passedCount = 0;
    let failedCount = 0;
    let incompleteCount = 0;

    for (const sr of subjectRecords) {
      const subjDoc = sr.subjectId as any;
      if (!subjDoc) continue;

      const subjectId = subjDoc._id ? subjDoc._id : subjDoc;
      const subjectCode = subjDoc.code || 'SUBJ';
      const subjectName = subjDoc.name || 'Subject';
      const subjectType = subjDoc.type || 'theory';
      const credits = Number(sr.credits || subjDoc.credits || 0);

      // Query published assessments for this subject in this semester
      const assessmentQuery: any = {
        collegeId,
        subjectId,
        semesterId,
        academicYearId,
        status: 'PUBLISHED',
      };
      if (sectionId) {
        assessmentQuery.$or = [{ sectionId }, { sectionId: null }, { sectionId: { $exists: false } }];
      }

      const publishedAssessments = await InternalAssessment.find(assessmentQuery);

      let subjObtained = 0;
      let subjMax = 0;
      const assessmentsIncluded = [];

      for (const assess of publishedAssessments) {
        const studentEntry = assess.entries.find(
          (e) => e.studentId.toString() === studentId.toString()
        );

        if (studentEntry) {
          const obtained = Number(studentEntry.totalMarks || 0);
          const max = Number(assess.maximumMarks || 50);

          assessmentsIncluded.push({
            assessmentId: assess._id,
            title: assess.title || 'Internal Assessment',
            assessmentType: assess.assessmentType || 'INTERNAL_EXAM',
            maximumMarks: max,
            obtainedMarks: obtained,
            status: studentEntry.status || 'ENTERED',
          });

          subjObtained += obtained;
          subjMax += max;
        }
      }

      // Check if assessments are missing
      let subjStatus = SubjectResultStatus.INCOMPLETE;
      let percentage = 0;
      let earnedCredits = 0;
      let matchedGrade = null;
      let matchedGradePoint = null;

      if (assessmentsIncluded.length === 0) {
        warnings.push(`Subject ${subjectCode} (${subjectName}) has no published assessments.`);
        incompleteCount++;
      } else {
        // Percentage calculation (safe decimal round to 2 places)
        percentage = subjMax > 0 ? Math.round((subjObtained / subjMax) * 10000) / 100 : 0;

        // Match Grade
        const gradeResult = this.matchGrade(percentage, ruleConfig.gradingScale);
        matchedGrade = gradeResult.grade;
        matchedGradePoint = gradeResult.gradePoint;

        // Evaluate Pass/Fail
        const minPassPercentage = ruleConfig.passCriteria?.minSubjectPercentage ?? 40;
        const isGradePassing = gradeResult.isPassing;
        const isScorePassing = percentage >= minPassPercentage;

        if (isScorePassing && isGradePassing) {
          subjStatus = SubjectResultStatus.PASS;
          earnedCredits = credits;
          passedCount++;
        } else {
          subjStatus = SubjectResultStatus.FAIL;
          earnedCredits = 0;
          failedCount++;
        }
      }

      totalCreditsAttempted += credits;
      totalCreditsEarned += earnedCredits;
      totalMaxMarks += subjMax;
      totalObtainedMarks += subjObtained;

      subjectResults.push({
        subjectId,
        subjectCode,
        subjectName,
        subjectType,
        credits,
        totalMaxMarks: Math.round(subjMax * 100) / 100,
        totalObtainedMarks: Math.round(subjObtained * 100) / 100,
        percentage,
        grade: matchedGrade,
        gradePoint: matchedGradePoint,
        status: subjStatus,
        earnedCredits,
        assessmentsIncluded,
      });
    }

    // 6. Overall Semester Summary & Status
    const overallPercentage =
      totalMaxMarks > 0 ? Math.round((totalObtainedMarks / totalMaxMarks) * 10000) / 100 : null;

    let overallResult = OverallResultStatus.PASS;
    if (incompleteCount > 0) {
      overallResult = OverallResultStatus.INCOMPLETE;
    } else if (failedCount > 0) {
      overallResult = OverallResultStatus.FAIL;
    }

    // 7. GPA Calculation (only if configured!)
    let gpa: number | null = null;
    if (ruleConfig.gpaPolicy?.enabled) {
      if (ruleConfig.gpaPolicy.formula === 'CREDIT_WEIGHTED') {
        let weightedPoints = 0;
        let totalCountedCredits = 0;

        for (const sr of subjectResults) {
          if (sr.gradePoint !== null && sr.gradePoint !== undefined && sr.credits > 0) {
            weightedPoints += sr.gradePoint * sr.credits;
            totalCountedCredits += sr.credits;
          }
        }

        if (totalCountedCredits > 0) {
          gpa = Math.round((weightedPoints / totalCountedCredits) * 100) / 100;
        }
      } else {
        // Simple Average
        const points = subjectResults
          .map((sr) => sr.gradePoint)
          .filter((gp): gp is number => gp !== null);
        if (points.length > 0) {
          const sum = points.reduce((acc, p) => acc + p, 0);
          gpa = Math.round((sum / points.length) * 100) / 100;
        }
      }
    }

    // 8. CGPA Calculation (only if configured!)
    let cgpa: number | null = null;
    if (ruleConfig.cgpaPolicy?.enabled) {
      const priorResults = await AcademicResult.find({
        collegeId,
        studentId,
        courseId,
        status: { $in: [ResultLifecycleStatus.FINALIZED, ResultLifecycleStatus.PUBLISHED] },
        semesterId: { $ne: semesterId },
      });

      let cumulativeWeightedPoints = 0;
      let cumulativeCredits = 0;

      // Add prior results
      for (const pr of priorResults) {
        if (pr.summary?.gpa !== null && pr.summary?.gpa !== undefined && pr.summary?.totalCreditsAttempted) {
          cumulativeWeightedPoints += pr.summary.gpa * pr.summary.totalCreditsAttempted;
          cumulativeCredits += pr.summary.totalCreditsAttempted;
        }
      }

      // Add current result
      if (gpa !== null && totalCreditsAttempted > 0) {
        cumulativeWeightedPoints += gpa * totalCreditsAttempted;
        cumulativeCredits += totalCreditsAttempted;
      }

      if (cumulativeCredits > 0) {
        cgpa = Math.round((cumulativeWeightedPoints / cumulativeCredits) * 100) / 100;
      }
    }

    const summary: IResultSummary = {
      totalSubjects: subjectResults.length,
      passedSubjects: passedCount,
      failedSubjects: failedCount,
      incompleteSubjects: incompleteCount,
      totalCreditsAttempted,
      totalCreditsEarned,
      totalMaxMarks: Math.round(totalMaxMarks * 100) / 100,
      totalObtainedMarks: Math.round(totalObtainedMarks * 100) / 100,
      percentage: overallPercentage,
      gpa,
      cgpa,
      overallResult,
    };

    const ruleSnapshot = {
      ruleId: ruleConfig._id.toString(),
      ruleName: ruleConfig.name,
      gradingScale: ruleConfig.gradingScale,
      passCriteria: ruleConfig.passCriteria,
      gpaPolicy: ruleConfig.gpaPolicy,
      cgpaPolicy: ruleConfig.cgpaPolicy,
    };

    // 9. Persist / Update AcademicResult
    if (!result) {
      result = await AcademicResult.create({
        collegeId,
        studentId,
        academicRecordId: academicRecord._id,
        studentEnrollmentId: enrollment?._id || academicRecord.studentEnrollmentId,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
        sectionId: sectionId || null,
        academicStage: academicRecord.academicStage,
        status: ResultLifecycleStatus.CALCULATED,
        version: 1,
        summary,
        subjectResults,
        ruleConfigurationId: ruleConfig._id,
        ruleSnapshot,
        calculatedAt: new Date(),
        calculatedBy: new Types.ObjectId(params.user.id),
        auditLog: [
          {
            action: 'CALCULATED',
            performedBy: new Types.ObjectId(params.user.id),
            performedByName: params.user.name || 'User',
            performedByRole: params.user.role || 'ADMIN',
            timestamp: new Date(),
            details: `Calculated semester result v1: ${overallResult} (${passedCount}/${subjectResults.length} passed)`,
          },
        ],
      });
    } else {
      result.summary = summary;
      result.subjectResults = subjectResults;
      result.ruleConfigurationId = ruleConfig._id;
      result.ruleSnapshot = ruleSnapshot;
      result.calculatedAt = new Date();
      result.calculatedBy = new Types.ObjectId(params.user.id);
      result.status = ResultLifecycleStatus.CALCULATED;

      result.auditLog.push({
        action: 'RECALCULATED',
        performedBy: new Types.ObjectId(params.user.id),
        performedByName: params.user.name || 'User',
        performedByRole: params.user.role || 'ADMIN',
        timestamp: new Date(),
        details: `Recalculated semester result v${result.version}: ${overallResult}`,
      });

      await result.save();
    }

    // 10. Emit Realtime Event
    try {
      await realtimeEventBus.publish({
        eventId: new Types.ObjectId().toString(),
        eventVersion: 1,
        eventType: AcadexEventType.ACADEMIC_RESULT_CALCULATED,
        aggregateType: 'AcademicResult',
        aggregateId: result._id.toString(),
        action: 'CREATED',
        occurredAt: new Date().toISOString(),
        collegeId: collegeId.toString(),
        scope: {
          type: 'department',
          collegeId: collegeId.toString(),
          departmentId: departmentId.toString(),
        },
        payload: {
          resultId: result._id.toString(),
          studentId: studentId.toString(),
          semesterId: semesterId.toString(),
          status: result.status,
          overallResult,
          gpa,
        },
      });
    } catch (e) {
      Logger.warn('Failed to emit ACADEMIC_RESULT_CALCULATED realtime event', e);
    }

    return { result, warnings };
  }

  /**
   * Bulk calculates semester results for an entire class / section
   */
  static async calculateClassResults(params: {
    collegeId: string | Types.ObjectId;
    courseId: string | Types.ObjectId;
    semesterId: string | Types.ObjectId;
    academicYearId: string | Types.ObjectId;
    sectionId?: string | Types.ObjectId | null;
    user: { id: string; name?: string; role?: string };
  }): Promise<{
    totalEnrolled: number;
    calculatedCount: number;
    incompleteCount: number;
    failedCount: number;
    warnings: Array<{ studentId: string; studentName: string; warnings: string[] }>;
  }> {
    const collegeId = new Types.ObjectId(params.collegeId);
    const courseId = new Types.ObjectId(params.courseId);
    const semesterId = new Types.ObjectId(params.semesterId);
    const academicYearId = new Types.ObjectId(params.academicYearId);

    const enrollQuery: any = {
      collegeId,
      courseId,
      semesterId,
      status: 'active',
    };
    if (params.sectionId) {
      enrollQuery.sectionId = new Types.ObjectId(params.sectionId);
    }

    const enrollments = await StudentEnrollment.find(enrollQuery).populate('studentId');
    let calculatedCount = 0;
    let incompleteCount = 0;
    let failedCount = 0;
    const warningsList: Array<{ studentId: string; studentName: string; warnings: string[] }> = [];

    for (const enroll of enrollments) {
      const studentDoc = enroll.studentId as any;
      if (!studentDoc) continue;

      const studentId = studentDoc._id ? studentDoc._id : studentDoc;
      const studentName = studentDoc.name || 'Student';

      try {
        const { result, warnings } = await this.calculateSemesterResult({
          collegeId,
          studentId,
          semesterId,
          academicYearId,
          courseId,
          user: params.user,
        });

        calculatedCount++;
        if (result.summary.overallResult === OverallResultStatus.INCOMPLETE) {
          incompleteCount++;
        } else if (result.summary.overallResult === OverallResultStatus.FAIL) {
          failedCount++;
        }

        if (warnings.length > 0) {
          warningsList.push({
            studentId: studentId.toString(),
            studentName,
            warnings,
          });
        }
      } catch (err: any) {
        warningsList.push({
          studentId: studentId.toString(),
          studentName,
          warnings: [err.message || 'Calculation error'],
        });
      }
    }

    return {
      totalEnrolled: enrollments.length,
      calculatedCount,
      incompleteCount,
      failedCount,
      warnings: warningsList,
    };
  }

  /**
   * Moves a calculated result to UNDER_REVIEW
   */
  static async reviewResult(params: {
    collegeId: string | Types.ObjectId;
    resultId: string | Types.ObjectId;
    user: { id: string; name?: string; role?: string };
    reviewNotes?: string | null;
  }): Promise<IAcademicResult> {
    const result = await AcademicResult.findOne({
      _id: new Types.ObjectId(params.resultId),
      collegeId: new Types.ObjectId(params.collegeId),
    });

    if (!result) throw new Error('Academic result not found.');

    if (!isValidResultTransition(result.status, ResultLifecycleStatus.UNDER_REVIEW)) {
      throw new Error(`Cannot transition result from ${result.status} to UNDER_REVIEW.`);
    }

    result.status = ResultLifecycleStatus.UNDER_REVIEW;
    result.reviewedAt = new Date();
    result.reviewedBy = new Types.ObjectId(params.user.id);
    result.reviewNotes = params.reviewNotes || null;

    result.auditLog.push({
      action: 'REVIEWED',
      performedBy: new Types.ObjectId(params.user.id),
      performedByName: params.user.name || 'Reviewer',
      performedByRole: params.user.role || 'HOD',
      timestamp: new Date(),
      details: params.reviewNotes ? `Review notes: ${params.reviewNotes}` : 'Marked as under review',
    });

    await result.save();

    try {
      await realtimeEventBus.publish({
        eventId: new Types.ObjectId().toString(),
        eventVersion: 1,
        eventType: AcadexEventType.ACADEMIC_RESULT_UNDER_REVIEW,
        aggregateType: 'AcademicResult',
        aggregateId: result._id.toString(),
        action: 'UPDATED',
        occurredAt: new Date().toISOString(),
        collegeId: result.collegeId.toString(),
        scope: {
          type: 'department',
          collegeId: result.collegeId.toString(),
          departmentId: result.departmentId.toString(),
        },
        payload: {
          resultId: result._id.toString(),
          studentId: result.studentId.toString(),
          semesterId: result.semesterId.toString(),
          status: result.status,
        },
      });
    } catch (e) {
      Logger.warn('Failed to emit ACADEMIC_RESULT_UNDER_REVIEW event', e);
    }

    return result;
  }

  /**
   * Finalizes an academic result (locks for ordinary modification)
   */
  static async finalizeResult(params: {
    collegeId: string | Types.ObjectId;
    resultId: string | Types.ObjectId;
    user: { id: string; name?: string; role?: string };
    reviewNotes?: string | null;
  }): Promise<IAcademicResult> {
    const result = await AcademicResult.findOne({
      _id: new Types.ObjectId(params.resultId),
      collegeId: new Types.ObjectId(params.collegeId),
    });

    if (!result) throw new Error('Academic result not found.');

    if (!isValidResultTransition(result.status, ResultLifecycleStatus.FINALIZED)) {
      throw new Error(`Cannot transition result from ${result.status} to FINALIZED.`);
    }

    // Critical Requirement: DO NOT finalize incomplete results!
    const incompleteSubjects = result.subjectResults.filter(
      (sr) => sr.status === SubjectResultStatus.INCOMPLETE
    );
    if (incompleteSubjects.length > 0) {
      const details = incompleteSubjects
        .map((s) => `${s.subjectCode} (${s.subjectName}): published assessments incomplete`)
        .join(', ');
      throw new Error(`Cannot finalize result with incomplete subjects: ${details}`);
    }

    result.status = ResultLifecycleStatus.FINALIZED;
    result.finalizedAt = new Date();
    result.finalizedBy = new Types.ObjectId(params.user.id);
    if (params.reviewNotes) {
      result.reviewNotes = params.reviewNotes;
    }

    result.auditLog.push({
      action: 'FINALIZED',
      performedBy: new Types.ObjectId(params.user.id),
      performedByName: params.user.name || 'Finalizer',
      performedByRole: params.user.role || 'ADMIN',
      timestamp: new Date(),
      details: `Result v${result.version} finalized and locked. Overall: ${result.summary.overallResult}`,
    });

    await result.save();

    try {
      await realtimeEventBus.publish({
        eventId: new Types.ObjectId().toString(),
        eventVersion: 1,
        eventType: AcadexEventType.ACADEMIC_RESULT_FINALIZED,
        aggregateType: 'AcademicResult',
        aggregateId: result._id.toString(),
        action: 'UPDATED',
        occurredAt: new Date().toISOString(),
        collegeId: result.collegeId.toString(),
        scope: {
          type: 'department',
          collegeId: result.collegeId.toString(),
          departmentId: result.departmentId.toString(),
        },
        payload: {
          resultId: result._id.toString(),
          studentId: result.studentId.toString(),
          semesterId: result.semesterId.toString(),
          status: result.status,
          version: result.version,
        },
      });
    } catch (e) {
      Logger.warn('Failed to emit ACADEMIC_RESULT_FINALIZED event', e);
    }

    return result;
  }

  /**
   * Officially publishes a finalized result to students
   */
  static async publishResult(params: {
    collegeId: string | Types.ObjectId;
    resultId: string | Types.ObjectId;
    user: { id: string; name?: string; role?: string };
    publicationNotes?: string | null;
  }): Promise<IAcademicResult> {
    const result = await AcademicResult.findOne({
      _id: new Types.ObjectId(params.resultId),
      collegeId: new Types.ObjectId(params.collegeId),
    });

    if (!result) throw new Error('Academic result not found.');

    if (result.status !== ResultLifecycleStatus.FINALIZED) {
      throw new Error(`Only FINALIZED results can be published. Current status: ${result.status}.`);
    }

    const publishedAt = new Date();
    const publishedBy = new Types.ObjectId(params.user.id);
    const publishedByName = params.user.name || 'Official Publisher';

    // Create Immutable Historical Publication Snapshot
    const snapshot: IPublicationSnapshot = {
      version: result.version,
      publishedAt,
      publishedBy,
      publishedByName,
      summary: JSON.parse(JSON.stringify(result.summary)),
      subjectResults: JSON.parse(JSON.stringify(result.subjectResults)),
      ruleSnapshot: JSON.parse(JSON.stringify(result.ruleSnapshot || {})),
    };

    result.status = ResultLifecycleStatus.PUBLISHED;
    result.publishedAt = publishedAt;
    result.publishedBy = publishedBy;
    result.currentPublishedSnapshot = snapshot;
    result.publicationSnapshots.push(snapshot);

    result.auditLog.push({
      action: 'PUBLISHED',
      performedBy: publishedBy,
      performedByName: publishedByName,
      performedByRole: params.user.role || 'ADMIN',
      timestamp: publishedAt,
      details: `Official publication of semester result Version ${result.version}.`,
    });

    await result.save();

    // Emit Realtime Event to student and department
    try {
      await realtimeEventBus.publish({
        eventId: new Types.ObjectId().toString(),
        eventVersion: 1,
        eventType: AcadexEventType.ACADEMIC_RESULT_PUBLISHED,
        aggregateType: 'AcademicResult',
        aggregateId: result._id.toString(),
        action: 'UPDATED',
        occurredAt: new Date().toISOString(),
        collegeId: result.collegeId.toString(),
        scope: {
          type: 'user',
          collegeId: result.collegeId.toString(),
          userId: result.studentId.toString(),
        },
        payload: {
          resultId: result._id.toString(),
          studentId: result.studentId.toString(),
          semesterId: result.semesterId.toString(),
          version: result.version,
          publishedAt: publishedAt.toISOString(),
        },
      });
    } catch (e) {
      Logger.warn('Failed to emit ACADEMIC_RESULT_PUBLISHED event', e);
    }

    // Persistent Notification to Student
    try {
      const student = await Student.findById(result.studentId);
      if (student && student.userId) {
        await NotificationService.createNotification({
          collegeId: result.collegeId.toString(),
          recipientUserId: student.userId.toString(),
          recipientRole: AppRole.STUDENT,
          notificationType: NotificationType.ACADEMIC_RESULT_PUBLISHED,
          category: NotificationCategory.ACADEMIC,
          priority: NotificationPriority.HIGH,
          title: 'Official Academic Results Published',
          body: `Your official semester results (Version ${result.version}) have been published and are available to view.`,
          deepLink: `/academic-results/${result._id}`,
          metadata: {
            resultId: result._id.toString(),
            semesterId: result.semesterId.toString(),
            version: result.version,
            overallResult: result.summary.overallResult,
          },
        });
      }
    } catch (e) {
      Logger.warn('Failed to send result publication notification', e);
    }

    return result;
  }

  /**
   * Controlled administrative reopening of a finalized or published result
   */
  static async reopenResult(params: {
    collegeId: string | Types.ObjectId;
    resultId: string | Types.ObjectId;
    user: { id: string; name?: string; role?: string };
    reason: string;
  }): Promise<IAcademicResult> {
    if (!params.reason || params.reason.trim().length < 5) {
      throw new Error('A valid reopening reason of at least 5 characters is required.');
    }

    const result = await AcademicResult.findOne({
      _id: new Types.ObjectId(params.resultId),
      collegeId: new Types.ObjectId(params.collegeId),
    });

    if (!result) throw new Error('Academic result not found.');

    if (
      result.status !== ResultLifecycleStatus.FINALIZED &&
      result.status !== ResultLifecycleStatus.PUBLISHED
    ) {
      throw new Error(`Only FINALIZED or PUBLISHED results can be reopened. Current: ${result.status}.`);
    }

    const previousStatus = result.status;
    const previousVersion = result.version;
    const reopenedAt = new Date();

    result.reopenHistory.push({
      reopenedAt,
      reopenedBy: new Types.ObjectId(params.user.id),
      reopenedByName: params.user.name || 'Admin',
      reopenedByRole: params.user.role || 'ADMIN',
      reason: params.reason.trim(),
      previousVersion,
      previousStatus,
    });

    // Version increments so subsequent calculation creates Version N+1
    result.version = previousVersion + 1;
    result.status = ResultLifecycleStatus.REOPENED;

    result.auditLog.push({
      action: 'REOPENED',
      performedBy: new Types.ObjectId(params.user.id),
      performedByName: params.user.name || 'Admin',
      performedByRole: params.user.role || 'ADMIN',
      timestamp: reopenedAt,
      details: `Reopened for correction. Reason: ${params.reason.trim()} (Bumping to version ${result.version})`,
    });

    await result.save();

    try {
      await realtimeEventBus.publish({
        eventId: new Types.ObjectId().toString(),
        eventVersion: 1,
        eventType: AcadexEventType.ACADEMIC_RESULT_REOPENED,
        aggregateType: 'AcademicResult',
        aggregateId: result._id.toString(),
        action: 'UPDATED',
        occurredAt: new Date().toISOString(),
        collegeId: result.collegeId.toString(),
        scope: {
          type: 'department',
          collegeId: result.collegeId.toString(),
          departmentId: result.departmentId.toString(),
        },
        payload: {
          resultId: result._id.toString(),
          studentId: result.studentId.toString(),
          semesterId: result.semesterId.toString(),
          version: result.version,
          reason: params.reason.trim(),
        },
      });
    } catch (e) {
      Logger.warn('Failed to emit ACADEMIC_RESULT_REOPENED event', e);
    }

    return result;
  }

  /**
   * Student View: Returns ONLY the latest official published snapshot
   */
  static async getStudentOfficialResult(params: {
    collegeId: string | Types.ObjectId;
    studentUserId: string | Types.ObjectId;
    semesterId?: string | Types.ObjectId;
    academicYearId?: string | Types.ObjectId;
  }): Promise<{
    hasPublishedResult: boolean;
    result: {
      resultId: string;
      academicYearId: string;
      semesterId: string;
      academicStage?: string | null;
      version: number;
      publishedAt: Date;
      summary: IResultSummary;
      subjectResults: Array<{
        subjectCode: string;
        subjectName: string;
        subjectType: string;
        credits: number;
        totalMaxMarks: number;
        totalObtainedMarks: number;
        percentage: number;
        grade: string | null;
        gradePoint: number | null;
        status: SubjectResultStatus;
        earnedCredits: number;
      }>;
    } | null;
  }> {
    const collegeId = new Types.ObjectId(params.collegeId);
    const student = await Student.findOne({
      collegeId,
      userId: new Types.ObjectId(params.studentUserId),
    });

    if (!student) {
      return { hasPublishedResult: false, result: null };
    }

    const query: any = {
      collegeId,
      studentId: student._id,
      currentPublishedSnapshot: { $ne: null },
    };

    if (params.semesterId) query.semesterId = new Types.ObjectId(params.semesterId);
    if (params.academicYearId) query.academicYearId = new Types.ObjectId(params.academicYearId);

    const doc = await AcademicResult.findOne(query).sort({ 'currentPublishedSnapshot.publishedAt': -1 });

    if (!doc || !doc.currentPublishedSnapshot) {
      return { hasPublishedResult: false, result: null };
    }

    const snapshot = doc.currentPublishedSnapshot;

    // Filter out internal technical IDs from subject results
    const publicSubjects = snapshot.subjectResults.map((sr) => ({
      subjectCode: sr.subjectCode,
      subjectName: sr.subjectName,
      subjectType: sr.subjectType,
      credits: sr.credits,
      totalMaxMarks: sr.totalMaxMarks,
      totalObtainedMarks: sr.totalObtainedMarks,
      percentage: sr.percentage,
      grade: sr.grade || null,
      gradePoint: sr.gradePoint ?? null,
      status: sr.status,
      earnedCredits: sr.earnedCredits,
    }));

    return {
      hasPublishedResult: true,
      result: {
        resultId: doc._id.toString(),
        academicYearId: doc.academicYearId.toString(),
        semesterId: doc.semesterId.toString(),
        academicStage: doc.academicStage || null,
        version: snapshot.version,
        publishedAt: snapshot.publishedAt,
        summary: snapshot.summary,
        subjectResults: publicSubjects,
      },
    };
  }

  /**
   * Admin / HOD View: Query Academic Results with status and readiness metrics
   */
  static async queryAdminResults(params: {
    collegeId: string | Types.ObjectId;
    user: { id: string; role?: string; departmentId?: string };
    courseId?: string;
    semesterId?: string;
    academicYearId?: string;
    departmentId?: string;
    sectionId?: string;
    status?: ResultLifecycleStatus;
    studentId?: string;
    page?: number;
    limit?: number;
  }): Promise<{
    results: any[];
    pagination: { total: number; page: number; limit: number; totalPages: number };
    metrics: {
      total: number;
      draftCount: number;
      calculatedCount: number;
      underReviewCount: number;
      finalizedCount: number;
      publishedCount: number;
      reopenedCount: number;
    };
  }> {
    const collegeId = new Types.ObjectId(params.collegeId);
    const filter: any = { collegeId };

    // HOD role scope enforcement
    if (params.user.role === 'hod') {
      if (params.user.departmentId) {
        filter.departmentId = new Types.ObjectId(params.user.departmentId);
      }
    } else if (params.departmentId) {
      filter.departmentId = new Types.ObjectId(params.departmentId);
    }

    if (params.courseId) filter.courseId = new Types.ObjectId(params.courseId);
    if (params.semesterId) filter.semesterId = new Types.ObjectId(params.semesterId);
    if (params.academicYearId) filter.academicYearId = new Types.ObjectId(params.academicYearId);
    if (params.sectionId) filter.sectionId = new Types.ObjectId(params.sectionId);
    if (params.status) filter.status = params.status;
    if (params.studentId) filter.studentId = new Types.ObjectId(params.studentId);

    const page = params.page || 1;
    const limit = params.limit || 50;
    const skip = (page - 1) * limit;

    const [results, total, statusAgg] = await Promise.all([
      AcademicResult.find(filter)
        .populate('studentId', 'name rollNumber admissionNumber')
        .populate('courseId', 'name code')
        .populate('semesterId', 'name number')
        .sort({ updatedAt: -1 })
        .skip(skip)
        .limit(limit),
      AcademicResult.countDocuments(filter),
      AcademicResult.aggregate([
        { $match: { collegeId } },
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),
    ]);

    const metrics = {
      total,
      draftCount: 0,
      calculatedCount: 0,
      underReviewCount: 0,
      finalizedCount: 0,
      publishedCount: 0,
      reopenedCount: 0,
    };

    for (const item of statusAgg) {
      if (item._id === ResultLifecycleStatus.DRAFT) metrics.draftCount = item.count;
      if (item._id === ResultLifecycleStatus.CALCULATED) metrics.calculatedCount = item.count;
      if (item._id === ResultLifecycleStatus.UNDER_REVIEW) metrics.underReviewCount = item.count;
      if (item._id === ResultLifecycleStatus.FINALIZED) metrics.finalizedCount = item.count;
      if (item._id === ResultLifecycleStatus.PUBLISHED) metrics.publishedCount = item.count;
      if (item._id === ResultLifecycleStatus.REOPENED) metrics.reopenedCount = item.count;
    }

    return {
      results,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
      metrics,
    };
  }

  /**
   * Fetches full single result for admin detail/review
   */
  static async getResultDetail(
    collegeId: string | Types.ObjectId,
    resultId: string | Types.ObjectId
  ): Promise<IAcademicResult> {
    const result = await AcademicResult.findOne({
      _id: new Types.ObjectId(resultId),
      collegeId: new Types.ObjectId(collegeId),
    })
      .populate('studentId', 'name rollNumber admissionNumber email')
      .populate('courseId', 'name code')
      .populate('semesterId', 'name number')
      .populate('departmentId', 'name code')
      .populate('calculatedBy', 'name role')
      .populate('reviewedBy', 'name role')
      .populate('finalizedBy', 'name role')
      .populate('publishedBy', 'name role');

    if (!result) throw new Error('Academic result not found.');
    return result;
  }
}
