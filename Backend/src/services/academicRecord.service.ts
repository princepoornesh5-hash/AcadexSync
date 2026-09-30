import mongoose from 'mongoose';
import { AcademicRecord, IAcademicRecord } from '../models/academicRecord.model';
import { SubjectAcademicRecord, ISubjectAcademicRecord } from '../models/subjectAcademicRecord.model';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { Student, IStudent } from '../models/student.model';
import { Subject, ISubject } from '../models/subject.model';
import { Faculty } from '../models/faculty.model';
import { FacultyAssignment } from '../models/facultyAssignment.model';
import { AttendanceRecord } from '../models/attendanceRecord.model';
import { AttendanceStatus } from '../constants/status';
import { PracticalParticipation } from '../models/practicalParticipation.model';
import { PracticalSession } from '../models/practicalSession.model';
import { PracticalParticipationStatus } from '../constants/practical.constants';
import { Assignment } from '../models/assignment.model';
import { AssignmentSubmission } from '../models/assignmentSubmission.model';
import { StudentTaskStatus } from '../constants/assignment.constants';
import { InternalAssessment, AssessmentStatus } from '../models/internalAssessment.model';
import {
  AcademicProgressionStatus,
  SubjectAcademicStatus,
  isValidProgressionTransition,
} from '../constants/academicRecord.constants';
import { AppRole } from '../constants/roles';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';
import { AuditService } from './audit.service';
import { NotificationService } from './notification.service';
import { NotificationType } from '../constants/notification.constants';
import { realtimeEventBus, AcadexEventType } from '../realtime';

export interface AttendanceAggregationSummary {
  totalClasses: number;
  presentCount: number;
  absentCount: number;
  lateCount: number;
  excusedCount: number;
  percentage: number;
}

export interface PracticalAggregationSummary {
  totalSessions: number;
  completedCount: number;
  inProgressCount: number;
  absentCount: number;
  excusedCount: number;
  completionRate: number;
}

export interface AssignmentAggregationSummary {
  totalAssignments: number;
  submittedCount: number;
  completedCount: number;
  lateCount: number;
  completionRate: number;
}

export interface AssessmentSummaryEntry {
  title: string;
  totalMarks?: number;
  isPublished: boolean;
}

export interface SubjectRecordSummary {
  id: string;
  subjectId: string;
  name: string;
  code: string;
  type: string;
  credits: number;
  status: SubjectAcademicStatus;
  facultyName?: string;
  attendance?: AttendanceAggregationSummary;
  practical?: PracticalAggregationSummary;
  assignment?: AssignmentAggregationSummary;
  assessment?: AssessmentSummaryEntry;
}

export interface AcademicRecordDetailResponse {
  record: IAcademicRecord;
  academicContext: {
    courseName?: string;
    departmentName?: string;
    academicYearName?: string;
    semesterNumber?: number;
    sectionName?: string;
  };
  overallAttendance: AttendanceAggregationSummary;
  overallPractical: PracticalAggregationSummary;
  overallAssignment: AssignmentAggregationSummary;
  subjects: SubjectRecordSummary[];
}

export class AcademicRecordService {
  // =========================================================================
  // 1. RECORD INITIALIZATION & GENERATION
  // =========================================================================

  /**
   * Initializes or fetches canonical AcademicRecord from an active StudentEnrollment.
   * Ensures idempotency: duplicate (collegeId, studentId, academicYearId, semesterId) records are prevented.
   */
  static async initializeFromEnrollment(
    collegeId: string,
    studentEnrollmentId: string,
    actorUserId?: string
  ): Promise<IAcademicRecord> {
    const enrollment = await StudentEnrollment.findOne({
      _id: studentEnrollmentId,
      collegeId,
    });

    if (!enrollment) {
      throw ApiError.notFound('Canonical student enrollment not found');
    }

    // Check if AcademicRecord already exists for this student and academic period
    let record = await AcademicRecord.findOne({
      collegeId: enrollment.collegeId,
      studentId: enrollment.studentId,
      academicYearId: enrollment.academicYearId,
      semesterId: enrollment.semesterId,
    });

    if (record) {
      return record;
    }

    // Create new AcademicRecord
    record = await AcademicRecord.create({
      collegeId: enrollment.collegeId,
      studentId: enrollment.studentId,
      studentEnrollmentId: enrollment._id,
      departmentId: enrollment.departmentId,
      courseId: enrollment.courseId,
      academicYearId: enrollment.academicYearId,
      semesterId: enrollment.semesterId,
      sectionId: enrollment.sectionId || null,
      academicStage: enrollment.academicStage || null,
      cohort: enrollment.cohort || null,
      progressionStatus: AcademicProgressionStatus.ACTIVE,
    });

    // Automatically initialize SubjectAcademicRecord entries for subjects in this course & semester
    await this.populateSubjectRecords(record);

    // Audit log
    await AuditService.logAction({
      collegeId,
      actorUserId: actorUserId || enrollment.studentId.toString(),
      action: 'ACADEMIC_RECORD_INITIALIZED',
      entityType: 'AcademicRecord',
      entityId: record._id.toString(),
      metadata: {
        studentId: enrollment.studentId.toString(),
        academicYearId: enrollment.academicYearId.toString(),
        semesterId: enrollment.semesterId.toString(),
      },
    });

    // Realtime event
    realtimeEventBus.publish({
      eventType: AcadexEventType.ACADEMIC_RECORD_CREATED,
      aggregateType: 'AcademicRecord',
      aggregateId: record._id.toString(),
      action: 'CREATED',
      collegeId,
      scope: {
        type: 'user',
        collegeId,
        departmentId: record.departmentId.toString(),
        userId: enrollment.studentId.toString(),
      },
      payload: {
        recordId: record._id.toString(),
        studentId: record.studentId.toString(),
        academicYearId: record.academicYearId.toString(),
        semesterId: record.semesterId.toString(),
        progressionStatus: record.progressionStatus,
      },
    });

    return record;
  }

  /**
   * Discovers canonical subjects for the academic record context and creates SubjectAcademicRecord entries.
   */
  static async populateSubjectRecords(record: IAcademicRecord): Promise<void> {
    const subjects = await Subject.find({
      collegeId: record.collegeId,
      courseId: record.courseId,
      semesterId: record.semesterId,
      status: 'active',
    });

    for (const subj of subjects) {
      // Find active FacultyAssignment for teaching attribution if available
      const faQuery: Record<string, any> = {
        collegeId: record.collegeId,
        subjectId: subj._id,
        courseId: record.courseId,
        semesterId: record.semesterId,
        status: 'active',
      };
      if (record.sectionId) {
        faQuery.sectionId = record.sectionId;
      }
      const fa = await FacultyAssignment.findOne(faQuery);

      await SubjectAcademicRecord.findOneAndUpdate(
        {
          collegeId: record.collegeId,
          academicRecordId: record._id,
          subjectId: subj._id,
        },
        {
          $setOnInsert: {
            collegeId: record.collegeId,
            academicRecordId: record._id,
            studentId: record.studentId,
            subjectId: subj._id,
            facultyAssignmentId: fa ? fa._id : null,
            status: SubjectAcademicStatus.ENROLLED,
            credits: subj.credits || 0,
          },
        },
        { upsert: true, new: true }
      );
    }
  }

  // =========================================================================
  // 2. STUDENT ACADEMIC HISTORY
  // =========================================================================

  /**
   * Retrieves complete chronological academic history for a student across all completed and active periods.
   */
  static async getStudentAcademicHistory(
    collegeId: string,
    targetStudentId: string,
    requester: AuthenticatedUser
  ): Promise<Array<{
    record: IAcademicRecord;
    courseName: string;
    departmentName: string;
    academicYearName: string;
    semesterNumber: number;
    sectionName?: string;
    subjectCount: number;
    attendance: AttendanceAggregationSummary;
    practical: PracticalAggregationSummary;
    assignment: AssignmentAggregationSummary;
  }>> {
    const student = await this.resolveStudent(collegeId, targetStudentId);

    // Authorization check
    await this.verifyReadAuthorization(collegeId, student, requester);

    // Fetch all academic records for student
    const records = await AcademicRecord.find({
      collegeId,
      studentId: student._id,
    })
      .populate<{ courseId: { name: string; code?: string } }>('courseId', 'name code')
      .populate<{ departmentId: { name: string; code?: string } }>('departmentId', 'name code')
      .populate<{ academicYearId: { name: string; startDate?: Date } }>('academicYearId', 'name startDate')
      .populate<{ semesterId: { number: number; name?: string } }>('semesterId', 'number name')
      .populate<{ sectionId?: { name: string } }>('sectionId', 'name')
      .sort({ createdAt: -1 });

    const historyItems = [];

    for (const rec of records) {
      const subjectCount = await SubjectAcademicRecord.countDocuments({
        academicRecordId: rec._id,
      });

      const attendance = await this.calculatePeriodAttendance(
        collegeId,
        student._id.toString(),
        rec.academicYearId?.toString() || '',
        rec.semesterId?.toString() || ''
      );

      const practical = await this.calculatePeriodPracticals(
        collegeId,
        student._id.toString(),
        rec.academicYearId?.toString() || '',
        rec.semesterId?.toString() || ''
      );

      const assignment = await this.calculatePeriodAssignments(
        collegeId,
        student._id.toString(),
        student.userId ? student.userId.toString() : '',
        rec.courseId?.toString() || '',
        rec.semesterId?.toString() || '',
        rec.sectionId ? rec.sectionId.toString() : undefined
      );

      const courseName = (rec.courseId as any)?.name || 'Course';
      const departmentName = (rec.departmentId as any)?.name || 'Department';
      const academicYearName = (rec.academicYearId as any)?.name || 'Academic Year';
      const semesterNumber = (rec.semesterId as any)?.number || 1;
      const sectionName = (rec.sectionId as any)?.name;

      historyItems.push({
        record: rec as unknown as IAcademicRecord,
        courseName,
        departmentName,
        academicYearName,
        semesterNumber,
        sectionName,
        subjectCount,
        attendance,
        practical,
        assignment,
      });
    }

    return historyItems;
  }

  // =========================================================================
  // 3. ACADEMIC RECORD DETAIL
  // =========================================================================

  /**
   * Retrieves full structured detail for a single academic record including subject breakdowns.
   */
  static async getRecordDetail(
    collegeId: string,
    recordId: string,
    requester: AuthenticatedUser
  ): Promise<AcademicRecordDetailResponse> {
    const record = await AcademicRecord.findOne({
      _id: recordId,
      collegeId,
    })
      .populate<{ courseId: { name: string; code?: string } }>('courseId', 'name code')
      .populate<{ departmentId: { name: string; code?: string } }>('departmentId', 'name code')
      .populate<{ academicYearId: { name: string } }>('academicYearId', 'name')
      .populate<{ semesterId: { number: number; name?: string } }>('semesterId', 'number name')
      .populate<{ sectionId?: { name: string } }>('sectionId', 'name')
      .populate<{ studentId: IStudent }>('studentId');

    if (!record) {
      throw ApiError.notFound('Academic record not found');
    }

    const student = record.studentId as unknown as IStudent;
    await this.verifyReadAuthorization(collegeId, student, requester);

    // Fetch subject records
    const subjectRecords = await SubjectAcademicRecord.find({
      academicRecordId: record._id,
      collegeId,
    }).populate<{ subjectId: ISubject }>('subjectId');

    // Aggregate overall metrics
    const overallAttendance = await this.calculatePeriodAttendance(
      collegeId,
      student._id.toString(),
      record.academicYearId?.toString() || '',
      record.semesterId?.toString() || ''
    );

    const overallPractical = await this.calculatePeriodPracticals(
      collegeId,
      student._id.toString(),
      record.academicYearId?.toString() || '',
      record.semesterId?.toString() || ''
    );

    const overallAssignment = await this.calculatePeriodAssignments(
      collegeId,
      student._id.toString(),
      student.userId ? student.userId.toString() : '',
      record.courseId?.toString() || '',
      record.semesterId?.toString() || '',
      record.sectionId ? record.sectionId.toString() : undefined
    );

    // Subject breakdown
    const subjectsList: SubjectRecordSummary[] = [];

    for (const sr of subjectRecords) {
      const subj = sr.subjectId as unknown as ISubject;
      if (!subj) continue;

      // Subject attendance
      const subjAttendance = await this.calculateSubjectAttendance(
        collegeId,
        student._id.toString(),
        subj._id.toString(),
        record.academicYearId?.toString() || '',
        record.semesterId?.toString() || ''
      );

      // Subject practicals if practical capable
      let subjPractical: PracticalAggregationSummary | undefined;
      const isPractical = subj.type && ['PRACTICAL', 'LAB', 'THEORY_PRACTICAL', 'BOTH'].includes(subj.type.toUpperCase());
      if (isPractical) {
        subjPractical = await this.calculateSubjectPracticals(
          collegeId,
          student._id.toString(),
          subj._id.toString()
        );
      }

      // Subject assignments
      const subjAssignment = await this.calculateSubjectAssignments(
        collegeId,
        student._id.toString(),
        student.userId ? student.userId.toString() : '',
        subj._id.toString()
      );

      // Subject assessment if published
      const assessment = await this.getSubjectAssessmentSummary(
        collegeId,
        student._id.toString(),
        subj._id.toString(),
        record.semesterId?.toString() || ''
      );

      subjectsList.push({
        id: sr._id.toString(),
        subjectId: subj._id.toString(),
        name: subj.name,
        code: subj.code,
        type: subj.type,
        credits: sr.credits || subj.credits || 0,
        status: sr.status,
        attendance: subjAttendance,
        practical: subjPractical,
        assignment: subjAssignment,
        assessment,
      });
    }

    return {
      record: record as unknown as IAcademicRecord,
      academicContext: {
        courseName: (record.courseId as any)?.name,
        departmentName: (record.departmentId as any)?.name,
        academicYearName: (record.academicYearId as any)?.name,
        semesterNumber: (record.semesterId as any)?.number,
        sectionName: (record.sectionId as any)?.name,
      },
      overallAttendance,
      overallPractical,
      overallAssignment,
      subjects: subjectsList,
    };
  }

  // =========================================================================
  // 4. PROGRESSION & RECORD MUTATIONS
  // =========================================================================

  /**
   * Updates student progression status (e.g. ACTIVE -> PROMOTED or COMPLETED).
   * Restricted strictly to HOD and College Admin. Validates state transition.
   */
  static async updateProgressionStatus(
    collegeId: string,
    recordId: string,
    targetStatus: AcademicProgressionStatus,
    remarks: string | null | undefined,
    actorUser: AuthenticatedUser
  ): Promise<IAcademicRecord> {
    // Only College Admin or HOD can modify progression
    if (
      actorUser.role !== AppRole.SUPER_ADMIN &&
      actorUser.role !== AppRole.COLLEGE_ADMIN &&
      actorUser.role !== AppRole.HOD
    ) {
      throw ApiError.forbidden('Only College Administrators and HODs may record progression status');
    }

    const record = await AcademicRecord.findOne({
      _id: recordId,
      collegeId,
    });

    if (!record) {
      throw ApiError.notFound('Academic record not found');
    }

    // HOD department scope enforcement
    if (actorUser.role === AppRole.HOD) {
      if (actorUser.departmentId && record.departmentId.toString() !== actorUser.departmentId) {
        throw ApiError.forbidden('HOD can only update progression for students in their department');
      }
    }

    // Validate transition
    if (!isValidProgressionTransition(record.progressionStatus, targetStatus)) {
      throw ApiError.badRequest(
        `Invalid progression transition from ${record.progressionStatus} to ${targetStatus}`
      );
    }

    const oldStatus = record.progressionStatus;
    record.progressionStatus = targetStatus;
    if (remarks !== undefined) record.remarks = remarks;

    const actorObjId = mongoose.Types.ObjectId.isValid(actorUser.id)
      ? new mongoose.Types.ObjectId(actorUser.id)
      : null;

    if (targetStatus === AcademicProgressionStatus.PROMOTED) {
      record.promotedAt = new Date();
      record.promotedBy = actorObjId;
      record.completedAt = record.completedAt || new Date();
    } else if (targetStatus === AcademicProgressionStatus.COMPLETED) {
      record.completedAt = new Date();
    }

    await record.save();

    // Audit log
    await AuditService.logAction({
      collegeId,
      actorUserId: actorUser.id,
      action: 'ACADEMIC_PROGRESSION_UPDATED',
      entityType: 'AcademicRecord',
      entityId: record._id.toString(),
      metadata: {
        oldStatus,
        newStatus: targetStatus,
        remarks,
      },
    });

    // Realtime event
    realtimeEventBus.publish({
      eventType: AcadexEventType.ACADEMIC_RECORD_PROGRESSION_UPDATED,
      aggregateType: 'AcademicRecord',
      aggregateId: record._id.toString(),
      action: 'UPDATED',
      collegeId,
      scope: {
        type: 'user',
        collegeId,
        departmentId: record.departmentId.toString(),
        userId: record.studentId.toString(),
      },
      payload: {
        recordId: record._id.toString(),
        studentId: record.studentId.toString(),
        progressionStatus: targetStatus,
        oldStatus,
      },
    });

    // Notification to student
    try {
      const studentDoc = await Student.findById(record.studentId);
      if (studentDoc && studentDoc.userId) {
        await NotificationService.createNotification({
          recipientUserId: studentDoc.userId.toString(),
          collegeId,
          notificationType: NotificationType.ACADEMIC_PROGRESSION_UPDATED,
          title: 'Academic Status Updated',
          body: `Your academic progression status has been updated to ${targetStatus}.`,
          entityType: 'AcademicRecord',
          entityId: record._id.toString(),
          metadata: {
            recordId: record._id.toString(),
            status: targetStatus,
          },
        });
      }
    } catch {
      // Non-critical notification failure
    }

    return record;
  }

  /**
   * Updates an individual subject academic status.
   */
  static async updateSubjectStatus(
    collegeId: string,
    subjectRecordId: string,
    status: SubjectAcademicStatus,
    remarks: string | null | undefined,
    actorUser: AuthenticatedUser
  ): Promise<ISubjectAcademicRecord> {
    if (
      actorUser.role !== AppRole.SUPER_ADMIN &&
      actorUser.role !== AppRole.COLLEGE_ADMIN &&
      actorUser.role !== AppRole.HOD &&
      actorUser.role !== AppRole.FACULTY
    ) {
      throw ApiError.forbidden('Unauthorized to update subject status');
    }

    const sr = await SubjectAcademicRecord.findOne({
      _id: subjectRecordId,
      collegeId,
    });

    if (!sr) {
      throw ApiError.notFound('Subject academic record not found');
    }

    sr.status = status;
    if (remarks !== undefined) sr.remarks = remarks;
    await sr.save();

    // Realtime event
    realtimeEventBus.publish({
      eventType: AcadexEventType.SUBJECT_ACADEMIC_RECORD_UPDATED,
      aggregateType: 'SubjectAcademicRecord',
      aggregateId: sr._id.toString(),
      action: 'UPDATED',
      collegeId,
      scope: {
        type: 'user',
        collegeId,
        userId: sr.studentId.toString(),
      },
      payload: {
        subjectRecordId: sr._id.toString(),
        studentId: sr.studentId.toString(),
        subjectId: sr.subjectId.toString(),
        status,
      },
    });

    return sr;
  }

  // =========================================================================
  // 5. DEPARTMENT & FACULTY RECORD LISTS
  // =========================================================================

  /**
   * Lists academic records in a department for HOD and College Admin.
   */
  static async listDepartmentRecords(
    collegeId: string,
    params: {
      departmentId?: string;
      courseId?: string;
      academicYearId?: string;
      semesterId?: string;
      sectionId?: string;
      progressionStatus?: AcademicProgressionStatus;
      search?: string;
      page?: number;
      limit?: number;
    },
    requester: AuthenticatedUser
  ) {
    const query: Record<string, any> = { collegeId };

    // HOD department scope
    if (requester.role === AppRole.HOD) {
      if (requester.departmentId) {
        query.departmentId = requester.departmentId;
      }
    } else if (params.departmentId) {
      query.departmentId = params.departmentId;
    }

    if (params.courseId) query.courseId = params.courseId;
    if (params.academicYearId) query.academicYearId = params.academicYearId;
    if (params.semesterId) query.semesterId = params.semesterId;
    if (params.sectionId) query.sectionId = params.sectionId;
    if (params.progressionStatus) query.progressionStatus = params.progressionStatus;

    const page = params.page || 1;
    const limit = params.limit || 20;
    const skip = (page - 1) * limit;

    const [total, records] = await Promise.all([
      AcademicRecord.countDocuments(query),
      AcademicRecord.find(query)
        .populate<{ studentId: { name: string; rollNumber?: string; email?: string } }>('studentId', 'name rollNumber email')
        .populate<{ courseId: { name: string } }>('courseId', 'name')
        .populate<{ semesterId: { number: number } }>('semesterId', 'number')
        .populate<{ academicYearId: { name: string } }>('academicYearId', 'name')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
    ]);

    return {
      records,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  // =========================================================================
  // 6. HELPER CALCULATIONS (ATTENDANCE, PRACTICALS, ASSIGNMENTS)
  // =========================================================================

  private static async calculatePeriodAttendance(
    collegeId: string,
    studentId: string,
    academicYearId: string,
    semesterId: string
  ): Promise<AttendanceAggregationSummary> {
    const query: Record<string, any> = {
      collegeId: new mongoose.Types.ObjectId(collegeId),
      studentId: new mongoose.Types.ObjectId(studentId),
      isCancelled: { $ne: true },
    };
    if (academicYearId && mongoose.Types.ObjectId.isValid(academicYearId)) {
      query.academicYearId = new mongoose.Types.ObjectId(academicYearId);
    }
    if (semesterId && mongoose.Types.ObjectId.isValid(semesterId)) {
      query.semesterId = new mongoose.Types.ObjectId(semesterId);
    }

    const records = await AttendanceRecord.find(query);
    const totalClasses = records.length;
    if (totalClasses === 0) {
      return { totalClasses: 0, presentCount: 0, absentCount: 0, lateCount: 0, excusedCount: 0, percentage: 0 };
    }

    const presentCount = records.filter((r) => r.status === AttendanceStatus.PRESENT).length;
    const lateCount = records.filter((r) => r.status === AttendanceStatus.LATE).length;
    const absentCount = records.filter((r) => r.status === AttendanceStatus.ABSENT).length;
    const excusedCount = records.filter((r) => r.status === AttendanceStatus.EXCUSED).length;

    // Effective present count includes present and late
    const effectivePresent = presentCount + lateCount;
    const percentage = Math.round((effectivePresent / totalClasses) * 100);

    return { totalClasses, presentCount, absentCount, lateCount, excusedCount, percentage };
  }

  private static async calculateSubjectAttendance(
    collegeId: string,
    studentId: string,
    subjectId: string,
    academicYearId: string,
    semesterId: string
  ): Promise<AttendanceAggregationSummary> {
    const query: Record<string, any> = {
      collegeId: new mongoose.Types.ObjectId(collegeId),
      studentId: new mongoose.Types.ObjectId(studentId),
      subjectId: new mongoose.Types.ObjectId(subjectId),
      isCancelled: { $ne: true },
    };
    if (academicYearId && mongoose.Types.ObjectId.isValid(academicYearId)) {
      query.academicYearId = new mongoose.Types.ObjectId(academicYearId);
    }
    if (semesterId && mongoose.Types.ObjectId.isValid(semesterId)) {
      query.semesterId = new mongoose.Types.ObjectId(semesterId);
    }

    const records = await AttendanceRecord.find(query);
    const totalClasses = records.length;
    if (totalClasses === 0) {
      return { totalClasses: 0, presentCount: 0, absentCount: 0, lateCount: 0, excusedCount: 0, percentage: 0 };
    }

    const presentCount = records.filter((r) => r.status === AttendanceStatus.PRESENT).length;
    const lateCount = records.filter((r) => r.status === AttendanceStatus.LATE).length;
    const absentCount = records.filter((r) => r.status === AttendanceStatus.ABSENT).length;
    const excusedCount = records.filter((r) => r.status === AttendanceStatus.EXCUSED).length;
    const effectivePresent = presentCount + lateCount;
    const percentage = Math.round((effectivePresent / totalClasses) * 100);

    return { totalClasses, presentCount, absentCount, lateCount, excusedCount, percentage };
  }

  private static async calculatePeriodPracticals(
    collegeId: string,
    studentId: string,
    academicYearId: string,
    semesterId: string
  ): Promise<PracticalAggregationSummary> {
    // Find sessions in this academic period
    const sessionQuery: Record<string, any> = { collegeId };
    if (academicYearId && mongoose.Types.ObjectId.isValid(academicYearId)) sessionQuery.academicYearId = academicYearId;
    if (semesterId && mongoose.Types.ObjectId.isValid(semesterId)) sessionQuery.semesterId = semesterId;

    const sessions = await PracticalSession.find(sessionQuery).select('_id');
    const sessionIds = sessions.map((s) => s._id);

    if (sessionIds.length === 0) {
      return { totalSessions: 0, completedCount: 0, inProgressCount: 0, absentCount: 0, excusedCount: 0, completionRate: 0 };
    }

    const participations = await PracticalParticipation.find({
      collegeId,
      studentId: new mongoose.Types.ObjectId(studentId),
      practicalSessionId: { $in: sessionIds },
    });

    const totalSessions = participations.length;
    if (totalSessions === 0) {
      return { totalSessions: 0, completedCount: 0, inProgressCount: 0, absentCount: 0, excusedCount: 0, completionRate: 0 };
    }

    const completedCount = participations.filter((p) => p.status === PracticalParticipationStatus.COMPLETED).length;
    const inProgressCount = participations.filter((p) => p.status === PracticalParticipationStatus.IN_PROGRESS).length;
    const absentCount = participations.filter((p) => p.status === PracticalParticipationStatus.ABSENT).length;
    const excusedCount = participations.filter((p) => p.status === PracticalParticipationStatus.EXCUSED).length;
    const completionRate = Math.round((completedCount / totalSessions) * 100);

    return { totalSessions, completedCount, inProgressCount, absentCount, excusedCount, completionRate };
  }

  private static async calculateSubjectPracticals(
    collegeId: string,
    studentId: string,
    subjectId: string
  ): Promise<PracticalAggregationSummary> {
    const sessions = await PracticalSession.find({
      collegeId,
      subjectId: new mongoose.Types.ObjectId(subjectId),
    }).select('_id');
    const sessionIds = sessions.map((s) => s._id);

    if (sessionIds.length === 0) {
      return { totalSessions: 0, completedCount: 0, inProgressCount: 0, absentCount: 0, excusedCount: 0, completionRate: 0 };
    }

    const participations = await PracticalParticipation.find({
      collegeId,
      studentId: new mongoose.Types.ObjectId(studentId),
      practicalSessionId: { $in: sessionIds },
    });

    const totalSessions = participations.length;
    if (totalSessions === 0) {
      return { totalSessions: 0, completedCount: 0, inProgressCount: 0, absentCount: 0, excusedCount: 0, completionRate: 0 };
    }

    const completedCount = participations.filter((p) => p.status === PracticalParticipationStatus.COMPLETED).length;
    const inProgressCount = participations.filter((p) => p.status === PracticalParticipationStatus.IN_PROGRESS).length;
    const absentCount = participations.filter((p) => p.status === PracticalParticipationStatus.ABSENT).length;
    const excusedCount = participations.filter((p) => p.status === PracticalParticipationStatus.EXCUSED).length;
    const completionRate = Math.round((completedCount / totalSessions) * 100);

    return { totalSessions, completedCount, inProgressCount, absentCount, excusedCount, completionRate };
  }

  private static async calculatePeriodAssignments(
    collegeId: string,
    studentId: string,
    studentUserId: string,
    courseId: string,
    semesterId: string,
    sectionId?: string
  ): Promise<AssignmentAggregationSummary> {
    const assignQuery: Record<string, any> = {
      collegeId,
      status: { $in: ['PUBLISHED', 'CLOSED'] },
    };
    if (courseId && mongoose.Types.ObjectId.isValid(courseId)) assignQuery.courseId = courseId;
    if (semesterId && mongoose.Types.ObjectId.isValid(semesterId)) assignQuery.semesterId = semesterId;
    if (sectionId && mongoose.Types.ObjectId.isValid(sectionId)) {
      assignQuery.$or = [{ sectionId }, { sectionId: null }];
    }

    const assignments = await Assignment.find(assignQuery).select('_id');
    const assignmentIds = assignments.map((a) => a._id);

    if (assignmentIds.length === 0) {
      return { totalAssignments: 0, submittedCount: 0, completedCount: 0, lateCount: 0, completionRate: 0 };
    }

    const subQuery: Record<string, any> = {
      collegeId,
      assignmentId: { $in: assignmentIds },
    };
    if (studentUserId && mongoose.Types.ObjectId.isValid(studentUserId)) {
      subQuery.$or = [
        { studentId: new mongoose.Types.ObjectId(studentId) },
        { studentUserId: new mongoose.Types.ObjectId(studentUserId) },
      ];
    } else {
      subQuery.studentId = new mongoose.Types.ObjectId(studentId);
    }

    const submissions = await AssignmentSubmission.find(subQuery);
    const totalAssignments = assignmentIds.length;
    const submittedCount = submissions.filter((s) => s.status === StudentTaskStatus.SUBMITTED || s.status === StudentTaskStatus.COMPLETED).length;
    const completedCount = submissions.filter((s) => s.status === StudentTaskStatus.COMPLETED).length;
    const lateCount = submissions.filter((s) => s.isLate).length;
    const completionRate = Math.round((submittedCount / totalAssignments) * 100);

    return { totalAssignments, submittedCount, completedCount, lateCount, completionRate };
  }

  private static async calculateSubjectAssignments(
    collegeId: string,
    studentId: string,
    studentUserId: string,
    subjectId: string
  ): Promise<AssignmentAggregationSummary> {
    const assignments = await Assignment.find({
      collegeId,
      subjectId: new mongoose.Types.ObjectId(subjectId),
      status: { $in: ['PUBLISHED', 'CLOSED'] },
    }).select('_id');
    const assignmentIds = assignments.map((a) => a._id);

    if (assignmentIds.length === 0) {
      return { totalAssignments: 0, submittedCount: 0, completedCount: 0, lateCount: 0, completionRate: 0 };
    }

    const subQuery: Record<string, any> = {
      collegeId,
      assignmentId: { $in: assignmentIds },
    };
    if (studentUserId && mongoose.Types.ObjectId.isValid(studentUserId)) {
      subQuery.$or = [
        { studentId: new mongoose.Types.ObjectId(studentId) },
        { studentUserId: new mongoose.Types.ObjectId(studentUserId) },
      ];
    } else {
      subQuery.studentId = new mongoose.Types.ObjectId(studentId);
    }

    const submissions = await AssignmentSubmission.find(subQuery);
    const totalAssignments = assignmentIds.length;
    const submittedCount = submissions.filter((s) => s.status === StudentTaskStatus.SUBMITTED || s.status === StudentTaskStatus.COMPLETED).length;
    const completedCount = submissions.filter((s) => s.status === StudentTaskStatus.COMPLETED).length;
    const lateCount = submissions.filter((s) => s.isLate).length;
    const completionRate = Math.round((submittedCount / totalAssignments) * 100);

    return { totalAssignments, submittedCount, completedCount, lateCount, completionRate };
  }

  private static async getSubjectAssessmentSummary(
    collegeId: string,
    studentId: string,
    subjectId: string,
    semesterId: string
  ): Promise<AssessmentSummaryEntry | undefined> {
    const assess = await InternalAssessment.findOne({
      collegeId,
      subjectId: new mongoose.Types.ObjectId(subjectId),
      semesterId: new mongoose.Types.ObjectId(semesterId),
      status: AssessmentStatus.PUBLISHED,
    });

    if (!assess) return undefined;

    const studentEntry = assess.entries.find(
      (e) => e.studentId.toString() === studentId
    );

    return {
      title: assess.title,
      totalMarks: studentEntry?.totalMarks,
      isPublished: true,
    };
  }

  // =========================================================================
  // 7. AUTHORIZATION UTILITIES
  // =========================================================================

  private static async resolveStudent(collegeId: string, studentIdOrUserId: string): Promise<IStudent> {
    let student: IStudent | null = null;
    if (mongoose.Types.ObjectId.isValid(studentIdOrUserId)) {
      student = await Student.findOne({
        collegeId,
        $or: [
          { _id: new mongoose.Types.ObjectId(studentIdOrUserId) },
          { userId: new mongoose.Types.ObjectId(studentIdOrUserId) },
        ],
      });
    }

    if (!student) {
      throw ApiError.notFound('Student not found in this institution');
    }

    return student;
  }

  private static async verifyReadAuthorization(
    collegeId: string,
    student: IStudent,
    requester: AuthenticatedUser
  ): Promise<void> {
    // Tenant boundary
    if (
      requester.role !== AppRole.SUPER_ADMIN &&
      requester.collegeId &&
      requester.collegeId !== collegeId
    ) {
      throw ApiError.forbidden('Cross-institution access is strictly prohibited');
    }

    // Student role boundary: can only access own records
    if (requester.role === AppRole.STUDENT) {
      const isSelf =
        (student.userId && student.userId.toString() === requester.id) ||
        student._id.toString() === requester.id;
      if (!isSelf) {
        throw ApiError.forbidden('Students are strictly restricted to their own academic records');
      }
      return;
    }

    // HOD role boundary: department scope
    if (requester.role === AppRole.HOD) {
      if (
        requester.departmentId &&
        student.departmentId.toString() !== requester.departmentId
      ) {
        throw ApiError.forbidden('HOD can only access records of students within their department');
      }
      return;
    }

    // Faculty role boundary: teaching scope
    if (requester.role === AppRole.FACULTY) {
      const faculty = await Faculty.findOne({ userId: requester.id, collegeId });
      if (!faculty) {
        throw ApiError.forbidden('Faculty profile not linked');
      }
      // Check if faculty has an active FacultyAssignment matching student's enrollment
      const hasTeachingScope = await FacultyAssignment.exists({
        collegeId,
        facultyId: faculty._id,
        courseId: student.courseId,
        semesterId: student.semesterId,
        status: 'active',
      });
      if (!hasTeachingScope) {
        throw ApiError.forbidden('Faculty is not assigned to teach in this student academic context');
      }
      return;
    }

    // College Admin & Super Admin have college-wide access
  }
}
