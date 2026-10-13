import mongoose, { Types } from 'mongoose';
import {
  AttendanceSession,
  IAttendanceSession,
  IAttendanceRecordItem,
} from '../models/attendanceSession.model';
import { AttendanceRecord, IAttendanceRecord } from '../models/attendanceRecord.model';
import {
  HistoricalAttendanceSummary,
  IHistoricalAttendanceSummary,
  HistoricalAttendancePrecision,
} from '../models/historicalAttendanceSummary.model';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { Subject } from '../models/subject.model';
import { Section } from '../models/section.model';
import { AcademicYear } from '../models/academicYear.model';
import { Semester } from '../models/semester.model';
import { Faculty } from '../models/faculty.model';
import { FacultyAssignment } from '../models/facultyAssignment.model';
import { College } from '../models/college.model';
import { AuditLog } from '../models/auditLog.model';
import { AttendanceStatus, AttendanceSessionStatus } from '../constants/status';
import { AppRole } from '../constants/roles';
import { TeachingAuthorizationService } from './teachingAuthorization.service';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';
import {
  DEFAULT_INSTITUTION_TIMEZONE,
  formatDateToCalendarString,
} from '../utils/dateTime';

export interface DetailedSessionRecordInput {
  studentEnrollmentId: string;
  status: AttendanceStatus;
  remarks?: string;
}

export interface CreateDetailedHistoricalSessionPayload {
  academicYearId: string;
  semesterId: string;
  sectionId?: string;
  subjectId: string;
  facultyAssignmentId?: string;
  date: string | Date;
  timeSlot: string;
  records: DetailedSessionRecordInput[];
  remarks?: string;
}

export interface HistoricalSummaryEntryInput {
  studentEnrollmentId: string;
  classesHeld?: number | null;
  presentCount?: number | null;
  absentCount?: number | null;
  attendancePercentage?: number | null;
  remarks?: string;
}

export interface CreateHistoricalSummariesPayload {
  academicYearId: string;
  semesterId: string;
  sectionId?: string;
  subjectId: string;
  periodLabel: string;
  periodStart?: string | Date;
  periodEnd?: string | Date;
  entries: HistoricalSummaryEntryInput[];
}

export interface CorrectHistoricalStudentAttendancePayload {
  recordId?: string;
  sessionId?: string;
  studentEnrollmentId?: string;
  newStatus: AttendanceStatus;
  reason: string;
}

export class HistoricalAttendanceService {
  /**
   * Resolves canonical active student enrollment roster for a given academic context.
   */
  static async getHistoricalRoster(
    requester: AuthenticatedUser,
    query: {
      academicYearId: string;
      semesterId: string;
      sectionId?: string;
      subjectId?: string;
    }
  ) {
    if (requester.role === AppRole.STUDENT) {
      throw ApiError.forbidden('Students are not permitted to access class attendance rosters.');
    }

    const collegeId = requester.collegeId;
    if (!collegeId) {
      throw ApiError.badRequest('College ID is required for academic roster resolution.');
    }

    if (!mongoose.Types.ObjectId.isValid(query.academicYearId)) {
      throw ApiError.badRequest('Invalid academicYearId.');
    }
    if (!mongoose.Types.ObjectId.isValid(query.semesterId)) {
      throw ApiError.badRequest('Invalid semesterId.');
    }

    // Verify teaching authorization if subject is provided
    if (query.subjectId) {
      await TeachingAuthorizationService.assertSubjectSectionAccess(
        collegeId,
        {
          id: requester.id,
          role: requester.role,
          collegeId: requester.collegeId,
          departmentId: requester.departmentId,
        },
        query.subjectId,
        query.sectionId,
        'view historical attendance roster'
      );
    }

    const enrollmentQuery: any = {
      collegeId: new Types.ObjectId(collegeId),
      academicYearId: new Types.ObjectId(query.academicYearId),
      semesterId: new Types.ObjectId(query.semesterId),
      status: { $in: ['enrolled', 'active'] },
    };

    if (query.sectionId && mongoose.Types.ObjectId.isValid(query.sectionId)) {
      enrollmentQuery.sectionId = new Types.ObjectId(query.sectionId);
    }

    const enrollments = await StudentEnrollment.find(enrollmentQuery)
      .populate('studentId', 'name rollNumber admissionNumber email phone')
      .lean();

    const roster = enrollments.map((enr: any) => {
      const studentObj = enr.studentId || {};
      return {
        studentEnrollmentId: enr._id.toString(),
        studentId: (studentObj._id || enr.studentId)?.toString(),
        studentName: studentObj.name || 'Student',
        rollNumber: studentObj.rollNumber || studentObj.admissionNumber || '—',
        academicYearId: enr.academicYearId?.toString(),
        semesterId: enr.semesterId?.toString(),
        sectionId: enr.sectionId?.toString(),
      };
    });

    let facultyAssignment: any = null;
    if (query.subjectId && mongoose.Types.ObjectId.isValid(query.subjectId)) {
      const faQuery: any = {
        collegeId: new Types.ObjectId(collegeId),
        subjectId: new Types.ObjectId(query.subjectId),
        academicYearId: new Types.ObjectId(query.academicYearId),
        semesterId: new Types.ObjectId(query.semesterId),
        isActive: true,
      };
      if (query.sectionId && mongoose.Types.ObjectId.isValid(query.sectionId)) {
        faQuery.sectionId = new Types.ObjectId(query.sectionId);
      }
      facultyAssignment = await FacultyAssignment.findOne(faQuery).lean();
    }

    return {
      roster,
      count: roster.length,
      facultyAssignment,
    };
  }

  /**
   * MODE A: DETAILED HISTORICAL ATTENDANCE ENTRY
   * Creates an AttendanceSession and canonical AttendanceRecord documents for a specific past date & period.
   */
  static async createDetailedHistoricalSession(
    requester: AuthenticatedUser,
    payload: CreateDetailedHistoricalSessionPayload
  ): Promise<IAttendanceSession> {
    if (requester.role === AppRole.STUDENT) {
      throw ApiError.forbidden('Students are not permitted to enter historical attendance.');
    }

    const collegeId = requester.collegeId;
    if (!collegeId) {
      throw ApiError.badRequest('College ID is required.');
    }

    const collegeDoc = await College.findById(collegeId);
    if (!collegeDoc) {
      throw ApiError.notFound('College not found.');
    }
    const collegeTimezone = collegeDoc.timezone || DEFAULT_INSTITUTION_TIMEZONE;

    // 1. Date Validation
    if (!payload.date) {
      throw ApiError.badRequest('Historical attendance date is required.');
    }
    const parsedDate = new Date(payload.date);
    if (isNaN(parsedDate.getTime())) {
      throw ApiError.badRequest('Invalid date format provided for historical attendance.');
    }

    const nowServer = new Date();
    const todayCalendarStr = formatDateToCalendarString(nowServer, collegeTimezone);
    const sessionCalendarStr = formatDateToCalendarString(parsedDate, collegeTimezone);

    if (sessionCalendarStr > todayCalendarStr) {
      throw ApiError.badRequest('Historical attendance cannot be marked for future dates (date cannot be in the future).');
    }

    // Canonical midnight UTC normalized date for consistency
    const normalizedDate = new Date(`${sessionCalendarStr}T00:00:00.000Z`);

    if (!payload.timeSlot || payload.timeSlot.trim().length === 0) {
      throw ApiError.badRequest('Class timeSlot / period is required.');
    }

    // 2. Academic Context & Teaching Authorization Validation
    if (!mongoose.Types.ObjectId.isValid(payload.academicYearId)) {
      throw ApiError.badRequest('Invalid academicYearId.');
    }
    const anyAy = await AcademicYear.findById(payload.academicYearId);
    if (!anyAy) {
      throw ApiError.notFound('Academic year not found.');
    }
    if (anyAy.collegeId.toString() !== collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited.');
    }

    if (!mongoose.Types.ObjectId.isValid(payload.semesterId)) {
      throw ApiError.badRequest('Invalid semesterId.');
    }
    const anySem = await Semester.findById(payload.semesterId);
    if (!anySem) {
      throw ApiError.notFound('Semester not found.');
    }
    if (anySem.collegeId.toString() !== collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited.');
    }

    if (!mongoose.Types.ObjectId.isValid(payload.subjectId)) {
      throw ApiError.badRequest('Invalid subjectId.');
    }
    const anySub = await Subject.findById(payload.subjectId);
    if (!anySub) {
      throw ApiError.notFound('Subject not found.');
    }
    if (anySub.collegeId.toString() !== collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited.');
    }
    const subjectDoc = anySub;

    let sectionDoc: any = null;
    if (payload.sectionId) {
      if (!mongoose.Types.ObjectId.isValid(payload.sectionId)) {
        throw ApiError.badRequest('Invalid sectionId.');
      }
      const anySec = await Section.findById(payload.sectionId);
      if (!anySec) {
        throw ApiError.notFound('Section not found.');
      }
      if (anySec.collegeId.toString() !== collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited.');
      }
      sectionDoc = anySec;
    }

    // Authorize requester using canonical TeachingAuthorizationService
    let resolvedFa: any = null;
    if (payload.facultyAssignmentId && mongoose.Types.ObjectId.isValid(payload.facultyAssignmentId)) {
      resolvedFa = await TeachingAuthorizationService.assertFacultyAssignmentAccess(
        collegeId,
        {
          id: requester.id,
          role: requester.role,
          collegeId: requester.collegeId,
          departmentId: requester.departmentId,
        },
        payload.facultyAssignmentId,
        'enter historical attendance'
      );
    } else {
      resolvedFa = await TeachingAuthorizationService.assertSubjectSectionAccess(
        collegeId,
        {
          id: requester.id,
          role: requester.role,
          collegeId: requester.collegeId,
          departmentId: requester.departmentId,
        },
        payload.subjectId,
        payload.sectionId,
        'enter historical attendance'
      );
    }

    // Resolve target faculty for session
    let targetFacultyId: Types.ObjectId;
    if (requester.role === AppRole.FACULTY) {
      const facultyProfile = await TeachingAuthorizationService.resolveFacultyProfile(collegeId, {
        id: requester.id,
        role: requester.role,
        collegeId: requester.collegeId,
        email: requester.email,
      });
      if (!facultyProfile) {
        throw ApiError.forbidden('Authenticated user does not have a linked faculty profile.');
      }
      targetFacultyId = facultyProfile._id as Types.ObjectId;
    } else if (resolvedFa && resolvedFa.facultyId) {
      targetFacultyId = resolvedFa.facultyId as Types.ObjectId;
    } else {
      const anyFa = await Faculty.findOne({ collegeId });
      if (!anyFa) {
        throw ApiError.badRequest('No valid faculty profile found for attendance session assignment.');
      }
      targetFacultyId = anyFa._id as Types.ObjectId;
    }

    // 3. Duplicate Session Protection
    const duplicateSessionQuery: any = {
      collegeId: new Types.ObjectId(collegeId),
      subjectId: new Types.ObjectId(payload.subjectId),
      date: normalizedDate,
      timeSlot: payload.timeSlot.trim(),
    };
    if (payload.sectionId) {
      duplicateSessionQuery.sectionId = new Types.ObjectId(payload.sectionId);
    } else {
      duplicateSessionQuery.sectionId = null;
    }

    const existingSession = await AttendanceSession.findOne(duplicateSessionQuery);
    if (existingSession) {
      throw ApiError.conflict(
        `An attendance session already exists for this subject, section, date (${sessionCalendarStr}), and time slot (${payload.timeSlot}). Duplicate sessions are prevented.`
      );
    }

    // 4. Validate Roster Records
    if (!payload.records || !Array.isArray(payload.records) || payload.records.length === 0) {
      throw ApiError.badRequest('At least one student attendance record is required.');
    }

    const allowedStatuses = Object.values(AttendanceStatus);
    const seenEnrollmentIds = new Set<string>();
    const preparedSessionRecordItems: IAttendanceRecordItem[] = [];
    const preparedAttendanceRecords: any[] = [];

    const sessionId = new Types.ObjectId();

    for (const item of payload.records) {
      if (!item.studentEnrollmentId || !mongoose.Types.ObjectId.isValid(item.studentEnrollmentId)) {
        throw ApiError.badRequest(`Invalid studentEnrollmentId: ${item.studentEnrollmentId}`);
      }
      if (seenEnrollmentIds.has(item.studentEnrollmentId)) {
        throw ApiError.badRequest(
          `Duplicate student enrollment entry '${item.studentEnrollmentId}' in the same session payload.`
        );
      }
      seenEnrollmentIds.add(item.studentEnrollmentId);

      // Validate student enrollment canonically belongs to this college and context
      const enrollmentDoc = await StudentEnrollment.findOne({
        _id: item.studentEnrollmentId,
        collegeId: new Types.ObjectId(collegeId),
      }).populate('studentId', 'name rollNumber admissionNumber');

      if (!enrollmentDoc) {
        throw ApiError.badRequest(
          `Student enrollment '${item.studentEnrollmentId}' does not belong to this college.`
        );
      }

      // Check section match if section is specified
      if (payload.sectionId && enrollmentDoc.sectionId?.toString() !== payload.sectionId) {
        throw ApiError.badRequest(
          `Student enrollment '${item.studentEnrollmentId}' does not belong to section '${payload.sectionId}'.`
        );
      }

      if (!allowedStatuses.includes(item.status)) {
        throw ApiError.badRequest(`Invalid attendance status: ${item.status}`);
      }

      const studentObj: any = enrollmentDoc.studentId || {};
      const studentName = studentObj.name || 'Student';
      const rollNumber = studentObj.rollNumber || studentObj.admissionNumber || '—';

      preparedSessionRecordItems.push({
        studentId: enrollmentDoc.studentId as Types.ObjectId,
        studentName,
        rollNumber,
        sectionId: payload.sectionId ? new Types.ObjectId(payload.sectionId) : null,
        status: item.status,
        remarks: item.remarks || payload.remarks || undefined,
        lastModified: new Date(),
        modifiedBy: requester.id,
      });

      preparedAttendanceRecords.push({
        collegeId: new Types.ObjectId(collegeId),
        departmentId: subjectDoc.departmentId,
        sessionId,
        studentId: enrollmentDoc.studentId,
        studentEnrollmentId: enrollmentDoc._id,
        studentName,
        rollNumber,
        sectionId: payload.sectionId ? new Types.ObjectId(payload.sectionId) : null,
        subjectId: new Types.ObjectId(payload.subjectId),
        courseId: subjectDoc.courseId || enrollmentDoc.courseId || null,
        academicYearId: payload.academicYearId ? new Types.ObjectId(payload.academicYearId) : null,
        semesterId: payload.semesterId ? new Types.ObjectId(payload.semesterId) : null,
        facultyId: targetFacultyId,
        date: normalizedDate,
        timeSlot: payload.timeSlot.trim(),
        status: item.status,
        remarks: item.remarks || payload.remarks || undefined,
        isCancelled: false,
        sourceType: 'HISTORICAL_MANUAL',
      });
    }

    // 5. Persist AttendanceSession
    const sessionDoc = await AttendanceSession.create({
      _id: sessionId,
      collegeId: new Types.ObjectId(collegeId),
      departmentId: subjectDoc.departmentId,
      courseId: subjectDoc.courseId || null,
      academicYearId: payload.academicYearId ? new Types.ObjectId(payload.academicYearId) : null,
      semesterId: payload.semesterId ? new Types.ObjectId(payload.semesterId) : null,
      facultyId: targetFacultyId,
      facultyAssignmentId: resolvedFa?._id || null,
      subjectId: new Types.ObjectId(payload.subjectId),
      subjectName: subjectDoc.name,
      sectionId: payload.sectionId ? new Types.ObjectId(payload.sectionId) : null,
      sectionName: sectionDoc?.name || null,
      timeSlot: payload.timeSlot.trim(),
      date: normalizedDate,
      records: preparedSessionRecordItems,
      status: AttendanceSessionStatus.LOCKED,
      isSubmitted: true,
      isLocked: true,
      sourceType: 'HISTORICAL_MANUAL',
      createdBy: requester.id,
      version: 1,
    });

    // 6. Bulk Insert Canonical AttendanceRecords
    await AttendanceRecord.insertMany(preparedAttendanceRecords);

    // 7. Audit Log
    await AuditLog.create({
      collegeId,
      actorUserId: requester.id,
      action: 'HISTORICAL_MANUAL_ATTENDANCE_SESSION_CREATED',
      entityType: 'AttendanceSession',
      entityId: sessionDoc.id,
      newValue: {
        sessionId: sessionDoc.id,
        date: sessionCalendarStr,
        timeSlot: payload.timeSlot.trim(),
        subjectId: payload.subjectId,
        sectionId: payload.sectionId || null,
        totalStudents: preparedAttendanceRecords.length,
        sourceType: 'HISTORICAL_MANUAL',
      },
    });

    return sessionDoc;
  }

  /**
   * MODE B: HISTORICAL ATTENDANCE SUMMARIES ENTRY
   * Records accumulated historical totals (classesHeld, presentCount) or percentage-only metrics
   * without manufacturing fake AttendanceSession documents.
   */
  static async createHistoricalSummaries(
    requester: AuthenticatedUser,
    payload: CreateHistoricalSummariesPayload
  ): Promise<{ summaries: IHistoricalAttendanceSummary[]; count: number }> {
    if (requester.role === AppRole.STUDENT) {
      throw ApiError.forbidden('Students are not permitted to enter historical attendance summaries.');
    }

    const collegeId = requester.collegeId;
    if (!collegeId) {
      throw ApiError.badRequest('College ID is required.');
    }

    if (!payload.periodLabel || payload.periodLabel.trim().length === 0) {
      throw ApiError.badRequest('periodLabel is required for historical attendance summaries.');
    }

    if (!payload.entries || !Array.isArray(payload.entries) || payload.entries.length === 0) {
      throw ApiError.badRequest('At least one student summary entry is required.');
    }

    // Validate Academic Year
    if (!mongoose.Types.ObjectId.isValid(payload.academicYearId)) {
      throw ApiError.badRequest('Invalid academicYearId.');
    }
    const anyAy = await AcademicYear.findById(payload.academicYearId);
    if (!anyAy) {
      throw ApiError.notFound('Academic year not found.');
    }
    if (anyAy.collegeId.toString() !== collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited.');
    }

    // Validate Semester
    if (!mongoose.Types.ObjectId.isValid(payload.semesterId)) {
      throw ApiError.badRequest('Invalid semesterId.');
    }
    const anySem = await Semester.findById(payload.semesterId);
    if (!anySem) {
      throw ApiError.notFound('Semester not found.');
    }
    if (anySem.collegeId.toString() !== collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited.');
    }

    // Validate Subject
    if (!mongoose.Types.ObjectId.isValid(payload.subjectId)) {
      throw ApiError.badRequest('Invalid subjectId.');
    }
    const anySub = await Subject.findById(payload.subjectId);
    if (!anySub) {
      throw ApiError.notFound('Subject not found.');
    }
    if (anySub.collegeId.toString() !== collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited.');
    }
    const subjectDoc = anySub;

    // Validate Section if provided
    if (payload.sectionId) {
      if (!mongoose.Types.ObjectId.isValid(payload.sectionId)) {
        throw ApiError.badRequest('Invalid sectionId.');
      }
      const anySec = await Section.findById(payload.sectionId);
      if (!anySec) {
        throw ApiError.notFound('Section not found.');
      }
      if (anySec.collegeId.toString() !== collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited.');
      }
    }

    // Authorize requester
    await TeachingAuthorizationService.assertSubjectSectionAccess(
      collegeId,
      {
        id: requester.id,
        role: requester.role,
        collegeId: requester.collegeId,
        departmentId: requester.departmentId,
      },
      payload.subjectId,
      payload.sectionId,
      'enter historical attendance summaries'
    );

    const savedSummaries: IHistoricalAttendanceSummary[] = [];

    for (const entry of payload.entries) {
      if (!entry.studentEnrollmentId || !mongoose.Types.ObjectId.isValid(entry.studentEnrollmentId)) {
        throw ApiError.badRequest(`Invalid studentEnrollmentId: ${entry.studentEnrollmentId}`);
      }

      // Canonical student enrollment verification
      const enrollmentDoc = await StudentEnrollment.findOne({
        _id: entry.studentEnrollmentId,
        collegeId: new Types.ObjectId(collegeId),
      });

      if (!enrollmentDoc) {
        throw ApiError.badRequest(
          `Student enrollment '${entry.studentEnrollmentId}' does not belong to this college.`
        );
      }

      const rawHeld = entry.classesHeld;
      const rawPresent = entry.presentCount;
      const rawPct = entry.attendancePercentage;

      let precisionLevel: HistoricalAttendancePrecision = 'PERIOD_SUMMARY';
      let classesHeld: number | null = null;
      let presentCount: number | null = null;
      let absentCount: number | null = null;
      let attendancePercentage: number = 0;

      if (rawHeld !== null && rawHeld !== undefined) {
        // MODE B1: Count-based Period Summary
        classesHeld = Number(rawHeld);
        if (isNaN(classesHeld) || classesHeld < 0) {
          throw ApiError.badRequest('classesHeld must be a non-negative number.');
        }

        presentCount = Number(rawPresent ?? 0);
        if (isNaN(presentCount) || presentCount < 0) {
          throw ApiError.badRequest('presentCount must be a non-negative number.');
        }

        if (presentCount > classesHeld) {
          throw ApiError.badRequest(
            `presentCount (${presentCount}) cannot exceed classesHeld (${classesHeld}).`
          );
        }

        absentCount = Number(entry.absentCount ?? (classesHeld - presentCount));
        attendancePercentage =
          classesHeld > 0 ? Math.round((presentCount / classesHeld) * 10000) / 100 : 0;
        precisionLevel = 'PERIOD_SUMMARY';
      } else if (rawPct !== null && rawPct !== undefined) {
        // MODE B2: Percentage-Only Summary
        attendancePercentage = Number(rawPct);
        if (isNaN(attendancePercentage) || attendancePercentage < 0 || attendancePercentage > 100) {
          throw ApiError.badRequest('attendancePercentage must be between 0 and 100.');
        }

        // Strict Policy: NEVER fabricate classes held or present counts!
        classesHeld = null;
        presentCount = null;
        absentCount = null;
        precisionLevel = 'PERCENTAGE_ONLY';
      } else {
        throw ApiError.badRequest(
          'Each summary entry must provide either count totals (classesHeld, presentCount) or an attendancePercentage.'
        );
      }

      // Conflict / Idempotency check
      const existingSummary = await HistoricalAttendanceSummary.findOne({
        collegeId: new Types.ObjectId(collegeId),
        studentEnrollmentId: enrollmentDoc._id,
        subjectId: new Types.ObjectId(payload.subjectId),
        periodLabel: payload.periodLabel.trim(),
      });

      if (existingSummary) {
        if (
          existingSummary.classesHeld === classesHeld &&
          existingSummary.presentCount === presentCount &&
          existingSummary.attendancePercentage === attendancePercentage
        ) {
          // Idempotent retry match
          savedSummaries.push(existingSummary);
          continue;
        } else {
          // Update existing with audit
          existingSummary.classesHeld = classesHeld;
          existingSummary.presentCount = presentCount;
          existingSummary.absentCount = absentCount;
          existingSummary.attendancePercentage = attendancePercentage;
          existingSummary.precisionLevel = precisionLevel;
          existingSummary.remarks = entry.remarks || existingSummary.remarks;
          await existingSummary.save();

          savedSummaries.push(existingSummary);
          continue;
        }
      }

      const summaryDoc = await HistoricalAttendanceSummary.create({
        collegeId: new Types.ObjectId(collegeId),
        departmentId: subjectDoc.departmentId,
        courseId: subjectDoc.courseId || enrollmentDoc.courseId || null,
        academicYearId: payload.academicYearId ? new Types.ObjectId(payload.academicYearId) : null,
        semesterId: payload.semesterId ? new Types.ObjectId(payload.semesterId) : null,
        sectionId: payload.sectionId ? new Types.ObjectId(payload.sectionId) : null,
        subjectId: new Types.ObjectId(payload.subjectId),
        studentEnrollmentId: enrollmentDoc._id,
        studentId: enrollmentDoc.studentId,
        periodLabel: payload.periodLabel.trim(),
        periodStart: payload.periodStart ? new Date(payload.periodStart) : null,
        periodEnd: payload.periodEnd ? new Date(payload.periodEnd) : null,
        classesHeld,
        presentCount,
        absentCount,
        attendancePercentage,
        precisionLevel,
        sourceType: 'HISTORICAL_MANUAL',
        importBatchId: 'MANUAL_ENTRY',
        importedBy: new Types.ObjectId(requester.id),
        importedAt: new Date(),
        remarks: entry.remarks || null,
      });

      savedSummaries.push(summaryDoc);
    }

    // Audit Log
    await AuditLog.create({
      collegeId,
      actorUserId: requester.id,
      action: 'HISTORICAL_ATTENDANCE_SUMMARY_CREATED',
      entityType: 'HistoricalAttendanceSummary',
      entityId: (savedSummaries[0] && (savedSummaries[0] as any)._id ? (savedSummaries[0] as any)._id.toString() : payload.subjectId),
      newValue: {
        subjectId: payload.subjectId,
        sectionId: payload.sectionId || null,
        periodLabel: payload.periodLabel.trim(),
        entriesCount: savedSummaries.length,
        sourceType: 'HISTORICAL_MANUAL',
      },
    });

    return {
      summaries: savedSummaries,
      count: savedSummaries.length,
    };
  }

  /**
   * MODE C: STUDENT-SPECIFIC HISTORICAL ATTENDANCE CORRECTION
   */
  static async correctHistoricalStudentAttendance(
    requester: AuthenticatedUser,
    payload: CorrectHistoricalStudentAttendancePayload
  ): Promise<IAttendanceRecord> {
    const collegeId = requester.collegeId;
    if (!collegeId) throw ApiError.badRequest('College ID is required.');

    if (!payload.reason || payload.reason.trim().length < 5) {
      throw ApiError.badRequest('A descriptive reason (at least 5 characters) is required for attendance correction.');
    }

    const allowedStatuses = Object.values(AttendanceStatus);
    if (!allowedStatuses.includes(payload.newStatus)) {
      throw ApiError.badRequest(`Invalid attendance status: ${payload.newStatus}`);
    }

    // Path 1: Correct by existing recordId
    if (payload.recordId) {
      if (!mongoose.Types.ObjectId.isValid(payload.recordId)) {
        throw ApiError.badRequest('Invalid recordId.');
      }

      const record = await AttendanceRecord.findById(payload.recordId);
      if (!record) {
        throw ApiError.notFound('Attendance record not found.');
      }

      if (record.collegeId.toString() !== collegeId) {
        throw ApiError.forbidden('Cross-college attendance correction is strictly prohibited.');
      }

      // Check permission: Super Admin, College Admin, HOD within department, or Faculty who owns the session
      if (requester.role === AppRole.HOD) {
        const session = await AttendanceSession.findById(record.sessionId);
        if (!session || session.departmentId.toString() !== requester.departmentId) {
          throw ApiError.forbidden('HOD can only correct attendance within their own department.');
        }
      } else if (requester.role === AppRole.FACULTY) {
        const facultyProfile = await TeachingAuthorizationService.resolveFacultyProfile(collegeId, {
          id: requester.id,
          role: requester.role,
          collegeId: requester.collegeId,
          email: requester.email,
        });
        if (!facultyProfile || record.facultyId.toString() !== facultyProfile._id.toString()) {
          throw ApiError.forbidden('Faculty can only correct attendance records for sessions they own.');
        }
      }

      const previousStatus = record.status;
      record.oldStatus = previousStatus;
      record.status = payload.newStatus;
      record.remarks = payload.reason.trim();
      record.lastModified = new Date();
      record.modifiedBy = requester.id;
      await record.save();

      // Update parent session record item
      await AttendanceSession.updateOne(
        { _id: record.sessionId, 'records.studentId': record.studentId },
        {
          $set: {
            'records.$.oldStatus': previousStatus,
            'records.$.status': payload.newStatus,
            'records.$.remarks': payload.reason.trim(),
            'records.$.lastModified': new Date(),
            'records.$.modifiedBy': requester.id,
          },
        }
      );

      await AuditLog.create({
        collegeId,
        actorUserId: requester.id,
        action: 'ATTENDANCE_CORRECTED',
        entityType: 'AttendanceRecord',
        entityId: record.id,
        previousValue: { status: previousStatus },
        newValue: {
          status: payload.newStatus,
          reason: payload.reason.trim(),
          studentId: record.studentId.toString(),
          sessionId: record.sessionId.toString(),
        },
      });

      return record;
    }

    // Path 2: Record missing student into historical session by sessionId and studentEnrollmentId
    if (payload.sessionId && payload.studentEnrollmentId) {
      if (!mongoose.Types.ObjectId.isValid(payload.sessionId)) {
        throw ApiError.badRequest('Invalid sessionId.');
      }
      if (!mongoose.Types.ObjectId.isValid(payload.studentEnrollmentId)) {
        throw ApiError.badRequest('Invalid studentEnrollmentId.');
      }

      const session = await AttendanceSession.findById(payload.sessionId);
      if (!session) {
        throw ApiError.notFound('Attendance session not found.');
      }
      if (session.collegeId.toString() !== collegeId) {
        throw ApiError.forbidden('Cross-college attendance operation is strictly prohibited.');
      }

      const enrollment = await StudentEnrollment.findOne({
        _id: payload.studentEnrollmentId,
        collegeId: new Types.ObjectId(collegeId),
      }).populate('studentId', 'name rollNumber admissionNumber');

      if (!enrollment) {
        throw ApiError.notFound('Student enrollment not found in this college.');
      }

      const studentObj: any = enrollment.studentId || {};
      const studentName = studentObj.name || 'Student';
      const rollNumber = studentObj.rollNumber || studentObj.admissionNumber || '—';

      // Find or create record
      let record = await AttendanceRecord.findOne({
        sessionId: session._id,
        studentId: enrollment.studentId,
      });

      const previousStatus = record ? record.status : null;

      if (record) {
        record.oldStatus = previousStatus as AttendanceStatus;
        record.status = payload.newStatus;
        record.remarks = payload.reason.trim();
        record.lastModified = new Date();
        record.modifiedBy = requester.id;
        await record.save();

        await AttendanceSession.updateOne(
          { _id: session._id, 'records.studentId': enrollment.studentId },
          {
            $set: {
              'records.$.oldStatus': previousStatus,
              'records.$.status': payload.newStatus,
              'records.$.remarks': payload.reason.trim(),
              'records.$.lastModified': new Date(),
              'records.$.modifiedBy': requester.id,
            },
          }
        );
      } else {
        record = await AttendanceRecord.create({
          collegeId: session.collegeId,
          departmentId: session.departmentId,
          sessionId: session._id,
          studentId: enrollment.studentId,
          studentEnrollmentId: enrollment._id,
          studentName,
          rollNumber,
          sectionId: session.sectionId,
          subjectId: session.subjectId,
          courseId: session.courseId,
          academicYearId: session.academicYearId,
          semesterId: session.semesterId,
          facultyId: session.facultyId,
          date: session.date,
          timeSlot: session.timeSlot,
          status: payload.newStatus,
          remarks: payload.reason.trim(),
          isCancelled: false,
          sourceType: session.sourceType || 'HISTORICAL_MANUAL',
          modifiedBy: requester.id,
          lastModified: new Date(),
        });

        await AttendanceSession.updateOne(
          { _id: session._id },
          {
            $push: {
              records: {
                studentId: enrollment.studentId,
                studentName,
                rollNumber,
                sectionId: session.sectionId,
                status: payload.newStatus,
                remarks: payload.reason.trim(),
                lastModified: new Date(),
                modifiedBy: requester.id,
              },
            },
          }
        );
      }

      await AuditLog.create({
        collegeId,
        actorUserId: requester.id,
        action: 'HISTORICAL_STUDENT_ATTENDANCE_RECORDED',
        entityType: 'AttendanceRecord',
        entityId: record.id,
        previousValue: previousStatus ? { status: previousStatus } : null,
        newValue: {
          status: payload.newStatus,
          reason: payload.reason.trim(),
          studentId: (enrollment.studentId as any).toString(),
          sessionId: session.id,
        },
      });

      return record;
    }

    throw ApiError.badRequest('Either recordId or both sessionId and studentEnrollmentId must be provided.');
  }
}
